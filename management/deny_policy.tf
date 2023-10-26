resource "google_iam_deny_policy" "deny_policy" {
  provider = google-beta

  for_each = { for policy in var.deny_policies : split("/", policy.name)[3] => policy }

  parent       = split("/", each.value.name)[1]
  name         = each.key
  display_name = each.value.displayName
  dynamic "rules" {
    for_each = each.value.rules
    content {
      description = try(rules.value.description, null)
      deny_rule {
        denied_principals    = compact(try(rules.value.denyRule.deniedPrincipals, []))
        denied_permissions   = try(rules.value.denyRule.deniedPermissions, [])
        exception_principals = try(rules.values.denyRUle.exceptionPincipals, [])

        denial_condition {
          title       = try(rules.value.denialCondition.title, null)
          description = try(rules.value.denialCondition.description, null)
          location    = try(rules.value.denialCondition, null)
          expression  = try(rules.value.denialCondition.expression, null)
        }
      }
    }
  }
}
