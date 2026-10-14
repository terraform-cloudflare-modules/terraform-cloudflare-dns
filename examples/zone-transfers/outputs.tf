output "peers" {
  description = "Managed peers, including their IDs for reuse by other zones."
  value       = module.transfers.peers
}

output "tsig_key_ids" {
  description = "Managed signing IDs without secret material."
  value       = module.transfers.tsig_key_ids
}

output "incoming" {
  description = "Complete incoming configuration and transfer status."
  value       = module.transfers.incoming
}

output "outgoing" {
  description = "Complete outgoing configuration and transfer status."
  value       = module.transfers.outgoing
}
