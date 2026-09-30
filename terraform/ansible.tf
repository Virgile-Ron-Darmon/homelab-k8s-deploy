# Runs the Ansible playbooks in ansible/ once the VMs exist:
#   1. configure_interface: moves the VMs from DHCP to their static addresses
#   2. ansible_requirements: installs the collections the playbooks need
#   3. k8s_common: prepares every node
#   4. k8s_control_plane: builds the control plane and installs Helm
#   5. k8s_workers: joins the workers
#
# Needs ansible-playbook, ansible-galaxy, git and sshpass on the machine
# running terraform.

locals {
  ansible_dir = abspath("${path.module}/ansible")

  ansible_env = {
    ANSIBLE_CONFIG      = "${local.ansible_dir}/ansible.cfg"
    ANSIBLE_FORCE_COLOR = "1"
  }

  # Both static inventories, and host patterns built from the same prefixes
  # Terraform names the VMs with, so the playbooks never guess them.
  k8s_ansible_args = join(" ", [
    "-i '${abspath(module.control_plane.inventory_new)}'",
    "-i '${abspath(module.workers.inventory_new)}'",
    "-e k8s_control_plane_hosts='${var.name_prefix_control_plane}-*'",
    "-e k8s_worker_hosts='${var.name_prefix_workers}-*'",
  ])
}

resource "terraform_data" "configure_interface" {
  # Runs again only when a VM is replaced or its planned address changes.
  # The DHCP inventory always holds the address the guest agent reports now,
  # so a rerun moves a VM from whatever it has to its new static address.
  triggers_replace = [
    for vm in concat(module.control_plane.vms, module.workers.vms) :
    "${vm.vm_id}=${vm.new_ip}"
  ]

  provisioner "local-exec" {
    working_dir = local.ansible_dir
    command     = <<-EOT
      ansible-playbook \
        -i '${abspath(module.control_plane.inventory_current)}' \
        -i '${abspath(module.workers.inventory_current)}' \
        configure_interface.yml
    EOT
    environment = local.ansible_env
  }
}

# Installs the Ansible collections the playbooks need.
# Runs again only when requirements.yml changes.
resource "terraform_data" "ansible_requirements" {
  triggers_replace = [
    filesha256("${local.ansible_dir}/requirements.yml"),
  ]

  provisioner "local-exec" {
    working_dir = local.ansible_dir
    command     = "ansible-galaxy collection install -r requirements.yml"
    environment = local.ansible_env
  }
}

# Prepares every node. Runs again when the VMs change (through
# configure_interface), or when the playbook or shared vars change.
resource "terraform_data" "k8s_common" {
  triggers_replace = [
    terraform_data.configure_interface.id,
    filesha256("${local.ansible_dir}/k8s_common.yml"),
    filesha256("${local.ansible_dir}/vars/k8s.yml"),
  ]

  provisioner "local-exec" {
    working_dir = local.ansible_dir
    command     = "ansible-playbook ${local.k8s_ansible_args} k8s_common.yml"
    environment = local.ansible_env
  }

  depends_on = [terraform_data.ansible_requirements]
}

# Builds the control plane and installs Helm. Runs again whenever
# k8s_common reruns, or when its playbook or the shared vars change.
resource "terraform_data" "k8s_control_plane" {
  triggers_replace = [
    terraform_data.k8s_common.id,
    filesha256("${local.ansible_dir}/k8s_control_plane.yml"),
    filesha256("${local.ansible_dir}/vars/k8s.yml"),
  ]

  provisioner "local-exec" {
    working_dir = local.ansible_dir
    command     = "ansible-playbook ${local.k8s_ansible_args} k8s_control_plane.yml"
    environment = local.ansible_env
  }
}

# Joins the workers. Runs again whenever the control plane step reruns,
# or when its playbook or the shared vars change.
resource "terraform_data" "k8s_workers" {
  triggers_replace = [
    terraform_data.k8s_control_plane.id,
    filesha256("${local.ansible_dir}/k8s_workers.yml"),
    filesha256("${local.ansible_dir}/vars/k8s.yml"),
  ]

  provisioner "local-exec" {
    working_dir = local.ansible_dir
    command     = "ansible-playbook ${local.k8s_ansible_args} k8s_workers.yml"
    environment = local.ansible_env
  }
}