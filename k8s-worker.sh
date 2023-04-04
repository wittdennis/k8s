#!/bin/bash

# check if we are root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Check to see if the script has been run before. Exit out if so.
FILE=$HOME/k8s-worker
if [ -f "$FILE" ]; then
    echo "WARNING!"
    echo "$FILE exists. Script has already been run. Do not run on control plane."
    echo "This should be run on the worker node."
    echo
    exit 1
else
    echo "$FILE does not exist. Running  script"
fi

# Create a file when this script is started to keep it from running
# on the control plane node.
touch $FILE

KUBERNETES_VERSION="1.26.3"
CRICTL_VERSION="1.26.0"

# Update the system
dnf update -y

# Install necessary software
dnf install curl git wget gnupg2 ca-certificates 'dnf-command(versionlock)' dnf-plugins-core kernel-modules-extra -y

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
dnf install -y kubelet-${KUBERNETES_VERSION}-0.x86_64 kubeadm-${KUBERNETES_VERSION}-0.x86_64 kubectl-${KUBERNETES_VERSION}-0.x86_64
dnf versionlock add kubelet
dnf versionlock add kubeadm
dnf versionlock add kubectl

tailscale up --authkey $1

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
net.ipv6.conf.all.forwarding = 1
EOF

sysctl --system

# Configure containerd settings
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
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz
tar zxvf crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz
mv crictl /usr/local/bin

# Set the endpoints to avoid the deprecation error
crictl config \
    --set runtime-endpoint=unix:///run/containerd/containerd.sock \
    --set image-endpoint=unix:///run/containerd/containerd.sock

# Ready to continue
sleep 3
echo
echo
echo '***************************'
echo
echo "Continue to the next step"
echo
echo "Use and copy over kubeadm join command from"
echo "control plane."
echo
echo '***************************'
echo
echo

