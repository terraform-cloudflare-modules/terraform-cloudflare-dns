variable "account_id" {
  description = "Cloudflare account with zone transfers enabled."
  type        = string
}

variable "primary_zone_name" {
  description = "New test domain for which Cloudflare is the primary DNS provider."
  type        = string
}

variable "secondary_zone_name" {
  description = "New test domain for which the external provider is primary and Cloudflare is secondary."
  type        = string
}

variable "transfer_secret" {
  description = "Already-encoded TSIG secret shared with the external DNS provider."
  type        = string
  sensitive   = true
}
