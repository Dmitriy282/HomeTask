# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Ескіз: 1 control-plane + 1–2 workers для навчального кластера Kubernetes (kubeadm).
# Запуск:  vagrant up        | один вузол: vagrant up k8s-cp
# Доступ:  vagrant ssh k8s-cp

BOX          = "bento/ubuntu-24.04"   # або "bento/debian-12"
NETWORK      = "192.168.56"           # host-only мережа VirtualBox (діапазон за замовчуванням)
CP_IP        = "#{NETWORK}.10"
WORKER_COUNT = 2                      # 1 або 2

NODES = [
  { name: "k8s-cp", ip: CP_IP, cpus: 2, memory: 2048, role: "control-plane" }
] + (1..WORKER_COUNT).map do |i|
  { name: "k8s-w#{i}", ip: "#{NETWORK}.#{10 + i}", cpus: 1, memory: 1536, role: "worker" }
end

# "192.168.56.10 k8s-cp,192.168.56.11 k8s-w1,..." — для /etc/hosts на кожному вузлі
HOSTS = NODES.map { |n| "#{n[:ip]} #{n[:name]}" }.join(",")

Vagrant.configure("2") do |config|
  config.vm.box = BOX
  config.vm.boot_timeout = 300
  config.vm.box_check_update = false

  # Спільна підготовка всіх вузлів (виконується першою: outside-in порядок провіжнінгу)
  config.vm.provision "shell", name: "common", path: "scripts/common.sh",
    env: { "HOSTS" => HOSTS }

  NODES.each do |node|
    config.vm.define node[:name] do |n|
      n.vm.hostname = node[:name]
      n.vm.network "private_network", ip: node[:ip]
      n.vm.network "forwarded_port", guest: 22, host: 2200 + node[:ip].split(".").last.to_i, id: "ssh", host_ip: "127.0.0.1"
      n.vm.network "forwarded_port", guest: 6443, host: 6443, host_ip: "127.0.0.1" if node[:role] == "control-plane"

      n.vm.provider "virtualbox" do |vb|
        vb.name         = node[:name]
        vb.cpus         = node[:cpus]
        vb.memory       = node[:memory]
        vb.linked_clone = true            # швидше створення ВМ із базового образу
      end

      # Роль вузла: control-plane.sh або worker.sh
      n.vm.provision "shell", name: node[:role], path: "scripts/#{node[:role]}.sh",
        env: { "NODE_IP" => node[:ip], "CP_IP" => CP_IP }
    end
  end
end
