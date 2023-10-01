locals {

  organization = yamldecode(templatefile("${path.module}/foundation.yaml", var.environment))

  projects = flatten([
    for folder in local.organization.folders : [
      for project in folder.projects : { folder = folder, project = project }
    ]
  ])
}

module "organization" {
  source = "github.com/gcp-foundation/modules//resources/organization?ref=0.0.1"

  domain = local.organization.domain
}

module "folders" {
  source   = "github.com/gcp-foundation/modules//resources/folder?ref=0.0.1"
  for_each = { for folder in local.organization.folders : folder.display_name => folder }

  display_name = each.value.display_name
  parent       = module.organization.name
}

module "projects" {
  source   = "github.com/gcp-foundation/modules//resources/folder?ref=0.0.1"
  for_each = { for project in local.projects : "${project.folder.display_name}/${project.project.name}" => project }

  name            = each.value.project.name
  folder          = module.folders[each.value.folder.display_name].name
  services        = each.value.project.services
  billing_account = var.environment.billing_account
  labels          = var.labels
}


