#!/bin/bash

# Bootstrapping ready-to-use one-node K8S deployment on Ubuntu 16.04 (Xenial)

echo; echo "Install Docker"; echo

apt-get update && apt-get install -qy docker.io

echo; echo "Install Kubernetes apt repo"; echo

apt-get update
apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list

echo; echo "Install kubelet, kubeadm and kubernetes-cni"; echo

apt-get update
apt-get install -y kubelet kubeadm kubernetes-cni

echo; echo "Disabling SWAP"; echo

swapoff -a
sed -i '/swap/s/^/#/g' /etc/fstab

echo; echo "Extracting IP address and cluster initialzing"; echo

ADVERTISE_IP=$(hostname -I | cut -d' ' -f2)
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$ADVERTISE_IP

echo; echo "Setting up KUBECONFIG variable"; echo

export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=$KUBECONFIG" >> ~/.bashrc

echo; echo "Setting up Flannel"; echo

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml

echo; echo "Untaint Master nodes (for pods scheduling on a 1-node k8s cluster);" echo

kubectl taint nodes --all node-role.kubernetes.io/master-

echo; echo "NGINX ingress implementation (Baremetal)"; echo

docker build . -t my-default-http-backend
kubectl apply -f custom-nginx-ingress.yml # https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml

sleep 5;

NODEPORT_HTTP=$(kubectl -n ingress-nginx describe service/ingress-nginx | grep 'NodePort:.*http ' | awk '{ print $3 }'  | cut -d'/' -f1)
NODEPORT_HTTPS=$(kubectl -n ingress-nginx describe service/ingress-nginx | grep 'NodePort:.*https ' | awk '{ print $3 }'  | cut -d'/' -f1)

echo "Private IP: $ADVERTISE_IP"
echo "Ingress listening on $NODEPORT_HTTP (http) and $NODEPORT_HTTPS"

#vim /etc/haproxy/haproxy.cfg
#listen kube-ingress
#        bind *:80
#        balance roundrobin
#        option forwardfor
#        option httpchk
#        server node1 $ADVERTISE_IP:$NODEPORT_HTTP check

###
