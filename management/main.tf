locals {

  environment = {
    domain = var.domain
  }

  organization = yamldecode(templatefile("${path.module}/foundation.yaml", local.environment))
}
