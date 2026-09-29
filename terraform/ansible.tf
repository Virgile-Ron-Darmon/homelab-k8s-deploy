# Runs ansible/configure_interface.yml once the VMs exist, moving them from
# their DHCP address to their static one.
#
# Needs ansible-playbook, git and sshpass on the machine running terraform.

locals {
  ansible_dir = abspath("${path.module}/ansible")

  planned_ips = concat(
    [for vm in module.control_plane.vms : vm.new_ip],
    [for vm in module.workers.vms : vm.new_ip],
  )
}

resource "terraform_data" "configure_interface" {
  # Runs again only when a VM is replaced or its planned address changes.
  # The DHCP inventory always holds the address the guest agent reports now,
  # so a rerun moves a VM from whatever it has to its new static address.
  triggers_replace = {
    control_plane = [for vm in module.control_plane.vms : "${vm.vm_id}=${vm.new_ip}"]
    workers       = [for vm in module.workers.vms : "${vm.vm_id}=${vm.new_ip}"]
  }

  lifecycle {
    # Caught at plan time, before any VM is created or changed.
    precondition {
      condition     = length(local.planned_ips) == length(distinct(local.planned_ips))
      error_message = "Two VMs are planned for the same static IP (${join(", ", local.planned_ips)}). Make the control_plane and workers ip_network/ip_netmask ranges not overlap."
    }
  }

  provisioner "local-exec" {
    working_dir = local.ansible_dir
    command     = <<-EOT
      ansible-playbook \
        -i '${abspath(module.control_plane.inventory_current)}' \
        -i '${abspath(module.workers.inventory_current)}' \
        configure_interface.yml
    EOT

    environment = {
      ANSIBLE_CONFIG      = "${local.ansible_dir}/ansible.cfg"
      ANSIBLE_FORCE_COLOR = "1"
    }
  }
}