variable "domain" {
  description = "The domain to bootstrap"
    domain          = "latest.gcp-foundation.com"
    billing_account = "01EBA6-74BB59-078C79"
  }
}

variable "labels" {
  default = {
    environment               = "bootstrap"
    application_name          = "seed-bootstrap"
    env_code                  = "b"
    business-owner            = "tonstand"
    finance-approver          = "afins"
    hfm-entity                = "gb4581"
    pid                       = "245924"
    primary-technical-contact = "davbutla"
    project-code              = "245924"
  }
}
