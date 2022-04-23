variable "rg_name" {
  description = "The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists"
  type        = string
  validation {
    condition     = length(var.rg_name) > 1 && length(var.rg_name) <= 24
    error_message = "Resource group name is not valid."
  }
}

variable "location" {
  description = "The location for this resource to be put in"
  type        = string
}

variable "lb_name" {
  description = "The name of the LB"
  type        = string
}

variable "lb_frontend_ip_configurations" {
  description = "Load Balancer frontend config"
  type        = map(any)
  default     = {}
}

variable "lb_sku_name" {
  description = "The SKU of the lb"
  type        = string
  default     = "Standard"
}

variable "lb_ip_configuration_name" {
  description = "The name of the frontend IP Configuration name"
  type        = string
}

variable "lb_bpool_name" {
  description = "The name for the backend pool for the Load Balancer"
  type        = string
}

variable "enable_outbound_rule" {
  description = "Whether an outbound rule should be made"
  type        = bool
}

variable "outbound_rule_name" {
  description = "The name of the outbound rule"
  type        = string
}

variable "outbound_protocol" {
  type        = string
  description = "The protocol for the outbound rule"
}

variable "allocated_outbound_ports" {
  description = "The number of ports allocated for the outbound rule"
  type        = number
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "terraform"
  }
}
