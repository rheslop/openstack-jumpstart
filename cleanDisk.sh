rm /home/stack/deploy.sh
subscription-manager unsubscribe --all

cat << EOF > /etc/motd
##########################################################

Useful files:

The clouds.yaml file is at ~/.config/openstack/clouds.yaml

Use "export OS_CLOUD=standalone" before running the
openstack command.

##########################################################
EOF

cat << EOF > /etc/issue

------------------
username: root
password: password

username: stack
password: stack
------------------

EOF

echo "" > /root/.ssh/authorized_keys

pcs cluster stop --all
sh
utdown -h now

