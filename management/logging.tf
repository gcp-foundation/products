locals {
  log_filter = <<-EOF
    logName: /logs/cloudaudit.googleapis.com%2Factivitiy OR
    logName: /logs/cloudaudit.googleapis.com%2Fsystem_event OR
    logName: /logs/cloudaudit.googleapis.com%2Fdata_access OR
    logName: /logs/cloudaudit.googleapis.com%2Fpolicy OR
    logName: /logs/cloudaudit.googleapis.com%2Faccess_transparency
  EOF

  logging_services = ["pubsub.googleapis.com", "artifactregistry.googleapis.com"]
  other_encrypters = [
    "serviceAccount:${data.google_storage_project_service_account.logging_gcs_account.email_address}",
    #    "serviceAccount:bq-${local.projects["logging"].number}@bigquery-encryption.iam.gserviceaccount.com}"
    "serviceAccount:bq-164725902861@bigquery-encryption.iam.gserviceaccount.com"
  ]
  logging_encrypters = concat([for identity in module.logging_service_identity : "serviceAccount:${identity.email}"], local.other_encrypters)
}

module "logging_service_identity" {
  source   = "github.com/gcp-foundation/modules//resources/service_identity?ref=0.0.1"
  for_each = toset(local.logging_services)
  project  = local.projects["logging"].project_id
  service  = each.value
}

data "google_storage_project_service_account" "logging_gcs_account" {
  project = local.projects["logging"].project_id
}

module "logging_kms_key" {
  source        = "github.com/gcp-foundation/modules//kms/key?ref=0.0.1"
  name          = local.projects["logging"].project_id
  key_ring_name = local.projects["logging"].project_id
  project       = local.projects["logging"].project_id
  location      = var.location
  encrypters    = local.logging_encrypters
  decrypters    = local.logging_encrypters
}

# No filter on this log sink ensures all logs are forwarded to the storage bucket
module "log_sink_all_to_storage" {
  source           = "github.com/gcp-foundation/modules//log_sink?ref=0.0.1"
  name             = "log_storage"
  org_id           = local.organization_id
  include_children = true
  destination      = "storage.googleapis.com/${module.log_storage.name}"
  filter           = ""
}

module "log_storage" {
  source              = "github.com/gcp-foundation/modules//storage/bucket?ref=0.0.1"
  name                = "log_storage"
  project             = local.projects["logging"].project_id
  location            = var.location
  kms_key_id          = module.logging_kms_key.key_id
  data_classification = "logs"

  depends_on = [module.logging_kms_key.encrypters]
}

resource "google_storage_bucket_iam_member" "storage_sink_member" {
  bucket = module.log_storage.name
  role   = "roles/storage.objectCreator"
  member = module.log_sink_all_to_storage.writer_identity
}

module "log_sink_filtered_to_bigquery" {
  source           = "github.com/gcp-foundation/modules//log_sink?ref=0.0.1"
  name             = "log_bigquery"
  org_id           = local.organization_id
  include_children = true
  destination      = "bigquery.googleapis.com/projects/${local.projects["logging"].project_id}/datasets/${module.log_bigquery.dataset_id}"
  filter           = local.log_filter
}

module "log_bigquery" {
  source     = "github.com/gcp-foundation/modules//bigquery/dataset?ref=0.0.1"
  name       = "log_bigquery"
  project    = local.projects["logging"].project_id
  location   = var.location
  kms_key_id = module.logging_kms_key.key_id

  depends_on = [module.logging_kms_key.encrypters]
}

resource "google_project_iam_member" "bigquery_sink_member" {
  project = local.projects["logging"].project_id
  role    = "roles/bigquery.dataEditor"
  member  = module.log_sink_filtered_to_bigquery.writer_identity
}

# module "logging_to_pubsub" {

# }

# module "log_pubsub" {

# }

