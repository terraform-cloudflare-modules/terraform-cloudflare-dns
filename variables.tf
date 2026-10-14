variable "create" {
  description = "Whether to manage DNS resources and perform zone lookups. Disabling an existing module plans destruction of its managed records, DNSSEC configuration, and any managed zone."
  type        = bool
  default     = true
  nullable    = false
}

variable "create_zone" {
  description = "Whether to manage the zone itself. Requires zone_name and account_id; excludes zone_id and zone_filter. Import an existing zone before applying to adopt it."
  type        = bool
  default     = false
  nullable    = false
}

variable "zone" {
  description = "Optional managed-zone properties. Only supported with create_zone = true. Null values defer to the provider; an empty vanity_name_servers list explicitly clears custom nameservers."
  type = object({
    paused              = optional(bool)
    type                = optional(string)
    vanity_name_servers = optional(list(string))
  })
  default  = {}
  nullable = false
}

variable "create_dnssec" {
  description = "Whether to manage DNSSEC for the selected zone, independently of zone ownership. Set dnssec.status to active to enable signing. Removing managed DNSSEC invokes provider deletion; coordinate parent DS removal first."
  type        = bool
  default     = false
  nullable    = false
}

variable "dnssec" {
  description = "DNSSEC properties, requiring create_dnssec = true. Status accepts active or disabled and is trimmed/lowercased. Null properties defer to the provider; explicit false values are preserved. Registrar or parent-zone DS publication is managed separately."
  type = object({
    status              = optional(string)
    dnssec_multi_signer = optional(bool)
    dnssec_presigned    = optional(bool)
    dnssec_use_nsec3    = optional(bool)
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.dnssec.status == null ? true : contains(["active", "disabled"], lower(trimspace(var.dnssec.status)))
    error_message = "dnssec.status must be null, active, or disabled. Pending states are API results, not desired configuration."
  }
}

variable "create_dns_settings" {
  description = "Whether to manage zone-wide DNS settings, independently of zone and DNSSEC ownership. Settings affect all records in the zone, including records outside this module."
  type        = bool
  default     = false
  nullable    = false
}

variable "dns_settings" {
  description = "Zone-wide DNS settings, requiring create_dns_settings = true. Null properties defer to the provider; false, zero, and empty nested objects are passed through. Zone mode and nameserver type are trimmed/lowercased. foundation_dns is deprecated upstream; prefer nameservers.type."
  type = object({
    flatten_all_cnames  = optional(bool)
    foundation_dns      = optional(bool)
    multi_provider      = optional(bool)
    ns_ttl              = optional(number)
    secondary_overrides = optional(bool)
    zone_mode           = optional(string)
    internal_dns = optional(object({
      reference_zone_id = optional(string)
    }))
    nameservers = optional(object({
      type              = string
      ns_set            = optional(number)
      nameserver_set_id = optional(string)
    }))
    soa = optional(object({
      expire  = optional(number)
      min_ttl = optional(number)
      mname   = optional(string)
      refresh = optional(number)
      retry   = optional(number)
      rname   = optional(string)
      ttl     = optional(number)
    }))
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.dns_settings.zone_mode == null ? true : contains(["standard", "cdn_only", "dns_only"], lower(trimspace(var.dns_settings.zone_mode)))
    error_message = "dns_settings.zone_mode must be null, standard, cdn_only, or dns_only."
  }

  validation {
    condition     = var.dns_settings.nameservers == null ? true : try(length(trimspace(var.dns_settings.nameservers.type)) > 0, false)
    error_message = "dns_settings.nameservers.type must be a nonempty string when nameservers is configured."
  }

  validation {
    condition     = try(var.dns_settings.nameservers.ns_set, null) == null ? true : floor(var.dns_settings.nameservers.ns_set) == var.dns_settings.nameservers.ns_set
    error_message = "dns_settings.nameservers.ns_set must be null or an integer."
  }
}

variable "zone_id" {
  description = "Existing zone ID. Bypasses zone lookup; may be unknown until apply. Mutually exclusive with zone_name, zone_filter, and create_zone."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null ? true : length(trimspace(var.zone_id)) > 0
    error_message = "zone_id must be null or a nonempty zone ID."
  }
}

variable "zone_name" {
  description = "Zone name to create/manage when create_zone is true, or look up otherwise. Mutually exclusive with zone_id and zone_filter. Use Punycode for internationalized names."
  type        = string
  default     = null

  validation {
    condition     = var.zone_name == null ? true : length(trimsuffix(trimspace(var.zone_name), ".")) > 0
    error_message = "zone_name must be null or a nonempty domain name."
  }
}

variable "account_id" {
  description = "Account ID required for a managed zone, an optional account filter for a zone_name lookup, and the default account for load balancing pools/monitors. For advanced lookups use zone_filter.account instead."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null ? true : length(trimspace(var.account_id)) > 0
    error_message = "account_id must be null or a nonempty account ID."
  }
}

