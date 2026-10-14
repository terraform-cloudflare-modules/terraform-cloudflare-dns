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

variable "groups" {
  description = "Reusable monitor groups keyed by stable identifiers. Each member supplies a monitor ID and all required health flags. Members are unordered; false flags, empty descriptions, and empty member sets pass through for provider validation."
  type = map(object({
    account_id  = optional(string)
    description = string
    members = set(object({
      enabled         = bool
      monitor_id      = string
      monitoring_only = bool
      must_be_healthy = bool
    }))
  }))
  default  = {}
  nullable = false
}
