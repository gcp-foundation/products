# locals {

#   config_V2 = yamldecode(templatefile("${path.module}/foundation_V2.yaml", local.environment))

#   regex_parent = "(?P<type>.*)/(?P<name>.*)"

#   service_accounts_V2 = merge([
#     for name, project in try(local.config_V2.projects, {}) : {
#       for service_account in try(project.serviceAccounts, []) : service_account.name =>
#       { project = project, service_account = service_account }
#     }
#   ]...)
# }

# module "organizations_V2" {
#   source   = "github.com/gcp-foundation/modules//resources/organization?ref=0.0.2"
#   for_each = local.config_V2.organizations

#   domain = each.value.displayName
# }

# # Stil can't support multiple levels of folders due to cyclical nature of this module
# module "folders_V2" {
#   source   = "github.com/gcp-foundation/modules//resources/folder?ref=0.0.2"
#   for_each = local.config_V2.folders

#   display_name = each.value.displayName
#   parent       = module.organizations_V2[regex(local.regex_parent, each.value.parent).name].name
# }

# module "projects_V2" {
#   source   = "github.com/gcp-foundation/modules//resources/project?ref=0.0.2"
#   for_each = local.config_V2.projects

#   name            = each.value.displayName
#   folder          = module.folders_V2[regex(local.regex_parent, each.value.parent).name].name
#   services        = each.value.services
#   billing_account = try(each.value.billingAccount, local.environment.billingAccount)
#   labels          = var.labels
# }

# module "service_accounts_V2" {
#   source   = "github.com/gcp-foundation/modules//iam/service_account?ref=0.0.2"
#   for_each = local.service_accounts_V2

#   project      = module.projects[each.value.project.displayName].project_id
#   name         = each.value.service_account.name
#   display_name = each.value.service_account.displayName
#   description  = each.value.service_account.description
# }

