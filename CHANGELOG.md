## [2.1.0](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/compare/v2.0.0...v2.1.0) (2026-10-15)

### Features

* add account DNS settings submodule ([ffb8777](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/ffb8777c82e0284b31c1123f3b85d56560d0c31e))
* add DNS Firewall submodule ([28c3eb9](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/28c3eb9e68c034d937109fdc405c03cedadcdebb))
* add internal DNS views submodule ([16631e2](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/16631e2533f0a9237bcc51b2a680b8f39aea46ea))
* add load balancing and geographic steering ([9871f22](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/9871f2249b81d459abd389c0e8f53af04803cff2))
* add load balancing monitor groups submodule ([1f3bc95](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/1f3bc9580726b5bec961582c10935b74ac8397ac))
* add optional DNSSEC management ([9fa73d2](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/9fa73d2984bcab7e668476fd17b8ad6e28ea81d9))
* add optional zone DNS settings management ([692353d](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/692353daf20dc57f6764e1bdfb1485fbe415e8ec))
* add reusable DNS zone transfer management ([1aaa44e](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/1aaa44eb88b2be7931165ee4aded09d7c75820e2))

### Bug Fixes

* use valid provider inputs in DNS tests and examples ([6f1813f](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/6f1813f7b00c3698108d96c4aa5f3c9018df50bc))

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

- Add a standalone account-settings submodule for DNS-only enforcement and new-zone defaults.
- Add a standalone monitor-groups submodule with complete member controls and reusable group outputs.
- Add a standalone dns-firewall submodule with complete cluster settings and assigned-address outputs.
- Add a standalone internal-views submodule for account-level internal zone associations, without Gateway policies.
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
