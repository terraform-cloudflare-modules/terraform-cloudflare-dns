variable "create" {
  description = "Whether to manage resources in this submodule. Must be known at plan time."
  type        = bool
  default     = true
  nullable    = false
}

variable "account_id" {
  description = "Default account for managed entries. Individual entries can override it."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null ? true : length(trimspace(var.account_id)) > 0
    error_message = "account_id must be null or a nonempty account ID."
  }
}

variable "clusters" {
  description = "DNS Firewall clusters keyed by stable identifiers. Names default to keys; all upstream settings, including nested attack mitigation, are configurable. Null optional fields defer to the provider; explicit false, zero, and empty collections/objects pass through."
  type = map(object({
    account_id = optional(string)
    attack_mitigation = optional(object({
      enabled                      = optional(bool)
      only_when_upstream_unhealthy = optional(bool)
    }))
    deprecate_any_requests = optional(bool)
    dns_firewall_ip_count  = optional(number)
    ecs_fallback           = optional(bool)
    maximum_cache_ttl      = optional(number)
    minimum_cache_ttl      = optional(number)
    name                   = optional(string)
    negative_cache_ttl     = optional(number)
    ratelimit              = optional(number)
    retries                = optional(number)
    upstream_ips           = set(string)
  }))
  default  = {}
  nullable = false
}
