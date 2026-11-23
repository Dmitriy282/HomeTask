#!/usr/bin/env bash
# Виконується на всіх нодах: базова підготовка ОС під k3s.
set -euo pipefail

# Імена нод → IP, щоб ноди бачили одна одну за hostname
if ! grep -q "# k8s-homelab" /etc/hosts; then
  cat >> /etc/hosts <<'EOF'
# k8s-homelab
192.168.56.10 k8s-cp
192.168.56.11 k8s-w1
192.168.56.12 k8s-w2
EOF
fi

# Swap вимикаємо: kubelet погано з ним працює
swapoff -a
sed -i '/\sswap\s/ s/^#*/#/' /etc/fstab

# curl потрібен для інсталятора k3s
if ! command -v curl >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y -qq curl
fi

echo "common: OK on $(hostname)"
