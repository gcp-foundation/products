module "billing_dataset" {
  source                     = "github.com/XBankGCPOrg/gcp-lz-modules//bigquery/dataset?ref=v0.0.1"
  name                       = "billing"
  delete_contents_on_destroy = true
  project                    = local.projects[local.environment.project_billing].project_id
  location                   = var.location
}

module "billing_details_dataset" {
  source                     = "github.com/XBankGCPOrg/gcp-lz-modules//bigquery/dataset?ref=v0.0.1"
  name                       = "billing_details"
  delete_contents_on_destroy = true
  project                    = local.projects[local.environment.project_billing].project_id
  location                   = var.location
}

module "pricing_dataset" {
  source                     = "github.com/XBankGCPOrg/gcp-lz-modules//bigquery/dataset?ref=v0.0.1"
  name                       = "pricing"
  delete_contents_on_destroy = true
  project                    = local.projects[local.environment.project_billing].project_id
  location                   = var.location
}
