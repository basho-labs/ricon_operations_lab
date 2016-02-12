#! /bin/bash
source /vagrant/bin/provision_helper.sh

# provision_all -- loads useful utilities onto the box
echo "* Installing block/unblock scripts"
cp /vagrant/data/applications/block /usr/local/sbin/block
chmod +x /usr/local/sbin/block

cp /vagrant/data/applications/unblock /usr/local/sbin/unblock
chmod +x /usr/local/sbin/unblock

cp /vagrant/data/applications/blocklist /usr/local/sbin/blocklist
chmod +x /usr/local/sbin/blocklist
