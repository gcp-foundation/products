###############################################################################
# Read resource defintion file and replace environment values
###############################################################################

locals {

  environment = merge({
    domain                 = var.domain
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
    project_labels         = jsonencode(var.labels)
  }, var.environment)

  config = yamldecode(templatefile("${path.module}/config/foundation.yaml", local.environment))

  resources = module.resources
}

###############################################################################
# Create resources from definition file
###############################################################################

module "resources" {
  source = "github.com/gcp-foundation/modules//resources?ref=0.0.2"

  config          = local.config
  billing_account = local.environment.billingAccount
  labels          = var.labels
}

