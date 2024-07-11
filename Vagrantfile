Vagrant.configure(2) do |config|

    (1..4).each do |i|
        config.vm.define "node#{i}" do |node|
            
            node.vm.box = "ubuntu/jammy64"
            node.vm.hostname = "node#{i}"
            node.vm.network "private_network", ip: "192.168.56.1#{i}"
            
            node.vm.provider "virtualbox" do |v|
                v.memory = 2048
                v.cpus = 2
            end

            node.vm.provision "file" do |f|
                f.source = "~/.ssh/id_rsa.pub"
                f.destination = "/tmp/authorized_keys"
            end

            node.vm.provision "shell", inline: "sudo cat /tmp/authorized_keys > /home/ubuntu/.ssh/authorized_keys"

        end
        
    end

end
