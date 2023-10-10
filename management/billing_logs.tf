module "billing_dataset" {
  source   = "github.com/gcp-foundation/modules//bigquery/dataset?ref=0.0.1"
  name     = "billing"
  project  = local.projects["billing"].project_id
  location = var.location
}

module "billing_dataset" {
  source   = "github.com/gcp-foundation/modules//bigquery/dataset?ref=0.0.1"
  name     = "billing_details"
  project  = local.projects["billing"].project_id
  location = var.location
}

module "billing_dataset" {
  source   = "github.com/gcp-foundation/modules//bigquery/dataset?ref=0.0.1"
  name     = "pricing"
  project  = local.projects["billing"].project_id
  location = var.location
}
