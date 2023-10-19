module "organization" {
  source = "github.com/XBankGCPOrg/gcp-lz-modules//resources/organization?ref=v0.0.1"
  domain = var.domain
}

module "folders" {
  source      = "github.com/XBankGCPOrg/gcp-lz-modules//resources/folder?ref=osttra-release"
  folder_list = var.organization.folders
  parent_name = module.organization.name
}

module "projects" {
  source   = "github.com/XBankGCPOrg/gcp-lz-modules//resources/project?ref=v0.0.1"
  for_each = { for entry in var.organization.projects : entry.displayName => entry }

  name            = each.value.displayName
  folder          = flatten([for folder in module.folders.folder_id : values(folder) if contains(keys(folder), each.value.parent)]).0
  services        = each.value.services
  billing_account = try(each.value.billingAccount, var.billing_account)
  labels          = var.labels
}

