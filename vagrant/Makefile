CPAN_MIRROR:=$(shell echo 'o conf urllist' | cpan | awk '/0 \[/ {print $$2}' | tr -d '[]')
OPENBSD_MIRROR:=openbsd.c3sl.ufpr.br
OPENBSD_VERSION:=7.0
OPENBSD_ARCHITETURE:=amd64
TIMEZONE:=America/Sao_Paulo
ISO_DIR:=ISO
ISO_IMAGE:=install$(subst .,,${OPENBSD_VERSION}).iso
ISO_SHA:=$(shell curl -s ${OPENBSD_MIRROR}/openbsd/${OPENBSD_VERSION}/${OPENBSD_ARCHITETURE}/SHA256 | awk '/${ISO_IMAGE}/ {print $$4}')
BOX:=openbsd-${OPENBSD_VERSION}-cpan-smoker.box
NAMED_BOX:=arfreitas/openbsd-${OPENBSD_VERSION}-cpan-smoker

base:
	packer build -var 'local_mirror=${CPAN_MIRROR}' \
	-var 'openbsd_mirror=${OPENBSD_MIRROR}' \
	-var 'openbsd_architeture=${OPENBSD_ARCHITETURE}' \
	-var 'timezone=${TIMEZONE}' \
	-var 'iso_path=${PWD}/${ISO_DIR}/${ISO_IMAGE}' \
	-var 'iso_sha=${ISO_SHA}' -var 'box=${BOX}' \
	-var 'openbsd_version=${OPENBSD_VERSION}' packer.json
add:
	vagrant box list ${NAMED_BOX} > /dev/null && vagrant box remove ${NAMED_BOX}
	vagrant box add --name ${NAMED_BOX} ${BOX}
clean:
	@rm -f ${BOX} packer_virtualbox-iso_virtualbox-iso_sha256.checksum
init:
	@rm -rf ${ISO_DIR} && mkdir -p ${ISO_DIR} && rm -rf packer_cache/
	cd ISO && wget -c https://${OPENBSD_MIRROR}/pub/OpenBSD/${OPENBSD_VERSION}/${OPENBSD_ARCHITETURE}/${ISO_IMAGE}
	vagrant plugin install vagrant-vbguest
	pip install -U pip wheel setuptools && pip install -U ansible
