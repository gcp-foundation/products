locals {

  environment = merge({
    domain             = var.domain
    billingAccount     = var.billing_account
    folder_devops      = "devops"
    folder_management  = "management"
    project_control    = "control"
    project_logging    = "logging"
    project_billing    = "billing"
    project_guardrails = "guardrails"
  }, var.environment)

  organization = yamldecode(templatefile("${path.module}/foundation.yaml", local.environment))

  projects = flatten([
    for folder in local.organization.folders : [
      for project in folder.projects : { folder = folder, project = project }
    ]
  ])
}

module "organization" {
  source = "github.com/gcp-foundation/modules//resources/organization?ref=0.0.1"

  domain = local.organization.displayName
}

module "folders" {
  source   = "github.com/gcp-foundation/modules//resources/folder?ref=0.0.1"
  for_each = { for folder in local.organization.folders : folder.displayName => folder }

  display_name = each.value.displayName
  parent       = module.organization.name
}

module "projects" {
  source   = "github.com/gcp-foundation/modules//resources/project?ref=0.0.1"
  for_each = { for entry in local.projects : "${entry.folder.displayName}/${entry.project.displayName}" => entry }

  name            = each.value.project.displayName
  folder          = module.folders[each.value.folder.displayName].name
  services        = each.value.project.services
  billing_account = try(each.value.project.billingAccount, local.environment.billingAccount)
  labels          = var.labels
}

