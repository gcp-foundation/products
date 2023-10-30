###############################################################################
# Identify service accounts in the control project
###############################################################################

locals {
  regex_sa = "projects\\/(?P<project>.*)\\/serviceAccounts/(?P<name>.*)@(?P<domain>.*)\\.iam\\.gserviceaccount\\.com"

  pipeline_service_accounts = merge(
    { for pipeline in try(var.cloudbuild_pipelines.pipelines, {}) : pipeline.service_account => local.resources.service_accounts[pipeline.service_account] },
    { for pipeline in try(var.github_pipelines.pipelines, {}) : pipeline.service_account => local.resources.service_accounts[pipeline.service_account] }
  )
}

###############################################################################
# Create a KMS key for this project with permissions for the storage service account to use it
###############################################################################

module "control_kms_key" {
  source        = "github.com/gcp-foundation/modules//kms/key?ref=0.0.2"
  name          = module.resources.projects[local.environment.project_control].project_id
  key_ring_name = module.resources.projects[local.environment.project_control].project_id
  project       = module.resources.projects[local.environment.project_control].project_id
  location      = var.location
  services      = ["storage.googleapis.com"]

  depends_on = [module.resources.projects]
}

###############################################################################
# Create a storage bucket for holding statefiles 
###############################################################################

module "state_files" {
  source              = "github.com/gcp-foundation/modules//storage/bucket?ref=0.0.2"
  name                = "tfstate"
  project             = module.resources.projects[local.environment.project_control].project_id
  location            = var.location
  data_classification = "terraform_state"
  kms_key_id          = module.control_kms_key.key_id

  depends_on = [module.control_kms_key.encrypters, module.control_kms_key.decrypters]
}

###############################################################################
# Give the service accounts in the control project permission to use the state file storage bucket
###############################################################################

resource "google_storage_bucket_iam_member" "sa_service_account_state_storage_admin" {
  for_each = local.pipeline_service_accounts
  bucket   = module.state_files.name
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${module.resources.service_accounts[each.key].email}"
}

###############################################################################
# Need to consider how to do billing
###############################################################################

# resource "google_billing_account_iam_member" "sa_service_account_billing_user" {
#   for_each           = local.pipeline_service_accounts
#   billing_account_id = var.billing_account
#   role               = "roles/billing.user"
#   member             = "serviceAccount:${module.resources.service_accounts[each.key].email}"
# }

# resource "google_billing_account_iam_member" "sa_service_account_billing_admin" {
#   for_each           = local.service_accounts
#   billing_account_id = var.billing_account_id
#   role               = "roles/billing.admin"
#   member             = "serviceAccount:${module.service_accounts[each.key].email}"
# }*/
