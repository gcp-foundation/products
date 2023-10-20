locals {

  organization = yamldecode(templatefile("${path.module}/org_policy.yaml", local.environment))

  organization_policies = flatten([
    for policy in local.organization.orgPolicy :
    { policy = policy } if try(policy.exists, false) != true
  ])

  #   folder_names = compact([ 
  #     for folder in local.organization.folders : lookup( local.folders, folder.displayName, null ) != null ? folder.displayName : null   
  #   ])

  #   project_names = compact([
  #     for project in local.organization.projects : lookup( local.projects, project.name, null ) != null ? project.name : null
  #   ])

  #   folder_org_policies = flatten([])
}

# module "organization_policy" {
#   source   = "github.com/gcp-foundation/modules//iam/org_policy?ref=0.0.1"
#   parent   = "organizations/${local.organization_id}"
#   policies = local.organization_policies
# }

output "organization_policies" {
  value = local.organization_policies
}
