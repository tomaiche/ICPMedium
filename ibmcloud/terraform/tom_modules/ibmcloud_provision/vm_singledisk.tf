##############################################################
# Add ssh key to IBM Cloud, so it can be used against the VM
##############################################################

resource "ibm_compute_ssh_key" "icp_public_key" {
  label      = "ICP Key"
  public_key = "${var.vm_public_ssh_key}"
}

##############################################################
# Create Virtual Machine 
##############################################################
resource "ibm_compute_vm_instance" "softlayer_virtual_guest" {
  # count = "${var.vm_disk2_enable == "false" && var.enable_vm == "true" ? 1 : 0}"
  hostname                 = "${var.hostname}"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = false
  cores                   = "${var.vm_cpu}"
  memory                   = "${var.vm_ram}"
  # flavor_key_name          = "B1.16x64"
  # disks                    = [25,${var.vm_disk1_size}]
  disks                    = [25,400]
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.icp_public_key.id}"]


  # Specify the connection
  connection {
    type     = "ssh"
    user        = "${var.vm_os_user}"
    private_key = "${var.vm_private_ssh_key}"
    host     = "${self.ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"        
  }

  provisioner "file" {
    destination = "VM_add_ssh_key.sh"

    content = <<EOF
# =================================================================
# Licensed Materials - Property of IBM
# 5737-E67
# @ Copyright IBM Corporation 2016, 2017 All Rights Reserved
# US Government Users Restricted Rights - Use, duplication or disclosure
# restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================
#!/bin/bash

if (( $# != 3 )); then
echo "usage: arg 1 is user, arg 2 is public key, arg3 is Private Key"
exit -1
fi

userid="$1"
ssh_key="$2"
private_ssh_key="$3"


echo "Userid: $userid"

echo "ssh_key: $ssh_key"
echo "private_ssh_key: $private_ssh_key"


user_home=$(eval echo "~$userid")
user_auth_key_file=$user_home/.ssh/authorized_keys
user_auth_key_file_private=$user_home/.ssh/id_rsa
user_auth_key_file_private_temp=$user_home/.ssh/id_rsa_temp
echo "$user_auth_key_file"
if ! [ -f $user_auth_key_file ]; then
echo "$user_auth_key_file does not exist on this system, creating."
mkdir $user_home/.ssh
chmod 700 $user_home/.ssh
touch $user_home/.ssh/authorized_keys
chmod 600 $user_home/.ssh/authorized_keys
else
echo "user_home : $user_home"
fi

echo "$user_auth_key_file"
echo "$ssh_key" >> "$user_auth_key_file"
if [ $? -ne 0 ]; then
echo "failed to add to $user_auth_key_file"
exit -1
else
echo "updated $user_auth_key_file"
fi

# echo $private_ssh_key  >> $user_auth_key_file_private_temp
# decrypt=`cat $user_auth_key_file_private_temp | base64 --decode`
# echo "$decrypt" >> "$user_auth_key_file_private"

echo "$private_ssh_key"  >> "$user_auth_key_file_private"
chmod 600 $user_auth_key_file_private
if [ $? -ne 0 ]; then
echo "failed to add to $user_auth_key_file_private"
exit -1
else
echo "updated $user_auth_key_file_private"
fi
rm -rf $user_auth_key_file_private_temp

# manage additional disk
echo "adding partition to additionnal disk "
# add partition on new disk

parted -s /dev/xvdc mklabel gpt mkpart extra ext4 0% 100%

echo "partition added to additionnal disk "

# create fs

echo "creating filesystem"

mkfs -t ext4 /dev/xvdc1
mkdir -p /extra
mount /dev/xvdc1 /extra
echo "/dev/xvdc1 /extra  ext4 defaults   0 0" >> /etc/fstab

echo "filesystem created and mounted, creating mount points and directories"

# create directorie and mount points

mkdir -p /extra/docker
mkdir -p /extra/kubelet
mkdir -p /extra/etcd
mkdir -p /extra/icp
mkdir -p /extra/registry

mkdir -p /var/lib/docker
mkdir -p /var/lib/kubelet
mkdir -p /var/lib/etcd
mkdir -p /var/lib/icp
mkdir -p /var/lib/registry

echo "mount points and directories created, doing mounts"


# mount bind target directories on extra disk and persist to fstab

mount --rbind /extra/docker /var/lib/docker
echo "/extra/docker /var/lib/docker none defaults,bind 0 0" >> /etc/fstab

mount --rbind /extra/kubelet /var/lib/kubelet
echo "/extra/kubelet /var/lib/kubelet none defaults,bind 0 0" >> /etc/fstab

mount --rbind /extra/etcd /var/lib/etcd
echo "/extra/etcd /var/lib/etcd none defaults,bind 0 0" >> /etc/fstab

mount --rbind /extra/icp /var/lib/icp
echo "/extra/icp /var/lib/icp none defaults,bind 0 0" >> /etc/fstab

mount --rbind /extra/registry /var/lib/registry
echo "/extra/registry /var/lib/registry none defaults,bind 0 0" >> /etc/fstab

echo "everything mounted and persisted to /etc/fstab"

exit 0

EOF
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "bash -c 'chmod +x VM_add_ssh_key.sh'",
      "bash -c './VM_add_ssh_key.sh  \"root\" \"${var.vm_public_ssh_key}\" \"${var.vm_private_ssh_key}\">> VM_add_ssh_key.log 2>&1'",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"${self.ipv4_address}       ${var.hostname}.${var.vm_domain} ${var.hostname}\" >> /tmp/${var.random}/hosts"
  }
}



resource "null_resource" "vm-create_done" {
#   depends_on = ["vsphere_virtual_m:achine.vm", "vsphere_virtual_machine.vm2disk"]
  depends_on = ["ibm_compute_vm_instance.softlayer_virtual_guest"]

  provisioner "local-exec" {
    command = "echo 'VM creates done for ${var.hostname}X.'"
  }
}
