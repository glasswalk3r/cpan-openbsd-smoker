#!/usr/local/bin/bash
CPAN_MIRROR=${1}
PROCESSORS=${2}
PERLBREW_URL=${3}
idempotent_control='/home/vagrant/.vagrant_provision'
local_repo=/home/vagrant/tmp

function cfg_metabase() {
    (cat <<BLOCK
address=127.0.0.1
port=8080
idfile=/home/vagrant/.metabase/metabase_id.json
dbfile=/home/vagrant/.metabase/relay.db
url=https://metabase.cpantesters.org/beta/
debug=1
multiple=1
BLOCK
    ) > /home/vagrant/.metabase/relayd
}

function mcpani_cfg() {
    local mirror=${1}
    local repo=${2}
    
    if ! [ -d "${repo}" ]
    then
        mkdir "${repo}"
    fi
    
    if ! [ -d /home/vagrant/.mcpani ]
    then
        mkdir /home/vagrant/.mcpani
    fi
    
    (cat <<BLOCK
local: /minicpan
remote: ${mirror}
repository: /home/vagrant/tmp    
BLOCK
     ) > /home/vagrant/.mcpani/config

}

now=$(date)
echo "Starting vagrant configuration at ${now}"

if ! [ -f "${idempotent_control}" ]
then
    echo "Configuring vagrant user"
    echo "Installing Perlbrew"
    curl -L ${PERLBREW_URL} | bash
    # some tests fails on OpenBSD and that's expected since the oficial Perl tests are changed
    perlbrew install ${PERL} --notest -j ${PROCESSORS}
    perlbrew install-cpanm
    perlbrew switch ${PERL}
    cpanm YAML::XS CPAN::SQLite Module::Version Log::Log4perl CPAN::Mini -n
    # it is expected to fail, but is required due the metabase-relayd requirements
    cpanm --force POE::Component::SSLify -n
    cpanm POE::Component::Metabase::Client::Submit POE::Component::Metabase::Relay::Server metabase::relayd Dist::Zilla CPAN::Mini::Inject -n
    echo 'Injecting CPAN-Reporter-Smoker-OpenBSD into local minicpan repository'
    git clone https://github.com/glasswalk3r/cpan-openbsd-smoker.git
    mcpani_cfg "${CPAN_MIRROR}" "${local_repo}"
    
    if [ $? -ne 0 ]
    then
        echo 'Failed to configure mcpani, cannot continue'
        exit 1
    fi
    
    echo "Creating the .bash_profile"
    (cat <<END
if [ -e "/home/vagrant/.bashrc" ]
then
    source "/home/vagrant/.bashrc"
fi
source ~/perl5/perlbrew/etc/bashrc
END
    ) > /home/vagrant/.bash_profile

    (echo "o conf urllist file:///minicpan ${CPAN_MIRROR}"; echo 'o conf commit') | cpan
    cp -v /tmp/metabase_id.json /home/vagrant/.metabase/metabase_id.json
    chmod 400 /home/vagrant/.metabase/metabase_id.json
    cfg_metabase
    touch "${idempotent_control}"    
    echo "Finished"
fi

echo 'Updating local CPAN mirror...'
cd
#minicpan
echo 'Injecting updates from Github...'
cd /home/vagrant/cpan-openbsd-smoker/CPAN-Reporter-Smoker-OpenBSD
git pull origin master
dzil authordeps --missing | cpanm -n
distro_version=$(grep version dist.ini | cut -d '=' -f2 | sed -e 's/ //g')
dzil build
tarball="CPAN-Reporter-Smoker-OpenBSD-${distro_version}.tar.gz"
rm -rf "${local_repo}/*"
mcpani --add --module CPAN::Reporter::Smoker::OpenBSD --authorid ARFREITAS --modversion ${distro_version} --file ./${tarball} --verbose
mcpani --inject --verbose

now=$(date)
echo "Finished at ${now}"
