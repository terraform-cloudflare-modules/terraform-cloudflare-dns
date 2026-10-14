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

An existing `terraform providers schema -json` snapshot can be used without starting
the provider: add `--schema-file secrets/schema.json` to both Formr commands.
The current report was generated from such a snapshot, which does not record engine
or provider versions. Regenerate it with version provenance before publication.

The current default policy checks inventory completeness and unresolved
analysis. Strict interface coverage and exception annotations are not yet
implemented, so a passing default check does not approve omitted fields.
Review every added, removed or changed provider property when updating versions.
Every configurable resource and zone-filter field must remain reachable through
the typed inputs; computed fields remain available through the whole-object outputs.
Provider authentication and other provider configuration belong to the caller.

The data source's `zone_id` selector is deliberately omitted: direct IDs bypass
lookup, while `zone_name` and `zone_filter` select zones through its filter.
The current Formr analysis labels DNSSEC and DNS settings results as unused because
it does not trace their `one(...)` outputs. Those outputs return complete resource
objects; the tests check both their values and null behavior when unmanaged.

The `data.flags` input deliberately accepts a string, with CAA/DNSKEY flags
converted to numbers at the resource boundary and NAPTR flags kept as strings.
Review this transformation and all name/default handling when assessing coverage.

Regenerate README inputs/outputs with `terraform-docs -c .github/linters/.terraform-docs.yml .`.
Resource IDs remain provider-managed. Removed provider fields are not reintroduced as inputs;
still-configurable deprecated settings are identified with their preferred replacement.

## Release and Registry publication

