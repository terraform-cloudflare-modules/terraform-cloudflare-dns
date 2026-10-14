# Upgrade from dns-record v1 to dns v2

The repository is now `terraform-cloudflare-dns`; the intended Registry address is `terraform-cloudflare-modules/dns/cloudflare`.
v2 changes both the public API and the Cloudflare provider major version. The old `v1.0.0` tag remains unchanged.

The source-address rename itself does not change resource addresses.
The change from `cloudflare_record.current` to `cloudflare_dns_record.this["key"]` does require state migration.

The migration below still needs verification against live Cloudflare state. Native mocked tests do not exercise provider state conversion.

## 1. Prepare the existing configuration

Use Terraform >= 1.8 for provider-supported moves between resource types.
The test matrix covers Terraform 1.8.5/1.16.6 and OpenTofu 1.13.1. Verify migration with the engine you use;
do not infer OpenTofu migration support from Terraform's version numbers.

Back up the consumer's state and retain the current configuration and dependency lockfile.
Serialize migration with other state operations. Run the upgrade in the consuming root module, not this reusable module repository.

If the old Registry listing is unavailable, the unchanged v1 module remains available through Git:

```hcl
module "dns" {
  source = "git::https://github.com/terraform-cloudflare-modules/terraform-cloudflare-dns.git?ref=v1.0.0"

  domain           = "example.com"
  dns_record_name  = "www"
  dns_record_type  = "A"
  dns_record_value = "192.0.2.10"
  use_cf_proxy     = false
}
```

Keep the existing module label and any module `for_each` keys.

## 2. Apply the transitional v4 provider upgrades

Keep the v1 module configuration and explicitly select Cloudflare 4.52.5 in the root module:

```hcl
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "= 4.52.5"
    }
  }
}
```

Run `terraform init -upgrade`, inspect the plan, and apply the transitional state updates.
Then repeat with 4.52.9, the latest v4 release reviewed for this migration.

