###############################################################################
# Read the IAM configuration files
###############################################################################

locals {
  devops_policy     = yamldecode(templatefile("${path.module}/config/devops_policy.yaml", local.environment))
  management_policy = yamldecode(templatefile("${path.module}/config/management_policy.yaml", local.environment))
}

###############################################################################
# Apply the IAM configuration to the devops service account
###############################################################################

module "devops_iam" {
  source = "github.com/gcp-foundation/modules//iam/policy?ref=0.0.2"

  policy    = local.devops_policy
  members   = module.resources.service_accounts
  resources = local.resources

  depends_on = [module.resources]
}

###############################################################################
# Apply the IAM configuration to the management service account
###############################################################################

module "management_iam" {
  source = "github.com/gcp-foundation/modules//iam/policy?ref=0.0.2"

  policy    = local.management_policy
  members   = module.resources.service_accounts
  resources = local.resources

  depends_on = [module.resources]
}

