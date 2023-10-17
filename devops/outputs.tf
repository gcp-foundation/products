output "gcs-bucket-name" {
  value = module.state_files.name
}

output "service-account" {
  value = [for sa, des in local.service_accounts : module.service_account[sa].email]
}