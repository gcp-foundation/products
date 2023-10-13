module "assets" {
  source = "github.com/gcp-foundation/modules//assets?ref=0.0.1"
  domain = var.domain
}

locals {

  environment = merge({
    domain             = var.domain
    folder_devops      = "devops"
    folder_management  = "management"
    project_control    = "control"
    project_pipelines  = "pipelines"
    project_logging    = "logging"
    project_billing    = "billing"
    project_guardrails = "guardrails"
  }, var.environment)

  organization_id = module.assets.organization_id
  folders         = module.assets.folders
  projects        = module.assets.projects
}
