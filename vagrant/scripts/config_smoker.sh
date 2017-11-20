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
PROCESSORS=${8}
REPORTS_FROM=${9}
USE_LOCAL_MIRROR=${10}
GROUP=testers

declare -A USERS
USERS[${USER_1}]=${PERL_1}
USERS[${USER_2}]=${PERL_2}

now=$(date)
echo "Starting provisioning at ${now}"
idempotent_control=/var/vagrant_provision_users
echo "Using ${idempotent_control} to control provisioning"

if [ -f "${idempotent_control}" ]
then
    echo "All implemented, exiting..."
    exit 0
else
    echo "Adding users to ${GROUP} group"

    for user in ${USER_1} ${USER_2}
    do
        echo "Adding user ${user}"
        # login group fullname password
        adduser -batch "${user}" ${GROUP} "${user}" "${user}"
        olddir=$PWD
        
        if [ -e "/tmp/config_user.sh" ]
        then
            # required to avoid permission errors
            cd "/home/${user}"
            # WORKAROUND: this is to avoid issues with strings containing spaces that might be interpreted
            # incorrectly by Bash, config_user.sh should read it from a file
            reports_from_config='/tmp/reports_from.cfg'
            echo "${REPORTS_FROM}" > "${reports_from_config}"

            if [ ${USE_LOCAL_MIRROR} == 'yes' ]
            then
                cmd="/tmp/config_user.sh file:///minicpan ${user} ${USERS[${user}]} ${BUILD_DIR} ${PROCESSORS} ${reports_from_config}"
            else
                cmd="/tmp/config_user.sh ${CPAN_MIRROR} ${user} ${USERS[${user}]} ${BUILD_DIR} ${PROCESSORS} ${reports_from_config}"
            fi

            echo "executing su ${user} -c" "${cmd}"
            su ${user} -c "/tmp/config_user.sh ${cmd}"
        else
            echo "/tmp/config_user.sh not available, cannot continue"
            ls -l /tmp
            exit 1
        fi
        
        cd "${olddir}"
    done

    rm -f /tmp/config_user.sh
    rm -rf /tmp/cpan-openbsd-smoker
    touch "${idempotent_control}"
fi

now=$(date)
echo "Finished provisioning at ${now}"

