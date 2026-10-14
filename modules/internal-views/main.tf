resource "cloudflare_account_dns_settings_internal_view" "this" {
  for_each = { for key, value in var.views : key => value if var.create }

  account_id = each.value.account_id != null ? each.value.account_id : var.account_id
  name       = each.value.name != null ? each.value.name : each.key
  zones      = each.value.zones

  lifecycle {
    precondition {
      condition     = try(length(trimspace(each.value.account_id != null ? each.value.account_id : var.account_id)) > 0, false)
      error_message = "Each entry requires account_id, either on the entry or at module level."
    }
  }
}
