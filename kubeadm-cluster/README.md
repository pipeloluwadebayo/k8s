This is a vagrantfile configuration to install kubeadm for a multi-node cluster on Ubuntu distribution.

Requirements:
- 2GB or more of RAM per machine
- 2CPUs or more
- Swap must be disabled for the kubelet to work properly

Steps followed
- Install packages (curl, kubeadm, kubelet, kubectl, gnupg)
- Configure /etc/hosts file
- Disable swap permanently
- Forward ipv4 and let bridged tables see traffic
- Install containerd.io package from docker
    - OS requirements
        - Ubuntu Lunar 23.04
        - Ubuntu Kinetic 22.10
        - Ubuntu Jammy 22.04 (LTS)
        - Ubuntu Focal 20.04 (LTS)
- Install CNI plugin(weavenet)
- Join the workers to the master node

vagrant up and your cluster should be ready!

Aftwr Installation
- Run the command to configure kubectl to run as non-root user
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

Notes:
If there are any problems, feel free to create an issue.