This sequence accommodates the explicit 4.52.5 step in Cloudflare's
[migration guide](https://raw.githubusercontent.com/cloudflare/terraform-provider-cloudflare/v5.27.0/docs/guides/version-5-migration.md)
and the latest-v4 recommendation in its
[upgrade guide](https://raw.githubusercontent.com/cloudflare/terraform-provider-cloudflare/v5.27.0/docs/guides/version-5-upgrade.md).
Do not downgrade a workspace already beyond a particular step.

## 3. Change the module API and provider together

After v2 is published:

```hcl
module "dns" {
  source  = "terraform-cloudflare-modules/dns/cloudflare"
  version = "~> 2.0"

  zone_name = "example.com"

  records = {
    www = {
      name    = "www"
      type    = "A"
      content = "192.0.2.10"
      proxied = false
      ttl     = 1
    }
  }
}

moved {
  from = module.dns.cloudflare_record.current
  to   = module.dns.cloudflare_dns_record.this["www"]
}
```

Select Cloudflare `= 5.28.0` in the root for the initial migration. Reinitialize to install the new module and provider.
Keep the reviewed root lockfile. The module's broader constraint permits later v5 upgrades once tested.

Use the consumer's real module path and chosen record key in each move.
For example, a former `module.records["web"]` instance needs that full indexed path in `from`.
If several old module invocations are consolidated, write a move for each old record to its new map entry.
There is no universal move inside this module because record keys are caller-selected.

A root can select only one version of a given provider. Other Cloudflare modules/resources in that root must also be compatible with v5.
Provider aliases do not allow retaining a separate v4 version.

## 4. Review and apply

The plan must not destroy or recreate existing DNS records.
Cloudflare's DNS resource supports provider-assisted state conversion during the cross-type move; the move preserves association with the existing remote record ID.

Confirm names, content, proxy status and TTL, then apply the reviewed plan.
Run a second plan to check for drift. Retain migration blocks so older workspaces can still follow the upgrade path.
If migration fails, keep the state backup and lockfile; do not apply a replacement plan or blindly downgrade a state already converted to v5.

## Input and output mapping

| v1 | v2 |
| --- | --- |
| `domain` | `zone_name`, or replace lookup with `zone_id` |
| `dns_record_name` | `records[key].name`; use `full_name` for an existing FQDN |
| `dns_record_type` | `records[key].type` (now required) |
| `dns_record_value` | `records[key].content` |
| `use_cf_proxy` | `records[key].proxied` |
| `comment` | `records[key].comment`, or `defaults.comment` |
| `hostname` output | `records[key].name` when using lookup mode or an explicit FQDN |
| `proxiable` output | `records[key].proxied` to preserve its old behavior |
| Actual proxy capability | `records[key].proxiable` |

The old `proxiable` output was misnamed: it returned whether proxying was enabled.

## Provider properties outside the old wrapper

Callers migrating direct resources should also review these changes:

- `data` is an object assignment, not a block. Former `data.name` and `data.proto` require reconstructing the DNS owner name, particularly for SRV.
- Top-level `value`, `allow_overwrite`, and per-record `timeouts` are absent from the v5 resource.
- `data.content` is absent; use a supported structured representation or `content`, with only one selected.
- `SPF` is not a supported v5 record type. Review any legacy SPF-type record explicitly; its type change can require replacement.
- `metadata` becomes the JSON-string `meta`; `hostname` is no longer a resource attribute.

For adoption of records not already in this Terraform state, import their actual IDs:

```shell
terraform import 'module.dns.cloudflare_dns_record.this["www"]' '<zone_id>/<record_id>'
```

Do not create a second managed resource for a record already tracked in state.

## Checks

Run `terraform init -backend=false`, `terraform validate`, and `terraform test`
(or the equivalent `tofu` commands). Initialize and validate both examples and
the unknown-value test fixture separately. Tests mock Cloudflare resources; no
cloud credentials are needed and no real DNS records are created.

Before a production release, use a dedicated test zone to exercise creation,
a second no-change plan, content updates, comment/tag clearing, and teardown.
Cover A, AAAA, TXT, CAA, SRV and NAPTR records, including mixed numeric/textual flags.
Verify the v1 migration above preserves existing record IDs without replacement.
Mocks do not verify live API behavior or account-specific feature availability.

## Provider coverage maintenance

Use Formr for the [schema report](SCHEMA.md). With the module initialized,
run `formr schema . -o docs/SCHEMA.md` to generate it and
`formr check . --report docs/SCHEMA.md` to check for drift. Use the same engine
and provider selections recorded in the report's provenance.

The current default policy checks inventory completeness and unresolved
analysis. Strict interface coverage and exception annotations are not yet
implemented, so a passing default check does not approve omitted fields.
Review every added, removed or changed provider property when updating versions.
Every configurable DNS record and zone-filter field must remain reachable through
the typed inputs; computed fields remain available through the whole-object outputs.
Provider authentication and other provider configuration belong to the caller.

The `data.flags` input deliberately accepts a string, with CAA/DNSKEY flags
converted to numbers at the resource boundary and NAPTR flags kept as strings.
Review this transformation and all name/default handling when assessing coverage.

Regenerate README inputs/outputs with `terraform-docs -c .github/linters/.terraform-docs.yml .`.
Resource IDs remain provider-managed. Deprecated fields are not reintroduced as new inputs.

## First v2 publication

Keep the original `v1.0.0` tag. Use a conventional breaking-change commit for the
v2 API so Semantic Release selects the next major version. Follow the shared
[CI and release process](CONTRIBUTING.md#continuous-integration-and-releases).
Complete the provider checks and disposable-zone migration verification before
merging the release change, and update the README release-status paragraph.

Publish `terraform-cloudflare-dns` through the Terraform Registry UI as
`terraform-cloudflare-modules/dns/cloudflare`, then verify installation in a fresh
consumer root. Registry publication is separate from creating a GitHub release;
historical semantic-version tags may also be indexed.
