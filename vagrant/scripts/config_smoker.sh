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
FROM=${9}

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
    echo "Adding smoker users"
    cd /tmp
    git clone https://github.com/glasswalk3r/cpan-openbsd-smoker.git
    chmod a+rx /tmp/cpan-openbsd-smoker
    chmod a+rx /tmp/cpan-openbsd-smoker/prefs
    chmod a+r /tmp/cpan-openbsd-smoker/prefs/*.yml

    for user in ${USER_1} ${USER_2}
    do
        echo "Adding user ${user}"
        groupadd "${user}"
        # login group fullname password
        adduser -batch "${user}" "${user}" "${user^}" "${user}"
        olddir=$PWD
        
        if [ -e "/tmp/config_user.sh" ]
        then
            # required to avoid permission errors
            cd "/home/${user}"
            cmd="/tmp/config_user.sh ${CPAN_MIRROR} ${user} ${USERS[${user}]} ${BUILD_DIR} ${PROCESSORS} ${FROM}"
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
echo <<BLOCK
Remember to execute the following manual steps after provisioning is finished:
1 - Configure passwords for the new users with passwd. Change the default password of vagrant user and configure a new SSH key for it.
2 - Spend some time validating tests results. Tests will not be submitted automatically, but saved to a local directory before submission. This will give you a chance to validate the smoker configuration first.
3 - Once everything is fine, start the metabase-relayd application with the vagrant user.
4 - Submit reports with the script bin/send_reports.pl.
5 - If some distribution halts the smoker, block it with bin/block.pl.
BLOCK

