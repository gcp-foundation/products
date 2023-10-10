resource "google_iam_workload_identity_pool" "github" {
  provider                  = google-beta
  project                   = module.projects["devops/pipelines"].project_id
  workload_identity_pool_id = "github"
  display_name              = "Github"
  description               = "Github workload identity pool"
}

resource "google_iam_workload_identity_pool_provider" "example" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "Github"
  description                        = "Github workload identity pool provider"
  attribute_mapping = {
    "google.subject"  = "assertion.sub"
    "attribute.actor" = "assertion.actor"
    "attribute.aud"   = "assertion.aud"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "workload_user" {
  service_account_id = "sa-devops@${module.projects["devops/pipelines"].project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${module.projects["devops/pipelines"].number}/locations/global/workloadIdentityPools/github/attribute.repository/${module.organization.org_id}/devops"
}
