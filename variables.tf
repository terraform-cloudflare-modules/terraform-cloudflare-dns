variable "create" {
  description = "Whether to manage DNS records and perform zone lookups. Disabling an existing module plans destruction of its managed records."
  type        = bool
  default     = true
  nullable    = false
}

variable "zone_id" {
  description = "Existing zone ID. Bypasses zone lookup; may be unknown until apply. Mutually exclusive with zone_name and zone_filter."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null ? true : length(trimspace(var.zone_id)) > 0
    error_message = "zone_id must be null or a nonempty zone ID."
  }
}

variable "zone_name" {
  description = "Existing zone name to look up. Mutually exclusive with zone_id and zone_filter. Use account_id to disambiguate accounts."
  type        = string
  default     = null

  validation {
    condition     = var.zone_name == null ? true : length(trimsuffix(trimspace(var.zone_name), ".")) > 0
    error_message = "zone_name must be null or a nonempty domain name."
  }
}

variable "account_id" {
  description = "Account ID for a zone_name lookup. For advanced lookups use zone_filter.account instead."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null ? true : length(trimspace(var.account_id)) > 0
    error_message = "account_id must be null or a nonempty account ID."
  }
}

variable "zone_filter" {
  description = "Complete cloudflare_zone lookup filter. Must match exactly one zone. Mutually exclusive with zone_id, zone_name, and account_id. Filter strings, including operators, are passed through unchanged."
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
  description = "DNS records keyed by stable caller-chosen identifiers. Use relative name (defaults to key), @ or empty name for apex, or full_name for an FQDN. Supply exactly one of content or data. Numeric CAA/DNSKEY flags are accepted and normalized to numbers; NAPTR flags remain strings."
  type = map(object({
    name                    = optional(string)
    full_name               = optional(string)
    type                    = string
    content                 = optional(string)
    comment                 = optional(string)
    include_shadow_metadata = optional(bool)
    priority                = optional(number)
    private_routing         = optional(bool)
    proxied                 = optional(bool)
    tags                    = optional(set(string))
    ttl                     = optional(number)
    settings = optional(object({
      flatten_cname = optional(bool)
      ipv4_only     = optional(bool)
      ipv6_only     = optional(bool)
    }))
    data = optional(object({
      algorithm      = optional(number)
      altitude       = optional(number)
      certificate    = optional(string)
      digest         = optional(string)
      digest_type    = optional(number)
      fingerprint    = optional(string)
      flags          = optional(string)
      key_tag        = optional(number)
      lat_degrees    = optional(number)
      lat_direction  = optional(string)
      lat_minutes    = optional(number)
      lat_seconds    = optional(number)
      long_degrees   = optional(number)
      long_direction = optional(string)
      long_minutes   = optional(number)
      long_seconds   = optional(number)
      matching_type  = optional(number)
      order          = optional(number)
      port           = optional(number)
      precision_horz = optional(number)
      precision_vert = optional(number)
      preference     = optional(number)
      priority       = optional(number)
      protocol       = optional(number)
      public_key     = optional(string)
      regex          = optional(string)
      replacement    = optional(string)
      selector       = optional(number)
      service        = optional(string)
      size           = optional(number)
      tag            = optional(string)
      target         = optional(string)
      type           = optional(number)
      usage          = optional(number)
      value          = optional(string)
      weight         = optional(number)
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for record in var.records : (record.content != null) != (record.data != null)])
    error_message = "Each record must set exactly one of content or data."
  }

  validation {
    condition     = alltrue([for record in var.records : record.name == null || record.full_name == null])
    error_message = "A record may set name or full_name, but not both."
  }

  validation {
    condition = alltrue([for record in var.records : record.full_name == null ? true : (
      length(trimsuffix(trimspace(record.full_name), ".")) > 0 && trimspace(record.full_name) != "@"
    )])
    error_message = "full_name must be a nonempty DNS name; use name = \"@\" for the zone apex."
  }

  validation {
    condition = alltrue([for key, record in var.records : (
      length(trimspace(key)) > 0 && (record.type == null ? false : length(trimspace(record.type)) > 0)
    )])
    error_message = "Record keys and types must be nonempty."
  }

  validation {
    condition = alltrue([for record in var.records : record.ttl == null ? true : (
      record.ttl == 1 || (record.ttl >= 30 && record.ttl <= 86400 && floor(record.ttl) == record.ttl)
    )])
    error_message = "Record ttl must be 1 (automatic) or an integer from 30 to 86400. Values below 60 require an Enterprise zone."
  }

  validation {
    condition = alltrue([for record in var.records : record.data == null ? true : (
      record.data.flags == null ? true : (
        contains(["CAA", "DNSKEY"], upper(trimspace(record.type))) ? can(tonumber(record.data.flags)) : true
      )
    )])
    error_message = "CAA and DNSKEY data.flags must be numeric. NAPTR flags may be text."
  }
}
