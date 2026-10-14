variable "account_id" {
  description = "Cloudflare account containing the managed resources."
  type        = string
}

variable "zone_id" {
  description = "Existing zone used for the example load balancer."
  type        = string
}

variable "hostname" {
  description = "Fully qualified hostname for the example load balancer."
  type        = string
}
