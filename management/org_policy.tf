locals {

  organization_policies = flatten([
    for policy in var.org_policy.orgPolicy :
    { policy = policy } if try(policy.exists, false) != true
  ])

  #   folder_names = compact([ 
  #     for folder in local.organization.folders : lookup( local.folders, folder.displayName, null ) != null ? folder.displayName : null   
  #   ])

  #   project_names = compact([
  #     for project in local.organization.projects : lookup( local.projects, project.name, null ) != null ? project.name : null
  #   ])

  #   folder_org_policies = flatten([])

  folder_policies = flatten([
    for folder in var.org_policy.folders : { parent = folder.parent, iac_created = folder.iac_created, policy = flatten([for policy in folder.orgPolicy :
      { policy = policy } if try(policy.exists, false) != true
  ]) }])

  project_policies = flatten([
    for project in var.org_policy.projects : { parent = project.parent, iac_created = project.iac_created, policy = flatten([for policy in project.orgPolicy :
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
  parent   = each.value.iac_created ? flatten([for folder in module.folders.folder_id : values(folder) if contains(keys(folder), each.value.parent)]).0 : "folders/${each.value.parent}"
  policies = each.value.policy
}

module "project_policy" {
  source   = "github.com/XBankGCPOrg/gcp-lz-modules//iam/org_policy?ref=main"
  for_each = { for project in local.project_policies : project.parent => project }
  parent   = each.value.iac_created ? "projects/${module.projects[each.value.parent].project_id}" : "projects/${each.value.parent}"
  policies = each.value.policy
}

