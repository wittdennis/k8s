#!/bin/bash

# check if we are root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Check to see if the script has been run before. Exit out if so.
FILE=/k8sControl
if [ -f "$FILE" ]; then
    echo "WARNING!"
    echo "$FILE exists. Script has already been run on control plane."
    echo
    exit 1
else
    echo "$FILE does not exist. Running script"
fi

KUBERNETES_VERSION="1.26.3"
CRICTL_VERSION="1.26"
POD_NETWORK_CIDR="10.244.0.0/16"
CALICO_VERSION="3.25.0"
HELM_VERSION="3.9.0"

# Create a file when this script is started to keep it from running
# twice on same node
touch /k8sControl

# Update the system
dnf update -y

# Install necessary software
dnf install curl apt-transport-https vim git wget gnupg2 software-properties-common apt-transport-https ca-certificates 'dnf-command(versionlock)' dnf-plugins-core -y

# Add repo for Kubernetes
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install the Kubernetes software, and lock the version
dnf install -y kubelet=${KUBERNETES_VERSION} kubeadm=${KUBERNETES_VERSION} kubectl=${KUBERNETES_VERSION}
dnf versionlock add kubelet
dnf versionlock add kubeadm
dnf versionlock add kubectl

# Ensure Kubelet is running
systemctl enable --now kubelet

# Disable swap just in case
swapoff -a

# Ensure Kernel has modules
modprobe overlay
modprobe br_netfilter

# Update networking to allow traffic
cat <<EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.default.forwarding = 1
EOF

sysctl --system

# Configure containerd settings
￼
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sysctl --system

# Install the containerd software
dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo
dnf install containerd.io -y

# Configure containerd and restart
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd


#  Create the config file so no more errors
# Install and configure crictl
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
tar zxvf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
mv crictl /usr/local/bin

# Set the endpoints to avoid the deprecation error
crictl config \
    --set runtime-endpoint=unix:///run/containerd/containerd.sock \
    --set image-endpoint=unix:///run/containerd/containerd.sock

# Configure the cluster
kubeadm init --pod-network-cidr=${POD_NETWORK_CIDR} | tee /var/log/kubeinit.log

# Configure the non-root user to use kubectl
mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Use Calico as the network plugin
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/calico.yaml

# Add Helm to make our life easier
wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz
tar -xf helm-v${HELM_VERSION}-linux-amd64.tar.gz
cp linux-amd64/helm /usr/local/bin/

sleep 9
# Output the state of the cluster
kubectl get node

# Ready to continue
sleep 3
echo
echo
echo '***************************'
echo
echo "Continue to the next step"
echo
echo '***************************'
echo

