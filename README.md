# cpan-openbsd-smoker
Configuration files and scripts to maintain a CPAN Smoker on OpenBSD

This project includes the following:

  * the CPAN-Reporter-Smoker-OpenBSD distribution.
  * CPAN preference files to disable distributions that causes the smoker on OpenBSD to halt.
  * Vagrantfile and corresponding shell scripts for provisioning

## Vagrant provisioned VM

This project also includes a Vagrant VM (based on Virtualbox) with the Smoker pre-configured on OpenBSD 6. Many aspects of the VM can be customized during the provisioning phase, like:

  * Mirrors to be used
  * Which perl to compile and use for the smoker
  * Tests submitter
  * number of processors in the VM (used for parallel tasks executing, for example)
  * Keyboard selection
  * Adds up to two users with low privileges to execute the CPAN::Reporter::Smoker application.
  
The VM will have pre-installed and pre-configured:

  * the metabase-relayd to be executed under vagrant user.
  * a CPAN mirror (minicpan).
  * related packages installed (like Git, compilers, etc)
  * the scripts provided by CPAN-Reporter-Smoker-OpenBSD distribution.
  
Most of the process is documented at [here](http://wiki.cpantesters.org/wiki/SmokerOnOpenBSD).

### Quick start

First clone this repository. Then go to the `vagrant` directory.

Once there, you will find the `Vagrantfile`, where the definitions of the CPAN::Reporter::Smoker VM. You will want to look up for the section named "CONFIGURABLE STEPS". Some options are required, others not. Make sure to read the comments, they are currently the only documentation available.
Finally, besides the Vagrantfile, you need only to copy your metabase_id.json to the `metabase` directory and hit `vagrant up`.
