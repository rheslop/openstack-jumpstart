if [ $(whoami) != root ]; then
	echo "Use sudo when running this script"
	exit
fi

if [ ! -f rhel-8-large-150-openstack.qcow2 ]; then
	echo "Disk not found!"
	exit
fi

mv rhel-8-large-150-openstack.qcow2 /var/lib/libvirt/images/
DISK=/var/lib/libvirt/images/rhel-8-large-150-openstack.qcow2

# echo "Checking disk:\n"
# 
# MD5SUM=60403afb42b7929a861cdad54eeb57a0
# DISKMD5SUM=$(md5sum ${DISK})
# 
# if [ ${MD5SUM} != ${DISKMD5SUM} ]; then
# 	echo "DISK ERROR"
# 	exit
# fi

function PACKAGE_MANAGEMENT {
if [ ! -f /usr/bin/virt-customize ]; then
        yum -y install libguestfs-tools-c
fi

if [ ! -f /usr/bin/virt-install ]; then
        yum -y install virt-install
fi
}

function NETCHECK_ONE {
echo -e "\n## Checking for network: ootpa ##\n"

if virsh net-list --all | grep " ootpa " ; then

        echo "ootpa exists."

else cat << EOF > /tmp/ootpa.xml
<network>
  <name>ootpa</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <ip address='10.44.80.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.44.80.201' end='10.44.80.254'/>
    </dhcp>
  </ip>
</network>
EOF

virsh net-define /tmp/ootpa.xml

fi

if virsh net-list | grep " ootpa " ; then
        echo "ootpa is started."
else
        virsh net-start ootpa
        virsh net-autostart ootpa
fi

# Clean up

if [ -f /tmp/ootpa.xml ]; then
rm /tmp/ootpa.xml
fi

echo -e "\n"
}


function NETCHECK_TWO {
echo -e "\n## Checking for network: ootpa-2"

if virsh net-list --all | grep " ootpa-2 " ; then

        echo "ootpa-2 exists."

else cat << EOF > /tmp/ootpa-2.xml
<network>
  <name>ootpa-2</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <ip address='10.44.81.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.44.81.201' end='10.44.81.254'/>
    </dhcp>
  </ip>
</network>
EOF

virsh net-define /tmp/ootpa-2.xml

fi

if virsh net-list | grep " ootpa-2 " ; then
        echo "ootpa-2 is started."
else
        virsh net-start ootpa-2
        virsh net-autostart ootpa-2
fi

# Clean up

if [ -f /tmp/ootpa-2.xml ]; then
rm /tmp/ootpa-2.xml
fi

echo -e "\n"
}

function SSH_KEY_MANAGEMENT {
# Create an SSH key for root if one does not already exist

if [ ! -f /root/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 2048 -N "" -f /root/.ssh/id_rsa
fi

# If an SSH key exists for this VM (from a previous deploy) remove it

echo -e "## Cleaning up known_hosts ##\n"

if [ -f /root/.ssh/known_hosts ]; then
        ssh-keygen -R 10.44.80.150
        ssh-keygen -R 10.44.81.150
fi

echo -e "\n"
}


function DISK_CUSTOMIZATIONS {
export LIBGUESTFS_BACKEND=direct
virt-customize -a ${DISK} \
--ssh-inject root \
--selinux-relabel
}

function CREATE_VM {
/usr/bin/virt-install \
--disk path=${DISK} \
--import \
--vcpus 4 \
--network network=ootpa \
--network network=ootpa-2 \
--name OpenStackVM \
--ram 16384 \
--os-type=linux \
--dry-run --print-xml > /tmp/OpenStackVM.xml

virsh define --file /tmp/OpenStackVM.xml && rm /tmp/OpenStackVM.xml
}

PACKAGE_MANAGEMENT
NETCHECK_ONE
NETCHECK_TWO
SSH_KEY_MANAGEMENT
# DISK_CUSTOMIZATIONS
CREATE_VM

