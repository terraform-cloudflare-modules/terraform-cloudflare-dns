# Cloudflare account DNS settings

Manage `cloudflare_account_dns_settings` once per account, independently of any
zone module instance. An enabled call manages one settings resource; `account_id`
is required. `create = false` produces no resource and a null `settings` output.

```hcl
module "account_settings" {
  source = "terraform-cloudflare-modules/dns/cloudflare//modules/account-settings"

  account_id = var.account_id
  settings = {
    enforce_dns_only = false
    zone_defaults = {
      zone_mode   = "standard"
      nameservers = { type = "cloudflare.standard" }
      ns_ttl      = 86400
      soa         = { min_ttl = 1800, ttl = 3600 }
    }
  }
}
```

## Account behavior

`enforce_dns_only` changes how the account's proxied records are served at the
edge without changing their individual proxy flags. Review this account-wide
behavior before taking ownership. [Enforce DNS-only documentation][enforcement].

`zone_defaults` supplies defaults for newly created zones. It does not update
existing or revived zones. If the same configuration creates zones that should
inherit these defaults, add `depends_on = [module.account_settings]` to those zone
module calls. See the [composed example](../../examples/modules/account-settings/main.tf).
[Cloudflare's zone-default documentation][defaults] describes availability and behavior.

All configurable account fields are exposed: enforcement, CNAME flattening,
Foundation DNS, multi-provider behavior, NS TTL, secondary overrides, zone mode,
internal reference zone, nameserver type, and every SOA property. The account
schema differs from zone DNS settings: `nameservers.type` is optional here, and
there are no account-default `ns_set` or `nameserver_set_id` fields in the supplied schema.

Zone mode and nameserver type are trimmed and lowercased. SOA names and reference
IDs pass through unchanged. Null optional fields defer to the provider; explicit
false, zero, and empty nested objects are forwarded. The complete `settings`
output preserves the upstream object. Account feature entitlements and setting
combinations are validated upstream.

Choose one owning module instance per account. Adding a second owner would make
both instances write the same settings. Removing ownership or passing null does
not promise to restore previous values: explicitly apply desired settings before
handing off ownership, and review the provider's removal behavior.

[enforcement]: https://developers.cloudflare.com/dns/proxy-status/enforce-dns-only/
[defaults]: https://developers.cloudflare.com/dns/additional-options/dns-zone-defaults/

## Adoption and verification

These submodules were added after v2.0.0. Use a local checkout containing them until
a release includes them, then pin that release when using the Registry source.
Provider configuration and credentials belong to the caller.

When an existing resource is already managed in the same state, retain its ID with
a caller-root move and remove the old declaration:

```hcl
moved {
  from = cloudflare_account_dns_settings.existing
  to   = module.account_settings.cloudflare_account_dns_settings.this[0]
}
```

Match existing settings and inspect the plan before applying. For resources not
already in state, follow the import procedure for the installed provider version.
For a handoff between states, coordinate ownership before applying either state.
Setting `create = false` plans resource removal; it is not a state-only handoff.

The [schema report](docs/SCHEMA.md) includes every configurable resource field.
From the repository root, regenerate and check it with:

```sh
formr schema modules/account-settings --schema-file secrets/schema.json \
  -o modules/account-settings/docs/SCHEMA.md
formr check modules/account-settings --schema-file secrets/schema.json \
  --report modules/account-settings/docs/SCHEMA.md
```

The supplied raw snapshot lacks engine/provider version provenance; refresh it
with provenance before publication. Native mock tests cover configuration,
outputs, disabling, account checks, and unknown inputs. They do not verify live
API behavior or account entitlements. Exercise creation, updates, a second
no-change plan, and removal in a dedicated test account before production use.

The current Formr analysis labels results behind `one(...)` as unused. The
`settings` output still returns the complete resource, and tests verify its value
and null behavior when disabled.

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | >= 5.28.0, < 6.0.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Account to manage. Required when create is true. | `string` | `null` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to manage resources in this submodule. Must be known at plan time. | `bool` | `true` | no |
| <a name="input_settings"></a> [settings](#input\_settings) | Account-wide DNS enforcement and defaults for newly created zones. Null optional fields defer to the provider; explicit false, zero, and empty collections/objects pass through. | ```object({ enforce_dns_only = optional(bool) zone_defaults = optional(object({ flatten_all_cnames = optional(bool) foundation_dns = optional(bool) internal_dns = optional(object({ reference_zone_id = optional(string) })) multi_provider = optional(bool) nameservers = optional(object({ type = optional(string) })) ns_ttl = optional(number) secondary_overrides = optional(bool) soa = optional(object({ expire = optional(number) min_ttl = optional(number) mname = optional(string) refresh = optional(number) retry = optional(number) rname = optional(string) ttl = optional(number) })) zone_mode = optional(string) })) })``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_settings"></a> [settings](#output\_settings) | Complete account DNS settings, or null when disabled. |
<!-- END_TF_DOCS -->
