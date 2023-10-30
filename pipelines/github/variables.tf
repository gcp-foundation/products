variable "pipelines" {
  description = "Details of pipelines for github actions"
}

variable "project" {
  description = "The project object containing the pipeline service acounts"
}

variable "service_accounts" {
  description = "A map of service account objects from resources"
}

variable "github_organization" {
  description = "The organization where the github repositories are located"
  type        = string
}
