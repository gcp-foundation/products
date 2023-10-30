locals {
  repositories              = toset(distinct([for pipeline in var.pipelines : pipeline.repo]))
  pipeline_service_accounts = toset(distinct([for pipeline in var.pipelines : pipeline.service_account]))
}

###############################################################################
# Create a KMS key for this project with permissions for the google service accounts to use it
###############################################################################

module "pipeline_kms_key" {
  source        = "github.com/gcp-foundation/modules//kms/key?ref=0.0.2"
  name          = var.project_pipelines.project_id
  key_ring_name = var.project_pipelines.project_id
  project       = var.project_pipelines.project_id
  location      = var.location
  services      = ["artifactregistry.googleapis.com", "storage.googleapis.com"]
}

###############################################################################
# Create an artifact registry for the cloudbuild images encrypted with the kms key
###############################################################################

module "artifact_registry" {
  source = "github.com/gcp-foundation/modules//devops/artifact_registry?ref=0.0.2"

  name        = local.gar_name
  description = "Docker containers for cloudbuild"
  project     = var.project_pipelines.project_id
  location    = var.location

  kms_key_id = module.pipeline_kms_key.key_id

  depends_on = [module.pipeline_kms_key.encrypters, module.pipeline_kms_key.decrypters]
}

###############################################################################
# Create a cloudbuild image for terraform 
###############################################################################

# resource "null_resource" "cloudbuild_terraform_builder" {
#   triggers = {
#     project_id                  = var.project_pipelines
#     terraform_version_sha256sum = local.terraform_version_sha256sum
#     terraform_version           = local.terraform_version
#     gar_name                    = local.gar_name
#     gar_location                = module.artifact_registry.location
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#     gcloud builds submit ${path.module}/cloudbuild_builder/ --project ${var.project_pipelines} --config=${path.module}/cloudbuild_builder/cloudbuild.yaml --substitutions=_GCLOUD_VERSION=${local.gcloud_version},_TERRAFORM_VERSION=${local.terraform_version},_TERRAFORM_VERSION_SHA256SUM=${local.terraform_version_sha256sum},_REGION=${module.artifact_registry.location},_REPOSITORY=${local.gar_name}
#   EOT
#   }

# }

###############################################################################
# Create a storage bucket for the cloudbuild output, encrypted with the kms key
###############################################################################

module "build_output" {
  source              = "github.com/gcp-foundation/modules//storage/bucket?ref=0.0.2"
  name                = "build-outputs"
  project             = var.project_pipelines.project_id
  location            = var.location
  data_classification = "internal"
  kms_key_id          = module.pipeline_kms_key.key_id
}

###############################################################################
# Need to create an org policy to allow service accounts from control to be used in pipelines
###############################################################################

resource "google_project_organization_policy" "iam_disableCrossProjectServiceAccountUsage" {
  project    = var.project_control.project_id
  constraint = "iam.disableCrossProjectServiceAccountUsage"
  boolean_policy {
    enforced = false
  }
}

###############################################################################
# Create cloud source repositories for holding the source code
###############################################################################

module "repository" {
  source   = "github.com/gcp-foundation/modules//devops/repository?ref=0.0.2"
  for_each = toset(local.repositories)

  name    = each.value
  project = var.project_pipelines.project_id
}

###############################################################################
# Create cloud source repositories for holding the source code
###############################################################################

resource "google_artifact_registry_repository_iam_member" "sa-project-artifact-reader" {
  for_each   = local.pipeline_service_accounts
  project    = module.artifact_registry.project
  location   = module.artifact_registry.location
  repository = module.artifact_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.service_accounts[each.key].email}"
}

###############################################################################
# Give service accounts permission to use themselves...
###############################################################################

resource "google_service_account_iam_member" "sa_service_account_user" {
  for_each           = local.pipeline_service_accounts
  service_account_id = var.service_accounts[each.key].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.service_accounts[each.key].email}"
}

###############################################################################
# Give service accounts permission to impersonate themselves...
###############################################################################

