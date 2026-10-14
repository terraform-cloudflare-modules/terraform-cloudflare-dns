resource "cloudflare_zone" "this" {
  count = var.create && var.create_zone ? 1 : 0

  account             = { id = var.account_id }
  name                = local.zone_name
  paused              = var.zone.paused
  type                = var.zone.type
  vanity_name_servers = var.zone.vanity_name_servers

  lifecycle {
    precondition {
      condition     = local.zone_selection_valid
      error_message = "Managed zones require zone_name and exclude zone_id and zone_filter."
    }
    precondition {
      condition     = local.account_selection_valid
      error_message = "Managed zones require account_id."
    }
  }
}

data "cloudflare_zone" "this" {
  count = var.create && local.lookup_zone ? 1 : 0

  filter = var.zone_name != null ? {
    name      = lower(trimsuffix(trimspace(var.zone_name), "."))
    account   = var.account_id == null ? null : { id = var.account_id, name = null }
    direction = null
    match     = null
    order     = null
    status    = null
    type      = null
  } : var.zone_filter

  lifecycle {
    precondition {
      condition     = local.zone_selection_valid
      error_message = "Set exactly one of zone_id, zone_name, or zone_filter when create is true."
    }
    precondition {
      condition     = local.account_selection_valid
      error_message = "Managed zones require account_id. Otherwise account_id is only supported with zone_name; use zone_filter.account for advanced lookups."
    }
  }
}

resource "cloudflare_zone_dns_settings" "this" {
  count = var.create && var.create_dns_settings ? 1 : 0

  zone_id             = local.zone_id
  flatten_all_cnames  = var.dns_settings.flatten_all_cnames
  foundation_dns      = var.dns_settings.foundation_dns
  multi_provider      = var.dns_settings.multi_provider
  ns_ttl              = var.dns_settings.ns_ttl
  secondary_overrides = var.dns_settings.secondary_overrides
  zone_mode           = var.dns_settings.zone_mode == null ? null : lower(trimspace(var.dns_settings.zone_mode))
  internal_dns        = var.dns_settings.internal_dns
  nameservers = var.dns_settings.nameservers == null ? null : merge(var.dns_settings.nameservers, {
    type = var.dns_settings.nameservers.type == null ? null : lower(trimspace(var.dns_settings.nameservers.type))
  })
  soa = var.dns_settings.soa

  lifecycle {
    precondition {
      condition     = local.zone_selection_valid
      error_message = "DNS settings require exactly one valid zone selector, or a managed zone."
    }
    precondition {
      condition     = local.account_selection_valid
      error_message = "Managed zones require account_id. Otherwise account_id is only supported with zone_name; use zone_filter.account for advanced lookups."
    }
  }
}

resource "cloudflare_zone_dnssec" "this" {
  count = var.create && var.create_dnssec ? 1 : 0

  zone_id             = local.zone_id
  status              = var.dnssec.status == null ? null : lower(trimspace(var.dnssec.status))
  dnssec_multi_signer = var.dnssec.dnssec_multi_signer
  dnssec_presigned    = var.dnssec.dnssec_presigned
  dnssec_use_nsec3    = var.dnssec.dnssec_use_nsec3

  lifecycle {
    precondition {
      condition     = local.zone_selection_valid
      error_message = "DNSSEC requires exactly one valid zone selector, or a managed zone."
    }
    precondition {
      condition     = local.account_selection_valid
      error_message = "Managed zones require account_id. Otherwise account_id is only supported with zone_name; use zone_filter.account for advanced lookups."
    }
  }
}

resource "cloudflare_dns_record" "this" {
  for_each = local.records

  # Configure zone-wide behavior and multi-signer DNSSEC before adding records.
  depends_on = [cloudflare_zone_dns_settings.this, cloudflare_zone_dnssec.this]

  zone_id                 = local.zone_id
  name                    = each.value.name
  type                    = each.value.type
  content                 = each.value.content
  data                    = each.value.data
  ttl                     = each.value.ttl
  proxied                 = each.value.proxied
  priority                = each.value.priority
  comment                 = each.value.comment
  tags                    = each.value.tags
  settings                = each.value.settings
  private_routing         = each.value.private_routing
  include_shadow_metadata = each.value.include_shadow_metadata

  lifecycle {
    precondition {
      condition     = local.zone_selection_valid
      error_message = "Set exactly one of zone_id, zone_name, or zone_filter when create is true."
    }
    precondition {
      condition     = local.account_selection_valid
      error_message = "Managed zones require account_id. Otherwise account_id is only supported with zone_name; use zone_filter.account for advanced lookups."
    }
    precondition {
      condition     = !each.value.proxied || each.value.ttl == 1
      error_message = "Proxied records require ttl = 1 (automatic). Set the record ttl to 1 or change defaults.ttl."
    }
  }
}
