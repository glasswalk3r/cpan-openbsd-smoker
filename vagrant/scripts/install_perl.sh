#!/usr/local/bin/bash
PERL=${1}
source "${HOME}/.bash_profile"
# some tests fails on OpenBSD and that's expected since the official Perl tests are changed
# Not enabling multi-core compiling since this will run in parallel with two users

if [ -z "${SMOKER_CFG}" ]
then
    echo "The variable SMOKER_CFG is not defined, cannot install perl modules without it!"
    echo "Aborting!"
    exit 1
fi

perlbrew install ${PERL} --notest

if [ $? -ne 0 ]
then
    echo "perlbrew install failed with ${?} error code, cannot continue"
    exit 1
fi

# if we don't receive an explicit perl version, we won't be able to switch to it without checking first
perlbrew switch ${PERL} 2> /dev/null
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
# first two must be installed separated and cpan client restarted
head -2 "${SMOKER_CFG}/modules/required.txt" | xargs cpan -T
total_lines=$(wc -l "${SMOKER_CFG}/modules/required.txt" | awk '{print $1}')
remaining=$((total_lines - 2))
tail -${remaining} "${SMOKER_CFG}/modules/required.txt" | xargs cpan -T
echo "Finished installing ${PERL} and required modules"
