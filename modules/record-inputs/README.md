# Internal record input types

The root DNS module normalizes scalar or list content to the list type below before
passing it through this module. This preserves Terraform's typed optional fields
and conversions when the caller mixes scalar, list and structured records.

This is an internal implementation module, not a standalone public entry point.
It creates no resources. Use the root module for validation, naming, MX priority
parsing, resource identity and Cloudflare resource management.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.8 |

## Providers

No providers.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| records | Internal normalized record inputs. Content has been converted to a list; all other fields retain the public record schema. | ```map(object({ name = optional(string) full_name = optional(string) type = string content = optional(list(string)) comment = optional(string) include_shadow_metadata = optional(bool) priority = optional(number) private_routing = optional(bool) proxied = optional(bool) tags = optional(set(string)) ttl = optional(number) settings = optional(object({ flatten_cname = optional(bool) ipv4_only = optional(bool) ipv6_only = optional(bool) })) data = optional(object({ algorithm = optional(number) altitude = optional(number) certificate = optional(string) digest = optional(string) digest_type = optional(number) fingerprint = optional(string) flags = optional(string) key_tag = optional(number) lat_degrees = optional(number) lat_direction = optional(string) lat_minutes = optional(number) lat_seconds = optional(number) long_degrees = optional(number) long_direction = optional(string) long_minutes = optional(number) long_seconds = optional(number) matching_type = optional(number) order = optional(number) port = optional(number) precision_horz = optional(number) precision_vert = optional(number) preference = optional(number) priority = optional(number) protocol = optional(number) public_key = optional(string) regex = optional(string) replacement = optional(string) selector = optional(number) service = optional(string) size = optional(number) tag = optional(string) target = optional(string) type = optional(number) usage = optional(number) value = optional(string) weight = optional(number) })) }))``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| records | Records with typed optional fields and defaults applied. |
<!-- END_TF_DOCS -->
