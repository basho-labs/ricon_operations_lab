#! /bin/bash
source /vagrant/bin/provision_helper.sh

echo "Generating Root Keypair"
ssh-keygen -t rsa -C "root@riak.local" -f /root/.ssh/id_rsa -N ""
chmod 600 /root/.ssh/id_rsa* 
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys 
cp /root/.ssh/id_rsa* /vagrant/data/work

echo "Installing tmux..."
cp /vagrant/data/applications/tmux /usr/local/bin/tmux

echo "Installing tmux-cssh..."
cp /vagrant/data/applications/tmux-cssh /usr/local/bin/tmux-cssh

echo "Creating ~/.tmux-cssh..."
echo "
others:-sc 192.168.228.12 -sc 192.168.228.13 -sc 192.168.228.14 -sc 192.168.228.15
node1:-sc 192.168.228.11
riak:-cs node1 -cs others
" > ~/.tmux-cssh

cp ~/.tmux-cssh /home/vagrant
chown vagrant /home/vagrant/.tmux-cssh
