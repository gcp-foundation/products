locals {

  organization_bindings = flatten([
    for organization in var.sa_iam_org_binding.organizations : [
      for binding in organization.iamPolicy.bindings : [
        for member in binding.members : {
          org_id = organization.name
          role   = binding.role
          member = member
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