resource "google_service_account_iam_member" "sa_service_account_token_creator" {
  for_each           = local.pipeline_service_accounts
  service_account_id = var.service_accounts[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${var.service_accounts[each.key].email}"
}

###############################################################################
# Give cloudbuild master service account permission to impersonate pipeline service accounts
###############################################################################

resource "google_service_account_iam_member" "sa_cloudbuild_token_creator" {
  for_each           = local.pipeline_service_accounts
  service_account_id = var.service_accounts[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${var.project_pipelines.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

###############################################################################
# Give pipeline service accounts permission to write to cloudbuild output bucket
###############################################################################

resource "google_storage_bucket_iam_member" "sa_service_account_output_storage_admin" {
  for_each = local.pipeline_service_accounts
  bucket   = module.build_output.name
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${var.service_accounts[each.key].email}"
}

###############################################################################
# Create a cloudbuild trigger to build terraform cloudbuild image
###############################################################################

module "cloudbuild_repo" {
  source = "github.com/gcp-foundation/modules//devops/repository?ref=0.0.1"

  name    = "cloudbuild"
  project = var.project_pipelines.project_id
}

###############################################################################
# Create a cloudbuild trigger to build terraform cloudbuild image
###############################################################################

locals {
  cloudbuild_image = "${var.location}-docker.pkg.dev/${var.project_pipelines.project_id}/${local.gar_name}/terraform@sha256"
  gar_name         = "cloudbuild"

  terraform_version           = "1.5.7"
  gcloud_version              = "388.0.0"
  terraform_version_sha256sum = "c0ed7bc32ee52ae255af9982c8c88a7a4c610485cf1d55feeb037eab75fa082c"
  # terraform_version           = "1.6.2"
  # gcloud_version              = "452.0.1"
  # terraform_version_sha256sum = "107142241b12ff78b6eb9c419757d406a8714704f7928750a662ba19de055e98"
  tags  = ["terraform_${local.terraform_version}", "gcloud_${local.gcloud_version}", "latest"]
  image = "$${_REGION}-docker.pkg.dev/$${PROJECT_ID}/$${_REPOSITORY}/terraform"
}

resource "google_cloudbuild_trigger" "build_image" {
  project     = var.project_pipelines.project_id
  location    = var.location
  name        = "terraform-docker"
  description = "Trigger for building cloudbuild image"

  trigger_template {
    branch_name = "main"
    repo_name   = module.cloudbuild_repo.name
  }

  # service_account = var.service_accounts["service_account"].id

  substitutions = {
    _DEFAULT_REGION              = var.location
    _ARTIFACT_BUCKET_NAME        = module.build_output.name
    _TERRAFORM_VERSION           = local.terraform_version
    _TERRAFORM_VERSION_SHA256SUM = local.terraform_version_sha256sum
    _GCLOUD_VERSION              = local.gcloud_version
    _REGION                      = module.artifact_registry.location
    _REPOSITORY                  = local.gar_name
  }

  build {
    step {
      id   = "build_image"
      name = "gcr.io/cloud-builders/docker"
      args = concat(
        ["build"],
        [for tag in local.tags : "--tag=${local.image}:${tag}"],
        ["--build-arg=GCLOUD_VERSION=$${_GCLOUD_VERSION}-slim"],
        ["--build-arg=TERRAFORM_VERSION=$${_TERRAFORM_VERSION}"],
        ["--build-arg=TERRAFORM_VERSION_SHA256SUM=$${_TERRAFORM_VERSION_SHA256SUM}"],
        ["."]
      )
    }
    step {
      id   = "test_image"
      name = "${local.image}:terraform_${local.terraform_version}"
      args = ["version"]
    }

    images = [
      for image in local.tags : "${local.image}:${image}"
    ]
    # logs_bucket = join("/", ["gs://$${module.build_output.name}/terraform/cloudbuild", "plan", "$BUILD_ID"])
  }

  # depends_on = [google_service_account_iam_member.sa_cloudbuild_token_creator]
}

###############################################################################
# Create a cloudbuild trigger on any branch except main to run a plan
###############################################################################

resource "google_cloudbuild_trigger" "plan-trigger" {
  # module "plan_trigger" {
  #   source   = "github.com/gcp-foundation/modules//devops/cloudbuild?ref=0.0.1"
  for_each = var.pipelines

  project     = var.project_pipelines.project_id
  location    = var.location
  name        = "${each.key}-terraform-plan"
  description = "Terraform plan for ${each.key}"

  trigger_template {
    branch_name  = "main"
    repo_name    = module.repository[each.value.repo].name
    invert_regex = true
  }

  service_account = var.service_accounts[each.value.service_account].id

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

###############################################################################
# Create a cloudbuild trigger on the main branch run an apply
###############################################################################

resource "google_cloudbuild_trigger" "apply-trigger" {
  # module "plan_trigger" {
  #   source   = "github.com/gcp-foundation/modules//devops/cloudbuild?ref=0.0.1"
  for_each = var.pipelines

  project     = var.project_pipelines.project_id
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

  service_account = var.service_accounts[each.value.service_account].id

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
