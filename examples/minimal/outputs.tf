output "lb_ids" {
  description = "Map of load balancer name to resource id."
  value       = module.private_lb.ids
}

output "private_ip_addresses" {
  description = "Private ip addresses allocated to the load balancer frontends."
  value       = module.private_lb.private_ip_addresses
}
