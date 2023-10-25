
locals {
  resources = {
    organizations = module.organizations
    projects = {
      for project in module.projects :
      project.name => { project_id = project.project_id, number = project.number }
    }
    folders = {
      for folder in module.folders : folder.display_name => folder.folder_id
    }
    service_accounts = {
      for service_account in local.service_accounts : service_account.service_account.name =>
      { name = module.service_accounts[service_account.service_account.name].name, email = module.service_accounts[service_account.service_account.name].email }
    }
  }

  devops_policy     = yamldecode(templatefile("${path.module}/devops_policy.yaml", local.environment))
  management_policy = yamldecode(templatefile("${path.module}/management_policy.yaml", local.environment))
}

module "devops_iam" {
  source = "github.com/gcp-foundation/modules//iam/policy?ref=0.0.2"

  policy    = local.devops_policy
  members   = module.service_accounts
  resources = local.resources

  depends_on = [module.projects]
}

module "management_iam" {
  source = "github.com/gcp-foundation/modules//iam/policy?ref=0.0.2"

  policy    = local.management_policy
  members   = module.service_accounts
  resources = local.resources

  depends_on = [module.projects]
}


