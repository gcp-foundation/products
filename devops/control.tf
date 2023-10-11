locals {
  control_services         = []
  other_control_encrypters = ["serviceAccount:${data.google_storage_project_service_account.control_gcs_account.email_address}"]
  control_encrypters       = concat([for identity in module.control_service_identity : "serviceAccount:${identity.email}"], local.other_control_encrypters)
}

module "control_service_identity" {
  source   = "github.com/gcp-foundation/modules//resources/service_identity?ref=0.0.1"
  for_each = toset(local.pipeline_services)
  project  = module.projects["devops/${local.environment.project_control}"].project_id
  service  = each.value

  depends_on = [module.projects]
}

# Uses organization policy V1 to avoid needing to set quota project during bootstrap
resource "google_project_organization_policy" "iam_disableCrossProjectServiceAccountUsage" {
  project    = module.projects["devops/${local.environment.project_control}"].project_id
  constraint = "iam.disableCrossProjectServiceAccountUsage"
  boolean_policy {
    enforced = false
  }
}

data "google_storage_project_service_account" "control_gcs_account" {
  project = module.projects["devops/${local.environment.project_control}"].project_id

  depends_on = [module.projects]
}

module "control_kms_key" {
  source        = "github.com/gcp-foundation/modules//kms/key?ref=0.0.1"
  name          = module.projects["devops/${local.environment.project_control}"].project_id
  key_ring_name = module.projects["devops/${local.environment.project_control}"].project_id
  project       = module.projects["devops/${local.environment.project_control}"].project_id
  location      = var.location
  encrypters    = local.control_encrypters
  decrypters    = local.control_encrypters

  depends_on = [module.projects]
}

module "state_files" {
  source              = "github.com/gcp-foundation/modules//storage/bucket?ref=0.0.1"
  name                = "tfstate"
  project             = module.projects["devops/${local.environment.project_control}"].project_id
  location            = var.location
  data_classification = "terraform_state"
  kms_key_id          = module.control_kms_key.key_id

  depends_on = [module.control_kms_key.encrypters, module.control_kms_key.decrypters]
}

module "service_account" {
  source   = "github.com/gcp-foundation/modules//iam/service_account?ref=0.0.1"
  for_each = local.service_accounts

  name         = "sa-${each.value.name}"
  display_name = each.value.display_name
  description  = each.value.description
  project      = module.projects["devops/${local.environment.project_control}"].project_id
}

resource "google_project_iam_member" "sa_project_log_writer" {
  for_each = local.service_accounts
  project  = module.projects["devops/${local.environment.project_pipelines}"].project_id
  role     = "roles/logging.logWriter"
  member   = "serviceAccount:${module.service_account[each.key].email}"
}

resource "google_project_iam_member" "sa_project_source_reader" {
  for_each = local.service_accounts
  project  = module.projects["devops/${local.environment.project_pipelines}"].project_id
  role     = "roles/source.reader"
  member   = "serviceAccount:${module.service_account[each.key].email}"
}

resource "google_project_iam_member" "sa_project_builder" {
  for_each = local.service_accounts
  project  = module.projects["devops/${local.environment.project_pipelines}"].project_id
  role     = "roles/cloudbuild.builds.builder"
  member   = "serviceAccount:${module.service_account[each.key].email}"
}

resource "google_artifact_registry_repository_iam_member" "sa-project-artifact-reader" {
  for_each   = local.service_accounts
  project    = module.artifact_registry.project
  location   = module.artifact_registry.location
  repository = module.artifact_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.service_account[each.key].email}"
}

resource "google_service_account_iam_member" "sa_service_account_user" {
  for_each           = local.service_accounts
  service_account_id = module.service_account[each.key].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.service_account[each.key].email}"
}

resource "google_service_account_iam_member" "sa_service_account_token_creator" {
  for_each           = local.service_accounts
  service_account_id = module.service_account[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.service_account[each.key].email}"
}

resource "google_service_account_iam_member" "sa_cloudbuild_token_creator" {
  for_each           = local.service_accounts
  service_account_id = module.service_account[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${module.projects["devops/${local.environment.project_pipelines}"].number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Change this to object admin
resource "google_storage_bucket_iam_member" "sa_service_account_output_storage_admin" {
  for_each = local.service_accounts
  bucket   = module.build_output.name
  role     = "roles/storage.admin"
  member   = "serviceAccount:${module.service_account[each.key].email}"
}

# Change this to object admin
resource "google_storage_bucket_iam_member" "sa_service_account_state_storage_admin" {
  for_each = local.service_accounts
  bucket   = module.state_files.name
  role     = "roles/storage.admin"
  member   = "serviceAccount:${module.service_account[each.key].email}"
}

/* Will this work?
resource "google_storage_bucket_iam_member" "sa_service_account_billing_user" {
  for_each           = local.service_accounts
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${module.service_account[each.key].email}"
}

resource "google_storage_bucket_iam_member" "sa_service_account_billing_admin" {
  for_each           = local.service_accounts
  billing_account_id = var.billing_account_id
  role               = "roles/billing.admin"
  member             = "serviceAccount:${module.service_account[each.key].email}"
}
*/

locals {
  devops_env = {
    organization_id = module.organization.org_id
    devops_sa       = "serviceAccount:${module.service_account["devops"].email}"
    management_sa   = "serviceAccount:${module.service_account["management"].email}"
  }

  devops_policy     = yamldecode(templatefile("${path.module}/devops_policy.yaml", local.devops_env))
  management_policy = yamldecode(templatefile("${path.module}/management_policy.yaml", local.devops_env))
}

module "devops_iam" {
  source = "github.com/gcp-foundation/modules//iam/policy?ref=0.0.1"

  policy = local.devops_policy
}

module "management_iam" {
  source = "github.com/gcp-foundation/modules//iam/policy?ref=0.0.1"

  policy = local.management_policy
}

