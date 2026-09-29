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

variable "ssh_user" {
  type = string
}

variable "ssh_password" {
  type      = string
  sensitive = true
}


# Control Plane stuff

variable "name_prefix_control_plane"{
  type = string
}

variable "vms_control_plane" {
  description = "List of VMs to create, with the node they run on and their resources"
  type = list(object({
    node = string
    cpus = number
    ram  = number
  }))
}

variable "vm_id_start_control_plane"{
  type = number
}
variable "ip_network_control_plane"{
  type = string
}
variable "ip_netmask_control_plane"{
  type = string
}


# Workers stuff

variable "name_prefix_workers"{
  type = string
}

variable "vms_workers" {
  description = "List of VMs to create, with the node they run on and their resources"
  type = list(object({
    node = string
    cpus = number
    ram  = number
  }))
}

variable "vm_id_start_workers"{
  type = number
}
variable "ip_network_workers"{
  type = string
}
variable "ip_netmask_workers"{
  type = string
}