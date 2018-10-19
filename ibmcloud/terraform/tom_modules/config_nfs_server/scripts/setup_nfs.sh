#!/bin/bash

# Check if a command exists
function command_exists() {
  type "$1" &> /dev/null;
}

# platform dependant install
function check_command_and_install() {
	command=$1
  string="[*] Checking installation of: $command"
  line="......................................................................."
  if command_exists $command; then
    printf "%s %s [INSTALLED]\n" "$string" "${line:${#string}}"
  else
    printf "%s %s [MISSING]\n" "$string" "${line:${#string}}"
      if [ $# == 3 ]; then # If the package name is provided
        if [[ $PLATFORM == *"ubuntu"* ]]; then
          sudo apt-get update -y
          sudo apt-get install -y $2
        else
          sudo yum install -y $3
        fi
      else # If a function name is provided
        eval $2
      fi
      if [ $? -ne "0" ]; then
        echo "[ERROR] Failed while installing $command"
        exit 1
      fi
  fi
}
# Identify the platform and version using Python
if command_exists python; then
  PLATFORM=`python -c "import platform;print(platform.platform())" | rev | cut -d '-' -f3 | rev | tr -d '".' | tr '[:upper:]' '[:lower:]'`
  PLATFORM_VERSION=`python -c "import platform;print(platform.platform())" | rev | cut -d '-' -f2 | rev`
else
  if command_exists python3; then
    PLATFORM=`python3 -c "import platform;print(platform.platform())" | rev | cut -d '-' -f3 | rev | tr -d '".' | tr '[:upper:]' '[:lower:]'`
    PLATFORM_VERSION=`python3 -c "import platform;print(platform.platform())" | rev | cut -d '-' -f2 | rev`
  fi
fi
# # Check if the executing platform is supported
# if [[ $PLATFORM == *"ubuntu"* ]] || [[ $PLATFORM == *"redhat"* ]] || [[ $PLATFORM == *"rhel"* ]] || [[ $PLATFORM == *"centos"* ]]; then
#   echo "[*] Platform identified as: $PLATFORM $PLATFORM_VERSION"
# else
#   echo "[ERROR] Platform $PLATFORM not supported"
#   exit 1
# fi
# Change the string 'redhat' to 'rhel'
if [[ $PLATFORM == *"redhat"* ]]; then
  PLATFORM="rhel"
fi


DRIVE=$1
MOUNT_POINT="/var/nfs"
# format and mount a drive to /mnt
echo "Formatting drive $DRIVE"
mkfs -F -t ext3 $DRIVE
echo "Creating folder for mount point: $MOUNT_POINT"
mkdir -p $MOUNT_POINT
echo "Adding $DRIVE to /etc/fstab"
echo "$DRIVE  $MOUNT_POINT ext3  defaults 1 3" | tee -a /etc/fstab
echo ""
echo "Setting mount point permissions and mounting"
sudo chown nobody:nogroup $MOUNT_POINT
mount $MOUNT_POINT

echo "$MOUNT_POINT  *(rw,sync,no_subtree_check,no_root_squash)" | tee -a /etc/exports

echo "Installing nfs-kernel-server"


if [[ $PLATFORM == "rhel" ]]; then
  check_command_and_install  nfs-utils  nfs-utils  nfs-utils 
  check_command_and_install libnfsidmap libnfsidmap libnfsidmap
  systemctl enable rpcbind
  systemctl enable nfs-server
  systemctl enable nfs-lock
  systemctl enable nfs-idmap
  systemctl start rpcbind
  systemctl start nfs-server
  systemctl start nfs-lock
  systemctl start nfs-idmap
else
  check_command_and_install nfs-kernel-server nfs-kernel-server nfs-kernel-server
  sudo systemctl restart nfs-kernel-server
fi
