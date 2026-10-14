resource "cloudflare_load_balancer_monitor_group" "this" {
  for_each = { for key, value in var.groups : key => value if var.create }

  account_id  = each.value.account_id != null ? each.value.account_id : var.account_id
  description = each.value.description
  members     = each.value.members

  lifecycle {
    precondition {
      condition     = try(length(trimspace(each.value.account_id != null ? each.value.account_id : var.account_id)) > 0, false)
      error_message = "Each entry requires account_id, either on the entry or at module level."
    }
  }
}
