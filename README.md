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

This repository is the successor to `terraform-cloudflare-dns-record`. The v2 API manages individual records in one existing zone per module invocation.
Zone creation, DNSSEC, and further DNS capabilities are planned as optional additions within this module's scope.

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
      type    = "A"
      content = "192.0.2.10"
      proxied = true
    }
    mail_primary = {
      name     = "@"
      type     = "MX"
      content  = "mail.example.net"
      priority = 10
      ttl      = 3600
    }
    certificate_authority = {
      full_name = "example.com"
      type      = "CAA"
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

Set exactly one selector when `create = true`:

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

## Records and defaults

Map keys are Terraform resource identities. Keep them stable when names or content change; use a `moved` block when changing a key.
Different keys may share a DNS name and type. Each entry manages one Cloudflare record ID, rather than a Route53-style record set.

| Input | Convention |
| --- | --- |
| `name` | Relative DNS name. Defaults to the map key. Empty string or `@` selects the apex. |
| `full_name` | Explicit DNS name; mutually exclusive with `name`. No zone suffix is added. |
| `type` | Required. Whitespace is trimmed and the type is uppercased. Upstream validates supported types. |
| `content` / `data` | Exactly one must be provided. Content strings are passed through unchanged. |
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

`create = false` suppresses lookups and records. If the module already manages records, setting it to false plans to destroy those records.
Use it as a creation switch, not as a way to pause management.

## Outputs and compatibility

`records` exposes the entire resource map: `module.dns.records["www"].id`, `.name`, `.proxied`, `.proxiable`, and other upstream fields.
`proxied` means enabled; `proxiable` means capable. Metadata remains the upstream JSON string `meta`.

The implementation requires Terraform >= 1.8 and Cloudflare >= 5.28.0, < 6.0.0.
The test matrix covers Terraform 1.8.5/1.16.6 and OpenTofu 1.13.1.
Tests mock Cloudflare; live API behavior and the v1 state migration need separate verification before release.
See [UPGRADING.md](docs/UPGRADING.md) for migration and Formr coverage checks,
[SCHEMA.md](docs/SCHEMA.md) for report status, and [TODO.md](docs/TODO.md) for future DNS capabilities.

## Generated interface

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
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Account ID for a zone\_name lookup. For advanced lookups use zone\_filter.account instead. | `string` | `null` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to manage DNS records and perform zone lookups. Disabling an existing module plans destruction of its managed records. | `bool` | `true` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Record defaults. Non-null per-record values override these; empty comments, empty tags, and empty settings explicitly override defaults. Settings are replaced as a whole. | ```object({ comment = optional(string) include_shadow_metadata = optional(bool) private_routing = optional(bool) proxied = optional(bool, false) tags = optional(set(string)) ttl = optional(number, 1) settings = optional(object({ flatten_cname = optional(bool) ipv4_only = optional(bool) ipv6_only = optional(bool) })) })``` | `{}` | no |
| <a name="input_records"></a> [records](#input\_records) | DNS records keyed by stable caller-chosen identifiers. Use relative name (defaults to key), @ or empty name for apex, or full\_name for an FQDN. Supply exactly one of content or data. Numeric CAA/DNSKEY flags are accepted and normalized to numbers; NAPTR flags remain strings. | ```map(object({ name = optional(string) full_name = optional(string) type = string content = optional(string) comment = optional(string) include_shadow_metadata = optional(bool) priority = optional(number) private_routing = optional(bool) proxied = optional(bool) tags = optional(set(string)) ttl = optional(number) settings = optional(object({ flatten_cname = optional(bool) ipv4_only = optional(bool) ipv6_only = optional(bool) })) data = optional(object({ algorithm = optional(number) altitude = optional(number) certificate = optional(string) digest = optional(string) digest_type = optional(number) fingerprint = optional(string) flags = optional(string) key_tag = optional(number) lat_degrees = optional(number) lat_direction = optional(string) lat_minutes = optional(number) lat_seconds = optional(number) long_degrees = optional(number) long_direction = optional(string) long_minutes = optional(number) long_seconds = optional(number) matching_type = optional(number) order = optional(number) port = optional(number) precision_horz = optional(number) precision_vert = optional(number) preference = optional(number) priority = optional(number) protocol = optional(number) public_key = optional(string) regex = optional(string) replacement = optional(string) selector = optional(number) service = optional(string) size = optional(number) tag = optional(string) target = optional(string) type = optional(number) usage = optional(number) value = optional(string) weight = optional(number) })) }))``` | `{}` | no |
| <a name="input_zone_filter"></a> [zone\_filter](#input\_zone\_filter) | Complete cloudflare\_zone lookup filter. Must match exactly one zone. Mutually exclusive with zone\_id, zone\_name, and account\_id. Filter strings, including operators, are passed through unchanged. | ```object({ account = optional(object({ id = optional(string) name = optional(string) })) direction = optional(string) match = optional(string) name = optional(string) order = optional(string) status = optional(string) type = optional(list(string)) })``` | `null` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Existing zone ID. Bypasses zone lookup; may be unknown until apply. Mutually exclusive with zone\_name and zone\_filter. | `string` | `null` | no |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | Existing zone name to look up. Mutually exclusive with zone\_id and zone\_filter. Use account\_id to disambiguate accounts. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_records"></a> [records](#output\_records) | Complete DNS resources keyed by the input record keys. Includes IDs, names, content, proxied (enabled), proxiable (capable), metadata, and timestamps. Empty when disabled. |
| <a name="output_zone"></a> [zone](#output\_zone) | Complete zone lookup result, including computed properties. Null in direct zone\_id mode or when disabled. |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Target zone ID, or null when disabled. |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | Canonical name of the looked-up zone. Null in direct zone\_id mode or when disabled. |
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
