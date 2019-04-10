#!/bin/bash

# Bootstrapping ready-to-use one-node K8S deployment on Ubuntu 16.04 (Xenial)

# Install Docker
apt-get update && apt-get install -qy docker.io

# Install Kubernetes apt repo
apt-get update
apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list

# Install kubelet, kubeadm and kubernetes-cni
apt-get update
apt-get install -y kubelet kubeadm kubernetes-cni

# Disabling SWAP
swapoff -a
sed -i '/swap/s/^/#/g' /etc/fstab

# Extracting IP address and cluster initialzing
ADVERTISE_IP=$(hostname -I | cut -d' ' -f2)
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$ADVERTISE_IP

# Setting up KUBECONFIG variable
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=$KUBECONFIG" >> ~/.bashrc

# Setting up Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml

# Untaint Master nodes (for pods scheduling on a 1-node k8s cluster)
kubectl taint nodes --all node-role.kubernetes.io/master-

# NGINX ingress implementation (Baremetal)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml

#IP=
#NODEPORT=

#iptables -A PREROUTING -t nat -i bond0 -p tcp --dport 80 -j DNAT --to 10.80.95.129:32605
#iptables -A FORWARD -p tcp -d 10.80.95.129 --dport 32605 -j ACCEPT

#iptables -t nat -A PREROUTING -d 10.80.95.129 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 32605

#iptables -t nat -A PREROUTING -i bond0 -p tcp --dport 80 -j REDIRECT --to-port 32605
