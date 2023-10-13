resource "google_iam_workload_identity_pool" "github1" {
  provider                  = google-beta
  project                   = module.projects.project_id
  workload_identity_pool_id = "github1"
  display_name              = "Github1"
  description               = "Github1 workload identity pool"
}

resource "google_iam_workload_identity_pool_provider" "github1" {
  provider                           = google-beta
  project                            = module.projects.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github1.workload_identity_pool_id
  workload_identity_pool_provider_id = "github1"
  display_name                       = "Github1"
  description                        = "Github1 workload identity pool provider"
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

resource "google_service_account_iam_member" "devops" {
  service_account_id = module.service_account["devops"].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${module.projects.number}/locations/global/workloadIdentityPools/github1/attribute.repository/${var.authorized_repositories["devops"]}"
}

resource "google_iam_workload_identity_pool" "github2" {
  provider                  = google-beta
  project                   = module.projects.project_id
  workload_identity_pool_id = "github2"
  display_name              = "Github2"
  description               = "Github2 workload identity pool"
}

resource "google_iam_workload_identity_pool_provider" "github2" {
  provider                           = google-beta
  project                            = module.projects.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github2.workload_identity_pool_id
  workload_identity_pool_provider_id = "github2"
  display_name                       = "Github2"
  description                        = "Github2 workload identity pool provider"
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

resource "google_service_account_iam_member" "management" {
  service_account_id = module.service_account["management"].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${module.projects.number}/locations/global/workloadIdentityPools/github2/attribute.repository/${var.authorized_repositories["management"]}"
}