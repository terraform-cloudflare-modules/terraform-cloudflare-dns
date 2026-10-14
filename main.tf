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
      error_message = "Managed zones require account_id. Otherwise account_id needs a zone_name lookup or load balancing pools/monitors; use zone_filter.account for advanced lookups."
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
      error_message = "Managed zones require account_id. Otherwise account_id needs a zone_name lookup or load balancing pools/monitors; use zone_filter.account for advanced lookups."
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
      error_message = "Managed zones require account_id. Otherwise account_id needs a zone_name lookup or load balancing pools/monitors; use zone_filter.account for advanced lookups."
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
      error_message = "Managed zones require account_id. Otherwise account_id needs a zone_name lookup or load balancing pools/monitors; use zone_filter.account for advanced lookups."
    }
    precondition {
      condition     = !each.value.proxied || each.value.ttl == 1
      error_message = "Proxied records require ttl = 1 (automatic). Set the record ttl to 1 or change defaults.ttl."
    }
  }
}

resource "cloudflare_load_balancer_monitor" "this" {
  for_each = { for key, value in var.load_balancer_monitors : key => value if var.create }

  account_id       = each.value.account_id != null ? each.value.account_id : var.account_id
  allow_insecure   = each.value.allow_insecure
  consecutive_down = each.value.consecutive_down
  consecutive_up   = each.value.consecutive_up
  description      = each.value.description
  expected_body    = each.value.expected_body
  expected_codes   = each.value.expected_codes
  follow_redirects = each.value.follow_redirects
  header           = each.value.header
  interval         = each.value.interval
  method           = each.value.method == null ? null : upper(trimspace(each.value.method))
  path             = each.value.path
  port             = each.value.port
  probe_zone       = each.value.probe_zone
  retries          = each.value.retries
  timeout          = each.value.timeout
  type             = each.value.type == null ? null : lower(trimspace(each.value.type))

  lifecycle {
    precondition {
      condition     = try(length(trimspace(each.value.account_id != null ? each.value.account_id : var.account_id)) > 0, false)
      error_message = "Each monitor requires account_id, either on the entry or at module level."
    }
  }
}

resource "cloudflare_load_balancer_pool" "this" {
  for_each = { for key, value in var.load_balancer_pools : key => value if var.create }

  account_id          = each.value.account_id != null ? each.value.account_id : var.account_id
  check_regions       = each.value.check_regions
  description         = each.value.description
  enabled             = each.value.enabled
  health_sources      = each.value.health_sources
  latitude            = each.value.latitude
  load_shedding       = each.value.load_shedding
  longitude           = each.value.longitude
  minimum_origins     = each.value.minimum_origins
  monitor             = each.value.monitor == null ? null : lookup(local.load_balancer_monitor_ids, each.value.monitor, each.value.monitor)
  monitor_group       = each.value.monitor_group
  name                = (each.value.name != null ? each.value.name : each.key)
  notification_email  = each.value.notification_email
  notification_filter = each.value.notification_filter
  origin_steering     = each.value.origin_steering
  origins             = each.value.origins

  lifecycle {
    precondition {
      condition     = try(length(trimspace(each.value.account_id != null ? each.value.account_id : var.account_id)) > 0, false)
      error_message = "Each pool requires account_id, either on the entry or at module level."
    }
  }
}

resource "cloudflare_load_balancer" "this" {
  for_each = { for key, value in var.load_balancers : key => value if var.create }

  depends_on = [cloudflare_zone_dns_settings.this, cloudflare_zone_dnssec.this]

  adaptive_routing            = each.value.adaptive_routing
  country_pools               = local.resolved_pool_references[jsonencode([each.key])].country_pools
  default_pools               = local.resolved_pool_references[jsonencode([each.key])].default_pools
  description                 = each.value.description
  enabled                     = each.value.enabled
  fallback_pool               = local.resolved_pool_references[jsonencode([each.key])].fallback_pool
  location_strategy           = each.value.location_strategy
  name                        = local.load_balancer_names[each.key]
  networks                    = each.value.networks
  pop_pools                   = local.resolved_pool_references[jsonencode([each.key])].pop_pools
  proxied                     = each.value.proxied
  random_steering             = local.resolved_pool_references[jsonencode([each.key])].random_steering
  region_pools                = local.resolved_pool_references[jsonencode([each.key])].region_pools
  rules                       = local.load_balancer_rules[each.key]
  session_affinity            = each.value.session_affinity
  session_affinity_attributes = each.value.session_affinity_attributes
  session_affinity_ttl        = each.value.session_affinity_ttl
  steering_policy             = each.value.steering_policy == null ? null : lower(trimspace(each.value.steering_policy))
  ttl                         = each.value.ttl
  zone_id                     = local.zone_id

  lifecycle {
    precondition {
      condition     = local.zone_selection_valid
      error_message = "Load balancers require exactly one valid zone selector, or a managed zone."
    }
    precondition {
      condition     = local.account_selection_valid
      error_message = "account_id must select a managed zone, filter a zone_name lookup, or supply load balancing pools/monitors."
    }
  }
}
