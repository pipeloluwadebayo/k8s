#!/bin/bash

set -e

install_packages ()
{
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
# download the google cloud public signing key
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo apt -y install vim git curl wget
}


# cofigure etc/hosts file
configure_hosts ()
{
sudo tee /etc/hosts<<EOF
192.168.50.4 master
192.168.50.5 node-01
192.168.50.6 node-02
EOF
}


# permanently disable swap to accomodate kubernetes
disable_swap () 
{
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
}


# load the br_netfilter table and let iptables see bridged  traffic
configure_sysctl ()
{
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
}


# install containerd runtime
install_containerd ()
{
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# add docker official gpg key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# set up repository
echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install docker engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml 
service containerd restart
service kubelet restart
# containerd config default | sudo tee /etc/containerd/config.toml
# sudo systemctl restart containerd
systemctl daemon-reload
systemctl restart containerd.service
systemctl start docker
}


# sudo systemctl daemon-reload 
# sudo systemctl enable docker

# sed -i 's/plugins.cri.systemd_cgroup = false/plugins.cri.systemd_cgroup = true/' /etc/containerd/config.toml
# sudo systemctl restart containerd

# configure systemd group driver
# configure_cgroup () 
# {
#     cat <<EOF | sudo tee -a /etc/containerd/config.toml
# [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
# [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
# SystemdCgroup = true
# EOF
# }


# sudo sed -i 's/plugins.cri.systemd_cgroup = false/plugins.cri.systemd_cgroup = true/' /etc/containerd/config.toml

# sudo sed -i 's/^disabled_plugins \=/\#disabled_plugins \=/g' /etc/containerd/config.toml


#enable CRI plugins
enable_plugins ()
{
sudo mkdir -p /opt/cni/bin/
sudo wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.3.0.tgz
sudo systemctl restart containerd
}


# containerd config default | tee /etc/containerd/config.toml
# sed -i ‘s/SystemdCgroup = false/SystemdCgroup = true/g’ /etc/containerd/config.toml 
# service containerd restart
# service kubelet restart

install_packages
configure_hosts
disable_swap
configure_sysctl
install_containerd
# configure_cgroup
enable_plugins