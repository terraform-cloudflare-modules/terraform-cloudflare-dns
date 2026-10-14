resource "cloudflare_dns_firewall" "this" {
  for_each = { for key, value in var.clusters : key => value if var.create }

  account_id             = each.value.account_id != null ? each.value.account_id : var.account_id
  attack_mitigation      = each.value.attack_mitigation
  deprecate_any_requests = each.value.deprecate_any_requests
  dns_firewall_ip_count  = each.value.dns_firewall_ip_count
  ecs_fallback           = each.value.ecs_fallback
  maximum_cache_ttl      = each.value.maximum_cache_ttl
  minimum_cache_ttl      = each.value.minimum_cache_ttl
  name                   = each.value.name != null ? each.value.name : each.key
  negative_cache_ttl     = each.value.negative_cache_ttl
  ratelimit              = each.value.ratelimit
  retries                = each.value.retries
  upstream_ips           = each.value.upstream_ips

  lifecycle {
    precondition {
      condition     = try(length(trimspace(each.value.account_id != null ? each.value.account_id : var.account_id)) > 0, false)
      error_message = "Each entry requires account_id, either on the entry or at module level."
    }
  }
}
