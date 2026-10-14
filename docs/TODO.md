# ✅ Terraform Cloudflare Modules - `TODO`s

The product boundary is Cloudflare DNS. The v2 implementation manages records with optional ownership of their zone.

## ➕ Additions

- DNSSEC configuration and complete upstream outputs.
- Zone DNS settings and further DNS-specific resources.

Add each capability with complete configurable schema coverage and explicit ownership semantics.
Defaults for new capabilities must preserve existing consumers' behavior.
Keep record map keys and resource addresses stable as capabilities are added.
Workers belongs in a separate product module, `terraform-cloudflare-workers`.

## ✏️ Planned Changes

Before v2 publication, generate and review the Formr schema report, run the
provider-backed native tests, and verify the live migration described in [UPGRADING.md](UPGRADING.md).

## 💡 Ideas

## 🔗 Links

## 🗒️ Notes