Keep the original `v1.0.0` and released `v2.0.0` tags. New features on `main` can
postdate the latest release; use the corresponding release or an explicit revision
when adopting them. Follow the shared
[CI and release process](CONTRIBUTING.md#continuous-integration-and-releases).
Complete the provider checks and disposable-zone migration verification before
publishing further changes, and update the README release-status paragraph.

Publish `terraform-cloudflare-dns` through the Terraform Registry UI as
`terraform-cloudflare-modules/dns/cloudflare`, then verify installation in a fresh
consumer root. Registry publication is separate from creating a GitHub release;
historical semantic-version tags may also be indexed.

Standalone submodules share the repository's release tags. The
[zone-transfers](../modules/zone-transfers/README.md),
[account-settings](../modules/account-settings/README.md),
[monitor-groups](../modules/monitor-groups/README.md), and
[dns-firewall](../modules/dns-firewall/README.md) submodules were added after
v2.0.0. Each documents its ownership, state moves, and verification requirements.
Adding their calls does not change existing root-module resource addresses.
Each shared resource should have one owner; pass IDs between module instances.

## Adopt an existing zone

Zone management is optional and defaults off. Existing record-only consumers keep
all resource addresses and lookup behavior. For a zone already on Cloudflare,
set `create_zone = true`, `zone_name`, and `account_id`, and remove `zone_id` or
`zone_filter`. Match the current zone properties in `zone` before importing.

Import a zone that is not already owned by another Terraform resource using a
consumer-root import block:

```hcl
import {
  to = module.dns.cloudflare_zone.this[0]
  id = "023e105f4ecef8ad9ca31a8372d0c353"
}
```

Alternatively, after configuring the module, run:

```shell
terraform import 'module.dns.cloudflare_zone.this[0]' '<zone_id>'
```

If the zone is already managed at another address in the same state, move it
instead of importing it a second time:

```hcl
moved {
  from = cloudflare_zone.existing
  to   = module.dns.cloudflare_zone.this[0]
}
```

Remove the previous resource declaration when moving it. For ownership in a
separate state, coordinate the state handoff before adopting the zone here.
Review the plan: adoption must not create, replace or delete the existing zone.
Confirm the record names and IDs remain unchanged. Switching from direct-ID
mode to a managed zone qualifies relative names, so review any resulting name diff.

Setting `create_zone = false` after adoption schedules deletion of the zone;
setting `create = false` schedules deletion of both the zone and managed records.
Zone deletion affects the entire remote zone, including records not in this module.
To return to record-only management, explicitly move or remove the zone from
Terraform ownership without destroying it, then change the module configuration.
Registrar nameserver delegation and DNSSEC DS publication are separate operations.

The managed-zone resource exposes every configurable property in the reviewed
Cloudflare schema: `account.id`, `name`, `type`, `paused`, and `vanity_name_servers`.
All computed properties are retained in `zone`; `name_servers` is a convenience output.
The checked-in Formr report includes the managed-zone resource.

## Convert scalar content to a list

Existing scalar and structured entries retain their resource addresses. List entries
use `key[0]`, `key[1]`, etc. even when there is only one value. To convert an existing
scalar entry named `mail` to a list, retain its content as the first list value and
add a consumer-root move:

```hcl
moved {
  from = module.dns.cloudflare_dns_record.this["mail"]
  to   = module.dns.cloudflare_dns_record.this["mail[0]"]
}
```

For MX values, include each value's priority prefix, or keep a shared `priority`
with bare hostnames. Moving from several separately keyed entries to one list
requires one move for each previous address to its chosen new index. Review the
plan to confirm existing record IDs are retained and only additional values are
created. Moving back to scalar content needs the reverse address move.

List identity is positional: append to preserve existing addresses. Reordering or
inserting values updates the existing indexed resources. Use individually keyed
scalar entries when each server needs an identity independent of its list position.
The complete typed field schema is in `modules/record-inputs/variables.tf`; public
validation still applies before normalization. The Formr report traces resource
inputs through this normalization module.

## Adopt existing DNSSEC

DNSSEC defaults to unmanaged, preserving existing consumers' record and zone addresses.
Set `create_dnssec = true` and match the intended configuration in `dnssec`.
Use `status = "active"` for signing or `status = "disabled"` to manage a disabled configuration.
Review the current signing mode before choosing multi-signer, pre-signed, or NSEC3 settings.

For DNSSEC not already owned by another resource, import using the zone ID:

```hcl
import {
  to = module.dns.cloudflare_zone_dnssec.this[0]
  id = "023e105f4ecef8ad9ca31a8372d0c353"
}
```

If another resource in the same state already owns DNSSEC, move it instead:

```hcl
moved {
  from = cloudflare_zone_dnssec.existing
  to   = module.dns.cloudflare_zone_dnssec.this[0]
}
```

Remove the previous declaration when moving ownership. Coordinate handoff when moving
between separate states. Adoption should not replace DNSSEC, the zone, or existing records;
review status and signing-flag changes carefully. Compare `dnssec_ds` with the published parent DS.
The module manages Cloudflare's DNSSEC configuration; registrar and parent-zone changes are separate.

Setting `create_dnssec = false` removes the resource and invokes provider deletion.
Setting `dnssec.status = "disabled"` keeps the resource under management.
Coordinate parent DS removal and allow it to propagate before deleting signing configuration,
as described in [Cloudflare's DNSSEC states documentation](https://developers.cloudflare.com/dns/dnssec/dnssec-states/).
To relinquish ownership while retaining remote DNSSEC, move or remove the resource from state
without destroying it before removing the module's DNSSEC configuration.

The Formr report includes all configurable `cloudflare_zone_dnssec` fields.

## Adopt zone DNS settings

Zone DNS settings default to unmanaged. Set `create_dns_settings = true` and supply
the desired properties in `dns_settings`; the resource targets the module's selected zone.
Record keys and addresses remain unchanged, and managing these settings does not require
`create_zone` or `create_dnssec`.

Read the zone's current DNS settings before the first apply and review the configured
changes as zone-wide writes. These are not defaults limited to records in this module.
Only set properties you intend to manage, including nested SOA and nameserver properties.
Leave deprecated `foundation_dns` unset when using the replacement `nameservers.type` configuration.

If a resource in the same state already manages the settings, move it rather than
allowing two resources to write the same configuration:

```hcl
moved {
  from = cloudflare_zone_dns_settings.existing
  to   = module.dns.cloudflare_zone_dns_settings.this[0]
}
```

Remove the old declaration and review the plan for unintended settings changes.
For ownership in separate states, coordinate the state handoff before applying.
Import support depends on the provider version; do not reuse the zone or DNSSEC import
commands for this resource without checking its version-specific documentation.

Setting `create_dns_settings = false` removes the settings resource from the configuration.
Do not assume that removal or null inputs restore the values that preceded Terraform ownership.
Apply any desired replacement settings explicitly before relinquishing ownership.
The existing zone and record resources retain their own ownership controls.

The Formr report includes all configurable `cloudflare_zone_dns_settings` fields.
When supplying `dns_settings.nameservers`, its `type` is required by the provider schema.

## Adopt load balancing

All three resource maps default to empty. Existing zone and record addresses stay
unchanged. Adding an entry opts into ownership; deleting an entry or setting
`create = false` plans destruction. `enabled = false` on a balancer or pool retains
ownership and changes its enabled state instead. Monitors have no enabled flag.

Load balancers belong to the selected zone; pools and monitors belong to an account.
The module's `account_id` now also supplies pools and monitors, including with a
direct zone ID or a `zone_filter`. An entry's `account_id` takes precedence over
this default. The lookup's `zone_filter.account` remains independent.
Use account and zone IDs from the same intended deployment; the module does not
perform additional account lookups to establish ownership of external IDs.

For existing resources in the same state, retain their IDs with caller-root moves:

```hcl
moved {
  from = cloudflare_load_balancer_monitor.health
  to   = module.dns.cloudflare_load_balancer_monitor.this["https"]
}

moved {
  from = cloudflare_load_balancer_pool.europe
  to   = module.dns.cloudflare_load_balancer_pool.this["europe"]
}

moved {
  from = cloudflare_load_balancer.api
  to   = module.dns.cloudflare_load_balancer.this["api"]
}
```

Remove the old declarations, copy all intended settings into the corresponding
maps, and check that the plan preserves IDs. To retain an existing proxied balancer,
explicitly set `proxied = true`: the module's default is DNS-only. Use `full_name`
for an existing hostname to prevent adding a zone suffix twice. Pool and monitor
references can use managed map keys or external IDs, including nested rule overrides.

A DNS record and a load balancer are distinct resources. Do not move a
`cloudflare_dns_record` into a load balancer address. Cloudflare creates the load
balancer's DNS entry itself; review existing records at that hostname and their
fallback behavior before enabling or disabling balancing.

Pools and monitors can serve multiple zones. Keep one owner for each shared
resource and pass output IDs to other module instances. When ownership moves
between states, coordinate the handoff before applying. For unmanaged remote
resources, use the import procedure documented for the installed provider version
and the resource type; zone-scoped and account-scoped import identifiers differ.

The Formr report includes every configurable field of the balancer, pool, and
monitor resources in the supplied schema. Native mock tests cover references,
ordered steering rules, explicit empty values, and unknown resource IDs. Before
production adoption, verify health checks, DNS answers by region, failover, a
second no-change plan, and deletion behavior using a dedicated test hostname.
