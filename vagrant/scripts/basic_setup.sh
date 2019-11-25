#!/usr/local/bin/bash
OPENBSD_MIRROR=${1}
KEYBOARD_LAYOUT=${2}
TIME_ZONE=${3}

export PKG_PATH=${OPENBSD_MIRROR}/pub/OpenBSD/$(uname -r)/packages/$(arch -s)/
idempotent_control=/var/vagrant_provision_basic

if ! [ -f "${idempotent_control}" ]
then
    echo "Installing required software..."
    pkg_add -l /tmp/packages.txt
fi

echo "Updating existing packages with ${PKG_PATH}..."
pkg_add -u -I -a -x
echo "Configuring the keyboard layout with ${KEYBOARD_LAYOUT}"
wsconsctl keyboard.encoding=${KEYBOARD_LAYOUT}
zic -l ${TIME_ZONE}
