data "google_organization" "organization" {
  domain = var.domain
}

locals {
  organization_id = data.google_organization.organization.org_id
}

module "organization" {
  source = "github.com/XBankGCPOrg/gcp-lz-modules//resources/organization?ref=v0.0.1"
  domain = var.domain
}

module "folders" {
  source      = "github.com/XBankGCPOrg/gcp-lz-modules//resources/multi_level_folder?ref=main"
  folder_list = var.foundation_hierarchy.folders
  parent_name = module.organization.name
}

module "projects" {
  source   = "github.com/XBankGCPOrg/gcp-lz-modules//resources/project?ref=v0.0.1"
  for_each = { for entry in var.foundation_hierarchy.projects : entry.displayName => entry }

  name            = each.value.displayName
  folder          = flatten([for folder in module.folders.folder_id : values(folder) if contains(keys(folder), each.value.parent)]).0
  services        = each.value.services
  billing_account = try(each.value.billingAccount, var.billing_account)
  labels          = try(each.value.labels, var.labels)
}

resource "google_resource_manager_lien" "lien" {
  for_each = { for entry in var.foundation_hierarchy.projects : entry.displayName => entry if length(entry.lienReason) > 0 }
  parent       = "projects/${module.projects[each.key].number}"

  restrictions = ["resourcemanager.projects.delete"]
  origin       = "machine-readable-explanation"
  reason       = each.value.lienReason
}