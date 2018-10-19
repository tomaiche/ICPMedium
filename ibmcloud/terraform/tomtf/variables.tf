# Single Node
variable "datacenter" {
  type    = "string"
}
variable "private_ip_only" {
  type    = "string"
}

variable "singlenode_hostname" {
  type    = "string"
}

variable "singlenode_vcpu" {
  type    = "string"
}

variable "singlenode_memory" {
  type    = "string"
}


variable "singlenode_vm_os_user" {
  type = "string"
}

variable "singlenode_vm_os_password" {
  type = "string"
}


variable "singlenode_vm_disk1_size" {
  type    = "string"
  default = "400"
}


variable "singlenode_vm_disk2_enable" {
  type    = "string"
  default = "false"
}

variable "singlenode_vm_disk2_size" {
  type    = "string"
  default = ""
}



variable "vm_domain" {
  type = "string"
}


# SSH KEY Information
variable "icp_private_ssh_key" {
  type    = "string"
  default = ""
}

variable "icp_public_ssh_key" {
  type    = "string"
  default = ""
}

# Binary Download Locations
variable "docker_binary_url" {
  type = "string"
}

variable "icp_binary_url" {
  type = "string"
}

variable "icp_version" {
  type    = "string"
}

variable "kub_version" {
  type    = "string"
}

variable "download_user" {
  type = "string"
}

variable "download_user_password" {
  type = "string"
}

# ICP Settings
variable "enable_kibana" {
  type    = "string"
}

variable "enable_metering" {
  type    = "string"
}

variable "icp_cluster_name" {
  type = "string"
}

variable "icp_admin_user" {
  type    = "string"
}

variable "icp_admin_password" {
  type    = "string"
}

variable "enable_bluemix_install" {
  type    = "string"
  default = "false"
}

variable "bluemix_token" {
  type    = "string"
  default = ""
}

variable "enable_single_node" {
  type    = "string"
  default = "true"
}

variable "enable_vm_va" {
  type    = "string"
  default = "false"
}

variable "enable_vm_management" {
  type    = "string"
  default = "false"
}
