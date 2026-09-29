terraform {
  required_providers {
    proxmox = { source = "bpg/proxmox" }
  }
}

provider "proxmox" {
  endpoint  = "https://${var.node_ip}:8006/"
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure  = true
}

module "golden_template" {
  source = "git::https://github.com/Virgile-Ron-Darmon/homelab-platform.git//terraform/proxmox/deploy-cluster-from-source/golden-template?ref=main"

  source_vm_id   = var.source_vm_id
  template_vm_id = var.template_vm_id
  template_node  = var.template_node
  template_name  = var.template_name
}

module "control_plane" {
  source = "git::https://github.com/Virgile-Ron-Darmon/homelab-platform.git//terraform/proxmox/deploy-cluster-from-source/clone-fleet?ref=main"
  name_prefix    = var.name_prefix_control_plane
  template_vm_id = module.golden_template.template_vm_id
  template_node  = module.golden_template.template_node

  vms         = var.vms_control_plane
  vm_id_start = var.vm_id_start_control_plane
  ip_network  = var.ip_network_control_plane
  ip_netmask  = var.ip_netmask_control_plane
  network_netmask = var.network_netmask

  vm_ssh_user     = var.ssh_user
  vm_ssh_password = var.ssh_password

  gateway = var.gateway
  dns_nameservers = var.dns_nameservers
}

module "workers" {
  source = "git::https://github.com/Virgile-Ron-Darmon/homelab-platform.git//terraform/proxmox/deploy-cluster-from-source/clone-fleet?ref=main"
  name_prefix    = var.name_prefix_workers
  template_vm_id = module.golden_template.template_vm_id
  template_node  = module.golden_template.template_node

  vms         = var.vms_workers
  vm_id_start = var.vm_id_start_workers
  ip_network  = var.ip_network_workers
  ip_netmask  = var.ip_netmask_workers
  network_netmask = var.network_netmask

  vm_ssh_user     = var.ssh_user
  vm_ssh_password = var.ssh_password

  gateway = var.gateway
  dns_nameservers = var.dns_nameservers
}

