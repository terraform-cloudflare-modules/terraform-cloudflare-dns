<p align="center">
    <!-- terraform-cloudflare-dns -->
<img src="https://cdn.simpleicons.org/terraform/844FBA" alt="Terraform Logo" align="center" width="128">
<img src="https://cdn.simpleicons.org/cloudflare/F38020" alt="Cloudflare Logo" align="center" width="128">
    <h1 align="center">Cloudflare</h1>
    <h2 align="center"><code>dns</code></h2>
</p>

[![License](https://img.shields.io/github/license/terraform-cloudflare-modules/terraform-cloudflare-dns?label=License)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-_>=_1.8-brightgreen?logo=terraform&logoColor=623CE4)][terraform]
[![OpenTofu](https://img.shields.io/badge/OpenTofu-_>=_1.13.1-brightgreen?logo=opentofu)][opentofu]
[![CI Status](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/actions/workflows/testing.yaml/badge.svg)](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/blob/main/.github/workflows/testing.yaml)
[![GitHub Release](https://img.shields.io/github/v/release/terraform-cloudflare-modules/terraform-cloudflare-dns?label=Release)][github_releases]
[![GitHub Activity](https://img.shields.io/github/commit-activity/m/terraform-cloudflare-modules/terraform-cloudflare-dns?label=Commits)][github_commits]
[![Renovate](https://img.shields.io/badge/Renovate-enabled-brightgreen?logo=renovate&logoColor=1A1F6C)][renovate]
[![Pre-Commit](https://img.shields.io/badge/PreCommit-enabled-brightgreen?logo=precommit&logoColor=FAB040)][pre-commit]

A [Terraform module][module] to manage [Cloudflare][cloudflare] DNS with stable record keys,
typed inputs, and access to every configurable DNS record property.

This repository is the successor to `terraform-cloudflare-dns-record`. The v2 API manages individual records in one zone per module invocation, with optional zone, DNSSEC, and zone-wide DNS settings management.
Further DNS capabilities are planned as optional additions within this module's scope.

**Release status:** v2 is under development. The Registry source shown below is the intended v2 address; it must be published before Registry installation works.
The historical `v1.0.0` tag retains the original single-record API. Existing users should read the [v2 migration guide](docs/UPGRADING.md).

## ✨ TL;DR

```hcl
module "dns" {
  source  = "terraform-cloudflare-modules/dns/cloudflare"
  version = "~> 2.0"

  zone_name  = "example.com"
  account_id = var.cloudflare_account_id

  defaults = {
    ttl     = 1
    proxied = false
  }

  records = {
    www = {
      name    = "www"
      type    = "A"
      content = "192.0.2.10"
      proxied = true
    }
    mail = {
      name = "@"
      type = "MX"
      content = [
        "1 aspmx.l.google.com",
        "5 alt1.aspmx.l.google.com",
        "5 alt2.aspmx.l.google.com",
        "10 alt3.aspmx.l.google.com",
        "10 alt4.aspmx.l.google.com",
      ]
      ttl = 3600
    }
    certificate_authority = {
      name = "@"
      type = "CAA"
      data = {
        flags = 0
        tag   = "issue"
        value = "letsencrypt.org"
      }
    }
  }
}
```

Configure the Cloudflare provider in the calling root module. The examples use `CLOUDFLARE_API_TOKEN` through the provider's normal environment authentication.
Keep provider credentials out of module inputs.

See [basic](examples/basic) and [full](examples/full) examples.
Run examples from this checkout before publication.

## Zone selection

With `create_zone = false` (the default), set exactly one selector when `create = true`:

| Selector | Behavior |
| --- | --- |
| `zone_id` | Uses the ID directly, with no zone data-source request. The ID may be unknown until apply. |
| `zone_name` | Looks up the domain; optionally constrain it with `account_id`. |
| `zone_filter` | Passes the complete upstream filter, including nested account filters and operators. It must select exactly one zone. |

`account_id` is only valid with `zone_name`; use `zone_filter.account` for advanced lookups.
For example, replace `zone_name` and `account_id` with:

```hcl
zone_filter = {
  name    = "example.com"
  account = { id = "your-account-id" }
  match   = "all"
  status  = "active"
  type    = ["full"]
}
```

Selector presence must be known at plan time. In direct-ID mode, leave `zone_name` and `zone_filter` unset even if the ID comes from another resource.

In lookup mode, relative names are joined to the returned canonical zone name. In direct-ID mode, relative names and `@` are sent to Cloudflare for resolution.
The `zone` and `zone_name` outputs are null in direct-ID mode. Use `full_name` if you need to provide an exact FQDN without a lookup.

## Zone management

Set `create_zone = true` to create a zone or manage one imported into this module:

```hcl
module "dns" {
  source  = "terraform-cloudflare-modules/dns/cloudflare"
  version = "~> 2.0"

  create_zone = true
  zone_name   = "example.com"
  account_id  = var.cloudflare_account_id

  zone = {
    type   = "full"
    paused = false
  }

  records = {
    www = { name = "www", type = "A", content = "192.0.2.10" }
  }
}
```

Managed zones require `zone_name` and `account_id`; leave `zone_id` and `zone_filter` unset.
This mode bypasses lookup. The zone name is trimmed, lowercased and stripped of its terminal dot,
and relative record names use that normalized domain before Cloudflare assigns the zone ID.
The account ID and generated zone ID may be unknown at plan time; `create` and `create_zone` must be known.

The `zone` object exposes `type`, `paused` and `vanity_name_servers`, alongside the resource's
`name` and `account.id` supplied by the top-level inputs. Null optional properties defer to the provider.
`paused = false` and `vanity_name_servers = []` remain explicit values. Zone properties require managed-zone mode.
Zone types and account entitlements are validated by Cloudflare/the provider; selecting a secondary or internal
zone type does not configure transfers, DNS views or Gateway policies.

`zone` exposes the complete resource in managed mode and the complete data-source result in lookup mode;
these upstream objects have different shapes. `name_servers` exposes the Cloudflare-assigned nameservers
in either mode. Both are null in direct-ID mode. Other delegation information remains in the zone object,
including `original_name_servers` and `verification_key`. Update registrar or parent-zone delegation separately.

Zone ownership is opt-in. Import existing zones before the first apply, following
[the adoption guide](docs/UPGRADING.md#adopt-an-existing-zone). Changing `create_zone` from true to false
plans to destroy the managed zone; it does not relinquish ownership safely. Deleting a zone also removes
its DNS configuration, including records outside this module. Keep managed-zone configuration in place
until you have explicitly migrated its state ownership.

## DNSSEC

DNSSEC ownership is independent of zone ownership. Use it with a direct zone ID,
a zone lookup, or `create_zone = true`:

```hcl
module "dns" {
  source  = "terraform-cloudflare-modules/dns/cloudflare"
  version = "~> 2.0"

  zone_name     = "example.com"
  create_dnssec = true

  dnssec = {
    status              = "active"
    dnssec_multi_signer = false
    dnssec_presigned    = false
    dnssec_use_nsec3    = false
  }
}

output "ds_record" {
  value = module.dns.dnssec_ds
}
```

`create_dnssec` defaults to false and must be known at plan time. It controls Terraform
ownership; `dnssec.status` controls signing. Set status to `active` to enable DNSSEC,
or `disabled` to request disabling it while retaining the managed resource.
Status is trimmed and lowercased. Unset properties stay null and defer to the provider;
`create_dnssec = true` alone does not explicitly request active signing. False flags remain false.
DNSSEC properties require `create_dnssec = true` unless the whole module is disabled.

The typed object exposes every optional [DNSSEC resource setting][dnssec_resource]:
`status`, `dnssec_multi_signer`, `dnssec_presigned`, and `dnssec_use_nsec3`.
The zone ID comes from the module's zone selection and may be unknown until apply.
`dnssec` returns the complete resource, including its DS, digest, public key, and signing metadata;
`dnssec_ds` returns the full DS record. Both outputs are null when DNSSEC is unmanaged or `create = false`.

Publish the DS through the registrar or parent zone to complete the chain of trust.
Putting a DS for this zone in its own `records` map does not establish that parent delegation.
Cloudflare can report [pending states][dnssec_states] while delegation changes propagate;
those are observed states, not accepted values for the desired `dnssec.status` input.

Records wait for managed DNSSEC configuration, allowing external DNSKEY records after
multi-signer mode is enabled. The toggle alone does not complete a [multi-signer setup][dnssec_multisigner]:
coordinate keys, delegation, and external providers, and configure multi-provider DNS where required.
Pre-signed mode similarly requires an appropriate [secondary DNS setup][dnssec_secondary].

Import existing DNSSEC configuration before adopting it, following the
[DNSSEC adoption guide](docs/UPGRADING.md#adopt-existing-dnssec).
Changing `create_dnssec` to false, disabling the module, or removing it invokes DNSSEC deletion.
Coordinate parent DS removal and propagation before deleting signing configuration.
To stop managing DNSSEC while keeping it enabled, transfer or remove its state ownership without destroying it.

[dnssec_resource]: https://developers.cloudflare.com/api/terraform/resources/dns/subresources/dnssec/
[dnssec_states]: https://developers.cloudflare.com/dns/dnssec/dnssec-states/
[dnssec_multisigner]: https://developers.cloudflare.com/dns/dnssec/multi-signer-dnssec/setup/
[dnssec_secondary]: https://developers.cloudflare.com/dns/zone-setups/zone-transfers/cloudflare-as-secondary/dnssec-for-secondary/

## Zone DNS settings

Manage [zone-wide DNS behavior][dns_settings_resource] independently of zone and DNSSEC ownership:

```hcl
create_dns_settings = true
dns_settings = {
  flatten_all_cnames  = false
  multi_provider      = true
  ns_ttl              = 86400
  secondary_overrides = false
  zone_mode           = "standard"
  nameservers         = { type = "cloudflare.standard" }
  soa = {
    min_ttl = 1800
    rname   = "admin.example.com"
    ttl     = 3600
  }
}
```

`create_dns_settings` defaults to false and must be known at plan time. Settings may
contain unknown values, and the selected zone ID may come from another resource.
The `dns_settings` output returns the complete resource, or null when unmanaged or `create = false`.
Settings require explicit ownership even when you already manage the zone or DNSSEC.

| Property | Purpose |
| --- | --- |
| `flatten_all_cnames` | Apply CNAME flattening throughout the zone. Apex flattening is handled by Cloudflare regardless of this flag. |
| `multi_provider` | Configure Cloudflare's multi-provider DNS behavior; useful alongside multi-signer DNSSEC. |
| `ns_ttl` | TTL of the zone's NS records. |
| `secondary_overrides` | Permit override behavior for secondary zones. |
| `zone_mode` | `standard`, `cdn_only`, or `dns_only`; trimmed and lowercased. |
| `internal_dns.reference_zone_id` | Reference zone for internal DNS fallback. |
| `nameservers` | Required `type`, optional `ns_set` and `nameserver_set_id`; only `type` is trimmed and lowercased. |
| `soa` | `expire`, `min_ttl`, `mname`, `refresh`, `retry`, `rname`, and `ttl`. SOA names are passed through unchanged. |
| `foundation_dns` | Deprecated upstream compatibility field; prefer `nameservers.type` for Advanced Nameservers. |

Null values defer to the provider. Explicit false, zero, and optional empty objects are
forwarded, subject to upstream validation. Partial nested objects retain unset fields as null;
they are not filled with module-defined defaults. Cloudflare validates plan entitlements,
nameserver configurations, and setting combinations. Custom nameserver sets must already exist.

These settings affect the entire zone, including records managed elsewhere. They are distinct
from `defaults`, which supplies per-record inputs only to this module's records.
Managed settings are applied before records so new records use the intended zone behavior.
DNSSEC remains independently configured; setting `multi_provider = true` alone does not enable signing.

Read the [settings adoption guide](docs/UPGRADING.md#adopt-zone-dns-settings) before taking ownership.
Null inputs and removing ownership are not a promise to restore previous settings.
If you need different remote values, set and apply those values explicitly before relinquishing ownership.

[dns_settings_resource]: https://developers.cloudflare.com/api/terraform/resources/dns/subresources/settings/subresources/zone/

## Records and defaults

Map keys identify records or groups of records in Terraform. Keep them stable when names or content change; use a `moved` block when changing a key.
Different keys may share a DNS name and type. Scalar `content` and structured `data` create one resource; list `content` creates one resource per value.

| Input | Convention |
| --- | --- |
| `name` | Relative DNS name. Defaults to the map key. Empty string or `@` selects the apex. |
| `full_name` | Explicit DNS name; mutually exclusive with `name`. No zone suffix is added. |
| `type` | Required. Whitespace is trimmed and the type is uppercased. Upstream validates supported types. |
| `content` / `data` | Exactly one must be provided. Content accepts a string or a list of strings; data accepts one structured object. |
| `priority` | Shared priority for the entry. An inline MX list priority overrides it for that value. |
| `ttl` | Defaults to 1 (automatic). Proxied records require 1; fixed TTLs must be integral, 30–86400. Values below 60 require Enterprise. |
| `settings` | All upstream record settings: `flatten_cname`, `ipv4_only`, and `ipv6_only`. |
| `tags` | A set of Cloudflare tag strings such as `owner:dns-team`. |
| `private_routing`, `include_shadow_metadata` | Passed through when set. Availability and behavior depend on Cloudflare. |

Names are lowercased, surrounding whitespace is removed, and one terminal DNS dot is removed. Payloads, targets inside `data`, comments, tags, and advanced filter strings retain their supplied contents.
Use Punycode for internationalized DNS names.

Per-record non-null values override `defaults`. Null means inherit; `comment = ""`, `tags = []`, and boolean `false` are explicit overrides.
A per-record `settings` object replaces the entire default object. `settings = {}` stops inheriting defaults; use explicit `false` values to disable upstream settings.
If neither scope supplies an optional value, it stays null and the provider controls its behavior.

All 36 upstream `data` fields are exposed. The input type accepts `flags` as a string or a number convertible to a string.
The module converts CAA/DNSKEY flags back to numbers per record, retaining textual NAPTR flags.
This avoids Terraform's homogeneous-map conversion changing the dynamic flag type when record types are mixed.

Module validation checks selection, naming, content/data exclusivity, TTLs and numeric flags. Cloudflare/provider validation remains authoritative for record-type-specific combinations and account features.

`create = false` suppresses zones, lookups and records. Setting it to false plans to destroy all resources owned by this module, including a managed zone.
Use it as a creation switch, not as a way to pause management.

## Multiple content values

The basic example groups several A addresses under one name; the full example groups Google Workspace MX values.
Use your mail provider's actual required hosts and priorities; the examples illustrate the input format.

For MX lists, use `"<priority> <hostname>"`. Spaces and tabs between those two fields are accepted,
with surrounding whitespace ignored. Priorities must be integers from 0 to 65535.
A bare hostname instead inherits the entry's `priority`; an inline priority takes precedence.
Every value must have a priority by one of these two mechanisms. For example:

```hcl
records = {
  mail = {
    name     = "@"
    type     = "MX"
    priority = 20
    content  = ["mx1.example.net", "10 mx2.example.net"]
  }
}
```

This creates two MX records with priorities 20 and 10. All values inherit the entry's TTL, proxy setting,
comments, tags and other properties. Use separately keyed records when those properties need to differ per value.
Only MX **list** values use priority parsing: scalar content and every non-MX payload remain unchanged,
including TXT whitespace. Structured `data` remains a single object.

Scalar entries retain their existing resource keys. List entries always use zero-based keys such as
`mail[0]` and `mail[1]`, including one-element lists. Appending a value preserves existing identities;
inserting, removing or reordering values changes which payload occupies each subsequent index.
An empty list creates no records and removes any previously managed entries in that group.
Generated keys must not collide with caller-supplied keys; the module rejects such collisions.

Keys and list lengths must be known at plan time, but individual content values and MX priorities may be unknown.
Changing an existing scalar to a list changes its resource address: follow the
[state-move example](docs/UPGRADING.md#convert-scalar-content-to-a-list) to retain its record identity.

The full record field types remain enforced after content normalization. Terraform has no string-or-list union
inside a map of typed objects, so the public `records` input uses `any` with validation and delegates normalized
objects to an internal [typed input module](modules/record-inputs/README.md). This module creates no resources.

## Outputs and compatibility

`records` exposes the entire expanded resource map: `module.dns.records["www"].id`, `.name`, `.proxied`, `.proxiable`, and other upstream fields.
`proxied` means enabled; `proxiable` means capable. Metadata remains the upstream JSON string `meta`. List entries are available as `module.dns.records["mail[0]"]`, `module.dns.records["mail[1]"]`, and so on.

The implementation requires Terraform >= 1.8 and Cloudflare >= 5.28.0, < 6.0.0.
The test matrix covers Terraform 1.8.5/1.16.6 and OpenTofu 1.13.1.
Tests mock Cloudflare; live API behavior and the v1 state migration need separate verification before release.
See [UPGRADING.md](docs/UPGRADING.md) for migration and Formr coverage checks,
[SCHEMA.md](docs/SCHEMA.md) for report status, and [TODO.md](docs/TODO.md) for future DNS capabilities.

## Optional name shorthand

All examples above set `name` explicitly. As an optional shorthand, omitting both `name` and `full_name`
uses the map key as the relative DNS name. This creates `www.example.com` in the `example.com` zone;
entry order has no effect. For lists, the group key supplies the name, without the generated index suffix.

```hcl
records = {
  www = {
    type    = "A"
    content = "192.0.2.10"
  }
}
```

## Generated interface

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | >= 5.28.0, < 6.0.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_record_inputs"></a> [record\_inputs](#module\_record\_inputs) | ./modules/record-inputs | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Account ID required for a managed zone, or an optional account filter for a zone\_name lookup. For advanced lookups use zone\_filter.account instead. | `string` | `null` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to manage DNS resources and perform zone lookups. Disabling an existing module plans destruction of its managed records, DNSSEC configuration, and any managed zone. | `bool` | `true` | no |
| <a name="input_create_dns_settings"></a> [create\_dns\_settings](#input\_create\_dns\_settings) | Whether to manage zone-wide DNS settings, independently of zone and DNSSEC ownership. Settings affect all records in the zone, including records outside this module. | `bool` | `false` | no |
| <a name="input_create_dnssec"></a> [create\_dnssec](#input\_create\_dnssec) | Whether to manage DNSSEC for the selected zone, independently of zone ownership. Set dnssec.status to active to enable signing. Removing managed DNSSEC invokes provider deletion; coordinate parent DS removal first. | `bool` | `false` | no |
| <a name="input_create_zone"></a> [create\_zone](#input\_create\_zone) | Whether to manage the zone itself. Requires zone\_name and account\_id; excludes zone\_id and zone\_filter. Import an existing zone before applying to adopt it. | `bool` | `false` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Record defaults. Non-null per-record values override these; empty comments, empty tags, and empty settings explicitly override defaults. Settings are replaced as a whole. | ```object({ comment = optional(string) include_shadow_metadata = optional(bool) private_routing = optional(bool) proxied = optional(bool, false) tags = optional(set(string)) ttl = optional(number, 1) settings = optional(object({ flatten_cname = optional(bool) ipv4_only = optional(bool) ipv6_only = optional(bool) })) })``` | `{}` | no |
| <a name="input_dns_settings"></a> [dns\_settings](#input\_dns\_settings) | Zone-wide DNS settings, requiring create\_dns\_settings = true. Null properties defer to the provider; false, zero, and empty nested objects are passed through. Zone mode and nameserver type are trimmed/lowercased. foundation\_dns is deprecated upstream; prefer nameservers.type. | ```object({ flatten_all_cnames = optional(bool) foundation_dns = optional(bool) multi_provider = optional(bool) ns_ttl = optional(number) secondary_overrides = optional(bool) zone_mode = optional(string) internal_dns = optional(object({ reference_zone_id = optional(string) })) nameservers = optional(object({ type = string ns_set = optional(number) nameserver_set_id = optional(string) })) soa = optional(object({ expire = optional(number) min_ttl = optional(number) mname = optional(string) refresh = optional(number) retry = optional(number) rname = optional(string) ttl = optional(number) })) })``` | `{}` | no |
| <a name="input_dnssec"></a> [dnssec](#input\_dnssec) | DNSSEC properties, requiring create\_dnssec = true. Status accepts active or disabled and is trimmed/lowercased. Null properties defer to the provider; explicit false values are preserved. Registrar or parent-zone DS publication is managed separately. | ```object({ status = optional(string) dnssec_multi_signer = optional(bool) dnssec_presigned = optional(bool) dnssec_use_nsec3 = optional(bool) })``` | `{}` | no |
| <a name="input_records"></a> [records](#input\_records) | DNS records keyed by stable identifiers. Set name explicitly, or omit it to use the key. Content accepts a scalar or a list; MX list entries support a priority followed by a hostname. Supply exactly one of content or data. Full typed fields are defined in modules/record-inputs/variables.tf. | `any` | `{}` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | Optional managed-zone properties. Only supported with create\_zone = true. Null values defer to the provider; an empty vanity\_name\_servers list explicitly clears custom nameservers. | ```object({ paused = optional(bool) type = optional(string) vanity_name_servers = optional(list(string)) })``` | `{}` | no |
| <a name="input_zone_filter"></a> [zone\_filter](#input\_zone\_filter) | Complete cloudflare\_zone lookup filter. Must match exactly one zone. Mutually exclusive with zone\_id, zone\_name, and account\_id. Filter strings, including operators, are passed through unchanged. | ```object({ account = optional(object({ id = optional(string) name = optional(string) })) direction = optional(string) match = optional(string) name = optional(string) order = optional(string) status = optional(string) type = optional(list(string)) })``` | `null` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Existing zone ID. Bypasses zone lookup; may be unknown until apply. Mutually exclusive with zone\_name, zone\_filter, and create\_zone. | `string` | `null` | no |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | Zone name to create/manage when create\_zone is true, or look up otherwise. Mutually exclusive with zone\_id and zone\_filter. Use Punycode for internationalized names. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dns_settings"></a> [dns\_settings](#output\_dns\_settings) | Complete managed zone DNS settings, retaining all upstream fields. Null when DNS settings are unmanaged or the module is disabled. |
| <a name="output_dnssec"></a> [dnssec](#output\_dnssec) | Complete managed DNSSEC resource, including status, signing settings, DS, digest, key metadata, and public key. Null when DNSSEC is unmanaged or the module is disabled. |
| <a name="output_dnssec_ds"></a> [dnssec\_ds](#output\_dnssec\_ds) | Full DS record for publication through the registrar or parent zone. Null when DNSSEC is unmanaged or the module is disabled. Availability otherwise follows the provider. |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | Cloudflare-assigned nameservers for the managed or looked-up zone. Null in direct zone\_id mode or when disabled. Registrar delegation is managed separately. |
| <a name="output_records"></a> [records](#output\_records) | Complete DNS resources keyed by the input key for scalar/structured entries, or key[index] for list content. Includes IDs, names, content, proxied (enabled), proxiable (capable), metadata, and timestamps. Empty when disabled. |
| <a name="output_zone"></a> [zone](#output\_zone) | Complete managed zone or zone lookup result, preserving its upstream schema and computed properties. Null in direct zone\_id mode or when disabled. |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Target zone ID, or null when disabled. |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | Normalized name of the managed or looked-up zone. Null in direct zone\_id mode or when disabled. |
<!-- END_TF_DOCS -->

### 🔃 Contributing

Refer to our [documentation for contributors][contributing] for contributing guidelines, commit message
formats and versioning tips.

### 📥 Maintainers

This project is owned and maintained by [Terraform Cloudflare Modules][org]. Refer to the [`AUTHORS`][authors] or [`CODEOWNERS`][owners]
for more information. You may also use the linked contact details to reach out directly.

### ©️ Copyright

- _Assets provided by:_ **[HashiCorp][hashicorp]**
- _Sources provided by:_ **[Terraform Cloudflare Modules][org]** under the **[MIT License][license]**

<!-- INTERNAL REFERENCES -->

<!-- Project references -->

<!-- File references -->

[license]: LICENSE
[contributing]: docs/CONTRIBUTING.md
[authors]: .github/AUTHORS
[owners]: .github/CODEOWNERS

<!-- General links -->

[org]: https://github.com/terraform-cloudflare-modules
[terraform]: https://terraform.io
[opentofu]: https://opentofu.org/
[hashicorp]: https://www.hashicorp.com/
[cloudflare]: https://cloudflare.com
[github_releases]: https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/releases
[github_commits]: https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commits/main/

<!-- Third-party -->

[module]: https://registry.terraform.io/modules/terraform-cloudflare-modules/dns/cloudflare/latest
[renovate]: https://renovatebot.com/
[pre-commit]: https://pre-commit.com/
