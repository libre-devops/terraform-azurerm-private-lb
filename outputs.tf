output "backend_pool_address_ids" {
  description = "Map of \"<lb>/<pool>/<address>\" to the backend pool address resource id."
  value       = { for k, v in azurerm_lb_backend_address_pool_address.this : k => v.id }
}

output "backend_pool_ids" {
  description = "Map of \"<lb>/<pool>\" to the backend address pool resource id."
  value       = { for k, v in azurerm_lb_backend_address_pool.this : k => v.id }
}

output "backend_pool_ids_zipmap" {
  description = "Map of \"<lb>/<pool>\" to a { name, id } object for the backend address pool."
  value       = { for k, v in azurerm_lb_backend_address_pool.this : k => { name = v.name, id = v.id } }
}

output "frontend_ip_configurations" {
  description = "Map of load balancer name to its frontend ip configurations as returned by Azure (name, id, allocated private ip, subnet, zones)."
  value       = { for k, v in azurerm_lb.this : k => v.frontend_ip_configuration }
}

output "ids" {
  description = "Map of load balancer name to its resource id."
  value       = { for k, v in azurerm_lb.this : k => v.id }
}

output "ids_zipmap" {
  description = "Map of load balancer name to a { name, id } object, for passing where both are needed together."
  value       = { for k, v in azurerm_lb.this : k => { name = v.name, id = v.id } }
}

output "names" {
  description = "The load balancer names."
  value       = keys(azurerm_lb.this)
}

output "nat_pool_ids" {
  description = "Map of \"<lb>/<pool>\" to the inbound NAT pool resource id."
  value       = { for k, v in azurerm_lb_nat_pool.this : k => v.id }
}

output "nat_rule_ids" {
  description = "Map of \"<lb>/<rule>\" to the inbound NAT rule resource id."
  value       = { for k, v in azurerm_lb_nat_rule.this : k => v.id }
}

output "private_ip_addresses" {
  description = "Map of load balancer name to the list of private ip addresses allocated to its frontends."
  value       = { for k, v in azurerm_lb.this : k => v.private_ip_addresses }
}

output "probe_ids" {
  description = "Map of \"<lb>/<probe>\" to the health probe resource id."
  value       = { for k, v in azurerm_lb_probe.this : k => v.id }
}

output "resource_group_name" {
  description = "Resource group name parsed from resource_group_id."
  value       = local.resource_group_name
}

output "rule_ids" {
  description = "Map of \"<lb>/<rule>\" to the load-balancing rule resource id."
  value       = { for k, v in azurerm_lb_rule.this : k => v.id }
}

output "subscription_id" {
  description = "Subscription id parsed from resource_group_id."
  value       = local.rg.subscription_id
}

output "tags" {
  description = "The tags applied to the load balancers."
  value       = var.tags
}
