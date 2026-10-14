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
    for key, record in module.record_inputs.records : key => lower(trimsuffix(trimspace(record.name != null ? record.name : key), "."))
  }

  normalized_records = {
    for key, record in module.record_inputs.records : key => merge(record, {
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

locals {
  # Identities depend only on input keys and list lengths, never on record values.
  content_indexes = {
    for key, record in var.records : key => try([for index, value in tolist(record.content) : index], null)
  }
  record_instances = flatten([
    for key, indexes in local.content_indexes : indexes == null ? [
      { key = key, group = key, index = 0, multiple = false }
    ] : [for index in indexes : { key = "${key}[${index}]", group = key, index = index, multiple = true }]
  ])
  mx_values = {
    for instance in local.record_instances : instance.key => (
      instance.multiple && local.normalized_records[instance.group].type == "MX" ?
      try(regex("^([0-9]+)\\s+(\\S+)$", trimspace(local.normalized_records[instance.group].content[instance.index])), null) : null
    ) if var.create
  }
  records = {
    for instance in local.record_instances : instance.key => merge(local.normalized_records[instance.group], {
      content = local.mx_values[instance.key] != null ? local.mx_values[instance.key][1] : try(
        instance.multiple && local.normalized_records[instance.group].type == "MX" ?
        trimspace(local.normalized_records[instance.group].content[instance.index]) : local.normalized_records[instance.group].content[instance.index], null
      )
      priority = local.mx_values[instance.key] != null ? tonumber(local.mx_values[instance.key][0]) : local.normalized_records[instance.group].priority
    }) if var.create
  }
}
