#!/usr/local/bin/bash
CPAN_MIRROR=${1}

echo "Configuring vagrant user"
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