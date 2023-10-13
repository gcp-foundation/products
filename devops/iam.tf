
locals {
  devops_env = {
    organization_id = module.organization.org_id
    devops_sa       = "serviceAccount:${module.service_account["devops"].email}"
    management_sa   = "serviceAccount:${module.service_account["management"].email}"
    projects = {
      for project in module.projects :
      project.display_name => { project_id = substr(project.name, 47, -1), number = substr(project.project, 9, -1) }
    }
    folders = {
      for folder in data.google_cloud_asset_resources_search_all.folders.results : folder.display_name => substr(folder.name, 46, -1)
    }
  }

  devops_policy     = yamldecode(templatefile("${path.module}/devops_policy.yaml", local.devops_env))
  management_policy = yamldecode(templatefile("${path.module}/management_policy.yaml", local.devops_env))
}

module "devops_iam" {
  source = "github.com/gcp-foundation/modules//iam/policy?ref=0.0.1"

  policy = local.devops_policy

  depends_on = [modules.projects]
}

module "management_iam" {
  source = "github.com/gcp-foundation/modules//iam/policy?ref=0.0.1"

  policy = local.management_policy

  depends_on = [modules.projects]
}

