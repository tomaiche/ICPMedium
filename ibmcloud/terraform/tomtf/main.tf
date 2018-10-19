provider "ibm" {
}

provider "random" {
  version = "~> 1.0"
}

provider "local" {
  version = "~> 1.1"
}

provider "null" {
  version = "~> 1.0"
}

provider "tls" {
  version = "~> 1.0"
}

resource "random_string" "random-dir" {
  length  = 8
  special = false
}

resource "tls_private_key" "generate" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "null_resource" "create-temp-random-dir" {
  provisioner "local-exec" {
    command = "${format("mkdir -p  /tmp/%s" , "${random_string.random-dir.result}")}"
  }
}

module "deployVM_singlenode" {
  source = "git::https://github.com/tomaiche/ICPModules.git//ibmcloud_provision"


  #######
  datacenter    = "${var.datacenter}"
  
  #######
  # count = "${length(var.singlenode_hostname) }"
  
  # hostcount = "${length(list(var.singlenode_hostname)) }"
  
  private_ip_only = "${var.private_ip_only}"

  #######
  // vm_folder = "${module.createFolder.folderPath}"

  vm_cpu                     = "${var.singlenode_vcpu}"
  hostname                   = "${var.singlenode_hostname}"
  vm_ram                     = "${var.singlenode_memory}"
  vm_os_user                 = "${var.singlenode_vm_os_user}"
  vm_domain                  = "${var.vm_domain}"
  vm_private_ssh_key         = "${length(var.icp_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${var.icp_private_ssh_key}"}"
  vm_public_ssh_key          = "${length(var.icp_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.icp_public_ssh_key}"}"
  # vm_network_interface_label = "${var.vm_network_interface_label}"
  vm_disk1_size              = "${var.singlenode_vm_disk1_size}"
  vm_disk2_enable            = "${var.singlenode_vm_disk2_enable}"
  vm_disk2_size              = "${var.singlenode_vm_disk2_size}"
  random                     = "${random_string.random-dir.result}"
  enable_vm                  = "${var.enable_single_node}"
  
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"  
}

  


module "push_hostfile" {
  source               = "git::https://github.com/tomaiche/ICPSingle.git//ibmcloud/terraform/tom_modules/config_hostfile"
  
  private_key          = "${length(var.icp_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${var.icp_private_ssh_key}"}"
  vm_os_password       = "${var.singlenode_vm_os_password}"
  vm_os_user           = "${var.singlenode_vm_os_user}"
  host_count           = "${length(list(var.singlenode_hostname))}"
  vm_ipv4_address_list = "${module.deployVM_singlenode.ipv4}"
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"
  #######    
  random               = "${random_string.random-dir.result}"
  dependsOn            = "${module.deployVM_singlenode.dependsOn}"
}

module "icphosts" {
  source                = "git::https://github.com/tomaiche/ICPModules.git//config_icphosts"
  
  master_public_ips     = "${join(",", module.deployVM_singlenode.ipv4)}"
  proxy_public_ips      = "${join(",", module.deployVM_singlenode.ipv4)}"
  management_public_ips = "${join(",", module.deployVM_singlenode.ipv4)}"
  worker_public_ips     = "${join(",", module.deployVM_singlenode.ipv4)}"
  va_public_ips         = "${join(",", module.deployVM_singlenode.ipv4)}"
  enable_vm_management  = "${var.enable_vm_management}"
  enable_vm_va          = "${var.enable_vm_va}"
  random                = "${random_string.random-dir.result}"
}

module "icp_prereqs" {
  source               = "git::https://github.com/tomaiche/ICPSingle.git//ibmcloud/terraform/tom_modules/config_icp_prereqs"
  
  private_key          = "${length(var.icp_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${var.icp_private_ssh_key}"}"
  vm_os_password       = "${var.singlenode_vm_os_password}"
  vm_os_user           = "${var.singlenode_vm_os_user}"
  host_count           = "${length(list(var.singlenode_hostname))}"
  vm_ipv4_address_list = "${module.deployVM_singlenode.ipv4}"
  # vm_ipv4_address_list = "${list(var.singlenode_hostname)}"
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"  
  #######  
  random               = "${random_string.random-dir.result}"
  dependsOn            = "${module.deployVM_singlenode.dependsOn}"
}

module "icp_download_load" {
  source                 = "git::https://github.com/tomaiche/ICPSingle.git//ibmcloud/terraform/tom_modules/config_icp_download"
  
  private_key            = "${length(var.icp_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${var.icp_private_ssh_key}"}"
  vm_os_password         = "${var.singlenode_vm_os_password}"
  vm_os_user             = "${var.singlenode_vm_os_user}"
  host_count           = "${length(list(var.singlenode_hostname))}"
  vm_ipv4_address_list = "${module.deployVM_singlenode.ipv4}"
  docker_url             = "${var.docker_binary_url}"
  icp_url                = "${var.icp_binary_url}"
  icp_version            = "${var.icp_version}"
  download_user          = "${var.download_user}"
  download_user_password = "${var.download_user_password}"
  enable_bluemix_install = "${var.enable_bluemix_install}"
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"  
  #######    
  random                 = "${random_string.random-dir.result}"
  dependsOn              = "[${module.deployVM_singlenode.dependsOn}, ${module.icp_prereqs.dependsOn}]"
}

module "icp_config_yaml" {
  source                 = "git::https://github.com/tomaiche/ICPSingle.git//ibmcloud/terraform/tom_modules/config_icp_boot_standalone"
  
  private_key            = "${length(var.icp_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${var.icp_private_ssh_key}"}"
  vm_os_password         = "${var.singlenode_vm_os_password}"
  vm_os_user             = "${var.singlenode_vm_os_user}"
  vm_ipv4_address_list = "${module.deployVM_singlenode.ipv4}"
  enable_kibana          = "${lower(var.enable_kibana)}"
  enable_metering        = "${lower(var.enable_metering)}"
  icp_version            = "${var.icp_version}"
  kub_version            = "${var.kub_version}"
  vm_domain              = "${var.vm_domain}"
  icp_cluster_name       = "${var.icp_cluster_name}"
  icp_admin_user         = "${var.icp_admin_user}"
  icp_admin_password     = "${var.icp_admin_password}"
  enable_bluemix_install = "${var.enable_bluemix_install}"
  bluemix_token          = "${var.bluemix_token}"
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"  
  #######    
  random                 = "${random_string.random-dir.result}"
  dependsOn              = "[${module.icp_download_load.dependsOn}, ${module.icp_prereqs.dependsOn}]"
}
