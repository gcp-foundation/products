locals {
  control_services         = []
  other_control_encrypters = ["serviceAccount:${data.google_storage_project_service_account.control_gcs_account.email_address}"]
  control_encrypters       = concat([for identity in module.control_service_identity : "serviceAccount:${identity.email}"], local.other_control_encrypters)

  pipeline_service_accounts = {
    for entry in local.service_accounts : entry.service_account.name => entry.service_account if entry.project.displayName == "control"
  }
}

module "control_service_identity" {
  source   = "github.com/gcp-foundation/modules//resources/service_identity?ref=0.0.1"
  for_each = toset(local.pipeline_services)
  project  = module.projects[local.environment.project_control].project_id
  service  = each.value

  depends_on = [module.projects]
}

data "google_storage_project_service_account" "control_gcs_account" {
  project = module.projects[local.environment.project_control].project_id

  depends_on = [module.projects]
}

module "control_kms_key" {
  source        = "github.com/gcp-foundation/modules//kms/key?ref=0.0.1"
  name          = module.projects[local.environment.project_control].project_id
  key_ring_name = module.projects[local.environment.project_control].project_id
  project       = module.projects[local.environment.project_control].project_id
  location      = var.location
  encrypters    = local.control_encrypters
  decrypters    = local.control_encrypters

  depends_on = [module.projects]
}

module "state_files" {
  source              = "github.com/gcp-foundation/modules//storage/bucket?ref=0.0.1"
  name                = "tfstate"
  project             = module.projects[local.environment.project_control].project_id
  location            = var.location
  data_classification = "terraform_state"
  kms_key_id          = module.control_kms_key.key_id

  depends_on = [module.control_kms_key.encrypters, module.control_kms_key.decrypters]
}

resource "google_storage_bucket_iam_member" "sa_service_account_state_storage_admin" {
  for_each = local.pipeline_service_accounts
  bucket   = module.state_files.name
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${module.service_accounts[each.key].email}"
}

/* Need to determine best approach for billing
resource "google_storage_bucket_iam_member" "sa_service_account_billing_user" {
  for_each           = local.service_accounts
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${module.service_accounts[each.key].email}"
}

resource "google_storage_bucket_iam_member" "sa_service_account_billing_admin" {
  for_each           = local.service_accounts
  billing_account_id = var.billing_account_id
  role               = "roles/billing.admin"
  member             = "serviceAccount:${module.service_accounts[each.key].email}"
}
*/
