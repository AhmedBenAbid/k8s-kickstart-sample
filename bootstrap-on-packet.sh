#!/bin/bash

# Bootstrapping ready-to-use one node K8S on Ubuntu 16.04 (Xenial)

# Install Kubernetes apt repo
apt-get update
apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update

# Install kubelet, kubeadm and kubernetes-cni
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
