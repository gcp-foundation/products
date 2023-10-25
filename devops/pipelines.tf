locals {
  pipeline_services         = ["artifactregistry.googleapis.com"]
  other_pipeline_encrypters = ["serviceAccount:${data.google_storage_project_service_account.pipeline_gcs_account.email_address}"]
  pipeline_encrypters       = concat([for identity in module.pipeline_service_identity : "serviceAccount:${identity.email}"], local.other_pipeline_encrypters)

  gar_name         = "cloudbuild"
  cloudbuild_image = "${var.location}-docker.pkg.dev/${module.projects[local.environment.project_pipelines].project_id}/${local.gar_name}/terraform@sha256"

  repositories = ["devops", "management"]
  pipelines = {
    devops = {
      repo            = "devops"
      service_account = "sa-devops"
      storage_bucket  = "tfstate"
    }
    management = {
      repo            = "management"
      service_account = "sa-management"
      storage_bucket  = "tfstate"
    }
  }

  terraform_version_sha256sum = "c0ed7bc32ee52ae255af9982c8c88a7a4c610485cf1d55feeb037eab75fa082c"
  terraform_version           = "1.5.7"
  gcloud_version              = "388.0.0-slim"
}



module "pipeline_service_identity" {
  source   = "github.com/gcp-foundation/modules//resources/service_identity?ref=0.0.1"
  for_each = toset(local.pipeline_services)
  project  = module.projects[local.environment.project_pipelines].project_id
  service  = each.value

  depends_on = [module.projects]
}

data "google_storage_project_service_account" "pipeline_gcs_account" {
  project = module.projects[local.environment.project_pipelines].project_id

  depends_on = [module.projects]
}

module "pipeline_kms_key" {
  source        = "github.com/gcp-foundation/modules//kms/key?ref=0.0.1"
  name          = module.projects[local.environment.project_pipelines].project_id
  key_ring_name = module.projects[local.environment.project_pipelines].project_id
  project       = module.projects[local.environment.project_pipelines].project_id
  location      = var.location
  encrypters    = local.pipeline_encrypters
  decrypters    = local.pipeline_encrypters

  depends_on = [module.projects]
}

module "artifact_registry" {
  source = "github.com/gcp-foundation/modules//devops/artifact_registry?ref=0.0.1"

  name        = local.gar_name
  description = "Docker containers for cloudbuild"
  project     = module.projects[local.environment.project_pipelines].project_id
  location    = var.location

  kms_key_id = module.pipeline_kms_key.key_id

  depends_on = [module.projects, module.pipeline_kms_key.encrypters, module.pipeline_kms_key.decrypters]
}

resource "null_resource" "cloudbuild_terraform_builder" {
  triggers = {
    project_id                  = module.projects[local.environment.project_pipelines].project_id
    terraform_version_sha256sum = local.terraform_version_sha256sum
    terraform_version           = local.terraform_version
    gar_name                    = local.gar_name
    gar_location                = module.artifact_registry.location
  }

  provisioner "local-exec" {
    command = <<EOT
    gcloud builds submit ${path.module}/cloudbuild_builder/ --project ${module.projects[local.environment.project_pipelines].project_id} --config=${path.module}/cloudbuild_builder/cloudbuild.yaml --substitutions=_GCLOUD_VERSION=${local.gcloud_version},_TERRAFORM_VERSION=${local.terraform_version},_TERRAFORM_VERSION_SHA256SUM=${local.terraform_version_sha256sum},_REGION=${module.artifact_registry.location},_REPOSITORY=${local.gar_name}
  EOT
  }

  depends_on = [module.artifact_registry]
}

module "build_output" {
  source              = "github.com/gcp-foundation/modules//storage/bucket?ref=0.0.1"
  name                = "build-outputs"
  project             = module.projects[local.environment.project_pipelines].project_id
  location            = var.location
  data_classification = "internal"
  kms_key_id          = module.pipeline_kms_key.key_id

  depends_on = [module.projects, module.pipeline_kms_key.encrypters, module.pipeline_kms_key.decrypters]
}

# Uses organization policy V1 to avoid needing to set quota project during bootstrap
resource "google_project_organization_policy" "iam_disableCrossProjectServiceAccountUsage" {
  project    = module.projects[local.environment.project_control].project_id
  constraint = "iam.disableCrossProjectServiceAccountUsage"
  boolean_policy {
    enforced = false
  }
}

module "repository" {
  source   = "github.com/gcp-foundation/modules//devops/repository?ref=0.0.1"
  for_each = toset(local.repositories)

  name    = each.value
  project = module.projects[local.environment.project_pipelines].project_id

  depends_on = [module.projects]
}

// Permisions to pipeline service accounts for cloudbuild pipelines
resource "google_artifact_registry_repository_iam_member" "sa-project-artifact-reader" {
  for_each   = local.pipeline_service_accounts
  project    = module.artifact_registry.project
  location   = module.artifact_registry.location
  repository = module.artifact_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.service_accounts[each.key].email}"
}

