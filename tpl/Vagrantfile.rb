# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box_check_update = true
  #config.vm.provider 'virtualbox' do |vb|
  # vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
  #end  
  #config.vm.synced_folder ".", "/vagrant", type: "nfs", nfs_udp: false
  config.vm.synced_folder ".", "/vagrant", disabled: true
  $num_instances = 1
  (1..$num_instances).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "ysicing/debian"
      node.vm.hostname = "node#{i}"
      ip = "192.168.100.#{i+100}"
      node.vm.network "private_network", ip: ip
      node.vm.provider "virtualbox" do |vb|
        vb.gui = false
        vb.memory = "4096"
        vb.cpus = 2
        vb.name = "node#{i}"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
      end
      #node.vm.provision "shell", inline: "echo Hello, World"
    end
  end
end