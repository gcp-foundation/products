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

variable "seed_project_name" {
  description = "Seed project Name"
  type        = string
}

variable "service_accounts" {
  type        = list(map(string))
  description = "Repository information. eg: your_org/your_repository"
}

varaible "iam_policy" {
  type        = any
  description = "IAM policy binding for WIF service account"
}

variable "gcs_terraform_bucket_name" {
  type        = string
  description = "Terraform GCS bucket name"
}

variable "organization" {
  type        = string
  description = "Terraform GCS bucket name"
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