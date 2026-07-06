output "backend_pool_ids" {
  description = "Backend pool ids keyed by \"<lb>/<pool>\"."
  value       = module.private_lb.backend_pool_ids
}

output "frontend_ip_configurations" {
  description = "Frontend configurations as returned by Azure."
  value       = module.private_lb.frontend_ip_configurations
}

output "lb_ids" {
  description = "Map of load balancer name to resource id."
  value       = module.private_lb.ids
}

output "nat_rule_ids" {
  description = "Inbound NAT rule ids keyed by \"<lb>/<rule>\"."
  value       = module.private_lb.nat_rule_ids
}

output "private_ip_addresses" {
  description = "Private ip addresses allocated to the load balancer frontends."
  value       = module.private_lb.private_ip_addresses
}
