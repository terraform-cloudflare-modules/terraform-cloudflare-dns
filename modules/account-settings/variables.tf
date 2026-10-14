variable "create" {
  description = "Whether to manage resources in this submodule. Must be known at plan time."
  type        = bool
  default     = true
  nullable    = false
}

variable "account_id" {
  description = "Account to manage. Required when create is true."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null ? true : length(trimspace(var.account_id)) > 0
    error_message = "account_id must be null or a nonempty account ID."
  }
}

variable "settings" {
  description = "Account-wide DNS enforcement and defaults for newly created zones. Null optional fields defer to the provider; explicit false, zero, and empty collections/objects pass through."
  type = object({
    enforce_dns_only = optional(bool)
    zone_defaults = optional(object({
      flatten_all_cnames = optional(bool)
      foundation_dns     = optional(bool)
      internal_dns = optional(object({
        reference_zone_id = optional(string)
      }))
      multi_provider = optional(bool)
      nameservers = optional(object({
        type = optional(string)
      }))
      ns_ttl              = optional(number)
      secondary_overrides = optional(bool)
      soa = optional(object({
        expire  = optional(number)
        min_ttl = optional(number)
        mname   = optional(string)
        refresh = optional(number)
        retry   = optional(number)
        rname   = optional(string)
        ttl     = optional(number)
      }))
      zone_mode = optional(string)
    }))
  })
  default  = {}
  nullable = false

  validation {
    condition = try(var.settings.zone_defaults.zone_mode, null) == null ? true : contains(
      ["standard", "cdn_only", "dns_only"], lower(trimspace(var.settings.zone_defaults.zone_mode))
    )
    error_message = "settings.zone_defaults.zone_mode must be null, standard, cdn_only, or dns_only."
  }
}
