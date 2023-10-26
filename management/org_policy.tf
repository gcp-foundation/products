locals {

  organization = yamldecode(templatefile("${path.module}/org_policy.yaml", local.environment))

  organization_policies = flatten([
    for policy in local.organization.orgPolicy :
    { policy = policy } if try(policy.exists, false) != true
  ])

  folder_policies = {
    for folder in local.organization.folders : "${folder.parent}/${folder.displayName}" => [
      for policy in folder.orgPolicy :
      { policy = policy } if try(policy.exists, false) != true
    ]
  }

  project_policies = {
    for project in local.organization.projects : project.displayName => [
      for policy in project.orgPolicy :
      { policy = policy } if try(policy.exists, false) != true
    ]
  }
}

module "organization_policy" {
  source   = "github.com/gcp-foundation/modules//iam/org_policy?ref=0.0.2"
  parent   = "organizations/${local.organization_id}"
  policies = local.organization_policies
}

module "folder_policies" {
  source   = "github.com/gcp-foundation/modules//iam/org_policy?ref=0.0.2"
  for_each = local.folder_policies
  parent   = "folders/${local.folders[each.key].folder_id}"
  policies = each.value
}

module "project_policies" {
  source   = "github.com/gcp-foundation/modules//iam/org_policy?ref=0.0.2"
  for_each = local.project_policies
  parent   = "projects/${local.projects[each.key].project_id}"
  policies = each.value
}
