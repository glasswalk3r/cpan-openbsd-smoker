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
perl -MCPAN -e "CPAN::Shell->notest('install', 'YAML::XS', 'CPAN::SQLite', 'Module::Version', 'Log::Log4perl')"
perl -MCPAN -e "CPAN::Shell->notest('install', 'Bundle::CPAN')"
perl -MCPAN -e "CPAN::Shell->notest('install', 'Bundle::CPAN::Reporter::Smoker::Tests')"
perl -MCPAN -e "CPAN::Shell->notest('install', 'Task::CPAN::Reporter', 'CPAN::Reporter::Smoker', 'Test::Reporter::Transport::Socket')"
perl -MCPAN -e "CPAN::Shell->notest('install', 'CPAN::Reporter::Smoker::OpenBSD')"
# to test DBD::mysql, currently DBD::mysql is failing the tests, forcing it's install
perl -MCPAN -e "CPAN::Shell->notest('install', 'Proc::ProcessTable', 'DBD::mysql')"
# TODO: these are LOTS of dependencies, and should be tested as well. Move those guys to start_smoker
# to test DBIx::Class completely under Mysql
perl -MCPAN -e "CPAN::Shell->notest('install', 'JSON::Any', 'Moose', 'MooseX::Types', 'MooseX::Types::JSON', 'MooseX::Types::LoadableClass', 'MooseX::Types::Path::Class', 'Class::DBI', 'JSON::DWIW', 'Time::Piece::MySQL')"
perl -MCPAN -e "CPAN::Shell->notest('install', 'DateTime', 'Text::CSV_XS', 'Getopt::Long::Descriptive', 'SQL::Translator', 'DateTime::Format::Strptime', 'DateTime::Format::SQLite', 'DateTime::Format::MySQL')"
echo "Finished installing ${PERL} and required modules"
