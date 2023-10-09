locals {
  log_filter = <<-EOF
    logName: /logs/cloudaudit.googleapis.com%2Factivitiy OR
    logName: /logs/cloudaudit.googleapis.com%2Fsystem_event OR
    logName: /logs/cloudaudit.googleapis.com%2Fdata_access OR
    logName: /logs/cloudaudit.googleapis.com%2Fpolicy OR
    logName: /logs/cloudaudit.googleapis.com%2Faccess_transparency
  EOF

  #   logging_services          = ["artifactregistry.googleapis.com"]
  #   other_pipeline_encrypters = ["serviceAccount:${data.google_storage_project_service_account.pipeline_gcs_account.email_address}"]
  #   pipeline_encrypters       = concat([for identity in module.pipeline_service_identity : "serviceAccount:${identity.email}"], local.other_pipeline_encrypters)

}

# module "pipeline_service_identity" {
#   source   = "github.com/gcp-foundation/modules//resources/service_identity?ref=0.0.1"
#   for_each = toset(local.logging_services)
#   project  = module.projects["management/logging"].project_id
#   service  = each.value
# }

# data "google_storage_project_service_account" "pipeline_gcs_account" {
#   project = module.projects["devops/pipelines"].project_id

#   depends_on = [module.projects["devops/pipelines"].services]
# }

# module "logging_kms_key" {
#   source        = "github.com/gcp-foundation/modules//kms/key?ref=0.0.1"
#   name          = module.projects["management/logging"].project_id
#   key_ring_name = module.projects["management/logging"].project_id
#   project       = module.projects["management/logging"].project_id
#   location      = var.location
#   encrypters    = local.logging_encrypters
#   decrypters    = local.logging_encrypters

#   depends_on = [module.projects["management/logging"].services]
# }

# No filter on this log sink ensures all logs are forwarded to the storage bucket
# module "log_sink_all_to_storage" {
#   source           = "github.com/gcp-foundation/modules//log_sink"
#   name             = "log_storage"
#   org_id           = local.organization_id
#   include_children = true
#   destination      = "storage.googleapis.com/${module.log_storage.name}"
# }

# module "log_storage" {
#   source       = "github.com/gcp-foundation/modules//storage/bucket?ref=0.0.1"
#   name         = "log_storage"
#   project      = module.projects["management/logging"].project_id
#   location     = var.location
#   kms_key_name = module.kms
# }

# module "logging_to_pubsub" {

# }

# module "log_pubsub" {

# }
