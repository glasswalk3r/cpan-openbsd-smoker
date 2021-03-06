#!/usr/local/bin/bash
# example of how this script is invoked
# su foo -c /tmp/config_user.sh http://mirror.nbtelecom.com.br/CPAN foo /mnt/cpan_build_dir 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>' /var/cpan/smoker/prefs
# ${1} is the script itself
echo "All parameters received: $@"
CPAN_MIRROR=${1}
USER=${2}
BUILD_DIR=${3}
REPORTS_FROM_CFG=${4}
PREFS_DIR=${5}

function create_profile() {
    local user=${1}
    local smoker_cfg=${2}
    local profile="/home/${user}/.bash_profile"
    local rc="/home/${user}/.bashrc"
    echo "Creating ${profile}"
    (cat <<END
if [ -e "${rc}" ]
then
    source "${rc}"
fi
source ~/perl5/perlbrew/etc/bashrc
END
) > "${profile}"


    local test_db=test
    local test_host=localhost
    local first_run="${smoker_cfg}/extended_tests_installed"

    echo "Creating ${rc}"
    (cat <<END
export CPAN_SQLITE_NO_LOG_FILES=1
export PATH=/home/${user}/bin:$PATH
# DBD::mysql extended testing
export DBD_MYSQL_TESTDB=${test_db}
export DBD_MYSQL_TESTHOST=${test_host}
export DBD_MYSQL_TESTPASSWORD=
export DBD_MYSQL_TESTPORT=3306
export DBD_MYSQL_TESTUSER=${user}
export EXTENDED_TESTING=1
# DBIx::Class extended tests
export DBICTEST_MYSQL_DSN=DBI:mysql:database=${test_db};host=${test_host}
export DBICTEST_MYSQL_USER=${user}
export DBICTEST_MYSQL_PASS=
export SMOKER_CFG="${smoker_cfg}"

function start_smoker() {
    echo 'Cleaning up previous executions...'
    rm -rf ${BUILD_DIR}/${user}/* $HOME/.cpan/sources/authors/id $HOME/.cpan/FTPstats.yml*
    find "\${PERLBREW_ROOT}" -name 'build.?perl-*.log' -delete
    local control="\${SMOKER_CFG}/extended_tests_installed"

    if ! [ -f "\${control}" ]
    then
        echo "First time running the Smoker, let's add some required modules for DBIx::Class extended tests..."
        cat "\${SMOKER_CFG}/modules/extended_tests.txt" | xargs cpan -i
        now=\$(date '+%Y-%m-%s %H:%M:%S')
        echo "All modules installed at \${now}, before first run" > "\${control}"
        echo "All done. Those steps will not be repeated again."
    fi

    perl -MCPAN::Reporter::Smoker -e 'start(clean_cache_after => 50, install => 1)'
}
END
) > "${rc}"
}

function config_cpan() {
    local USER=${1}
    local BUILD_DIR=${2}
    local CPAN_MIRROR=${3}
    local CPAN_BUILD_DIR="${BUILD_DIR}/${USER}"
    local PREFS_DIR=${4}

    if ! [ -d "${CPAN_BUILD_DIR}" ]
    then
        mkdir "${CPAN_BUILD_DIR}"
    fi

    mkdir -p "/home/${USER}/.cpan/CPAN"
    echo '$CPAN::Config = {' > "/home/${USER}/.cpan/CPAN/MyConfig.pm"
    (cat <<BLOCK
  'applypatch' => q[],
  'auto_commit' => q[0],
  'build_cache' => q[100],
  'build_dir' => q[${CPAN_BUILD_DIR}],
  'build_dir_reuse' => q[0],
  'build_requires_install_policy' => q[yes],
  'bzip2' => q[/usr/local/bin/bzip2],
  'cache_metadata' => q[1],
  'check_sigs' => q[0],
  'colorize_output' => q[0],
  'commandnumber_in_prompt' => q[1],
  'connect_to_internet_ok' => q[0],
  'cpan_home' => q[/home/${USER}/.cpan],
  'ftp_passive' => q[1],
  'ftp_proxy' => q[],
  'getcwd' => q[cwd],
  'gpg' => q[],
  'gzip' => q[/usr/bin/gzip],
  'halt_on_failure' => q[0],
  'histfile' => q[/home/${USER}/.cpan/histfile],
  'histsize' => q[100],
  'http_proxy' => q[],
  'inactivity_timeout' => q[60],
  'index_expire' => q[1],
  'inhibit_startup_message' => q[0],
  'keep_source_where' => q[/home/${USER}/.cpan/sources],
  'load_module_verbosity' => q[none],
  'make' => q[/usr/bin/make],
  'make_arg' => q[],
  'make_install_arg' => q[],
  'make_install_make_command' => q[/usr/bin/make],
  'makepl_arg' => q[],
  'mbuild_arg' => q[],
  'mbuild_install_arg' => q[],
  'mbuild_install_build_command' => q[./Build],
  'mbuildpl_arg' => q[],
  'no_proxy' => q[],
  'pager' => q[/usr/bin/less],
  'patch' => q[/usr/bin/patch],
  'perl5lib_verbosity' => q[none],
  'prefer_external_tar' => q[1],
  'prefer_installer' => q[MB],
  'prefs_dir' => q[${PREFS_DIR}],
  'prerequisites_policy' => q[follow],
  'recommends_policy' => q[1],
  'scan_cache' => q[atstart],
  'shell' => q[/usr/local/bin/bash],
  'show_unparsable_versions' => q[0],
  'show_upload_date' => q[0],
  'show_zero_versions' => q[0],
  'suggests_policy' => q[1],
  'tar' => q[/bin/tar],
  'tar_verbosity' => q[none],
  'term_is_latin' => q[1],
  'term_ornaments' => q[1],
  'test_report' => q[0],
  'trust_test_report_history' => q[0],
  'unzip' => q[/usr/local/bin/unzip],
  'urllist' => [q[${CPAN_MIRROR}],q[http://www.cpan.org/]],
  'use_prompt_default' => q[0],
  'use_sqlite' => q[1],
  'version_timeout' => q[15],
  'wget' => q[/usr/local/bin/wget],
  'yaml_load_code' => q[0],
  'yaml_module' => q[YAML:XS],
};
1;
__END__
BLOCK
) >> "/home/${USER}/.cpan/CPAN/MyConfig.pm"

}

function config_reporter() {
    local CFG_FILE=$1
    reports_from=$(cat "${CFG_FILE}")
    local cfg="${HOME}/.cpanreporter/config.ini"
    mkdir "${HOME}/.cpanreporter"
    mkdir "${HOME}/reports"
    echo 'edit_report=no' > "${cfg}"
    echo 'send_report=yes' >> "${cfg}"
    echo "email_from=${reports_from}" >> "${cfg}"
    echo "transport=File ${HOME}/reports" >> "${cfg}"
}

echo "Configuring ${USER}"
echo "Installing Perlbrew"
curl -s -L https://install.perlbrew.pl | bash

smoker_cfg="/home/${USER}/.smoker"

if ! [ -d "${smoker_cfg}" ]
then
    mkdir -p "${smoker_cfg}/modules"
fi

cp /tmp/required.txt "${smoker_cfg}/modules"
cp /tmp/extended_tests.txt "${smoker_cfg}/modules"

create_profile ${USER} "${smoker_cfg}"
source "${HOME}/.bash_profile"
config_cpan ${USER} "${BUILD_DIR}" "${CPAN_MIRROR}" "${PREFS_DIR}"
echo 'Done'
perlbrew version

if ! [ -d "/home/${USER}/bin" ]
then
    mkdir "/home/${USER}/bin"
fi

perlbrew install-cpanm
echo 'Enabling test reporting'
(echo 'o conf test_report 1'; echo 'o conf commit') | cpan
config_reporter "${REPORTS_FROM_CFG}"
echo "Finished configuring user ${USER}."
