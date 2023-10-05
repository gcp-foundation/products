locals {
  pipeline_services         = ["artifactregistry.googleapis.com"]
  other_pipeline_encrypters = ["serviceAccount:${data.google_storage_project_service_account.pipeline_gcs_account.email_address}"]
  pipeline_encrypters       = concat([for identity in module.pipeline_service_identity : "serviceAccount:${identity.email}"], local.other_pipeline_encrypters)

  repositories     = ["devops", "management"]
  cloudbuild_image = "$_DEFAULT_REGION-docker.pkg.dev/$PROJECT_ID/$_GAR_REPOSITORY/terraform@sha256"
  cloudbuild_sha   = "123"
  pipelines = {
    devops = {
      repo            = "devops"
      service_account = "devops"
    }
    management = {
      repo            = "management"
      service_account = "management"
    }
  }
  service_accounts = {
    devops : {
      name : "devops"
      display_name : "Devops Pipeline Service Account"
      description : "Service Account for the devops pipeline"
    },
    management : {
      name : "management"
      display_name : "Management Pipeline Service Account"
      description : "Service Account for the management pipeline"
    }
  }

}

module "pipeline_service_identity" {
  source   = "github.com/gcp-foundation/modules//resources/service_identity?ref=0.0.1"
  for_each = toset(local.pipeline_services)
  project  = module.projects["devops/pipelines"].project_id
  service  = each.value

  depends_on = [module.projects["devops/pipelines"]]
}

data "google_storage_project_service_account" "pipeline_gcs_account" {
  project = module.projects["devops/pipelines"].project_id

  depends_on = [module.projects["devops/pipelines"].services]
}

module "pipeline_kms_key" {
  source        = "github.com/gcp-foundation/modules//kms/key?ref=0.0.1"
  name          = module.projects["devops/pipelines"].project_id
  key_ring_name = module.projects["devops/pipelines"].project_id
  project       = module.projects["devops/pipelines"].project_id
  location      = var.location
  encrypters    = local.pipeline_encrypters
  decrypters    = local.pipeline_encrypters

  depends_on = [module.projects["devops/pipelines"].services]
}

module "artifact_registry" {
  source = "github.com/gcp-foundation/modules//devops/artifact_registry?ref=0.0.1"

  name        = "cloudbuild"
  description = "Docker containers for cloudbuild"
  project     = module.projects["devops/pipelines"].project_id
  location    = var.location

  kms_key_id = module.pipeline_kms_key.key_id

  depends_on = [module.pipeline_kms_key.encrypters, module.pipeline_kms_key.decrypters, module.projects["devops/pipelines"].services]
}

module "build_output" {
  source              = "github.com/gcp-foundation/modules//storage/bucket?ref=0.0.1"
  name                = "build-outputs"
  project             = module.projects["devops/pipelines"].project_id
  location            = var.location
  data_classification = "internal"
  kms_key_id          = module.pipeline_kms_key.key_id

  depends_on = [module.pipeline_kms_key.encrypters, module.pipeline_kms_key.decrypters, module.projects["devops/pipelines"].services]
}

module "repository" {
  source   = "github.com/gcp-foundation/modules//devops/repository?ref=0.0.1"
  for_each = toset(local.repositories)

  name    = each.value
  project = module.projects["devops/pipelines"].project_id

  depends_on = [module.projects["devops/pipelines"].services]
}

resource "google_cloudbuild_trigger" "plan-trigger" {
  # module "plan_trigger" {
  #   source   = "github.com/gcp-foundation/modules//devops/cloudbuild?ref=0.0.1"
  for_each = local.pipelines

  project     = module.projects["devops/pipelines"].project_id
  location    = var.location
  name        = "${each.key}-terraform-plan"
  description = "Terraform plan for ${each.key}"

  trigger_template {
    branch_name  = "main"
    repo_name    = module.repository[each.value.repo].name
    invert_regex = true
  }

  service_account = module.service_account[each.value.service_account].id

  substitutions = {
    _DEFAULT_REGION       = var.location
    _ARTIFACT_BUCKET_NAME = module.build_output.name
  }

  dynamic "build" {
    for_each = [{ "${each.key}" = each.value }]
    content {

      dynamic "step" {
        for_each = [local.steps.init, local.steps.plan]

        content {
          id         = step.value.id
          name       = join(":", [local.cloudbuild_image, local.cloudbuild_sha])
          entrypoint = step.value.entrypoint
          args       = step.value.args
        }
      }

      timeout     = try(each.value.timeout, "600s")
      logs_bucket = join("/", ["gs://${module.build_output.name}/terraform/cloudbuild", "plan", "$BUILD_ID"])
      artifacts {
        objects {
          location = join("/", ["gs://${module.build_output.name}/terraform/cloudbuild]", "plan", "$BUILD_ID"])
          paths    = ["tmp_plan.*.tfplan", "tmp_plan/*.tfinit"]
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

  project     = module.projects["devops/pipelines"].project_id
  location    = var.location
  name        = "${each.key}-terraform-apply"
  description = "Terraform plan for ${each.key}"

  trigger_template {
    branch_name = "main"
    repo_name   = module.repository[each.value.repo].name
  }

  service_account = module.service_account[each.value.service_account].id

  substitutions = {
    _DEFAULT_REGION       = var.location
    _ARTIFACT_BUCKET_NAME = module.build_output.name
  }

  dynamic "build" {
    for_each = [{ "${each.key}" = each.value }]
    content {

      dynamic "step" {
        for_each = [local.steps.init, local.steps.plan, local.steps.apply]

        content {
          id         = step.value.id
          name       = join(":", [local.cloudbuild_image, local.cloudbuild_sha])
          entrypoint = step.value.entrypoint
          args       = step.value.args
        }
      }

      timeout     = try(each.value.timeout, "600s")
      logs_bucket = join("/", ["gs://${module.build_output.name}/terraform/cloudbuild", "plan", "$BUILD_ID"])
      artifacts {
        objects {
          location = join("/", ["gs://${module.build_output.name}/terraform/cloudbuild]", "plan", "$BUILD_ID"])
          paths    = ["tmp_plan.*.tfplan", "tmp_plan/*.tfinit"]
        }
      }
    }
  }

  depends_on = [google_service_account_iam_member.sa_cloudbuild_token_creator]
}
