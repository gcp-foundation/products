output "gcs-bucket-name" {
  value = module.state_files.name
}

output "workload_identity_provider" {
  value = [for sa, des in var.authorized_repositories : { service_account = module.service_account[sa].email, workload_identity_provider = "projects/${module.projects["devops/control"].number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github[sa].name}/providers/${google_iam_workload_identity_pool_provider.github[sa].name}" }]
}
