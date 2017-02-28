#!/bin/ksh
# this script is kept only for "documentation" purpouses
# it shouldn't be necessary to execute it unless you want to build the OpenBSD VM from scratch
# since all changed promoted here so be already implemented in the VM provisioned by Vagrant
MIRROR_URL=http://openbsd.c3sl.ufpr.br/
export PKG_PATH=${MIRROR_URL}/pub/OpenBSD/$(uname -r)/packages/$(arch -s)/
echo "Updating existing packages"
pkg_add -u -I -a -x
echo "Installing required software"
pkg_add -v -I -a -x bzip2 unzip--iconv wget curl bash ntp tidyp
echo "Installing additional software"
pkg_add -I -a -x libxml gmp libxslt
chsh -s /usr/local/bin/bash vagrant
echo "Creating MFS for CPAN build_dir"
echo 'swap /mnt/cpan_build_dir mfs rw,async,nodev,nosuid,-s=512m 0 0' >> /etc/fstab
mkdir -p /mnt/cpan_build_dir
# each user should have it's private directory under it
chmod a+w /mnt/cpan_build_dir
mount /mnt/cpan_build_dir
echo "Checking mounted disks"
mount
echo 'Now you should run vagrant_user.sh script (with vagrant user!)'