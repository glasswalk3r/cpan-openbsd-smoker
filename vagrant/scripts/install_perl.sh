#!/usr/local/bin/bash
PERL=${1}
source "${HOME}/.bash_profile"
# some tests fails on OpenBSD and that's expected since the official Perl tests are changed
# Not enabling multi-core compiling since this will run in parallel with two users
perlbrew install ${PERL} --notest
if ! [ $? -eq 0 ]
then
    echo "perlbrew install failed with ${?} error code, cannot continue"
    exit 1
fi

# if we don't receive an explicit perl version, we won't be able to switch to it without checking first
perlbrew switch ${PERL}
ret_code=$?
if [ ${ret_code} -ne 0 ]
then
    echo "perlbrew switch failed with ${ret_code} return code, trying 'perlbrew list' to fetch it"
    installed=$(perlbrew list | tail -1 | awk '{print $1}')
    perlbrew switch ${installed}
    ret_code=$?
    if [ ${ret_code} -ne 0 ]
    then
        echo "Failed to switch with '${installed}', aborting..."
        exit 1
    fi
fi
current_version=$(perl -e 'print "$]\n"')
echo "perl version in use is: ${current_version}"
perlbrew clean

# using CPAN to be able to fetch from minicpan
echo "Installing required modules as described at ${SMOKER_CFG}/modules/required.txt"
cat "${SMOKER_CFG}/modules/required.txt" | xargs cpan -T 
echo "Finished installing ${PERL} and required modules"
