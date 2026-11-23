#!/usr/bin/env bash
# Виконується на k8s-w1, k8s-w2: приєднує ноду до кластера як k3s agent.
set -euo pipefail

CP_IP="192.168.56.10"
NODE_IP=$(ip -4 -o addr show | awk '/192\.168\.56\./ {split($4, a, "/"); print a[1]; exit}')
IFACE=$(ip -4 -o addr show | awk '/192\.168\.56\./ {print $2; exit}')

if [ -z "${NODE_IP}" ]; then
  echo "ERROR: не знайдено IP у мережі 192.168.56.x" >&2
  exit 1
fi

# Токен кладе control-plane.sh у спільну папку. Чекаємо до 5 хв.
for _ in $(seq 1 60); do
  [ -s /vagrant/node-token ] && break
  sleep 5
done

if [ ! -s /vagrant/node-token ]; then
  echo "ERROR: /vagrant/node-token не з'явився — спершу провіжн k8s-cp" >&2
  exit 1
fi

if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | \
    K3S_URL="https://${CP_IP}:6443" \
    K3S_TOKEN="$(cat /vagrant/node-token)" \
    INSTALL_K3S_EXEC="agent --node-ip=${NODE_IP} --flannel-iface=${IFACE}" sh -
fi

echo "worker: OK on $(hostname) (${NODE_IP}, ${IFACE})"
