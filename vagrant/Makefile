CPAN_MIRROR:=$(shell echo 'o conf urllist' | cpan | awk '/0 \[/ {print $$2}' | tr -d '[]')
OPENBSD_MIRROR:=openbsd.c3sl.ufpr.br
OPENBSD_VERSION:=7.0
TIMEZONE:=America/Sao_Paulo
ISO_DIR:=ISO
ISO_IMAGE:=install$(subst .,,${OPENBSD_VERSION}).iso
ISO_AMD64_SHA:=$(shell curl -s ${OPENBSD_MIRROR}/openbsd/${OPENBSD_VERSION}/amd64/SHA256 | awk '/${ISO_IMAGE}/ {print $$4}')
ISO_I386_SHA:=$(shell curl -s ${OPENBSD_MIRROR}/openbsd/${OPENBSD_VERSION}/i386/SHA256 | awk '/${ISO_IMAGE}/ {print $$4}')
BOX:=openbsd-${OPENBSD_VERSION}-cpan-smoker.box
NAMED_BOX:=arfreitas/openbsd-${OPENBSD_VERSION}-cpan-smoker

i386:
	cd ISO && wget -c https://${OPENBSD_MIRROR}/pub/OpenBSD/${OPENBSD_VERSION}/$@/${ISO_IMAGE}
	packer build -var 'local_mirror=${CPAN_MIRROR}' \
		-var 'openbsd_mirror=${OPENBSD_MIRROR}' \
		-var 'openbsd_architecture=$@' \
		-var 'timezone=${TIMEZONE}' \
		-var 'iso_path=${PWD}/${ISO_DIR}/${ISO_IMAGE}' \
		-var 'iso_sha=${ISO_I386_SHA}' -var 'box=${BOX}' \
		-var 'guest_os_type=OpenBSD' \
		-var 'openbsd_version=${OPENBSD_VERSION}' packer.json
amd64:
	cd ISO && wget -c https://${OPENBSD_MIRROR}/pub/OpenBSD/${OPENBSD_VERSION}/$@/${ISO_IMAGE}
	packer build -var 'local_mirror=${CPAN_MIRROR}' \
		-var 'openbsd_mirror=${OPENBSD_MIRROR}' \
		-var 'openbsd_architecture=$@' \
		-var 'timezone=${TIMEZONE}' \
		-var 'iso_path=${PWD}/${ISO_DIR}/${ISO_IMAGE}' \
		-var 'iso_sha=${ISO_AMD64_SHA}' -var 'box=${BOX}' \
		-var 'guest_os_type=OpenBSD_64' \
		-var 'openbsd_version=${OPENBSD_VERSION}' packer.json
add:
	vagrant box list ${NAMED_BOX} > /dev/null && vagrant box remove ${NAMED_BOX}
	vagrant box add --name ${NAMED_BOX} ${BOX}
clean:
	@rm -f ${BOX} packer_virtualbox-iso_virtualbox-iso_sha256.checksum
	@rm -rf packer_cache
init:
	vagrant plugin install vagrant-vbguest
	pip install -U pip wheel setuptools && pip install -U ansible
clean-iso:
	@rm -rf ${ISO_DIR} && mkdir -p ${ISO_DIR} && rm -rf packer_cache/

