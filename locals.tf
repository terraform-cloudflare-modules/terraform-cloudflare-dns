locals {
  # Decide lookup count from configuration, not a potentially unknown zone ID.
  lookup_zone = !var.create_zone && (var.zone_name != null || var.zone_filter != null)
  zone_selection_valid = !var.create || (
    var.create_zone ? (var.zone_name != null && var.zone_id == null && var.zone_filter == null) :
    (var.zone_id != null ? 1 : 0) + (var.zone_name != null ? 1 : 0) + (var.zone_filter != null ? 1 : 0) == 1
  )
  account_selection_valid = !var.create || (
    var.create_zone ? var.account_id != null : (var.account_id == null || var.zone_name != null)
  )
  zone_options_valid = !var.create || var.create_zone || alltrue([
    var.zone.paused == null, var.zone.type == null, var.zone.vanity_name_servers == null
  ])

  zone_id = !var.create ? null : (
    var.create_zone ? cloudflare_zone.this[0].id : (local.lookup_zone ? data.cloudflare_zone.this[0].id : var.zone_id)
  )
  zone_name = !var.create ? null : (
    var.create_zone ? (var.zone_name == null ? null : lower(trimsuffix(trimspace(var.zone_name), "."))) :
    (local.lookup_zone ? lower(trimsuffix(data.cloudflare_zone.this[0].name, ".")) : null)
  )
  # Preserve each upstream object's shape; resource and data-source schemas differ.
  zone = try(cloudflare_zone.this[0], data.cloudflare_zone.this[0], null)
}

locals {
  relative_names = {
    for key, record in var.records : key => lower(trimsuffix(trimspace(record.name != null ? record.name : key), "."))
  }

  records = {
    for key, record in var.records : key => merge(record, {
      name = record.full_name != null ? lower(trimsuffix(trimspace(record.full_name), ".")) : (
        contains(["", "@"], local.relative_names[key]) ? (local.zone_name != null ? local.zone_name : "@") : (
          local.zone_name != null ? "${local.relative_names[key]}.${local.zone_name}" : local.relative_names[key]
        )
      )
      type                    = upper(trimspace(record.type))
      ttl                     = record.ttl != null ? record.ttl : var.defaults.ttl
      proxied                 = record.proxied != null ? record.proxied : var.defaults.proxied
      comment                 = record.comment != null ? record.comment : var.defaults.comment
      tags                    = record.tags != null ? record.tags : var.defaults.tags
      settings                = record.settings != null ? record.settings : var.defaults.settings
      private_routing         = record.private_routing != null ? record.private_routing : var.defaults.private_routing
      include_shadow_metadata = record.include_shadow_metadata != null ? record.include_shadow_metadata : var.defaults.include_shadow_metadata

      # JSON selects the dynamic flags type without Terraform coercing numbers
      # back to strings when CAA/DNSKEY and NAPTR coexist in the same input map.
      data = record.data == null ? null : merge(record.data, {
        flags = jsondecode(
          contains(["CAA", "DNSKEY"], upper(trimspace(record.type)))
          ? jsonencode(try(tonumber(record.data.flags), null))
          : jsonencode(record.data.flags)
        )
      })
    }) if var.create
  }
}
