#!/usr/local/bin/bash
OPENBSD_MIRROR=${1}
KEYBOARD_LAYOUT=${2}

export PKG_PATH=${OPENBSD_MIRROR}/pub/OpenBSD/$(uname -r)/packages/$(arch -s)/
echo "Updating existing packages with ${PKG_PATH}..."
pkg_add -u -I -a -x
echo "Configuring the keyboard layout with ${KEYBOARD_LAYOUT}"
wsconsctl keyboard.encoding=${KEYBOARD_LAYOUT}