locals {
  organization_bindings = flatten([
    for organization in local.iam_policy.organizations : [
      for binding in organization.iamPolicy.bindings : [
        for member in binding.members : {
          org_id = organization.name
          role   = binding.role
          member = member
        }
      ]
    ]
  ])

  # Need to add code to cope with missing folders object
  folder_bindings = flatten([
    for folder in local.iam_policy.folders : [
      for binding in folder.iamPolicy.bindings : [
        for member in binding.members : {
          folder_id = folder.name
          role      = binding.role
          member    = member
        }
      ]
    ]
  ])

  # Need to add code to cope with missing projects object
  project_bindings = flatten([
    for project in local.iam_policy.projects : [
      for binding in project.iamPolicy.bindings : [
        for member in binding.members : {
          project_id = project.name
          role       = binding.role
          member     = member
        }
      ]
    ]
  ])
}

resource "google_organization_iam_member" "organization" {
  for_each = { for binding in local.organization_bindings : "${binding.org_id}/${binding.role}/${binding.member}" => binding }

  org_id = module.organization.org_id
  role   = each.value.role
  member = "serviceAccount:${module.service_account[each.value.member].email}"
}

resource "google_folder_iam_member" "folder" {
  for_each = { for binding in local.folder_bindings : "${binding.folder_id}/${binding.role}/${binding.member}" => binding }

  folder = module.folders[each.value.folder_id].id
  role   = each.value.role
  member = "serviceAccount:${module.service_account[each.value.member].email}"
}

resource "google_project_iam_member" "project" {
  for_each = { for binding in local.project_bindings : "${binding.project_id}/${binding.role}/${binding.member}" => binding }

  project = module.projects[each.value.project_id].project
  role    = each.value.role
  member  = "serviceAccount:${module.service_account[each.value.member].email}"
}