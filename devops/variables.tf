variable "config" {
  description = "The configuration of the cloud environment"
}

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

variable "cloudbuild_sha" {
  description = "The sha of the cloudbuild image to use for pipelines (known after first apply)"
  type        = string
  default     = "" # for first build only
}

variable "environment" {
  description = "Environment specific settings"
  type        = map(string)
  default     = {}
}

variable "cloudbuild_pipelines" {
  description = "The configuration for the cloudbuild pipelines"
  default     = null
}

variable "github_pipelines" {
  description = "The configuration for the github pipelines"
  default     = null
}

variable "github_organization" {
  description = "The github organization where the github repositories are storage"
  default     = null
}

variable "devops_policy" {
  description = "The iam policy to apply to the devops service account"
  default     = null
}

variable "management_policy" {
  description = "The iam policy to apply to the management service account"
  default     = null
}
