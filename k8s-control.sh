#!/bin/bash

set -e

# check if we are root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Check to see if the script has been run before. Exit out if so.
FILE=$HOME/k8s-control
if [ -f "$FILE" ]; then
    echo "WARNING!"
    echo "$FILE exists. Script has already been run on control plane."
    echo
    exit 1
else
    echo "$FILE does not exist. Running script"
fi

# Create a file when this script is started to keep it from running
# twice on same node
touch $FILE

HCLOUD_TOKEN=$1
PRIVATE_IP=$(hostname -I | grep -oP '10\.96\.\d{1,3}\.\d{1,3}')
HOSTNAME=$(hostname)
TAILSCALE_DNS="tail284a4.ts.net"
HETZNER_CLOUD_PROVIDER_VERSION="1.14.2"
KUBERNETES_VERSION="1.26.3"
CRICTL_VERSION="1.26.0"
API_SERVER_ADVERTISE_IP=${PRIVATE_IP}
POD_NETWORK_CIDR="10.128.0.0/16"
CALICO_VERSION="3.25.1"
HELM_VERSION="3.9.0"
SUBNET_NAME="kubenet"
YQ_VERSION="4.34.1"
HCLOUD_CHART_VERSION="1.15.0"
CSI_DRIVER_VERSION="2.3.2"
ARCH=$(uname -m)
if [ $ARCH == "x86_64" ];
then
    PACKAGES_ARCH="linux-amd64"
    YQ_ARCH="linux_amd64"
elif [ $ARCH == "aarch64" ]
then
    PACKAGES_ARCH="linux-arm"
    YQ_ARCH="linux_arm64"
else
    echo "Unsupported architecture detected"
    exit 1
fi

# Update the system
dnf update -y

# Install necessary software
dnf install curl git wget gnupg2 ca-certificates 'dnf-command(versionlock)' dnf-plugins-core kernel-modules-extra -y

wget https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_${YQ_ARCH} -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq

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
dnf install -y kubelet-${KUBERNETES_VERSION}-0.${ARCH} kubeadm-${KUBERNETES_VERSION}-0.${ARCH} kubectl-${KUBERNETES_VERSION}-0.${ARCH}
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
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-${PACKAGES_ARCH}.tar.gz
tar zxvf crictl-v${CRICTL_VERSION}-${PACKAGES_ARCH}.tar.gz
mv crictl /usr/local/bin

# Set the endpoints to avoid the deprecation error
crictl config \
    --set runtime-endpoint=unix:///run/containerd/containerd.sock \
    --set image-endpoint=unix:///run/containerd/containerd.sock

# Configure Hetzner as cloud provider as per https://github.com/hetznercloud/hcloud-cloud-controller-manager
mkdir -p /etc/systemd/system/kubelet.service.d
cat <<EOF | tee /etc/systemd/system/kubelet.service.d/20-hcloud.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external"
EOF

# Configure the cluster
kubeadm init --pod-network-cidr=${POD_NETWORK_CIDR} \
            --apiserver-advertise-address=${API_SERVER_ADVERTISE_IP} \
            --apiserver-cert-extra-sans=${API_SERVER_ADVERTISE_IP} \
            --apiserver-cert-extra-sans="${HOSTNAME}.${TAILSCALE_DNS}" \
            --upload-certs | tee /var/log/kubeinit.log

# expose controller-manager and scheduler for monitoring purposes
sed -e "s/- --bind-address=127.0.0.1/- --bind-address=0.0.0.0/" -i /etc/kubernetes/manifests/kube-controller-manager.yaml
sed -e "s/- --bind-address=127.0.0.1/- --bind-address=0.0.0.0/" -i /etc/kubernetes/manifests/kube-scheduler.yaml

# Configure the non-root user to use kubectl
mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Add Helm to make our life easier
wget https://get.helm.sh/helm-v${HELM_VERSION}-${PACKAGES_ARCH}.tar.gz
tar -xf helm-v${HELM_VERSION}-${PACKAGES_ARCH}.tar.gz
cp ${PACKAGES_ARCH}/helm /usr/local/bin/

# deploy hcloud-cloud-controller-manager
kubectl -n kube-system create secret generic hcloud --from-literal=token=$2 --from-literal=network=${SUBNET_NAME}
helm repo add hcloud https://charts.hetzner.cloud
helm repo update hcloud
helm upgrade --install hccm hcloud/hcloud-cloud-controller-manager -n kube-system \
                --version v${HCLOUD_CHART_VERSION} \
                --set networking.enabled=true \
                --set networking.clusterCIDR=${POD_NETWORK_CIDR} \
                --set monitoring.enabled=true \
                --set-json 'env.HCLOUD_NETWORK={"valueFrom":{"secretKeyRef":{"name":"hcloud","key":"network"}}}'

# Use Calico as the network plugin
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/tigera-operator.yaml

curl https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/custom-resources.yaml -o calico-custom-resources.yaml
yq -i ".spec.calicoNetwork.ipPools[0].cidr = \"${POD_NETWORK_CIDR}\"" calico-custom-resources.yaml

kubectl apply -f calico-custom-resources.yaml

kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v${CSI_DRIVER_VERSION}/deploy/kubernetes/hcloud-csi.yml

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

