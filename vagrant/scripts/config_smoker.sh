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
grant all privileges on test.* to '${user}'@'localhost';
grant select on performance_schema.* to '${user}'@'localhost';
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
    config_script='/tmp/config_user.sh'
    # WORKAROUND: this is to avoid issues with strings containing spaces that might be interpreted
    # incorrectly by Bash, config_user.sh should read it from a file
    reports_from_config='/tmp/reports_from.cfg'
    echo "${REPORTS_FROM}" > "${reports_from_config}"
    
    start=${SECONDS}
    for user in ${USER_1} ${USER_2}
    do
        echo "Adding user ${user} to ${GROUP} group"
        # password created with:
        # encrypt -c default vagrant
        adduser -shell bash -batch "${user}" "${GROUP}" "${user}" '$2b$10$jwgI5jv2x5d9VFFnU.I9s..f8ndKQqsBRb8wB/LapqqX.jKpt2/9q'
        mariadb_add_user ${user}
        olddir=$PWD
        
        if [ -f "${config_script}" ]
        then
	    echo "Configuring user with ${config_script}"
            # required to avoid permission errors
            cd "/home/${user}"

            if [ ${USE_LOCAL_MIRROR} == 'yes' ]
            then
                params="file:///minicpan ${user} ${USERS[${user}]} ${BUILD_DIR} ${PROCESSORS} ${reports_from_config} ${PREFS_DIR}"
            else
                params="${CPAN_MIRROR} ${user} ${USERS[${user}]} ${BUILD_DIR} ${PROCESSORS} ${reports_from_config} ${PREFS_DIR}"
            fi
            echo "Executing 'su -l ${user} -c \"${config_script} ${params}\"'"
            su -l ${user} -c "${config_script} ${params}"
        else
            echo "/tmp/config_user.sh not available, cannot continue"
            ls -l /tmp
            exit 1
        fi
        
        cd "${olddir}"
    done
    total=$(($SECONDS - $START))
    echo "Provisioning of users took ${total} seconds"

    rm -f "${config_script}"
    rm -f "${reports_from_config}"
    rm -rf /tmp/cpan-openbsd-smoker
    touch "${idempotent_control}"
fi

now=$(date)
echo "Finished provisioning at ${now}"