resource "google_service_account_iam_member" "sa_service_account_user" {
  for_each           = local.pipeline_service_accounts
  service_account_id = module.service_accounts[each.key].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.service_accounts[each.key].email}"
}

resource "google_service_account_iam_member" "sa_service_account_token_creator" {
  for_each           = local.pipeline_service_accounts
  service_account_id = module.service_accounts[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.service_accounts[each.key].email}"
}

resource "google_service_account_iam_member" "sa_cloudbuild_token_creator" {
  for_each           = local.pipeline_service_accounts
  service_account_id = module.service_accounts[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${module.projects[local.environment.project_pipelines].number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "sa_service_account_output_storage_admin" {
  for_each = local.pipeline_service_accounts
  bucket   = module.build_output.name
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${module.service_accounts[each.key].email}"
}

resource "google_cloudbuild_trigger" "plan-trigger" {
  # module "plan_trigger" {
  #   source   = "github.com/gcp-foundation/modules//devops/cloudbuild?ref=0.0.1"
  for_each = local.pipelines

  project     = module.projects[local.environment.project_pipelines].project_id
  location    = var.location
  name        = "${each.key}-terraform-plan"
  description = "Terraform plan for ${each.key}"

  trigger_template {
    branch_name  = "main"
    repo_name    = module.repository[each.value.repo].name
    invert_regex = true
  }

  service_account = module.service_accounts[each.value.service_account].id

  substitutions = {
    _DEFAULT_REGION       = var.location
    _ARTIFACT_BUCKET_NAME = module.build_output.name
    _CLOUDBUILD_SHA       = var.cloudbuild_sha
  }

  dynamic "build" {
    for_each = [{ "${each.key}" = each.value }]
    content {

      dynamic "step" {
        for_each = [local.steps.init, local.steps.plan]

        content {
          id         = step.value.id
          name       = join(":", [local.cloudbuild_image, "$_CLOUDBUILD_SHA"])
          entrypoint = step.value.entrypoint
          args       = step.value.args
        }
      }

      timeout     = try(each.value.timeout, "600s")
      logs_bucket = join("/", ["gs://${module.build_output.name}/terraform/cloudbuild", "plan", "$BUILD_ID"])
      artifacts {
        objects {
          location = join("/", ["gs://${module.build_output.name}/terraform/cloudbuild", "plan", "$BUILD_ID"])
          paths    = ["*.tfplan"]
        }
      }
    }
  }

  depends_on = [google_service_account_iam_member.sa_cloudbuild_token_creator]
}

resource "google_cloudbuild_trigger" "apply-trigger" {
  # module "plan_trigger" {
  #   source   = "github.com/gcp-foundation/modules//devops/cloudbuild?ref=0.0.1"
  for_each = local.pipelines

  project     = module.projects[local.environment.project_pipelines].project_id
  location    = var.location
  name        = "${each.key}-terraform-apply"
  description = "Terraform apply for ${each.key}"

  trigger_template {
    branch_name = "main"
    repo_name   = module.repository[each.value.repo].name
  }

  # dynamic "github" {
  #   content {
  #     owner = github.value.owner
  #     name  = github.value.name

  #     dynamic "pull_request" {
  #       for_each = github.value.is_pr_trigger ? { (github.key) = github.value } : {}
  #       content {
  #         branch          = pull_request.value.branch_regex
  #         comment_control = pull_request.value.comment_control
  #         invert_regex    = var.invert_regex
  #       }
  #     }

  #     dynamic "push" {
  #       for_each = github.value.is_pr_trigger ? {} : { (github.key) = github.value }
  #       content {
  #         branch       = push.value.branch_regex
  #         tag          = push.value.tag_regex
  #         invert_regex = var.invert_regex
  #       }
  #     }
  #   }
  # }

  service_account = module.service_accounts[each.value.service_account].id

  substitutions = {
    _DEFAULT_REGION       = var.location
    _ARTIFACT_BUCKET_NAME = module.build_output.name
    _CLOUDBUILD_SHA       = var.cloudbuild_sha
  }

  dynamic "build" {
    for_each = [{ "${each.key}" = each.value }]
    content {

      dynamic "step" {
        for_each = [local.steps.init, local.steps.plan, local.steps.apply]

        content {
          id         = step.value.id
          name       = join(":", [local.cloudbuild_image, "$_CLOUDBUILD_SHA"])
          entrypoint = step.value.entrypoint
          args       = step.value.args
        }
      }

      timeout     = try(each.value.timeout, "600s")
      logs_bucket = join("/", ["gs://${module.build_output.name}/terraform/cloudbuild", "plan", "$BUILD_ID"])
      artifacts {
        objects {
          location = join("/", ["gs://${module.build_output.name}/terraform/cloudbuild", "plan", "$BUILD_ID"])
          paths    = ["*.tfplan"]
        }
      }
    }
  }

  depends_on = [google_service_account_iam_member.sa_cloudbuild_token_creator]
}
