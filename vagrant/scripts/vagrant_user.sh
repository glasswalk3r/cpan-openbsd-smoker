#!/usr/local/bin/bash

function cleanup_cpan() {
    rm -rf $HOME/.cpan/build/* $HOME/.cpan/sources/authors/id $HOME/.cpan/FTPstats.yml*
}

CPAN_MIRROR=${1}
USE_LOCAL_MIRROR=${2}
PREFS_DIR=${3}
idempotent_control='/home/vagrant/.vagrant_provision'

# requirements for vagrant user:
# - perlbrew
# - basic modules: YAML::XS CPAN::SQLite Module::Version Log::Log4perl
# - required: CPAN::Mini CPAN::Mini::LatestDistVersion
# - cpanm --force POE::Component::SSLify -n (required, but broken)
# - The last modules (depend on the above): POE::Component::Metabase::Client::Submit POE::Component::Metabase::Relay::Server metabase::relayd CPAN::Reporter::Smoker::OpenBSD
# - configure metabase-relayd

function config_metabase() {
    local metabase_id=/home/vagrant/.metabase/metabase_id.json
    if ! [ -d /home/vagrant/.metabase ]
    then
        mkdir /home/vagrant/.metabase
    fi
    cp /tmp/metabase_id.json "${metabase_id}"
    chmod 400 "${metabase_id}"

    (cat <<END
debug=1
idfile=${metabase_id}
dbfile=/home/vagrant/.metabase/relaydb
url=http://metabase.cpantesters.org/api/v1/
port=8080
multiple=1
END
) > /home/vagrant/.metabase/relayd

}

now=$(date)
echo "Starting vagrant configuration at ${now}"
source "${HOME}/perl5/perlbrew/etc/bashrc"
perl_version=$(perl -v)
echo -e "Using the following perl:\n${perl_version}"

if [ -f "${HOME}/.bash_profile" ]
then
    cat "${HOME}/.bash_profile"
else
    echo 'source ~/perl5/perlbrew/etc/bashrc' > "${HOME}/.bash_profile"
fi

if ! [ -f "${idempotent_control}" ]
then
    echo "Configuring vagrant user"

    if [ -d /home/vagrant/cpan-openbsd-smoker ]
    then
        cd /home/vagrant/cpan-openbsd-smoker
        git pull
    else
        git clone https://github.com/glasswalk3r/cpan-openbsd-smoker.git
    fi

    if [ $? -ne 0 ]
    then
        echo "Failed to execute git, aborting..."
        exit 1
    fi

    config_metabase

    if [ ${USE_LOCAL_MIRROR} == 'true' ]
    then
        echo 'Installing required Perl modules...'
        (echo "o conf urllist ${CPAN_MIRROR}"; echo 'o conf commit') | cpan
        cpan -i CPAN::SQLite
        (echo 'o conf use_sqlite 1'; echo 'o conf commit') | cpan
        echo "Using ${CPAN_MIRROR} as remote mirror for minicpan"
        minicpanrc=/home/vagrant/.minicpanrc
        local_mirror=/minicpan
        sudo chmod g+rwx "${local_mirror}"
        echo "local: ${local_mirror}" > "${minicpanrc}"
        echo "remote: ${CPAN_MIRROR}" >> "${minicpanrc}"
        echo 'also_mirror: indices/find-ls.gz' >> "${minicpanrc}"
        cpan -i CPAN::Mini CPAN::Mini::LatestDistVersion
        echo 'source ~/.bashrc' >> ~/.bash_profile
        echo "alias minicpan='minicpan -c CPAN::Mini::LatestDistVersion'" >> ~/.bashrc
        alias minicpan='minicpan -c CPAN::Mini::LatestDistVersion'
        echo "Adding now ${local_mirror} as preferred remote mirror for CPAN client"
        (echo "o conf urllist file://${local_mirror} ${CPAN_MIRROR}"; echo 'o conf commit') | cpan
    fi

    cleanup_cpan
    touch "${idempotent_control}"
    echo "Finished"
fi

echo "Setting CPAN client to use ${CPAN_MIRROR}"
(echo "o conf urllist ${CPAN_MIRROR}"; echo 'o conf commit') | cpan

# Even if the local CPAN mirror is not used, the preferences are still shared between the
# users, so it must be updated anyway
echo 'Injecting CPAN preferences updates from Github...'
cd /home/vagrant/cpan-openbsd-smoker
git pull
echo 'Updating the shared distribution preferences prefs_dir directory'
(echo "o conf prefs_dir ${PREFS_DIR}"; echo 'o conf commit') | cpan

if [ -d "${PREFS_DIR}" ]
then
    rm "${PREFS_DIR}/*.yml"
else
    sudo mkdir -p "${PREFS_DIR}"
    # to enable smoker users to add new distro preferences
    sudo chgrp testers "${PREFS_DIR}"
    sudo chmod g+w "${PREFS_DIR}"
fi

cp prefs/*.yml "${PREFS_DIR}"

if [ ${USE_LOCAL_MIRROR} == 'true' ]
then
    echo 'Updating local CPAN mirror...'
    minicpan -c CPAN::Mini::LatestDistVersion
    mirror_cleanup
fi

cpan -i CPAN::Reporter::Smoker::OpenBSD
cleanup_cpan
now=$(date)
echo "Finished at ${now}"
