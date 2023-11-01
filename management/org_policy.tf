locals {

  org_policies = yamldecode(templatefile("${path.module}/org_policy.yaml", local.environment))

  organization_policies = {
    for organization in local.org_policies.organizations : organization.displayName => [
      for policy in organization.orgPolicy :
      { policy = policy } if try(policy.exists, false) != true
  ] }

  folder_policies = {
    for folder in local.org_policies.folders : "organizations/${local.organization_id}/${folder.displayName}" => [
      for policy in folder.orgPolicy :
      { policy = policy } if try(policy.exists, false) != true
    ]
  }

  project_policies = {
    for project in local.org_policies.projects : project.displayName => [
      for policy in project.orgPolicy :
      { policy = policy } if try(policy.exists, false) != true
    ]
  }
}

// Note: doesn't support multiple organizations
module "organization_policy" {
  source   = "github.com/gcp-foundation/modules//iam/org_policy?ref=0.0.2"
  for_each = local.organization_policies
  parent   = "organizations/${local.organization_id}"
  policies = each.value
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

moved {
  from = module.organization_policy
  to   = module.organization_policy["latest.gcp-foundation.com"]
}
