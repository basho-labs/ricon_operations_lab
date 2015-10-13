# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "chef/centos-6.5"

  config.vm.define "app" do |app|
    app.vm.hostname = "lb.riak.local"
    app.vm.network "private_network", ip: "192.168.228.10"
  end 

  config.vm.define "node1" do |node1|
    node1.vm.hostname = "node1.riak.local"
    node1.vm.provision "riak", type: "shell", path: "bin/provision_riak.sh"
    node1.vm.network "private_network", ip: "192.168.228.11"
  end

  config.vm.define "node2" do |node2|
    node2.vm.hostname = "node2.riak.local"
    node2.vm.provision "riak", type: "shell", path: "bin/provision_riak.sh"
    node2.vm.network "private_network", ip: "192.168.228.12"
  end

  config.vm.define "node3" do |node3|
    node3.vm.hostname = "node3.riak.local"
    node3.vm.provision "riak", type: "shell", path: "bin/provision_riak.sh"
    node3.vm.network "private_network", ip: "192.168.228.13"
  end

  config.vm.define "node4" do |node4|
    node4.vm.hostname = "node4.riak.local"
    node4.vm.provision "riak", type: "shell", path: "bin/provision_riak.sh"
    node4.vm.network "private_network", ip: "192.168.228.14"
  end

  config.vm.define "node5" do |node5|
    node5.vm.hostname = "node5.riak.local"
    node5.vm.provision "riak", type: "shell", path: "bin/provision_riak.sh"
    node5.vm.network "private_network", ip: "192.168.228.15"
  end

end
