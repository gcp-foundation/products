locals {

  environment = {
    domain = var.domain
  }

  organization = yamldecode(templatefile("${path.module}/foundation.yaml", local.environment))

  projects = flatten([
    for folder in local.organization.folders : [
      for project in folder.projects : { folder = folder, project = project }
    ]
  ])
}

module "organization" {
  source = "github.com/gcp-foundation/modules//resources/organization?ref=0.0.1"

  domain = local.organization.domain
}

module "folders" {
  source   = "github.com/gcp-foundation/modules//resources/folder?ref=0.0.1"
  for_each = { for folder in local.organization.folders : folder.display_name => folder }

  display_name = each.value.display_name
  parent       = module.organization.name
}

module "projects" {
  source   = "github.com/gcp-foundation/modules//resources/project?ref=0.0.1"
  for_each = { for project in local.projects : "${project.folder.display_name}/${project.project.name}" => project }

  name            = each.value.project.name
  folder          = module.folders[each.value.folder.display_name].name
  services        = each.value.project.services
  billing_account = var.billing_account
  labels          = var.labels
}

locals {
  services   = ["artifactregistry.googleapis.com", "storage.googleapis.com"]
  encrypters = [for identity in module.service_identity : "${identity.email}"]
  decrypters = [for identity in module.service_identity : "${identity.email}"]
}

module "service_identity" {
  source   = "github.com/gcp-foundation/modules//resources/service_identity?ref=0.0.1"
  for_each = toset(local.services)
  project  = module.projects["devops/control"].id
  service  = each.value
}

module "kms_key" {
  source        = "github.com/gcp-foundation/modules//kms/key?ref=0.0.1"
  name          = module.projects["devops/control"].id
  key_ring_name = module.projects["devops/control"].id
  project       = module.projects["devops/control"].id
  location      = var.location
  encrypters    = local.encrypters
  decrypters    = local.decrypters
}

module "artifact_registry" {
  source = "github.com/gcp-foundation/modules//artifact_registry?ref=0.0.1"

  name        = "cloudbuild"
  description = "Docker containers for cloudbuild"
  project     = module.projects["devops/control"].id
  location    = var.location

  kms_key_id = module.kms_key.key_id
}

/*
resource "google_kms_crypto_key_iam_member" "crypto_key" {
  crypto_key_id = "kms-key"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
}

module "state_files" {
  source = "github.com/gcp-foundation/modules//storage/bucket?ref=0.0.1"
}

module "build_outputs" {
  source = "github.com/gcp-foundation/modules//storage/bucket?ref=0.0.1"
}

module "service_account" {

}

module "main_trigger" {

}

module "branch_trigger" {

}
*/
