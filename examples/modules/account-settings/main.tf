module "account_settings" {
  source = "../../../modules/account-settings"

  create = true

  account_id = var.account_id
  settings = {
    enforce_dns_only = false
    zone_defaults = {
      flatten_all_cnames  = false
      foundation_dns      = null                         # Deprecated: prefer nameservers.type.
      internal_dns        = { reference_zone_id = null } # Internal zones only.
      multi_provider      = false
      secondary_overrides = false
      nameservers         = { type = "cloudflare.standard" }
      zone_mode           = "standard"
      ns_ttl              = 86400
      soa = {
        expire  = 604800
        min_ttl = 1800
        mname   = null # Optional primary name, when supported by the account.
        refresh = 10000
        retry   = 2400
        rname   = "admin.${var.zone_name}"
        ttl     = 3600
      }
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
