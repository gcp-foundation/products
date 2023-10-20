
locals {
  devops_env = {
    organization_id = module.organization.org_id
    domain          = local.organization.displayName
    devops_sa       = "serviceAccount:${module.service_account["devops"].email}"
    management_sa   = "serviceAccount:${module.service_account["management"].email}"

    projects = {
      for project in module.projects :
      project.name => { project_id = project.project_id, number = project.number }
    }
    folders = {
      for folder in module.folders : folder.display_name => folder.folder_id
    }
  }

  devops_policy     = yamldecode(templatefile("${path.module}/devops_policy.yaml", local.devops_env))
  management_policy = yamldecode(templatefile("${path.module}/management_policy.yaml", local.devops_env))
}

module "devops_iam" {
  source = "github.com/gcp-foundation/modules//iam/policy?ref=0.0.1"

  policy = local.devops_policy

  depends_on = [module.projects]
}

module "management_iam" {
  source = "github.com/gcp-foundation/modules//iam/policy?ref=0.0.1"

  policy = local.management_policy

  depends_on = [module.projects]
}

