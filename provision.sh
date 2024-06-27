ROL=$1
USER=ubuntu
HOME=/home/$USER
K8S=1.30

### base system configuration
sudo apt update
sudo apt install curl apt-transport-https ca-certificates gnupg -y
#useradd -m -g root -G sudo -s /bin/bash $USER
#ssh-keygen -q -t rsa -b 4096 -N '' -C "$USER@$HOSTNAME" -f ~/.ssh/id_rsa <<< y
sudo cat /tmp/authorized_keys > $HOME/.ssh/authorized_keys
sudo chown $USER:$USER $HOME/.ssh/authorized_keys
sudo chmod 644 /home/$USER/.ssh/authorized_keys
sudo echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/$USER"
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

### installing docker and k8s
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$K8S/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v'$K8S'/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt update ; apt install -y kubeadm kubelet kubectl
sudo apt-mark hold kubeadm kubelet kubectl
sudo apt install -y docker.io
sudo systemctl enable docker
sudo cat <<EOF | sudo tee /etc/docker/daemon.json
{ "exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts":
{ "max-size": "100m" },
"storage-driver": "overlay2"
}
EOF
sudo systemctl restart docker

### tuning the operating system
sed -i '/swap/d' /etc/fstab
swapoff -a
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
cat >>/etc/hosts<<EOF
192.168.56.10   master.homelab.local       master
192.168.56.11   worker01.homelab.local     worker01
192.168.56.12   worker02.homelab.local     worker02
EOF

### initializing master node
if [ $ROL == "master" ]; then
    mkdir -p $HOME/.kube
    kubeadm init --apiserver-advertise-address 192.168.56.10 --control-plane-endpoint 192.168.56.10 --pod-network-cidr=10.244.0.0/16
    kubeadm token create --print-join-command > $HOME/.kube/joincluster.sh
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown -R $USER:$USER $HOME/.kube
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    echo "export KUBECONFIG=~/.kube/config" >> $HOME/.bashrc
    python3 -m http.server 8089 -d $HOME/.kube > /dev/null 2>&1 &
fi

### join worker node to cluster
if [ $ROL == "worker" ]; then
    bash <(curl -s http://192.168.56.10:8089/joincluster.sh)
fi
