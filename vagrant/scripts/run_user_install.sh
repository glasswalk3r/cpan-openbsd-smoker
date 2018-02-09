#!/usr/local/bin/bash
# creating for the single purpose of running install_perl with parallel

USER=${1}
PERL=${2}
JOB_NUMBER=${3}
echo "${USER} will attempt to install ${PERL} in job number ${JOB_NUMBER}"
su -l ${USER} -c "/tmp/install_perl.sh ${PERL}"
echo 'Done'