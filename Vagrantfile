Vagrant.configure(2) do |config|

    config.vm.define "master" do |node|
        node.vm.box = "ubuntu/jammy64"
        node.vm.hostname = "master"
        node.vm.network "private_network", ip: "192.168.56.10"

        node.vm.provider "virtualbox" do |v|
            v.memory = 2048
            v.cpus = 2
        end

        node.vm.provision "file" do |f|
            f.source = "~/.ssh/id_rsa.pub"
            f.destination = "/tmp/authorized_keys"
        end

        node.vm.provision "shell" do |sh|
            sh.path = "provision.sh"
            sh.privileged = "false"
            sh.args = "master"
        end
    end

    (1..1).each do |i|
        config.vm.define "worker#{i}" do |node|
            node.vm.box = "ubuntu/jammy64"
            node.vm.hostname = "worker#{i}"
            node.vm.network "private_network", ip: "192.168.56.1#{i}"

            node.vm.provider "virtualbox" do |v|
                v.memory = 2048
                v.cpus = 2
            end

            node.vm.provision "file" do |f|
                f.source = "~/.ssh/id_rsa.pub"
                f.destination = "/tmp/authorized_keys"
            end

            node.vm.provision "shell" do |sh|
                sh.path = "provision.sh"
                sh.privileged = "false"
                sh.args = "worker"
            end
        end
    end

end
