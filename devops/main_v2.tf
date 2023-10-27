# locals {

#   config_V2 = yamldecode(templatefile("${path.module}/config/foundation_V2.yaml", local.environment))

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

# module "folders_level_1_V2" {
#   source   = "github.com/gcp-foundation/modules//resources/folder?ref=0.0.2"
#   for_each = { for key, value in local.config_V2.folders : key => value if regex(local.regex_parent, value.parent).type == "organizations" }

#   display_name = each.value.displayName
#   parent       = module.organizations_V2[regex(local.regex_parent, each.value.parent).name].name
# }

# module "folders_level_2_V2" {
#   source   = "github.com/gcp-foundation/modules//resources/folder?ref=0.0.2"
#   for_each = { for key, value in local.config_V2.folders : key => value if try(module.folders_level_1_V2[regex(local.regex_parent, value.parent).name], false) }

#   display_name = each.value.displayName
#   parent       = module.folders_level_1_V2[regex(local.regex_parent, each.value.parent).name].name
# }

# locals {
#   folders_V2 = merge(module.folders_level_1_V2, module.folders_level_2_V2)
# }

# module "projects_V2" {
#   source   = "github.com/gcp-foundation/modules//resources/project?ref=0.0.2"
#   for_each = local.config_V2.projects

#   name            = each.value.displayName
#   folder          = local.folders_V2[regex(local.regex_parent, each.value.parent).name].name
#   services        = each.value.services
#   billing_account = try(each.value.billingAccount, local.environment.billingAccount)
#   labels          = var.labels
# }

# module "service_accounts_V2" {
#   source   = "github.com/gcp-foundation/modules//iam/service_account?ref=0.0.2"
#   for_each = local.service_accounts_V2

#   project      = module.projects_V2[each.value.project.displayName].project_id
#   name         = each.value.service_account.name
#   display_name = each.value.service_account.displayName
#   description  = each.value.service_account.description
# }

