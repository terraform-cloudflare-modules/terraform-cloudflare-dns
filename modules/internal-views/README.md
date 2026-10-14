# Cloudflare internal DNS views

Manage `cloudflare_account_dns_settings_internal_view` resources independently
of internal zones. Each `views` entry opts into owning one view. An empty map or
`create = false` creates no resources.

```hcl
module "internal_views" {
  source = "terraform-cloudflare-modules/dns/cloudflare//modules/internal-views"

  account_id = var.account_id
  views = {
    corporate = {
      name = "Corporate clients"
      zones = [
        module.internal_apps.zone_id,
        module.internal_services.zone_id,
      ]
    }
  }
}
```

## Zone membership

The resource requires an account ID, view name, and set of zone IDs. Names default
to map keys; explicit names are preserved. Individual `account_id` values override
the module default. The `zones` input represents the complete desired membership,
not incremental additions. Its set type removes duplicate IDs.

Cloudflare permits empty views and allows an internal zone to participate in
multiple views. Views can contain only internal zones; names of zones within a
view must be unique, and view names must be unique within an account. These
constraints are enforced by Cloudflare; the module does not perform extra zone
lookups. See [Cloudflare's DNS view documentation][views].

Create internal zones with the root DNS module using `zone = { type = "internal" }`,
then pass their output IDs into this submodule. The
[complete example](../../examples/modules/internal-views/main.tf) creates two internal
zones and shares one between two views. Unknown zone IDs do not affect view
resource addresses, which depend only on the map keys.

The `views` output returns complete resources including IDs, zone membership, and
creation/modification timestamps. Export these IDs to a separate Zero Trust
configuration when needed. Gateway policies, client connectivity, and resolver
selection are outside this submodule's scope.

Removing a view does not destroy its linked zones, but external consumers may
still reference its ID. Update those consumers before deletion. Keep one owning
configuration per view so separate zone modules do not overwrite each other's
membership changes.

[views]: https://developers.cloudflare.com/dns/internal-dns/dns-views/

## Adoption and verification

These submodules were added after v2.0.0. Use a local checkout containing them until
a release includes them, then pin that release when using the Registry source.
Provider configuration and credentials belong to the caller.

When an existing resource is already managed in the same state, retain its ID with
a caller-root move and remove the old declaration:

```hcl
moved {
  from = cloudflare_account_dns_settings_internal_view.existing
  to   = module.internal_views.cloudflare_account_dns_settings_internal_view.this["corporate"]
}
```

Match existing settings and inspect the plan before applying. For resources not
already in state, follow the import procedure for the installed provider version.
For a handoff between states, coordinate ownership before applying either state.
Setting `create = false` plans resource removal; it is not a state-only handoff.

The [schema report](docs/SCHEMA.md) includes every configurable resource field.
From the repository root, regenerate and check it with:

```sh
formr schema modules/internal-views --schema-file secrets/schema.json \
  -o modules/internal-views/docs/SCHEMA.md
formr check modules/internal-views --schema-file secrets/schema.json \
  --report modules/internal-views/docs/SCHEMA.md
```

The supplied raw snapshot lacks engine/provider version provenance; refresh it
with provenance before publication. Native mock tests cover configuration,
outputs, disabling, account checks, and unknown inputs. They do not verify live
API behavior or account entitlements. Exercise creation, updates, a second
no-change plan, and removal in a dedicated test account before production use.

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
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Default account for managed entries. Individual entries can override it. | `string` | `null` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to manage resources in this submodule. Must be known at plan time. | `bool` | `true` | no |
| <a name="input_views"></a> [views](#input\_views) | Internal DNS views keyed by stable identifiers. Names default to keys; explicit names are preserved. zones is the complete set of internal zone IDs to associate with each view and may be empty. Individual account IDs override the module default. | ```map(object({ account_id = optional(string) name = optional(string) zones = set(string) }))``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_views"></a> [views](#output\_views) | Complete managed views keyed by input keys, including computed properties. Empty when disabled or unconfigured. |
<!-- END_TF_DOCS -->
