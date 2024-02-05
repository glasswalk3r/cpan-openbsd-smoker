packer {
  required_plugins {
    vagrant = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vagrant"
    }
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "vagrant_pub_ssh" {
  type        = string
  default     = "https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub"
  description = "An HTTP URL to Vagrant default SSH public key"
}

variable "openbsd_version" {
  type        = string
  description = "The OpenBSD version to be used for setup"
  default     = "7.0"
}

variable "openbsd_mirror" {
  type        = string
  description = "An URL of a OpenBSD HTTP mirror of the official repository"
  default     = ""
}

variable "openbsd_architecture" {
  type        = string
  description = "The OpenBSD processor architecture to use for setup"
  default     = "amd64"
  validation {
    condition     = var.openbsd_architecture == "amd64" || var.openbsd_architecture == "i386"
    error_message = "The openbsd_architecture must be amd64 or i386!"
  }
}

variable "timezone" {
  type        = string
  description = "The timezone to setup when creating the image"
  default     = ""
}

variable "iso_path" {
  type        = string
  description = "The complete path to the ISO image to use for install"
  default     = ""
}

variable "iso_sha" {
  type        = string
  description = "The ISO image SHA 256 checksum used for validating the ISO image"
  default     = ""
}

variable "guest_os_type" {
  type        = string
  description = "The Virtualbox Guest OS Type property to setup"
  default     = "OpenBSD_64"
  validation {
    condition     = var.guest_os_type == "OpenBSD" || var.guest_os_type == "OpenBSD_64"
    error_message = "OpenBSD and OpenBSD_64 are the only supported values for Virtualbox Guest OS Type!"
  }
}

variable "box" {
  type        = string
  description = "The name of the Vagrant box to generate at the end of installing the OS"
  default     = ""
}

locals {
  pkg_path = "https://${var.openbsd_mirror}/pub/OpenBSD/${var.openbsd_version}/packages/${var.openbsd_architecture}/"
  version_to_python_pkg = {
    "7.0" = "python-3.9.7",
    "7.1" = "python-3.9.12",
    "7.2" = "python-3.9.14",
    "7.3" = "python-3.11.2",
    "7.4" = "python-3.11.5"
  }
  python_pkg = local.version_to_python_pkg[var.openbsd_version]
}

source "virtualbox-iso" "openbsd" {
  boot_command = [
    "S<enter>",
    "cat <<EOF >> openbsd.disklabel<enter>",
    "/ 250M<enter>",
    "swap 1548M<enter>",
    "/home 35G<enter>",
    "/minicpan 5G<enter>",
    "/usr 10G<enter>",
    "/var 500M<enter>",
    "/tmp 1G-*<enter>",
    "EOF<enter>",
    "cat <<EOF >>install.conf<enter>",
    "System hostname = openbsd${var.openbsd_version}<enter>",
    "Which network interface do you wish to configure? (or 'done') em0<enter>",
    "IPv4 address for em0? (or 'dhcp' or 'none') dhcp<enter>",
    "Which network interface do you wish to configure? (or 'done') done<enter>",
    "Password for root = vagrant<enter>",
    "Setup a user = vagrant<enter>",
    "Password for user = vagrant<enter>",
    "Allow root ssh login = yes<enter>",
    "What timezone are you in = ${var.timezone}<enter>",
    "Location of sets = cd0<enter>",
    "Set name(s) = -game*.tgz -xshare*.tgz -xfont*.tgz -xserv*.tgz <enter>",
    "Directory does not contain SHA256.sig. Continue without verification = yes<enter>",
    "URL to autopartitioning template for disklabel = file:///openbsd.disklabel<enter>",
    "EOF<enter>",
    "install -af install.conf && reboot<enter>"
  ]
  boot_wait            = "30s"
  disk_size            = 55000
  guest_additions_mode = "disable"
  guest_os_type        = "${var.guest_os_type}"
  iso_checksum         = "sha256:${var.iso_sha}"
  iso_url              = "file://${var.iso_path}"
  output_directory     = ""
  shutdown_command     = "/sbin/halt -p"
  ssh_password         = "vagrant"
  ssh_username         = "root"
  ssh_wait_timeout     = "10000s"
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--memory", "2048"],
    ["modifyvm", "{{ .Name }}", "--cpus", "2"],
    ["modifyvm", "{{ .Name }}", "--natdnspassdomain1", "off"],
    ["modifyvm", "{{ .Name }}", "--natdnshostresolver1", "on"],
    ["modifyvm", "{{ .Name }}", "--uartmode1", "disconnected"],
    ["modifyvm", "{{ .Name }}", "--nic1", "nat", "--nictype1", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"],
    ["modifyvm", "{{ .Name }}", "--firmware", "bios"],
    ["modifyvm", "{{ .Name }}", "--ioapic", "off"]
  ]
  vm_name = "openbsd${var.openbsd_version}-base"
}

build {
  sources = [
    "source.virtualbox-iso.openbsd"
  ]

  provisioner "file" {
    source      = "packer/adduser.conf"
    destination = "/tmp/adduser.conf"
  }

  provisioner "file" {
    source      = "packer/mysql-perf.txt"
    destination = "/tmp/mysql-perf.txt"
  }

  provisioner "file" {
    source      = "packer/mariadb"
    destination = "/tmp/mariadb"
  }

  provisioner "file" {
    source      = "packer/mariadb-user.sql"
    destination = "/tmp/mariadb-user.sql"
  }

  provisioner "shell" {
    inline = [
      "mv /tmp/adduser.conf /etc/adduser.conf",
      "chmod 644 /etc/adduser.conf",
      "chown root.wheel /etc/adduser.conf"
    ]
  }

  provisioner "file" {
    source      = "packer/packages.txt"
    destination = "/tmp/packages.txt"
  }

  provisioner "shell" {
    environment_vars = [
      "PKG_PATH=${local.pkg_path}"
    ]
    inline = [
      "echo 'PS1=\"[\\u@\\h:\\w]$ \"' > /etc/profile",
      "echo 'PKG_PATH=${local.pkg_path}; export PKG_PATH' >> /root/.profile",
      "sed -i -e \"s#libpth => '/usr/lib /usr/lib'#libpth => '/usr/lib /usr/local/lib'#\" /usr/libdata/perl5/${var.openbsd_architecture}-openbsd/Config.pm",
      "sed -i -e \"s#libpth='/usr/lib /usr/lib'#libpth='/usr/lib /usr/local/lib'#\" /usr/libdata/perl5/${var.openbsd_architecture}-openbsd/Config_heavy.pl",
      "/usr/sbin/pkg_add ${local.python_pkg}",
      "/usr/sbin/pkg_add -l /tmp/packages.txt",
      "/usr/local/bin/mysql_install_db",
      "/usr/sbin/rcctl enable mysqld",
      "sed -i -E 's/^(log-bin=)/#\\1/' /etc/my.cnf",
      "sed -i -E 's/^(binlog_format=)/#\\1/' /etc/my.cnf",
      "/usr/sbin/rcctl start mysqld",
      "sed -i -f /tmp/mysql-perf.txt /etc/my.cnf",
      "/usr/sbin/rcctl restart mysqld",
      "/usr/local/bin/expect -f /tmp/mariadb",
      "/usr/local/bin/mysql -u root < /tmp/mariadb-user.sql",
      "echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers",
      "groupadd testers",
      "usermod -G wheel,testers vagrant",
      "mkdir /mnt/cpan_build_dir",
      "chgrp testers /mnt/cpan_build_dir",
      "chmod g+w /mnt/cpan_build_dir",
      "sed -i -E 's/^(PermitRootLogin )yes/\\1no/' /etc/ssh/sshd_config",
      "echo 'bootstraping vagrant user'",
      "/usr/bin/su vagrant -c 'mkdir -p /home/vagrant/.ssh'",
      "/usr/bin/su vagrant -c 'wget ${var.vagrant_pub_ssh} --output-document /home/vagrant/.ssh/authorized_keys'",
      "/usr/bin/su vagrant -c 'chmod 700 /home/vagrant/.ssh'",
      "/usr/bin/su vagrant -c 'chmod 600 /home/vagrant/.ssh/authorized_keys'"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      output = "${var.box}"
    }
    post-processor "checksum" {
      checksum_types = ["sha256"]
    }
  }
}
