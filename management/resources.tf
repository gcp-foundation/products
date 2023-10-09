locals {
  organization_id = data.google_organization.organization.org_id
}

data "google_organization" "organization" {
  domain = var.domain
}



# data "google_cloud_asset_resources_search_all" "folders" {
#   provider = google-beta

#   scope = local.organization_id
# }

data "google_cloud_asset_resources_search_all" "folders" {
  provider = google-beta

  scope = "organizations/${local.organization_id}"
  asset_types = [
    "cloudresourcemanager.googleapis.com/Folder"
  ]
}

data "google_cloud_asset_resources_search_all" "projects" {
  provider = google-beta

  scope = "organizations/${local.organization_id}"
  asset_types = [
    "cloudresourcemanager.googleapis.com/Project"
  ]
  query = "lifecycleState=ACTIVE"
}

locals {
  folders = {
    for folder in data.google_cloud_asset_resources_search_all.folders.results : folder.display_name => folder
  }

  projects = {
    for project in data.google_cloud_asset_resources_search_all.projects.results : project.display_name => project
  }
}
