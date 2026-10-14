# ✅ Terraform Cloudflare Modules - `TODO`s

The product boundary is Cloudflare DNS. The v2 implementation manages records with optional ownership of their zone, DNSSEC configuration, and zone-wide DNS settings.

## ➕ Additions

- DNS-only load balancing and geographic steering, including pools and monitors.
- Custom nameserver resources and secondary DNS transfers.
- Further internal DNS and account-level DNS settings.

Add each capability with complete configurable schema coverage and explicit ownership semantics.
Defaults for new capabilities must preserve existing consumers' behavior.
Keep record map keys and resource addresses stable as capabilities are added.
Workers belongs in a separate product module, `terraform-cloudflare-workers`.

## ✏️ Planned Changes

Before v2 publication, regenerate the reviewed Formr schema report with engine and provider version provenance, run the
provider-backed native tests, and verify the live migration described in [UPGRADING.md](UPGRADING.md).

## 💡 Ideas

## 🔗 Links

## 🗒️ Notes
