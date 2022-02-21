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

## The Vagrant provisioned VM

The associated VMs (see Vagranfile) with this project are based on Vagrant
(and Virtualbox as the provider) with the Smoker pre-configured on OpenBSD.
Many aspects of the VM can be customized during the provisioning phase, like:

  * Mirrors to be used (OpenBSD and CPAN).
  * Which perl to compile and use for the smoker. This project uses
  [perlbrew](https://perlbrew.pl) to download perl source code and compiles a
  interpreter. Currently, all compile options supported by perlbrew can be used.
  * Tests submitter identification.
  * Number of processors in the VM: this correlate directly to the number of
  users/smokers you want to run in parallel.
  * Keyboard selection.
  * An arbitrary number of users with low privileges to execute the
  `CPAN::Reporter::Smoker` application.
  * Using a CPAN mirror: you can declare one already available on your local
  network, configure one inside the VM or do both! Well, not much useful
  configuration unless you just want to pre-initialize your VM local CPAN
  mirror first, then latter change the configuration.
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
This project Vangrafile is prepared to implement idempotent operations, so only
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

There is some automated tests available for the `vagrant` user configuration.
You can use it by logging in with `vagrant ssh` (or using SSH client directly)
and go into the directory `~/cpan-openbsd-smoker/vagrant/scripts`. From there
you can type `prove -l -vm -m` and checkout the results:

```
[vagrant@openbsd6:~/cpan-openbsd-smoker/vagrant/scripts]$ prove -v -m
t/provisioning.t ..
# Exit code is 0, output 'hw.ncpufound=2' and errors ''
ok 1 - the number of CPUs is 2 or more
# Exit code is 0, output 'hw.physmem=1606352896' and errors ''
ok 2 - available RAM is at least 1.5GB
ok 3 - /mnt/cpan_build_dir has the expected size
ok 4 - /tmp has the expected size
ok 5 - /usr has the expected size
ok 6 - /var has the expected size
ok 7 - /home has the expected size
ok 8 - / has the expected size
ok 9 - /minicpan has the expected size
ok 10 - vagrant user is part of wheel group
ok 11 - the group testers is available
ok 12 - vagrant user is part of testers group
ok 13 - the MFS partition has the correct directory permissions
# Exit code is 0, output '6.5' and errors ''
# Exit code of pkg_info is 0, errors ''
ok 14 - package bzip2 is installed
# binary search failed with unzip
ok 15 - package unzip is installed
ok 16 - package wget is installed
ok 17 - package curl is installed
ok 18 - package bash is installed
ok 19 - package ntp is installed
ok 20 - package tidyp is installed
ok 21 - package libxml is installed
ok 22 - package gmp is installed
ok 23 - package libxslt is installed
ok 24 - package mpfr is installed
ok 25 - package gd is installed
ok 26 - package pkg_mgr is installed
ok 27 - package mariadb-server is installed
ok 28 - package mariadb-client is installed
ok 29 - package sqlite3 is installed
ok 30 - Module::Version is installed
ok 31 - Bundle::CPAN is installed
ok 32 - Log::Log4perl is installed
ok 33 - Module::Pluggable is installed
ok 34 - POE::Component::Metabase::Client::Submit is installed
ok 35 - POE::Component::Metabase::Relay::Server is installed
ok 36 - metabase::relayd is installed
ok 37 - CPAN::Reporter::Smoker::OpenBSD is installed
# Specific for modules that are installed without passing the tests
ok 38 - POE::Component::SSLify is installed even though fail the tests
# Exit code of pkg_info is 0, errors ''
ok 39 - mariadb server is running
ok 40 - performance_schema directive is available in /etc/my.cnf
ok 41 - directive performance_schema is enabled on /etc/my.cnf
ok 42 - performance-schema-instrument directive is available in /etc/my.cnf
ok 43 - directive performance-schema-instrument is enabled on /etc/my.cnf
ok 44 - performance-schema-consumer-events-stages-current directive is available in /etc/my.cnf
ok 45 - directive performance-schema-consumer-events-stages-current is enabled on /etc/my.cnf
ok 46 - performance-schema-consumer-events-stages-history directive is available in /etc/my.cnf
ok 47 - directive performance-schema-consumer-events-stages-history is enabled on /etc/my.cnf
ok 48 - performance-schema-consumer-events-stages-history-long directive is available in /etc/my.cnf
ok 49 - directive performance-schema-consumer-events-stages-history-long is enabled on /etc/my.cnf
ok 50 - sshd config PermitRootLogin is disabled
1..50
ok
All tests successful.
Files=1, Tests=50,  1 wallclock secs ( 0.04 usr  0.01 sys +  0.34 cusr  0.21 csys =  0.60 CPU)
Result: PASS
```

Those tests don't cover everything, but might help you do some troubleshooting,
and will be executed right after the provisioning executed by `packer`.

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

No. The VM specified in the `Vagrantfile` contains customizations as documented
in [here](http://wiki.cpantesters.org/wiki/SmokerOnOpenBSD). Besides, this box
already has required software installed, which reduces the provisioning time
substantially.

#### I'm a CPAN developer, can I use it for testing my own modules?

For sure you can. Any user added to the OpenBSD VM will be fully able to use
the CPAN client to test your code. There is also any tool you would require to
download, build and test your distributions.
