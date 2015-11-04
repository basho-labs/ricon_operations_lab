#! /bin/bash
source /vagrant/bin/provision_helper.sh

# provision_riak -- Installs and configures Riak as a cluster of 1
echo "* Installing Generated Root Key (if available)"
if [ -f "/vagrant/data/work/id_rsa" ] 
  then
        echo "    - Found a key, installing..."
        mkdir /root/.ssh
        chmod 700 /root/.ssh
        cp /vagrant/data/work/id_rsa* /root/.ssh
        cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
        chmod 600 -R /root/.ssh/*

        cp /vagrant/data/work/id_rsa* /home/vagrant/.ssh
        chown vagrant:vagrant /home/vagrant/.ssh/id_rsa*
fi

echo "* Checking for cached components"
if [ ! -f "/vagrant/data/rpmcache/riak-2.0.6-1.el6.x86_64.rpm" ] 
  then
    echo "   - Downloading Riak 2.0.6 Package into cache"
    wget -q --output-document=/vagrant/data/rpmcache/riak-2.0.6-1.el6.x86_64.rpm http://s3.amazonaws.com/downloads.basho.com/riak/2.0/2.0.6/rhel/6/riak-2.0.6-1.el6.x86_64.rpm 
fi

if [ ! -f "/vagrant/data/rpmcache/riak-2.1.1-1.el6.x86_64.rpm" ] 
  then
    echo "   - Downloading Riak 2.1.1 Package into cache"
    wget -q --output-document=/vagrant/data/rpmcache/riak-2.1.1-1.el6.x86_64.rpm http://s3.amazonaws.com/downloads.basho.com/riak/2.1/2.1.1/rhel/6/riak-2.1.1-1.el6.x86_64.rpm 
fi

echo "* Installing Riak Package"
  rpm -Uv /vagrant/data/rpmcache/riak-2.0.6-1.el6.x86_64.rpm

if [ ! -d "/etc/riak" ] 
  then
    echo "No Riak directory found after installation.  Aborting..."
    exit 1
fi

echo "* Increasing File Limits"
echo '
# Added by Vagrant Provisioning Script
# ulimit settings for Riak
root soft nofile 65536
root hard nofile 65536
riak soft nofile 65536
riak hard nofile 65536

'  >> /etc/security/limits.conf

echo ""
echo "* Configuring node as riak@$IP_ADDRESS "
echo '
# Added by Vagrant Provisioning Script'  >> /etc/riak/riak.conf
echo "nodename = riak@$IP_ADDRESS" >> /etc/riak/riak.conf
echo "buckets.default.allow_mult = true" >> /etc/riak/riak.conf
echo "listener.http.internal = 0.0.0.0:8098" >> /etc/riak/riak.conf
echo "listener.protobuf.internal = 0.0.0.0:8087" >> /etc/riak/riak.conf

echo "* Disabling GSSAPIAuthentication"
cp /etc/ssh/ssh_config /etc/ssh/ssh_config.orig
sed 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/ssh_config.orig > /etc/ssh/ssh_config


insert_attribute riak riak@$IP_ADDRESS
insert_service riak riak@$IP_ADDRESS

echo "* Enabling and Starting Riak"
chkconfig riak on
service riak start
