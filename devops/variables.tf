variable "domain" {
  description = "The domain to bootstrap"
  type        = string
}

variable "billing_account" {
  description = "The billing account to use for all resources"
  type        = string
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
