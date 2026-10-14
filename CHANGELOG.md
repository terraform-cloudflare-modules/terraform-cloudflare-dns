## [2.0.0](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/compare/v1.0.0...v2.0.0) (2026-10-14)

### ⚠ BREAKING CHANGES

* replace the single-record API and require Cloudflare v5

Use terraform-cloudflare-modules/dns/cloudflare with Terraform >= 1.8 and
Cloudflare >= 5.28.0, < 6.0.0. Migrate inputs, outputs, and resource state
as described in docs/UPGRADING.md before upgrading existing consumers.

### Features

* add optional DNS zone management ([c30d6fc](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/c30d6fc2a81cefb4ab0ee1e73080cf9f0ddbc8d4))
* introduce the Cloudflare DNS records API ([aae9b98](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/aae9b98f7748d1423b1e3670d91adc0527be05ea))
* support multiple DNS record content values ([393044d](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/393044da47310c3ffd856cce7967b6c24654f3aa))

## Unreleased

### Breaking changes

- Rename the product to Cloudflare DNS and its Registry source to `terraform-cloudflare-modules/dns/cloudflare`.
- Replace single-record inputs with a typed records map and complete Cloudflare 5.28 resource coverage.
- Require Terraform >= 1.8 and Cloudflare >= 5.28.0, < 6.0.0; replace scalar outputs with record and zone objects.
- Document explicit v1-to-v2 state moves in [the migration guide](docs/UPGRADING.md).

### Improvements

- Add a standalone zone-transfers submodule with complete ACL, TSIG, peer, incoming, and outgoing resource support; run standalone submodule tests in CI.
- Add DNS-only load balancing, geographic and weighted steering, pools, and health monitors with complete upstream inputs and key-or-ID references.
- Add opt-in zone DNS settings with nested SOA, nameserver, and internal DNS properties and complete outputs.
- Add opt-in DNSSEC management, all signing settings, complete outputs, and parent DS/adoption guidance.
- Support list-valued content with per-value MX priorities while retaining scalar addresses.
- Use explicit DNS names in examples and document key-based naming separately.

- Add opt-in zone creation/adoption, all zone resource inputs, and complete zone/nameserver outputs.

- Add direct zone IDs, account-aware lookup, full zone filters, record defaults and DNS-name normalization.
- Add native mock tests, basic/full examples, and upgrade guidance including Formr coverage maintenance.
- Align repository layout, development tooling, and test-triggered releases with the standardized Hetzner modules.

## 1.0.0 (2024-11-19)

### Bug Fixes

* correct invalid references in Terraform configuration ([1691a49](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/1691a4985c7fbd91c7b4054ff99d53c888774308))