variable "zone_filter" {
  description = "Complete cloudflare_zone lookup filter. Must match exactly one zone. Mutually exclusive with zone_id and zone_name. Use filter.account for lookup filtering; account_id can separately supply load balancing pools/monitors. Filter strings pass through unchanged."
  type = object({
    account = optional(object({
      id   = optional(string)
      name = optional(string)
    }))
    direction = optional(string)
    match     = optional(string)
    name      = optional(string)
    order     = optional(string)
    status    = optional(string)
    type      = optional(list(string))
  })
  default = null
}

variable "defaults" {
  description = "Record defaults. Non-null per-record values override these; empty comments, empty tags, and empty settings explicitly override defaults. Settings are replaced as a whole."
  type = object({
    comment                 = optional(string)
    include_shadow_metadata = optional(bool)
    private_routing         = optional(bool)
    proxied                 = optional(bool, false)
    tags                    = optional(set(string))
    ttl                     = optional(number, 1)
    settings = optional(object({
      flatten_cname = optional(bool)
      ipv4_only     = optional(bool)
      ipv6_only     = optional(bool)
    }))
  })
  default  = {}
  nullable = false

  validation {
    condition = var.defaults.ttl == 1 || (
      var.defaults.ttl >= 30 && var.defaults.ttl <= 86400 && floor(var.defaults.ttl) == var.defaults.ttl
    )
    error_message = "defaults.ttl must be 1 (automatic) or an integer from 30 to 86400. Values below 60 require an Enterprise zone."
  }
}

