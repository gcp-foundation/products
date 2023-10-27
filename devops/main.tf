###############################################################################
# Read resource defintion file and replace environment values
###############################################################################

locals {
  resources   = module.resources
  environment = var.environment
}

###############################################################################
# Create resources from definition file
###############################################################################

module "resources" {
  source = "github.com/gcp-foundation/modules//resources?ref=0.0.2"

  config          = var.config
  billing_account = local.environment.billingAccount
}

