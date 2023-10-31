###############################################################################
# Apply iam policies
###############################################################################

module "iam" {
  source = "github.com/gcp-foundation/modules//iam/iam_policy?ref=0.0.2"

  policies  = var.iam_policies
  resources = local.resources
  members   = module.resources.service_accounts

  depends_on = [module.resources]
}

