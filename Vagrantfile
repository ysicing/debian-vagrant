# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  config.vm.provider 'virtualbox' do |vb|
   vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
  end  
  config.vm.synced_folder ".", "/vagrant", type: "nfs", nfs_udp: false, disabled: true
  $num_instances = 1
  (1..$num_instances).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "file://builds/virtualbox-debian.10.3.0.box"
      node.vm.hostname = "node#{i}"
      #node.ssh.username = "root"
      #node.ssh.password = "vagrant"
      ip = "192.168.100.#{i+100}"
      node.vm.network "private_network", ip: ip
      node.vm.provider "virtualbox" do |vb|
        vb.gui = false
        vb.memory = "1024"
        vb.cpus = 1
        vb.name = "node#{i}"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
      end
      node.vm.provision "shell", inline: "uname -a"
    end
  end
end
