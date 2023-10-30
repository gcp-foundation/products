# Setup cloudbuild pipelines
module "cloudbuild" {
  source = "../../products//pipelines/cloudbuild"
  count  = var.cloudbuild_pipelines != null ? 1 : 0

  project_control   = module.resources.projects[local.environment.project_control]
  project_pipelines = module.resources.projects[local.environment.project_pipelines]
  pipelines         = var.cloudbuild_pipelines
  service_accounts  = local.resources.service_accounts
  location          = var.location
  cloudbuild_sha    = var.cloudbuild_sha
}

# Setup github action pipelines
module "github" {
  source = "../../products//pipelines/github"
  count  = var.github_pipelines != null ? 1 : 0

  project             = local.resources.projects[local.environment.project_control]
  pipelines           = var.github_pipelines
  github_organization = "gcp-foundations"
  service_accounts    = local.resources.service_accounts
}
