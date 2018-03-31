#!/usr/local/bin/bash
source "${HOME}/.bash_profile"
# some tests fails on OpenBSD and that's expected since the official Perl tests are changed
# Not enabling multi-core compiling since this will run in parallel with two users

if [ -z "${SMOKER_CFG}" ]
then
    echo "The variable SMOKER_CFG is not defined, cannot install perl modules without it!"
    echo "Aborting!"
    exit 1
fi

install_info="${HOME}/install_perl.txt"
install_cmd=$(head -1 "${install_info}")
perl=$(tail -1 "${install_info}")

$install_cmd

if [ $? -ne 0 ]
then
    echo "perlbrew install failed with ${?} error code, cannot continue"
    exit 1
fi

# if we don't receive an explicit perl version, we won't be able to switch to it without checking first
perlbrew switch ${perl}
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
rm "${install_info}"
rm -f "${HOME}/perlbrew.*"

# using CPAN to be able to fetch from minicpan
echo 'Installing CPAN::SQLite and initializing the database...'
cpan -T CPAN::SQLite
echo 'reload index' | cpan
echo "Installing required modules as described at ${SMOKER_CFG}/modules/required.txt"
cat "${SMOKER_CFG}/modules/required.txt" | xargs cpan -T
echo "Finished installing ${perl} and required modules"
