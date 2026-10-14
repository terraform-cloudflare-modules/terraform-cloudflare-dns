variable "create" {
  description = "Whether to manage any transfer resources. Map keys must be known at plan time; resource IDs and secrets may be unknown."
  type        = bool
  default     = true
  nullable    = false
}

variable "account_id" {
  description = "Default account for ACLs, TSIG keys, and peers. Individual entries can override it. Not required when only configuring transfers with existing peer IDs."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null ? true : length(trimspace(var.account_id)) > 0
    error_message = "account_id must be null or a nonempty account ID."
  }
}

variable "acls" {
  description = "Account-wide transfer ACLs keyed by stable identifiers. Name defaults to the key; ip_range passes through unchanged."
  type = map(object({
    account_id = optional(string)
    name       = optional(string)
    ip_range   = string
  }))
  default  = {}
  nullable = false
}

variable "tsig_keys" {
  description = "TSIG keys keyed by stable, non-secret identifiers. Name defaults to the key; algo is trimmed/lowercased; secret is preserved exactly. Keys are exposed in resource addresses; all values and the complete output are sensitive."
  type = map(object({
    account_id = optional(string)
    name       = optional(string)
    algo       = string
    secret     = string
  }))
  default   = {}
  nullable  = false
  sensitive = true
}

variable "peers" {
  description = "Account-level transfer peers keyed by stable identifiers. Name defaults to the key; tsig_id accepts a managed TSIG key or an existing ID. Null properties defer to the provider; explicit false and zero pass through."
  type = map(object({
    account_id  = optional(string)
    name        = optional(string)
    ip          = optional(string)
    port        = optional(number)
    ixfr_enable = optional(bool)
    tsig_id     = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "incoming" {
  description = "Incoming transfers keyed by stable identifiers. Supply zone_id and the zone's name, normalized as a DNS name. peers accepts managed peer keys or existing IDs. Zones must already exist or be supplied by another resource/module."
  type = map(object({
    zone_id              = string
    name                 = string
    peers                = set(string)
    auto_refresh_seconds = optional(number)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = length(distinct([for transfer in var.incoming : transfer.zone_id])) == length(var.incoming)
    error_message = "Only one incoming transfer entry may manage a given zone ID."
  }
}

variable "outgoing" {
  description = "Outgoing transfers keyed by stable identifiers. Supply zone_id and the zone's name, normalized as a DNS name. peers accepts managed peer keys or existing IDs. Resource keys are independent of zone and peer IDs."
  type = map(object({
    zone_id = string
    name    = string
    peers   = set(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = length(distinct([for transfer in var.outgoing : transfer.zone_id])) == length(var.outgoing)
    error_message = "Only one outgoing transfer entry may manage a given zone ID."
  }
}
