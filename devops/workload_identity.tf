resource "google_iam_workload_identity_pool" "github" {
  for_each                  = { for sa in var.service_accounts.service_accounts : sa.name => sa }
  provider                  = google-beta
  project                   = module.projects.project_id
  workload_identity_pool_id = "github-${each.key}-pool"
  display_name              = "Github-${each.key}-pool"
  description               = "Github ${each.key} workload identity pool"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  provider                           = google-beta
  for_each                           = { for sa in var.service_accounts.service_accounts : sa.name => sa }
  project                            = module.projects.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github[each.key].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-${each.key}-provider"
  display_name                       = "Github-${each.key}-provider"
  description                        = "Github ${each.key} workload identity pool provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.owner"      = "assertion.repository_owner"
    "attribute.refs"       = "assertion.ref"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "wif-sa-bind" {
  for_each           = { for sa in var.service_accounts.service_accounts : sa.name => sa }
  service_account_id = module.service_account[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${module.projects.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github[each.key].workload_identity_pool_id}/attribute.repository/${each.value.repository}"
}