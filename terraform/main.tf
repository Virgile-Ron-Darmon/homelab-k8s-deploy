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
  name_prefix    = "k8s-master"
  template_vm_id = module.golden_template.template_vm_id
  template_node  = module.golden_template.template_node

  vms         = [
    { node = "local1", cpus = 2, ram = 4096 },
  ]
  vm_id_start = 1700
  ip_network  = "10.0.50.0"
  ip_netmask  = "255.255.0.0"

  vm_ssh_user     = var.ssh_user
  vm_ssh_password = var.ssh_password
}

module "workers" {
  source = "git::https://github.com/Virgile-Ron-Darmon/homelab-platform.git//terraform/proxmox/deploy-cluster-from-source/clone-fleet?ref=main"
  name_prefix    = "k8s-worker"
  template_vm_id = module.golden_template.template_vm_id
  template_node  = module.golden_template.template_node

  vms         = [
    { node = "local2", cpus = 6, ram = 16384 },
    { node = "local3", cpus = 6, ram = 4096 },
    { node = "local4", cpus = 6, ram = 4096 },
  ]
  vm_id_start = 1800
  ip_network  = "10.0.51.0"
  ip_netmask  = "255.255.0.0"

  vm_ssh_user     = var.ssh_user
  vm_ssh_password = var.ssh_password
}