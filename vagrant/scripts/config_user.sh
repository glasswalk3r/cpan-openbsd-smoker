#!/usr/local/bin/bash
CPAN_MIRROR=${1}
USER=${2}
PERL=${3}
BUILD_DIR=${4}
PROCESSORS=2

function create_profile() {
    USER=${1}
    echo "Create the .bash_profile"
    (cat <<END
if [ -e "/home/${USER}/.bashrc" ]
then
    source "/home/${USER}/.bashrc"
fi
source ~/perl5/perlbrew/etc/bashrc
END
) > "/home/${USER}/.bash_profile"

    echo "Create the .bashrc"
    (cat <<END
export CPAN_SQLITE_NO_LOG_FILES=1
export PATH=/home/${USER}/bin:$PATH

function start_smoker() {
    echo 'Cleaning up previous execution...'
    rm -rf $HOME/.cpan/build/* $HOME/.cpan/sources/authors/id $HOME/.cpan/FTPstats.yml*
    perl -MCPAN::Reporter::Smoker -e 'start(clean_cache_after => 50, install => 1)'
}
END
) > "/home/${USER}/.bashrc"
}

function config_cpan() {
    USER=${1}
    BUILD_DIR=${2}
    CPAN_BUILD_DIR="${BUILD_DIR}/${USER}"
    PREFS_DIR="/home/${USER}/.cpan/prefs"
    
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
  'build_dir' => q[/${CPAN_BUILD_DIR}],
  'build_dir_reuse' => q[0],
  'build_requires_install_policy' => q[yes],
  'bzip2' => q[/usr/local/bin/bzip2],
  'cache_metadata' => q[1],
  'check_sigs' => q[0],
  'colorize_output' => q[0],
  'commandnumber_in_prompt' => q[1],
  'connect_to_internet_ok' => q[1],
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
cpanm YAML::XS CPAN::SQLite Module::Version Log::Log4perl
# not sure if cpanm can handle bundles
(echo 'install Bundle::CPAN') | cpan
(echo 'install Bundle::CPAN::Reporter::Smoker::Tests') | cpan
cpanm Task::CPAN::Reporter CPAN::Reporter::Smoker Test::Reporter::Transport::Socket
echo 'Enabling test reporting'
(echo 'o conf test_report 1'; echo 'o conf commit') | cpan
echo 'User is almost ready to smoke tests by executing "start_smoker" in a shell'
echo <<BLOCK
Remember to execute the following next steps:
1 - Configure passwords for the new users with passwd
2 - Spend some time validating tests smoked. Tests will not be submitted automatically, but saved to a local directory before submission. This will give you a chance to validate the smoker configuration first.
3 - Once everything is fine, start the metabase-relayd application with the vagrant user
4 - Submit reports with the script bin/send_reports.pl
5 - If some distribution halts the smoker, block it with bin/block.pl
BLOCK
