# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Box
  config.vm.box = "centos70"
  config.vm.box_url = "https://www.dur.ac.uk/resources/cis/vagrant/centos70.box"

  config.vm.post_up_message = "Sufia development box ready."

  config.vm.provider "virtualbox" do |v|
    v.name = "sufia-dev-vm"
    v.memory = 2048
    v.cpus = 2
  end

  # Hostname
  #config.vm.hostname = "sufia-dev-vm"

  # Port forwards
  config.vm.network :forwarded_port, guest: 3000, host: 3000
  config.vm.network :forwarded_port, guest: 8983, host: 8983

  # Shared directories

  # Disabling the default mount is only required for Vagrant < 1.6
  if Vagrant::VERSION =~ /^1.[0-5]/
    config.vm.synced_folder ".", "/vagrant", disabled:true
  end
  config.vm.synced_folder "./vagrant", "/vagrant"
  config.vm.synced_folder ".", "/opt/sufia"

  # Provisioning
  config.vm.provision "shell", path: "vagrant/root-provision.sh"
  config.vm.provision "shell", path: "vagrant/user-provision.sh", privileged: false
  config.vm.provision "shell", path: "vagrant/root-provision-resque.sh"

end
