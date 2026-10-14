resource "cloudflare_account_dns_settings" "this" {
  count = var.create ? 1 : 0

  account_id       = var.account_id
  enforce_dns_only = var.settings.enforce_dns_only
  zone_defaults = var.settings.zone_defaults == null ? null : merge(var.settings.zone_defaults, {
    zone_mode = var.settings.zone_defaults.zone_mode == null ? null : lower(trimspace(var.settings.zone_defaults.zone_mode))
    nameservers = var.settings.zone_defaults.nameservers == null ? null : merge(var.settings.zone_defaults.nameservers, {
      type = var.settings.zone_defaults.nameservers.type == null ? null : lower(trimspace(var.settings.zone_defaults.nameservers.type))
    })
  })

  lifecycle {
    precondition {
      condition     = try(length(trimspace(var.account_id)) > 0, false)
      error_message = "Managing account DNS settings requires account_id."
    }
  }
}