variable "records" {
  description = "DNS records keyed by stable identifiers. Set name explicitly, or omit it to use the key. Content accepts a scalar or a list; MX list entries support a priority followed by a hostname. Supply exactly one of content or data. Full typed fields are defined in modules/record-inputs/variables.tf."
  # Terraform has no union type for mixed scalar/list content in a map of objects.
  # Normalize content first, then apply the full object type in record-inputs.
  type     = any
  default  = {}
  nullable = false

  validation {
    condition = can(keys(var.records)) && try(alltrue([
      for record in var.records : can(keys(record)) && can(record.type)
    ]), false)
    error_message = "records must be an object of record objects, each with a type."
  }

  validation {
    condition = try(alltrue([for record in var.records : try(record.content, null) == null ? true : (
      can(tostring(record.content)) || try(alltrue([for value in tolist(record.content) : value != null && can(tostring(value))]), false)
    )]), false)
    error_message = "content must be a scalar string or a list of non-null strings. Structured payloads belong in data."
  }

  validation {
    condition = try(alltrue([for record in var.records : upper(trimspace(record.type)) != "MX" ? true : try(alltrue([
      for value in tolist(record.content) : can(regex("^([0-9]+)\\s+(\\S+)$", trimspace(value))) ? (
        tonumber(regex("^([0-9]+)\\s+(\\S+)$", trimspace(value))[0]) <= 65535
        ) : (
        can(regex("^\\S+$", trimspace(value))) && try(tonumber(record.priority) >= 0 && tonumber(record.priority) <= 65535 && floor(tonumber(record.priority)) == tonumber(record.priority), false)
      )
    ]), true)]), false)
    error_message = "Each MX list value must be '<priority> <hostname>', or a hostname with a record-level priority. Priorities must be integers from 0 to 65535."
  }

  validation {
    condition = try(length(distinct(flatten([
      for key, record in var.records : try([for index, value in tolist(record.content) : "${key}[${index}]"], [key])
      ]))) == sum(concat([0], [
      for record in var.records : try(length(tolist(record.content)), 1)
    ])), false)
    error_message = "Expanded content keys collide with another record key. Rename the conflicting key (list values use key[0], key[1], etc.)."
  }

  validation {
    condition     = alltrue([for record in var.records : (try(record.content, null) != null) != (try(record.data, null) != null)])
    error_message = "Each record must set exactly one of content or data."
  }

  validation {
    condition     = alltrue([for record in var.records : try(record.name, null) == null || try(record.full_name, null) == null])
    error_message = "A record may set name or full_name, but not both."
  }

  validation {
    condition = alltrue([for record in var.records : try(record.full_name, null) == null ? true : (
      length(trimsuffix(trimspace(try(record.full_name, null)), ".")) > 0 && trimspace(try(record.full_name, null)) != "@"
    )])
    error_message = "full_name must be a nonempty DNS name; use name = \"@\" for the zone apex."
  }

  validation {
    condition = alltrue([for key, record in var.records : (
      length(trimspace(key)) > 0 && (try(record.type, null) == null ? false : length(trimspace(try(record.type, null))) > 0)
    )])
    error_message = "Record keys and types must be nonempty."
  }

  validation {
    condition = alltrue([for record in var.records : try(tonumber(record.ttl), null) == null ? true : (
      try(tonumber(record.ttl), null) == 1 || (try(tonumber(record.ttl), null) >= 30 && try(tonumber(record.ttl), null) <= 86400 && floor(try(tonumber(record.ttl), null)) == try(tonumber(record.ttl), null))
    )])
    error_message = "Record ttl must be 1 (automatic) or an integer from 30 to 86400. Values below 60 require an Enterprise zone."
  }

  validation {
    condition = alltrue([for record in var.records : try(record.data, null) == null ? true : (
      try(record.data.flags, null) == null ? true : (
        contains(["CAA", "DNSKEY"], upper(trimspace(try(record.type, null)))) ? can(tonumber(try(record.data.flags, null))) : true
      )
    )])
    error_message = "CAA and DNSKEY data.flags must be numeric. NAPTR flags may be text."
  }
}

variable "load_balancers" {
  description = "Load balancers keyed by stable identifiers. Names follow record name/full_name rules. Pool references accept managed pool keys or existing IDs, including rule overrides and weight-map keys. Defaults to DNS-only (proxied = false); all upstream settings remain configurable."
  type = map(object({
    adaptive_routing = optional(object({
      failover_across_pools = optional(bool)
    }))
    country_pools = optional(map(list(string)))
    default_pools = list(string)
    description   = optional(string)
    enabled       = optional(bool)
    fallback_pool = string
    location_strategy = optional(object({
      mode       = optional(string)
      prefer_ecs = optional(string)
    }))
    name      = optional(string)
    networks  = optional(list(string))
    pop_pools = optional(map(list(string)))
    proxied   = optional(bool, false)
    random_steering = optional(object({
      default_weight = optional(number)
      pool_weights   = optional(map(number))
    }))
    region_pools = optional(map(list(string)))
    rules = optional(list(object({
      condition = optional(string)
      disabled  = optional(bool)
      fixed_response = optional(object({
        content_type = optional(string)
        location     = optional(string)
        message_body = optional(string)
        status_code  = optional(number)
      }))
      name = optional(string)
      overrides = optional(object({
        adaptive_routing = optional(object({
          failover_across_pools = optional(bool)
        }))
        country_pools = optional(map(list(string)))
        default_pools = optional(list(string))
        fallback_pool = optional(string)
        location_strategy = optional(object({
          mode       = optional(string)
          prefer_ecs = optional(string)
        }))
        pop_pools = optional(map(list(string)))
        random_steering = optional(object({
          default_weight = optional(number)
          pool_weights   = optional(map(number))
        }))
        region_pools     = optional(map(list(string)))
        session_affinity = optional(string)
        session_affinity_attributes = optional(object({
          drain_duration         = optional(number)
          headers                = optional(list(string))
          require_all_headers    = optional(bool)
          samesite               = optional(string)
          secure                 = optional(string)
          zero_downtime_failover = optional(string)
        }))
        session_affinity_ttl = optional(number)
        steering_policy      = optional(string)
        ttl                  = optional(number)
      }))
      priority   = optional(number)
      terminates = optional(bool)
    })))
    session_affinity = optional(string)
    session_affinity_attributes = optional(object({
      drain_duration         = optional(number)
      headers                = optional(list(string))
      require_all_headers    = optional(bool)
      samesite               = optional(string)
      secure                 = optional(string)
      zero_downtime_failover = optional(string)
    }))
    session_affinity_ttl = optional(number)
    steering_policy      = optional(string)
    ttl                  = optional(number)
    full_name            = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for key, value in var.load_balancers : length(trimspace(key)) > 0 && value != null])
    error_message = "load_balancers must have nonempty keys and non-null objects."
  }

  validation {
    condition     = alltrue([for balancer in var.load_balancers : (balancer.name == null || balancer.full_name == null)])
    error_message = "A load balancer may set name or full_name, but not both."
  }

  validation {
    condition = alltrue([for balancer in var.load_balancers : balancer.full_name == null ? true : (
      length(trimsuffix(trimspace(balancer.full_name), ".")) > 0 && trimspace(balancer.full_name) != "@"
    )])
    error_message = "Load balancer full_name must be a nonempty DNS name; use name = \"@\" for the zone apex."
  }

  validation {
    condition = alltrue([for balancer in var.load_balancers : try(
      length(balancer.default_pools) > 0 && alltrue([for pool in balancer.default_pools : length(trimspace(pool)) > 0]) &&
      length(trimspace(balancer.fallback_pool)) > 0, false
    )])
    error_message = "Load balancers require nonempty default_pools and a nonempty fallback_pool."
  }
}

