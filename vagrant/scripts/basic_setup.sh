#!/usr/local/bin/bash
MIRROR_URL=http://openbsd.c3sl.ufpr.br/
export PKG_PATH=${MIRROR_URL}/pub/OpenBSD/$(uname -r)/packages/$(arch -s)/
echo "Updating existing packages"
pkg_add -u -I -a -x
echo "Installing required software"
pkg_add -v -I -a -x bzip2 unzip--iconv wget curl bash ntp tidyp
echo "Installing additional software"
pkg_add -I -a -x libxml gmp libxslt
chsh -s /usr/local/bin/bash vagrant
echo "Create the .bash_profile"
(cat <<END
if [ -e "/home/vagrant/.bashrc" ]
then
    source "/home/vagrant/.bashrc"
fi
source ~/perl5/perlbrew/etc/bashrc
END
) > /home/vagrant/.bash_profile

echo "Create the .bashrc"
(cat <<EOF
alias smoker = "perl -MCPAN::Reporter::Smoker -e 'start( clean_cache_after => 50, install => 1)'"
EOF
) > /home/vagrant/.bashrc

echo "Creating MFS for CPAN build_dir"
echo 'swap /mnt/cpan_build_dir mfs rw,async,nodev,nosuid,-s=512m 0 0' >> /etc/fstab
mkdir -p /mnt/cpan_build_dir
mount /mnt/cpan_build_dir
echo "Checking mounted disks"
mount
#echo "Installing Perlbrew"
#curl -L https://install.perlbrew.pl | bash