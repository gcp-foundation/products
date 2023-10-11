variable "domain" {
  description = "The domain to bootstrap"
  type        = string
}

variable "location" {
  description = "The location to deploy resource"
  type        = string
}


variable "environment" {
  description = "Environment specific settings"
  type        = map(string)
  default     = {}
}
