output "bpool_id" {
  value       = azurerm_lb_backend_address_pool.private_lb_bpool.id
  description = "The id of the backend pool"

}

output "bpool_name" {
  value       = azurerm_lb_backend_address_pool.private_lb_bpool.id
  description = "The name of the backend pool"
}

output "lb_id" {
  value       = azurerm_lb.priv_lb.id
  description = "The ID of the load balancer"
}

output "lb_ip_configuration" {
  value       = azurerm_lb.priv_lb.frontend_ip_configuration
  description = "The frontend ip configuration object"
}

output "lb_name" {
  value       = azurerm_lb.priv_lb.name
  description = "The Name of the load balancer"
}
