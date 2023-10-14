module "billing_dataset" {
  source   = "github.com/XBankGCPOrg/gcp-lz-modules//bigquery/dataset?ref=v0.0.1"
  name     = "billing"
  project  = local.projects[local.environment.project_billing].project_id
  location = var.location
}

module "billing_details_dataset" {
  source   = "github.com/XBankGCPOrg/gcp-lz-modules//bigquery/dataset?ref=v0.0.1"
  name     = "billing_details"
  project  = local.projects[local.environment.project_billing].project_id
  location = var.location
}

module "pricing_dataset" {
  source   = "github.com/XBankGCPOrg/gcp-lz-modules//bigquery/dataset?ref=v0.0.1"
  name     = "pricing"
  project  = local.projects[local.environment.project_billing].project_id
  location = var.location
}
