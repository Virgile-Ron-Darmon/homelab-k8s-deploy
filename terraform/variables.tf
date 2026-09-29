# Proxmox connection
variable "node_ip" {
  type = string
}

variable "pm_api_token_id" {
  type      = string
  sensitive = true
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

# golden-template
variable "source_vm_id" {
  type = number
}

variable "template_vm_id" {
  type = number
}

variable "template_node" {
  type = string
}

variable "template_name" {
  type = string
}

# clone-fleet
variable "vms" {
  type = list(object({
    node = string
    cpus = number
    ram  = number
  }))
}

variable "vm_id_start" {
  type = number
}

variable "ip_network" {
  type = string
}

variable "ip_netmask" {
  type = string
}

variable "ssh_user" {
  type = string
}

variable "ssh_password" {
  type      = string
  sensitive = true
}