#!/usr/local/bin/bash
CPAN_MIRROR=${1}
idempotent_control='/home/vagrant/.vagrant_provision'
local_repo=/home/vagrant/tmp

# requirements for vagrant user:
# - perlbrew
# - basic modules: YAML::XS CPAN::SQLite Module::Version Log::Log4perl 
# - required: CPAN::Mini CPAN::Mini::LatestDistVersion Dist::Zilla CPAN::Mini::Inject
# - cpanm --force POE::Component::SSLify -n (required, but broken)
# - The last modules (depend on the above): POE::Component::Metabase::Client::Submit POE::Component::Metabase::Relay::Server metabase::relayd
# - configure metabase-relayd

function mcpani_cfg() {
    local mirror=${1}
    local repo=${2}
    
    echo 'Configuring mcpani...'
    
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
     
     cat /home/vagrant/.mcpani/config
}

now=$(date)
echo "Starting vagrant configuration at ${now}"

if ! [ -f "${idempotent_control}" ]
then
    echo "Configuring vagrant user"
    echo 'Injecting CPAN-Reporter-Smoker-OpenBSD into local minicpan repository'
    git clone https://github.com/glasswalk3r/cpan-openbsd-smoker.git
    mcpani_cfg "${CPAN_MIRROR}" "${local_repo}"
    
    if [ $? -ne 0 ]
    then
        echo 'Failed to configure mcpani, cannot continue'
        exit 1
    fi
    
    (echo "o conf urllist file:///minicpan ${CPAN_MIRROR}"; echo 'o conf commit') | cpan
    cp /tmp/metabase_id.json /home/vagrant/.metabase/metabase_id.json
    chmod 400 /home/vagrant/.metabase/metabase_id.json
    touch "${idempotent_control}"    
    echo "Finished"
fi

echo 'Updating local CPAN mirror...'
cd
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
# to update the minicpan script as well
dzil install
dzil clean
minicpan -c CPAN::Mini::LatestDistVersion
mirror_cleanup
now=$(date)
echo "Finished at ${now}"
