variable "account_id" {
  description = "Cloudflare account containing the managed resources."
  type        = string
}

variable "zone_name" {
  description = "New test zone that should inherit the configured account defaults."
  type        = string
}
