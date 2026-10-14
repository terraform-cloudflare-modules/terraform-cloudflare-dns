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

variable "views" {
  description = "Internal DNS views keyed by stable identifiers. Names default to keys; explicit names are preserved. zones is the complete set of internal zone IDs to associate with each view and may be empty. Individual account IDs override the module default."
  type = map(object({
    account_id = optional(string)
    name       = optional(string)
    zones      = set(string)
  }))
  default  = {}
  nullable = false
}
