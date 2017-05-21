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

# TODO: missing to add freetype, but that is available only with ports
# and I'm not sure if ports configuration can be automated
function install_pkgs() {
    local my_list='/root/pkgs.txt'
    echo "Installing required software"

    # this list should be kept up to date
    (cat <<PKGS
ap2-mod_wsgi-3.4p1  Python WSGI compliant interface module for Apache2
bash-4.4.12         GNU Bourne Again Shell
bzip2-1.0.6p8       block-sorting file compressor, unencumbered
collectd-5.6.2p2    system metrics collection engine
collectd-rrdtool-5.6.2p0 collectd rrdtool plugin
curl-7.53.1         get files from FTP, Gopher, HTTP or HTTPS servers
gd-2.1.1p3          library for dynamic creation of images
git-2.12.2          GIT - Tree History Storage Tool
gmp-6.1.2           library for arbitrary precision arithmetic
groff-1.22.3p3      GNU troff typesetter
libxml-2.9.4p0      XML parsing library
libxslt-1.1.29      XSLT C Library for GNOME
mariadb-client-10.0.30v1 multithreaded SQL database (client)
mariadb-server-10.0.30v1 multithreaded SQL database (server)
mariadb-tests-10.0.30v1 multithreaded SQL database (regression test suite/benchmark)
ntp-4.2.8pl10       Network Time Protocol reference implementation
py-pip-9.0.1p0      Python easy_install replacement
py-virtualenv-15.1.0p0 virtual Python environment builder
python-2.7.13p0     interpreted object-oriented programming language
quirks-2.304        exceptions to pkg_add rules
tidyp-1.04p1v0      validate, correct and pretty-print HTML
tree-0.62           print ascii formatted tree of a directory structure
unzip-6.0p10-iconv  extract, list & test files in a ZIP archive
wget-1.19.1         retrieve files from the web via HTTP, HTTPS and FTP
PKGS
) > "${my_list}"

   pkg_add -z -l "${my_list}" 
   rm "${my_list}"
}

function setup_mariadb() {
    local user_1=$1
    local user_2=$2

    echo "We will home a MariaDB server here to enable testing for DBD::mysql."
    echo "Initial configuration has some steps that cannot be automated, please follow up when requested."
    mysql_install_db
    /etc/rc.d/mysqld start

    # it is useless to try to automate this guy below
    # executing the SQL statements manually or running
    # expect over it will generate more maintenance if
    # the script itself is updated in the future (--defaults-file is useless so far)
    /usr/local/bin/mysql_secure_installation

    echo "Configuring DB access for smoker users"
    (cat <<BLOCK
grant all privileges on test.* to '${user_1}'@'localhost';
grant all privileges on test.* to '${user_2}'@'localhost';
grant select on performance_schema.* to '${user_1}'@'localhost';
grant select on performance_schema.* to '${user_2}'@'localhost';
BLOCK
) > temp.txt
    mysql -u root -p < temp.txt
    rm temp.txt
}

now=$(date)
echo "Starting provisioning at ${now}"
idempotent_control=/var/vagrant_provision_users
echo "Using ${idempotent_control} to control provisioning"

if [ -f "${idempotent_control}" ]
then
    echo "All implemented, exiting..."
    exit 0
else
    install_pkgs
    setup_mariadb ${USER_1} ${USER_2}

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

