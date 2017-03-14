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
echo "Updating existing packages with ${PKG_PATH}"
pkg_add -u -I -a -x
idempotent_control=/var/vagrant_provision_users
echo "Using ${idempotent_control} to control provisioning"

if [ -f "${idempotent_control}" ]
then
    echo "All implemented, exiting..."
    exit 0
else
    echo "Adding smoker users"
    pkg_add git
    cd /tmp
    git clone https://github.com/glasswalk3r/cpan-openbsd-smoker.git

    for user in ${USER_1} ${USER_2}
    do
        echo "Adding user ${user}"
        groupadd "${user}"
        # login group fullname password
        adduser -batch "${user}" "${user}" "${user^}" "${user}"
        
        if [ -e "/tmp/config_user.sh" ]
        then
            echo "executing su ${user}" "/tmp/config_user.sh ${CPAN_MIRROR} ${user} ${USERS[${user}]} ${BUILD_DIR}"
            su ${user} "/tmp/config_user.sh ${CPAN_MIRROR} ${user} ${USERS[${user}]} ${BUILD_DIR}"
            user_bin="/home/${user}/bin"
            
            if [ -d "${user_bin}" ]
            then
                cp /tmp/cpan-openbsd-smoker/bin/send_reports.pl "${user_bin}"
                cp /tmp/cpan-openbsd-smoker/bin/block.pl "${user_bin}"
            else
                echo "${user_bin} directory is not available, cannot copy smoker scripts!"
            fi
            
        else
            echo "/tmp/config_user.sh not available, cannot continue"
            exit 1
        fi
    done

    rm -f /tmp/config_user.sh
    rm -rf /tmp/cpan-openbsd-smoker
    touch "${idempotent_control}"
fi
