#!/usr/local/bin/bash
# Bootstraps the VM configuration for the vagrant user

source functions/cpan

function config_cpan() {
    mkdir -p "/home/${USER}/.cpan/CPAN"
    echo '$CPAN::Config = {' > "/home/vagrant/.cpan/CPAN/MyConfig.pm"
    (cat <<BLOCK
    'applypatch' => q[],
    'auto_commit' => q[0],
    'build_cache' => q[100],
    'build_dir' => q[/mnt/cpan_build_dir],
    'build_dir_reuse' => q[0],
    'build_requires_install_policy' => q[yes],
    'bzip2' => q[/usr/local/bin/bzip2],
    'cache_metadata' => q[1],
    'check_sigs' => q[0],
    'cleanup_after_install' => q[1],
    'colorize_output' => q[0],
    'commandnumber_in_prompt' => q[1],
    'connect_to_internet_ok' => q[0],
    'cpan_home' => q[/home/vagrant/.cpan],
    'ftp_passive' => q[1],
    'ftp_proxy' => q[],
    'getcwd' => q[cwd],
    'gpg' => q[],
    'gzip' => q[/usr/bin/gzip],
    'halt_on_failure' => q[0],
    'histfile' => q[/home/vagrant/.cpan/histfile],
    'histsize' => q[100],
    'http_proxy' => q[],
    'inactivity_timeout' => q[0],
    'index_expire' => q[1],
    'inhibit_startup_message' => q[0],
    'keep_source_where' => q[/home/vagrant/.cpan/sources],
    'load_module_verbosity' => q[none],
    'make' => q[/usr/bin/make],
    'make_arg' => q[-j3],
    'make_install_arg' => q[-j3],
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
    'prefs_dir' => q[/home/vagrant/.cpan/prefs],
    'prerequisites_policy' => q[follow],
    'recommends_policy' => q[1],
    'scan_cache' => q[atstart],
    'shell' => q[/usr/local/bin/bash],
    'show_unparsable_versions' => q[0],
    'show_upload_date' => q[0],
    'show_zero_versions' => q[0],
    'suggests_policy' => q[0],
    'tar' => q[/bin/tar],
    'tar_verbosity' => q[none],
    'term_is_latin' => q[0],
    'term_ornaments' => q[1],
    'test_report' => q[0],
    'trust_test_report_history' => q[0],
    'unzip' => q[/usr/local/bin/unzip],
    'urllist' => [q[http://minicpan:8090/]],
    'use_prompt_default' => q[0],
    'use_sqlite' => q[1],
    'version_timeout' => q[15],
    'wget' => q[/usr/local/bin/wget],
    'yaml_load_code' => q[0],
    'yaml_module' => q[YAML::XS],
  };
  1;
  __END__
BLOCK
    ) > "/home/vagrant/.cpan/CPAN/MyConfig.pm"
}

config_cpan
curl -s -L https://install.perlbrew.pl | bash
perlbrew install perl-stable --noman --notest -j 2 --as perl-stable
perlbrew install-cpanm
source ~/perl5/perlbrew/etc/bashrc
echo 'source ~/perl5/perlbrew/etc/bashrc' > .bash_profile
perlbrew switch perl-stable
cpanm --mirror http://minicpan:8090 --mirror-only Module::Version Bundle::CPAN Log::Log4perl Module::Pluggable
cpanm --mirror http://minicpan:8090 --mirror-only --notest POE::Component::SSLify
cpanm --mirror http://minicpan:8090 --mirror-only POE::Component::Metabase::Client::Submit POE::Component::Metabase::Relay::Server metabase::relayd CPAN::Reporter::Smoker::OpenBSD List::BinarySearch Filesys::Df
perlbrew cleanup
cleanup_cpan
cd /home/vagrant/cpan-openbsd-smoker/vagrant/scripts
prove -l -v -m