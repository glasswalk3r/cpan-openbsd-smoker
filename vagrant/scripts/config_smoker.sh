#!/usr/local/bin/bash
# This script requires Bash 4
# to increase the number of users, consider using the same number of processors in the VM
echo $@
CPAN_MIRROR=${1}
USER_1=${2}
PERL_1=${3}
USER_2=${4}
PERL_2=${5}
BUILD_DIR=${6}
PROCESSORS=${7}
REPORTS_FROM=${8}
USE_LOCAL_MIRROR=${9}
PREFS_DIR=${10}
GROUP=testers

function mariadb_add_user() {
    local user=${1}
    echo "Adding ${user} to the local Mysql DB for DBD::mysql extended tests"
    local temp_file=$(mktemp)
    (cat <<BLOCK
grant all privileges on test.* to 'foo'@'localhost';
grant select on performance_schema.* to 'foo'@'localhost';
BLOCK
) > "${temp_file}"
    # ugly, but Mysql should be running for localhost only
    mysql -u root -pvagrant < "${temp_file}"
    rm "${temp_file}"
}

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
    echo "Expanding the file system again for /home..."
    previous=${PWD}
    cd /home
    dd if=/dev/zero of=bigemptyfile bs=1000 count=5000000
    rm bigemptyfile
    cd ${previous}
    echo "Adding users to ${GROUP} group"

    for user in ${USER_1} ${USER_2}
    do
        echo "Adding user ${user}"
        # password created with:
        # encrypt -c default vagrant
        adduser -batch "${user}" ${GROUP} "${user}" '$2b$10$jwgI5jv2x5d9VFFnU.I9s..f8ndKQqsBRb8wB/LapqqX.jKpt2/9q'
        mariadb_add_user ${user}
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
                cmd="/tmp/config_user.sh file:///minicpan ${user} ${USERS[${user}]} ${BUILD_DIR} ${PROCESSORS} ${reports_from_config} ${PREFS_DIR}"
            else
                cmd="/tmp/config_user.sh ${CPAN_MIRROR} ${user} ${USERS[${user}]} ${BUILD_DIR} ${PROCESSORS} ${reports_from_config} ${PREFS_DIR}"
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

