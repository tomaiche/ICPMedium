#########################################################
# Define the variables
#########################################################
variable "datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
}

variable "hostname" {
  description = "Hostname of the virtual instance to be deployed"
}


variable "enable_vm" {
  type = "string"
  default = "true"
}

#Variable : vm_name
# variable "vm_name" {
#  type = "list"
# }

variable "count" {
  type = "string"
  default = "1"
}

#########################################################
##### Resource : vm_
#########################################################

variable "vm_private_ssh_key" {
  description = "private_ssh_key of virtual machine"
}

variable "vm_public_ssh_key" {
  description = "public_ssh_key of virtual machine"
}

variable "vm_os_user" {
  description = "os user of virtual machine"
  default = "root"
}



variable "vm_domain" {
  description = "Domain Name of virtual machine"
  default = "icpcam.ibmcloud"
}

variable "vm_cpu" {
  description = "vcpus of virtual machine"
  # default = 16
  }

variable "vm_ram" {
  description = "memory of virtual machine in MB"
  # default = 65536
  }


variable "vm_disk1_size" {
  description = "Size of template disk volume in GB"
  default = 400
}


variable "vm_disk2_enable" {
  type = "string"
  default = "false"
  description = "Enable a Second disk on VM"
} 

variable "vm_disk2_size" {
  description = "Size of template disk volume in GB"
  default = 200
}


variable "random" {
  type = "string"
  default = ""
  description = "Random String Generated"
}

variable "dependsOn" {
  default = "true"
  description = "Boolean for dependency"
}
