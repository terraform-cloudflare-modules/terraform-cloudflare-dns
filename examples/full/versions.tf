terraform {
  required_version = ">= 1.8"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.28.0, < 6.0.0"
    }
  }
}

provider "cloudflare" {}

variable "zone_name" {
  description = "Domain name of the zone to create, or import before applying."
  type        = string
}
