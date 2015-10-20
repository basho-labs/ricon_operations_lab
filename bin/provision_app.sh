#! /bin/bash
source /vagrant/bin/provision_helper.sh

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