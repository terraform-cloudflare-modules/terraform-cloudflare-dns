## Unreleased

### Breaking changes

- Rename the product to Cloudflare DNS and its Registry source to `terraform-cloudflare-modules/dns/cloudflare`.
- Replace single-record inputs with a typed records map and complete Cloudflare 5.28 resource coverage.
- Require Terraform >= 1.8 and Cloudflare >= 5.28.0, < 6.0.0; replace scalar outputs with record and zone objects.
- Document explicit v1-to-v2 state moves in [the migration guide](docs/UPGRADING.md).

### Improvements

- Add direct zone IDs, account-aware lookup, full zone filters, record defaults and DNS-name normalization.
- Add native mock tests, basic/full examples, and upgrade guidance including Formr coverage maintenance.
- Align repository layout, development tooling, and test-triggered releases with the standardized Hetzner modules.

## 1.0.0 (2024-11-19)

### Bug Fixes

* correct invalid references in Terraform configuration ([1691a49](https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns/commit/1691a4985c7fbd91c7b4054ff99d53c888774308))
