locals {
  control_encrypters = ["serviceAccount:${data.google_storage_project_service_account.control_gcs_account.email_address}"]
}

# Uses organization policy V1 to avoid needing to set quota project during bootstrap
resource "google_project_organization_policy" "iam_disableCrossProjectServiceAccountUsage" {
  project    = module.projects.project_id
  constraint = "iam.disableCrossProjectServiceAccountUsage"
  boolean_policy {
    enforced = false
  }
}

data "google_storage_project_service_account" "control_gcs_account" {
  project = module.projects.project_id

  depends_on = [module.projects]
}

module "control_kms_key" {
  source        = "github.com/XBankGCPOrg/gcp-lz-modules//kms/key?ref=v0.0.1"
  name          = module.projects.project_id
  key_ring_name = module.projects.project_id
  project       = module.projects.project_id
  location      = var.location
  encrypters    = local.control_encrypters
  decrypters    = local.control_encrypters

  depends_on = [module.projects]
}

module "state_files" {
  source              = "github.com/XBankGCPOrg/gcp-lz-modules//storage/bucket?ref=v0.0.1"
  name                = var.gcs_terraform_bucket_name
  project             = module.projects.project_id
  location            = var.location
  data_classification = "terraform_state"
  kms_key_id          = module.control_kms_key.key_id

  depends_on = [module.control_kms_key.encrypters, module.control_kms_key.decrypters]
}

module "service_account" {
  source   = "github.com/XBankGCPOrg/gcp-lz-modules//iam/service_account?ref=v0.0.1"
  for_each = { for sa in var.service_accounts.service_accounts : sa.name => sa }

  name         = "sa-${each.value.name}"
  display_name = each.value.display_name
  description  = each.value.description
  project      = module.projects.project_id
}

resource "google_service_account_iam_member" "sa_service_account_user" {
  for_each           = { for sa in var.service_accounts.service_accounts : sa.name => sa }
  service_account_id = module.service_account[each.key].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.service_account[each.key].email}"
}

resource "google_service_account_iam_member" "sa_service_account_token_creator" {
  for_each           = { for sa in var.service_accounts.service_accounts : sa.name => sa }
  service_account_id = module.service_account[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.service_account[each.key].email}"
}

# Change this to object admin
resource "google_storage_bucket_iam_member" "sa_service_account_state_storage_admin" {
  for_each = { for sa in var.service_accounts.service_accounts : sa.name => sa }
  bucket   = module.state_files.name
  role     = "roles/storage.admin"
  member   = "serviceAccount:${module.service_account[each.key].email}"
}

resource "google_billing_account_iam_member" "binding" {
  for_each           = { for sa in var.service_accounts.service_accounts : sa.name => sa if sa.billing_user }
  billing_account_id = var.billing_account
  role               = "roles/billing.user"
  member             = "serviceAccount:${module.service_account[each.key].email}"
}