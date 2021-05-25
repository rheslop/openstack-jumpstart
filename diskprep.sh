cp /var/lib/libvirt/images/rhel-8-large-150.qcow2 \
   /var/lib/libvirt/images/rhel-8-large-150-openstack.qcow2

virt-customize -a /var/lib/libvirt/images/rhel-8-large-150-openstack.qcow2 \
--run-command 'rm /root/train-rh16-standalone.sh' \
--run-command 'rm /root/cleanDisk.sh' \
--run-command 'rm /root/.bash_history' \
--run-command 'rm /home/stack/.bash_history'

qemu-img snapshot -d VANILLA /var/lib/libvirt/images/rhel-8-large-150-openstack.qcow2
qemu-img snapshot -c VANILLA /var/lib/libvirt/images/rhel-8-large-150-openstack.qcow2

