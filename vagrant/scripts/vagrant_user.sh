#!/usr/local/bin/bash
CPAN_MIRROR=${1}
USE_LOCAL_MIRROR=${1}
idempotent_control='/home/vagrant/.vagrant_provision'

# requirements for vagrant user:
# - perlbrew
# - basic modules: YAML::XS CPAN::SQLite Module::Version Log::Log4perl 
# - required: CPAN::Mini CPAN::Mini::LatestDistVersion
# - cpanm --force POE::Component::SSLify -n (required, but broken)
# - The last modules (depend on the above): POE::Component::Metabase::Client::Submit POE::Component::Metabase::Relay::Server metabase::relayd CPAN::Reporter::Smoker::OpenBSD
# - configure metabase-relayd

now=$(date)
echo "Starting vagrant configuration at ${now}"

if ! [ -f "${idempotent_control}" ]
then
    echo "Configuring vagrant user"
    git clone https://github.com/glasswalk3r/cpan-openbsd-smoker.git
    if [ $? -ne 0 ]
    then 
        echo "Failed to execute git, aborting..."
        exit 1
    fi
    if ! [ -d /home/vagrant/.metabase ]
    then
        mkdir /home/vagrant/.metabase
    fi
    cp /tmp/metabase_id.json /home/vagrant/.metabase/metabase_id.json
    chmod 400 /home/vagrant/.metabase/metabase_id.json
    echo 'Installing required Perl modules...'
    cpanm POE::Component::Metabase::Client::Submit POE::Component::Metabase::Relay::Server metabase::relayd CPAN::Reporter::Smoker::OpenBSD

    if [ ${USE_LOCAL_MIRROR} == 'true' ]
    then
        minicpanrc=/home/vagrant/.minicpanrc
        echo 'local: /minicpan/' > "${minicpanrc}"
        echo "remote: ${CPAN_MIRROR}" >> "${minicpanrc}"
        echo 'also_mirror: indices/find-ls.gz' >> "${minicpanrc}"
        (echo "o conf urllist file:///minicpan ${CPAN_MIRROR}"; echo 'o conf commit') | cpan
        cpanm CPAN::Mini CPAN::Mini::LatestDistVersion 
        echo 'source ~/.bashrc' >> ~/.bash_profile
        echo "alias minicpan='minicpan -c CPAN::Mini::LatestDistVersion'" >> ~/.bashrc
        alias minicpan='minicpan -c CPAN::Mini::LatestDistVersion'
    else
        (echo "o conf urllist ${CPAN_MIRROR}"; echo 'o conf commit') | cpan
    fi
    touch "${idempotent_control}"    
    echo "Finished"
fi

echo 'Injecting preferences updates from Github...'
cd /home/vagrant/cpan-openbsd-smoker
git pull
echo 'Updating the minicpan shared preferences directory'
if [ -d /minicpan/prefs ]
then
    rm /minicpan/prefs/*.yml
else
    mkdir /minicpan/prefs
    # to enable smoker users to update the distro preferences
    sudo chgrp testers /minicpan/prefs
    sudo chmod g+w /minicpan/prefs
fi
cp prefs/*.yml /minicpan/prefs
if [ ${USE_LOCAL_MIRROR} == 'true' ]
then
    echo 'Updating local CPAN mirror...'
    minicpan
    mirror_cleanup
fi
cpanm CPAN::Reporter::Smoker::OpenBSD
now=$(date)
echo "Finished at ${now}"
