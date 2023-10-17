output "gcs-bucket-name" {
  value = module.state_files.name
}

output "workload_identity_provider" {
  value = [for sa, des in var.authorized_repositories : { service_account = module.service_account[sa].email, workload_identity_provider = google_iam_workload_identity_pool_provider.github[sa].name }]
}
