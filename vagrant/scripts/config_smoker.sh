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
# TODO: configure automatically how to distribute the parallel tasks considering number
# of given processors and the number of users, also considering that perl setup will be
# done in parallel
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
    # TODO: remove this hardcode... the value should come from Vagrantfile
    config_script='/tmp/config_user.sh'
    # WORKAROUND: this is to avoid issues with strings containing spaces that might be interpreted
    # incorrectly by Bash, config_user.sh should read it from a file
    reports_from_config='/tmp/reports_from.cfg'
    echo "${REPORTS_FROM}" > "${reports_from_config}"
    
    # TODO: convert this shell script to Perl, in order to read a YAML file created by Vagrantfile and use
    # multiple arbitrary arguments like users and their respective settings
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
                params="file:///minicpan ${user} ${BUILD_DIR} ${reports_from_config} ${PREFS_DIR}"
            else
                params="${CPAN_MIRROR} ${user} ${BUILD_DIR} ${reports_from_config} ${PREFS_DIR}"
            fi
            # this script expects too many parameters to be practical to use with parallel... and should execute fast enough
            echo "Executing 'su -l ${user} -c \"${config_script} ${params}\"'"
            su -l ${user} -c "${config_script} ${params}"
        else
            echo ""${config_script}" not available, cannot continue"
            ls -l /tmp
            exit 1
        fi
        
        cd "${olddir}"
    done

    # this is an attempt to speed up things
    parallel --link '/tmp/run_user_install.sh {} {#}' ::: ${USER_1} ${USER_2} ::: ${USERS[${USER_1}]} ${USERS[${USER_2}]}

    rm -f "${reports_from_config}"
    touch "${idempotent_control}"
fi

now=$(date)
echo "Finished provisioning at ${now}"

