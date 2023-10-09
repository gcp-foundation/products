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
  query = "state:ACTIVE"
}

data "google_cloud_asset_resources_search_all" "projects" {
  provider = google-beta

  scope = "organizations/${local.organization_id}"
  asset_types = [
    "cloudresourcemanager.googleapis.com/Project"
  ]
  query = "state:ACTIVE"
}

locals {
  folders = {
    for folder in data.google_cloud_asset_resources_search_all.folders.results : folder.display_name => substr(folder.name, 46, -1)
  }

  projects = {
    for project in data.google_cloud_asset_resources_search_all.projects.results : project.display_name => substr(project.name, 47, -1)
  }
}

output "folders" {
  value = local.folders
}

output "projects" {
  value = local.projects
}
