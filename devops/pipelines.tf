###############################################################################
# Create Cloudbuild pipelines (if required)
###############################################################################

module "cloudbuild" {
  source = "../pipelines/cloudbuild"
  count  = var.cloudbuild_pipelines != null ? 1 : 0

  project_control   = module.resources.projects[local.environment.project_control]
  project_pipelines = module.resources.projects[local.environment.project_pipelines]
  pipelines         = var.cloudbuild_pipelines.pipelines
  service_accounts  = local.resources.service_accounts
  location          = var.location
  cloudbuild_sha    = var.cloudbuild_sha
}

###############################################################################
# Create github actions pipelines (if required)
###############################################################################

module "github" {
  source = "../pipelines/github"
  count  = var.github_pipelines != null ? 1 : 0

  project             = local.resources.projects[local.environment.project_control]
  pipelines           = var.github_pipelines.pipelines
  github_organization = "gcp-foundations"
  service_accounts    = local.resources.service_accounts
}
