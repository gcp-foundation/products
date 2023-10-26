variable "domain" {
  description = "The domain to bootstrap"
  type        = string
}

variable "billing_account" {
  description = "The billing account to use for all resources"
  type        = string
}

variable "location" {
  description = "The location to deploy resource"
  type        = string
}

variable "foundation_hierarchy" {
  description = "Foundation Resource Hierarchy"
  type = object({
    folders = list(object({
      displayName = string
      parent      = string
    }))
    projects = list(object({
      displayName = string
      parent      = string
      services    = list(string)
      labels      = map(string)
    }))
  })
}

variable "iam_policy" {
  description = "IAM role binding"
  type = object({
    organizations = list(object({
      name = string
      iamPolicy = object({
        bindings = list(object({
          role    = string
          members = list(string)
        }))
      })
    }))
    folders = list(object({
      name        = string
      iac_created = bool
      iamPolicy = object({
        bindings = list(object({
          role    = string
          members = list(string)
        }))
      })
    }))
    projects = list(object({
      name        = string
      iac_created = bool
      iamPolicy = object({
        bindings = list(object({
          role    = string
          members = list(string)
        }))
      })
    }))
  })

}

variable "org_policy" {
  description = "Organization policies"
  type        = any
}

variable "deny_policies" {
  description = "Deny policies"
  type        = any
}

variable "project_billing" {
  description = "Billing project name"
  type        = string
}

variable "project_guardrails" {
  description = "Security gaurdrail project name"
  type        = string
}

variable "project_logging" {
  description = "Logging project name"
  type        = string
}

variable "labels" {
  description = "Labels to apply to all foundation projects"
  type        = map(string)
  default = {
    environment      = "bootstrap"
    application_name = "seed-bootstrap"
    env_code         = "b"
    # business-owner            = "tonstand"
    # finance-approver          = "afins"
    # hfm-entity                = "gb4581"
    # pid                       = "245924"
    # primary-technical-contact = "davbutla"
    # project-code              = "245924"
  }
}