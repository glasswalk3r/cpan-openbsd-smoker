#!/usr/local/bin/bash
# example of how this script is invoked
# su foo -c /tmp/config_user.sh http://mirror.nbtelecom.com.br/CPAN foo perl-5.20.3 /mnt/cpan_build_dir 2 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
# ${1} is the script itself
CPAN_MIRROR=${2}
USER=${3}
PERL=${4}
BUILD_DIR=${5}
PROCESSORS=${6}
REPORTS_FROM=${7}

function create_profile() {
    local user=${1}
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

    echo "Creating ${rc}"
    (cat <<END
export CPAN_SQLITE_NO_LOG_FILES=1
export PATH=/home/${USER}/bin:$PATH

function start_smoker() {
    echo 'Cleaning up previous execution...'
    rm -rf $HOME/.cpan/build/* $HOME/.cpan/sources/authors/id $HOME/.cpan/FTPstats.yml*
    perl -MCPAN::Reporter::Smoker -e 'start(clean_cache_after => 50, install => 1)'
}
END
) > "${rc}"
}

function config_cpan() {
    local USER=${1}
    local BUILD_DIR=${2}
    local CPAN_BUILD_DIR="${BUILD_DIR}/${USER}"
    local PREFS_DIR="/minicpan/prefs"
    
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
  'urllist' => [q[file:///minicpan]],
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
    local FROM=$1
    local cfg='.cpanreporter/config.ini'
    mkdir .cpanreporter
    mkdir reports
    echo 'edit_report=no' > "${cfg}"
    echo 'send_report=yes' >> "${cfg}"
    echo "email_from=${FROM}" >> "${cfg}"
    echo "transport=File /home/${USER}/reports" >> "${cfg}"
}

echo "Configuring ${USER}"
echo "Installing Perlbrew"
curl -L https://install.perlbrew.pl | bash
create_profile ${USER}
source "/home/${USER}/.bash_profile"
# some tests fails on OpenBSD and that's expected since the oficial Perl tests are changed
perlbrew install ${PERL} --notest -j ${PROCESSORS}
config_cpan ${USER} "${BUILD_DIR}"

if ! [ -d "/home/${USER}/bin" ]
then
    mkdir "/home/${USER}/bin"
fi

perlbrew install-cpanm
perlbrew switch ${PERL}
perlbrew clean

# using CPAN to be able to fetch from minicpan
perl -MCPAN -e "CPAN::Shell->notest('install', 'YAML::XS', 'CPAN::SQLite', 'Module::Version', 'Log::Log4perl')"
perl -MCPAN -e "CPAN::Shell->notest('install', 'Bundle::CPAN')"
perl -MCPAN -e "CPAN::Shell->notest('install', 'Bundle::CPAN::Reporter::Smoker::Tests')"
perl -MCPAN -e "CPAN::Shell->notest('install', 'Task::CPAN::Reporter', 'CPAN::Reporter::Smoker', 'Test::Reporter::Transport::Socket')"
perl -MCPAN -e "CPAN::Shell->notest('install', 'CPAN::Reporter::Smoker::OpenBSD')"
echo 'Enabling test reporting'
(echo 'o conf test_report 1'; echo 'o conf commit') | cpan
config_reporter "${REPORTS_FROM}"
echo "Finished configuring user ${USER}."

