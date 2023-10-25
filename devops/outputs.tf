output "resources" {
  value = local.resources
}

output "organizations" {
  value = local.organizations
}

output "folders" {
  value = module.folders
}

output "projects" {
  value = module.projects
}

output "service_accounts" {
  value = local.pipeline_service_accounts
}

output "devops_policy" {
  value = local.devops_policy
}

output "management_policy" {
  value = local.management_policy
}
