variable "account_id" {
  description = "Cloudflare account containing the zone."
  type        = string
}

variable "zone_name" {
  description = "Domain name of the zone to create, or import before applying."
  type        = string
}

variable "notification_email" {
  description = "Address for pool health notifications."
  type        = string
}

variable "europe_origin" {
  description = "Reachable European origin IP or hostname."
  type        = string
}

variable "america_origin" {
  description = "Reachable American origin IP or hostname."
  type        = string
}

variable "ssh_fingerprint" {
  description = "SHA-256 SSH fingerprint as hexadecimal."
  type        = string
}

variable "tlsa_certificate" {
  description = "TLSA SHA-256 SPKI digest as hexadecimal."
  type        = string
}

variable "child_key_tag" {
  description = "Key tag from the delegated child zone."
  type        = number
}

variable "child_ds_digest" {
  description = "DS digest from the delegated child zone."
  type        = string
}

variable "external_dnskey" {
  description = "Base64 public key from the external multi-signer provider."
  type        = string
}
