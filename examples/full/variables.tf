variable "account_id" {
  description = "Cloudflare account containing the zone."
  type        = string
}

variable "zone_name" {
  description = "Domain name of the zone to create, or import before applying."
  type        = string
}
