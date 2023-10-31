output "folder_id" {
  value = module.folders.folder_id
}

output "project_id" {
  value = [for entry in var.foundation_hierarchy.projects : { "${entry.displayName}" = module.projects[entry.displayName].project_id }]
}

output "project_ids" {
  value = {
    for entry in var.foundation_hierarchy.projects : entry.displayName => module.projects[entry.displayName].project_id
  }
}
output "lien_name" {
  value = google_resource_manager_lien.lien.name
}
