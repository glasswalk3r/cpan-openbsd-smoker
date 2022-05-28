# cpan-openbsd-smoker

Configuration files and scripts to maintain a CPAN Smoker on OpenBSD

This project includes the following:

  * The CPAN-Reporter-Smoker-OpenBSD Perl distribution.
  * A set of CPAN "distroprefs" files to disable distributions that causes the
  smoker on OpenBSD to halt.
  * A Vagrant configuration file (`Vagrantfile`) and corresponding shell
  scripts for provisioning.
  * A VirtualBox image of OpenBSD, optimized to run a CPAN Smoker (available at
  Vagrant Cloud).
  * A Packer configuration file, used to create the base image that goes with
  Vagrant.
  * Most of the configuration with Vagrant is carried out with Ansible.

## The Vagrant provisioned VM

The associated VMs (see Vagranfile) with this project are based on Vagrant
(and Virtualbox as the provider) with the Smoker pre-configured on OpenBSD.
Many aspects of the VM can be customized during the provisioning phase, like:

  * Mirrors to be used (OpenBSD and CPAN).
  * Tests submitter identification.
  * Number of processors in the VM
  * Generic OS customizations like keyboard, time zone, etc.
  * A customable user with low privileges to execute the
  `CPAN::Reporter::Smoker` application.
  * Using a CPAN mirror: you can declare one already available on your local
  network, configure one inside the VM or do both!
  * The OpenBSD version you want to use (see `config.vm.box` available values).

The VM will have pre-installed and pre-configured:

  * the metabase-relayd to be executed under vagrant user.
  * a optional local CPAN mirror (implemented with
  [minicpan](http://search.cpan.org/search?query=minicpan&mode=all)).
  * related packages installed (like Git, compilers, etc).
  * a running Mysql server, configured to run extended tests of
  [DBD::mysql](http://search.cpan.org/search?query=DBD%3A%3Amysql&mode=dist)
  automatically.
  * shared "distroprefs" files for configuring (e.g. blocking) how
  distributions should be tested under the smoker.
  * several tools and libraries most used for modules that uses XS.
  * automatic updates for OpenBSD packages and the
  CPAN-Reporter-Smoker-OpenBSD distribution by running the provisioning again
  (idempotent controls are in place to execute only the necessary).
  * the command line utilities provided by CPAN-Reporter-Smoker-OpenBSD
  distribution.

Most of the process is documented at
[here](http://wiki.cpantesters.org/wiki/SmokerOnOpenBSD).

### Quick start

First clone this repository. Then go to the `vagrant` directory. You should
see the following structure:

```
.
├── metabase
│   └── copy your metabase.json here
├── scripts
│   ├── basic_setup.sh
│   ├── config_smoker.sh
│   ├── config_user.sh
│   └── vagrant_user.sh
└── Vagrantfile

```

Once there, you will find the `Vagrantfile`, where the definitions of the
`CPAN::Reporter::Smoker` VM.

You will want to look up for the section named "CONFIGURABLE STEPS". Some
options are required, others not. Make sure to read the comments, they are
currently the only documentation available.

Besides editing the Vagrantfile, you need to copy your `metabase_id.json` to
the `metabase` directory (there is even a tip over there ;-) ).

Finally, make sure you are in the same directory where the `Vagranfile` is
located and hit `vagrant up`.

After provisioning, all users including (including vagrant and root) have the
password setup to "vagrant". You might want to change that latter.

### On going usage

After initial provisioning, you will want to start your smoker with

```
vagrant up --provision
```
This project Vangratfile is prepared to implement idempotent operations, so only
the operations below will be repeated:

  * Updates OpenBSD packages.
  * Update your local CPAN mirror
  * Updates CPAN-Reporter-Smoker-OpenBSD distribution (available also at CPAN)
  for the vagrant and other users.
  * Updates the keyboard configuration based on the `Vagrantfile` respective
  option.

#### Troubleshooting

You might broke something meanwhile using. It might be easier to look for what
is wrong than just kill your VM and start from scratch.

### Packer

This project uses [Packer](https://www.packer.io/) to build the base image for
Vagrant. Packer allows the setup of the VM and install of OpenBSD automatically.

Unfortunately the format of the configuration file for Packer is JSON, which
doesn't allow for comments, so documentation is still to be developed.

Sections that you probably want to tweak with are:

* variables
* builders

After `git clone`ning the project, move to `cpan-openbsd-smoker/vagrant`, where
the `packer.json` is located and type:

```
$ packer build packer.json
```

#### Requirements

It is expected to have a local CPAN mirror (see `CPAN::Mini` module for that)
running in your local network/host at http://minicpan:8090. You can combine
your preferred web server with the `CPAN::Mini` mirror in order to achieve that.

# Maintenance

```
pkg_info -Q p5-Test- | sed -E 's/ \(installed\)//' | sed -E "s/^(p5-.*[a-zA-Z0-9])-.*/- \1/
```

A list of the Perl modules that needs to be installed through `cpan` are
available at the `modules` directory that includes:

- `required.txt`: the modules that are **required** for the Smoker to work. To
quickly enable the smoker, those modules should be installed without testing
first, then tested in order to have the structure to send reports.
- `extended_tests.txt`: the modules that enables more tests of the
distributions available, i.e., they are commonly included for testing only.

In both cases, only the Perl modules that **are not** included in the OpenBSD
package repository should be include, since those packages were already
validated and are installed much faster than using `cpan`.

### FAQ

#### Why a project for that?

It takes a considerable time to implement a CPAN smoker, so this project takes
care of automating most of it.

#### Does this works with any "basic" OpenBSD VM?

No. The VM specified in the `Vagrantfile` contains customizations. Besides, this
box already has required software installed, which reduces the provisioning time
substantially.

#### I'm a CPAN developer, can I use it for testing my own modules?

For sure you can. Any user added to the OpenBSD VM will be fully able to use
the CPAN client to test your code. There is also any tool you would require to
download, build and test your distributions.
