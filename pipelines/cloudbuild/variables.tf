variable "pipelines" {
  description = "Details of pipelines for github actions"
}

variable "project_control" {
  description = "The project object for the control project"
}

variable "project_pipelines" {
  description = "The project object for the pipeline project"
}

variable "service_accounts" {
  description = "A map of service account objects from resources"
}

variable "location" {
  description = "The location for the pipeline resources"
  type        = string
}

variable "cloudbuild_sha" {
  description = "The sha for the cloudbuild image"
  type        = string
}
