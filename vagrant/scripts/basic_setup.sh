#!/usr/local/bin/bash
OPENBSD_MIRROR=${1}
export PKG_PATH=${OPENBSD_MIRROR}/pub/OpenBSD/$(uname -r)/packages/$(arch -s)/
echo "Updating existing packages with ${PKG_PATH}"
pkg_add -u -I -a -x
idempotent_control=/var/git_provisioned

if [ -e "${idempotent_control}" ]
then
    echo "git already installed"
    exit 0
else
    pkg_add git
    touch "${idempotent_control}"
fi