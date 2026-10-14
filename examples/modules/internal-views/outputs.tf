output "views" {
  description = "Internal DNS view IDs and membership for external consumers."
  value       = module.internal_views.views
}
