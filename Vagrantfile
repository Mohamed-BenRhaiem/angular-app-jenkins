Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.hostname = "recette"

  # IP privee accessible depuis l'hote (Jenkins)
  config.vm.network "private_network", ip: "192.168.56.10"

  # Expose le port 80 du container nginx sur l'hote
  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus   = 1
  end

  # Installation de Docker sur la VM de recette
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    usermod -aG docker vagrant
    systemctl enable --now docker
  SHELL
end