variable "load_balancer_pools" {
  description = "Account-level pools keyed by stable identifiers. Name defaults to the key; account_id defaults to the module account_id. Monitor accepts a managed monitor key or an existing ID. All configurable upstream properties are available."
  type = map(object({
    account_id     = optional(string)
    check_regions  = optional(list(string))
    description    = optional(string)
    enabled        = optional(bool)
    health_sources = optional(list(string))
    latitude       = optional(number)
    load_shedding = optional(object({
      default_percent = optional(number)
      default_policy  = optional(string)
      session_percent = optional(number)
      session_policy  = optional(string)
    }))
    longitude          = optional(number)
    minimum_origins    = optional(number)
    monitor            = optional(string)
    monitor_group      = optional(string)
    name               = optional(string)
    notification_email = optional(string)
    notification_filter = optional(object({
      origin = optional(object({
        disable = optional(bool)
        healthy = optional(bool)
      }))
      pool = optional(object({
        disable = optional(bool)
        healthy = optional(bool)
      }))
    }))
    origin_steering = optional(object({
      policy = optional(string)
    }))
    origins = list(object({
      address       = optional(string)
      enabled       = optional(bool)
      flatten_cname = optional(bool)
      header = optional(object({
        host = optional(list(string))
      }))
      name               = optional(string)
      port               = optional(number)
      virtual_network_id = optional(string)
      weight             = optional(number)
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for key, value in var.load_balancer_pools : length(trimspace(key)) > 0 && value != null])
    error_message = "load_balancer_pools must have nonempty keys and non-null objects."
  }
}

variable "load_balancer_monitors" {
  description = "Account-level health monitors keyed by stable identifiers. account_id defaults to the module account_id. Monitor type and HTTP method are normalized; bodies, paths, headers, and other settings pass through unchanged."
  type = map(object({
    account_id       = optional(string)
    allow_insecure   = optional(bool)
    consecutive_down = optional(number)
    consecutive_up   = optional(number)
    description      = optional(string)
    expected_body    = optional(string)
    expected_codes   = optional(string)
    follow_redirects = optional(bool)
    header           = optional(map(list(string)))
    interval         = optional(number)
    method           = optional(string)
    path             = optional(string)
    port             = optional(number)
    probe_zone       = optional(string)
    retries          = optional(number)
    timeout          = optional(number)
    type             = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for key, value in var.load_balancer_monitors : length(trimspace(key)) > 0 && value != null])
    error_message = "load_balancer_monitors must have nonempty keys and non-null objects."
  }
}
