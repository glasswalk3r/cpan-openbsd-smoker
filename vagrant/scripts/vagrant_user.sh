#!/usr/local/bin/bash
CPAN_MIRROR=${1}
PROCESSORS=${2}
PERLBREW_URL=${3}
idempotent_control='/home/vagrant/.vagrant_provision'

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
    cpanm POE::Component::Metabase::Client::Submit POE::Component::Metabase::Relay::Server metabase::relayd -n
    echo "Create the .bash_profile"
    (cat <<END
if [ -e "/home/vagrant/.bashrc" ]
then
    source "/home/vagrant/.bashrc"
fi
source ~/perl5/perlbrew/etc/bashrc
END
    ) > /home/vagrant/.bash_profile

    (echo "o conf urllist push ${CPAN_MIRROR}"; echo 'o conf commit') | cpan

    (cat <<END
address=127.0.0.1
port=8080
idfile=/home/vagrant/.metabase/metabase_id.json
dbfile=/home/vagrant/.metabase/relayd
url=http://metabase.cpantesters.org/beta/
debug=1
multiple=1
END
    ) > "/home/${USER}/.bash_profile"
    touch "${idempotent_control}"
    cp -v /tmp/metabase_id.json /home/vagrant/.metabase/metabase_id.json
    chmod 400 /home/vagrant/.metabase/metabase_id.json
    cfg_metabase
    echo "Finished"
fi

echo "Updating local CPAN mirror..."
minicpan
now=$(date)
echo "Finished at ${now}"
