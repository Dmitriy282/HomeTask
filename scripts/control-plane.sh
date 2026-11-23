#!/usr/bin/env bash
# Виконується на k8s-cp: встановлює k3s server.
set -euo pipefail

# IP та інтерфейс із host-only мережі (а не NAT 10.0.2.15)
NODE_IP=$(ip -4 -o addr show | awk '/192\.168\.56\./ {split($4, a, "/"); print a[1]; exit}')
IFACE=$(ip -4 -o addr show | awk '/192\.168\.56\./ {print $2; exit}')

if [ -z "${NODE_IP}" ]; then
  echo "ERROR: не знайдено IP у мережі 192.168.56.x" >&2
  exit 1
fi

if ! command -v k3s >/dev/null 2>&1; then
  # servicelb вимкнено — його місце займе MetalLB. Traefik лишається як Ingress.
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --node-ip=${NODE_IP} \
    --advertise-address=${NODE_IP} \
    --flannel-iface=${IFACE} \
    --tls-san=${NODE_IP} \
    --disable=servicelb \
    --write-kubeconfig-mode=644" sh -
fi

# Чекаємо, поки нода стане Ready (до 5 хв)
for _ in $(seq 1 60); do
  if kubectl get nodes 2>/dev/null | grep -q " Ready"; then
    break
  fi
  sleep 5
done

# Токен для воркерів і kubeconfig для WSL — через спільну папку /vagrant.
# ОБОВ'ЯЗКОВО в .gitignore: це секрети.
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token
sed "s/127.0.0.1/${NODE_IP}/" /etc/rancher/k3s/k3s.yaml > /vagrant/kubeconfig

kubectl get nodes -o wide
echo "control-plane: OK (${NODE_IP}, ${IFACE})"
