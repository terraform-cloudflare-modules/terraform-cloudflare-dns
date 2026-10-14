resource "cloudflare_dns_zone_transfers_acl" "this" {
  for_each = { for key, acl in var.acls : key => acl if var.create }

  account_id = each.value.account_id != null ? each.value.account_id : var.account_id
  name       = each.value.name != null ? each.value.name : each.key
  ip_range   = each.value.ip_range

  lifecycle {
    precondition {
      condition     = try(length(trimspace(each.value.account_id != null ? each.value.account_id : var.account_id)) > 0, false)
      error_message = "Each ACL requires account_id, either on the entry or at module level."
    }
  }
}

resource "cloudflare_dns_zone_transfers_tsig" "this" {
  for_each = local.tsig_keys

  account_id = var.tsig_keys[each.key].account_id != null ? var.tsig_keys[each.key].account_id : var.account_id
  name       = var.tsig_keys[each.key].name != null ? var.tsig_keys[each.key].name : each.key
  algo       = lower(trimspace(var.tsig_keys[each.key].algo))
  secret     = var.tsig_keys[each.key].secret

  lifecycle {
    precondition {
      condition     = try(length(trimspace(var.tsig_keys[each.key].account_id != null ? var.tsig_keys[each.key].account_id : var.account_id)) > 0, false)
      error_message = "Each TSIG key requires account_id, either on the entry or at module level."
    }
  }
}

resource "cloudflare_dns_zone_transfers_peer" "this" {
  for_each = { for key, peer in var.peers : key => peer if var.create }

  account_id  = each.value.account_id != null ? each.value.account_id : var.account_id
  name        = each.value.name != null ? each.value.name : each.key
  ip          = each.value.ip
  port        = each.value.port
  ixfr_enable = each.value.ixfr_enable
  tsig_id     = each.value.tsig_id == null ? null : lookup(local.tsig_key_ids, each.value.tsig_id, each.value.tsig_id)

  lifecycle {
    precondition {
      condition     = try(length(trimspace(each.value.account_id != null ? each.value.account_id : var.account_id)) > 0, false)
      error_message = "Each peer requires account_id, either on the entry or at module level."
    }
  }
}

resource "cloudflare_dns_zone_transfers_incoming" "this" {
  for_each = { for key, transfer in var.incoming : key => transfer if var.create }

  depends_on = [cloudflare_dns_zone_transfers_acl.this]

  zone_id              = each.value.zone_id
  name                 = lower(trimsuffix(trimspace(each.value.name), "."))
  peers                = [for peer in each.value.peers : lookup(local.peer_ids, peer, peer)]
  auto_refresh_seconds = each.value.auto_refresh_seconds
}

resource "cloudflare_dns_zone_transfers_outgoing" "this" {
  for_each = { for key, transfer in var.outgoing : key => transfer if var.create }

  depends_on = [cloudflare_dns_zone_transfers_acl.this]

  zone_id = each.value.zone_id
  name    = lower(trimsuffix(trimspace(each.value.name), "."))
  peers   = [for peer in each.value.peers : lookup(local.peer_ids, peer, peer)]
}
