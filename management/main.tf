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

}
