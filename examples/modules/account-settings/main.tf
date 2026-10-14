module "account_settings" {
  source = "../../../modules/account-settings"

  account_id = var.account_id
  settings = {
    enforce_dns_only = false
    zone_defaults = {
      nameservers = { type = "cloudflare.standard" }
      zone_mode   = "standard"
      ns_ttl      = 86400
      soa         = { min_ttl = 1800, ttl = 3600 }
    }
  }
}

module "dns" {
  source = "../../.."

  # Account defaults apply only when the zone is created.
  depends_on = [module.account_settings]

  create_zone = true
  account_id  = var.account_id
  zone_name   = var.zone_name
}
