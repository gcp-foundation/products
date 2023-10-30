locals {

  organization_policies = flatten([
    for policy in var.org_policy.orgPolicy :
    { policy = policy } if try(policy.exists, false) != true
  ])

  folder_policies = flatten([
    for folder in var.org_policy.folders : { parent = folder.parent, policy = flatten([for policy in folder.orgPolicy :
      { policy = policy } if try(policy.exists, false) != true
  ]) }])

  project_policies = flatten([
    for project in var.org_policy.projects : { parent = project.parent, policy = flatten([for policy in project.orgPolicy :
      { policy = policy } if try(policy.exists, false) != true
  ]) }])
}

module "organization_policy" {
  source   = "github.com/XBankGCPOrg/gcp-lz-modules//iam/org_policy?ref=main"
  parent   = "organizations/${local.organization_id}"
  policies = local.organization_policies
}

module "folder_policy" {
  source   = "github.com/XBankGCPOrg/gcp-lz-modules//iam/org_policy?ref=main"
  for_each = { for folder in local.folder_policies : folder.parent => folder }
  parent   = flatten([for folder in module.folders.folder_id : values(folder) if contains(keys(folder), each.value.parent)]).0
  policies = each.value.policy
}

module "project_policy" {
  source   = "github.com/XBankGCPOrg/gcp-lz-modules//iam/org_policy?ref=main"
  for_each = { for project in local.project_policies : project.parent => project }
  parent   = "projects/${module.projects[each.value.parent].project_id}"
  policies = each.value.policy
}

