output "lb_id" {
  value       = azurerm_lb.pub_lb.id
  description = "The ID of the load balancer"
}

output "lb_name" {
  value       = azurerm_lb.pub_lb.name
  description = "The Name of the load balancer"
}

output "lb_ip_configuration" {
  value       = azurerm_lb.pub_lb.frontend_ip_configuration
  description = "The frontend ip configuration object"
}

output "bpool_id" {
  value       = azurerm_lb_backend_address_pool.public_lb_bpool.id
  description = "The id of the backend pool"

}

output "bpool_name" {
  value       = azurerm_lb_backend_address_pool.public_lb_bpool.id
  description = "The name of the backend pool"
}

output "outbound_rule_id" {
  value       = azurerm_lb_outbound_rule.outbound_rule.*.id
  description = "The id of the outbound rule if created"
}

output "outbound_rule_name" {
  value       = azurerm_lb_outbound_rule.outbound_rule.*.name
  description = "The name of the outbound rule if created"
}

output "outbound_rule_protocol" {
  value       = azurerm_lb_outbound_rule.outbound_rule.*.protocol
  description = "The protocl of the outbound rule if created"
}

output "outbound_allocated_outbound_ports" {
  value       = azurerm_lb_outbound_rule.outbound_rule.*.allocated_outbound_ports
  description = "The allocated ports of the outbound rule if created"
}