#!/usr/local/bin/bash
# This script requires Bash 4
# to increase the number of users, consider using the same number of processors in the VM
OPENBSD_MIRROR=${1}
CPAN_MIRROR=${2}
USER_1=${3}
PERL_1=${4}
USER_2=${5}
PERL_2=${6}
BUILD_DIR=${7}

declare -A USERS
USERS[${USER_1}]=${PERL_1}
USERS[${USER_2}]=${PERL_2}

export PKG_PATH=${OPENBSD_MIRROR}/pub/OpenBSD/$(uname -r)/packages/$(arch -s)/
echo "Updating existing packages"
pkg_add -u -I -a -x

idempotent_control=/var/vagrant_provision_users

if [ -f "${idempotent_control}" ]; then
    exit 0
else
    echo "Adding smoker users"
    cd /tmp
    git clone https://github.com/glasswalk3r/cpan-openbsd-smoker.git

    for user in ${USER_1} ${USER_2}
    do
        groupadd "${user}"
        # login group fullname password
        adduser -batch "${user}" "${user}" "${user^}" "${user}"
        su ${user} "/tmp/config_user.sh ${CPAN_MIRROR} ${user} ${USERS[${user}] ${BUILD_DIR}"
        cp /tmp/cpan-openbsd-smoker/bin/send_reports.pl "/home/${user}/bin"
        cp /tmp/cpan-openbsd-smoker/bin/block.pl "/home/${user}/bin"
        cp /tmp/cpan-openbsd-smoker/
    done

    rm -f /tmp/config_user.sh
    rm -rf /tmp/cpan-openbsd-smoker
    touch "${idempotent_control}"
fi
