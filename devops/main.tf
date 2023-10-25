locals {

  environment = merge({
    domain                 = var.domain
    organization_id        = "715048305958"
    billingAccount         = var.billing_account
    folder_devops          = "devops"
    folder_management      = "management"
    project_control        = "control"
    project_pipelines      = "pipelines"
    project_logging        = "logging"
    project_billing        = "billing"
    project_guardrails     = "guardrails"
    sa_devops              = "sa-devops"
    sa_management          = "sa-management"
    sa_guardrail_orgpolicy = "sa-guardrail-orgpolicy"
    bucket_tfstate         = "tfstate"
  }, var.environment)

  organizations = yamldecode(templatefile("${path.module}/foundation.yaml", local.environment)).organizations

  // Need to restructure foundation.yaml file and flatten it

  folders = flatten([
    for organization in try(local.organizations, []) : [
      for folder in try(organization.folders, []) : [
        { organization = organization, folder = folder }
      ]
    ]
  ])

  projects = flatten([
    for organization in try(local.organizations, []) : [
      for folder in try(organization.folders, []) : [
        for project in try(folder.projects, []) : { folder = folder, project = project }
      ]
    ]
  ])

  service_accounts = flatten([
    for organization in try(local.organizations, []) : [
      for folder in try(organization.folders, []) : [
        for project in try(folder.projects, []) : [
          for service_account in try(project.serviceAccounts, []) : [
            { project = project, service_account = service_account }
          ]
        ]
      ]
    ]
  ])
}

module "organizations" {
  source   = "github.com/gcp-foundation/modules//resources/organization?ref=0.0.2"
  for_each = { for organization in local.organizations : organization.displayName => organization }

  domain = each.value.displayName
}

module "folders" {
  source   = "github.com/gcp-foundation/modules//resources/folder?ref=0.0.2"
  for_each = { for entry in local.folders : entry.folder.displayName => entry }

  display_name = each.value.folder.displayName
  parent       = module.organizations[each.value.organization.displayName].name
}

module "projects" {
  source   = "github.com/gcp-foundation/modules//resources/project?ref=0.0.2"
  for_each = { for entry in local.projects : entry.project.displayName => entry }

  name            = each.value.project.displayName
  folder          = module.folders[each.value.folder.displayName].name
  services        = each.value.project.services
  billing_account = try(each.value.project.billingAccount, local.environment.billingAccount)
  labels          = var.labels
}

module "service_accounts" {
  source   = "github.com/gcp-foundation/modules//iam/service_account?ref=0.0.2"
  for_each = { for entry in local.service_accounts : entry.service_account.name => entry }

  project      = module.projects[each.value.project.displayName].project_id
  name         = each.value.service_account.name
  display_name = each.value.service_account.displayName
  description  = each.value.service_account.description
}

