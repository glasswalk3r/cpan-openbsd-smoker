CPAN_MIRROR:=$(shell echo 'o conf urllist' | cpan | awk '/0 \[/ {print $$2}' | tr -d '[]')
OPENBSD_MIRROR:=openbsd.c3sl.ufpr.br
OPENBSD_VERSION:=7.1
TIMEZONE:=America/Sao_Paulo
ISO_DIR:=ISO
ISO_IMAGE:=install$(subst .,,${OPENBSD_VERSION}).iso
ISO_AMD64_SHA:=$(shell curl -s ${OPENBSD_MIRROR}/openbsd/${OPENBSD_VERSION}/amd64/SHA256 | awk '/${ISO_IMAGE}/ {print $$4}')
ISO_I386_SHA:=$(shell curl -s ${OPENBSD_MIRROR}/openbsd/${OPENBSD_VERSION}/i386/SHA256 | awk '/${ISO_IMAGE}/ {print $$4}')
I386_BOX:=openbsd-${OPENBSD_VERSION}-cpan-smoker-i386
AMD64_BOX:=openbsd-${OPENBSD_VERSION}-cpan-smoker-amd64
VAGRANT_BOX_USER:=arfreitas
PACKER_CFG:=packer.pkr.hcl

i386:
	cd ISO && wget -c https://${OPENBSD_MIRROR}/pub/OpenBSD/${OPENBSD_VERSION}/$@/${ISO_IMAGE}
	packer build -var 'cpan_mirror=${CPAN_MIRROR}' \
		-var 'openbsd_mirror=${OPENBSD_MIRROR}' \
		-var 'openbsd_architecture=$@' \
		-var 'timezone=${TIMEZONE}' \
		-var 'iso_path=${PWD}/${ISO_DIR}/${ISO_IMAGE}' \
		-var 'iso_sha=${ISO_I386_SHA}' -var 'box=${I386_BOX}.box' \
		-var 'guest_os_type=OpenBSD' \
		-var 'openbsd_version=${OPENBSD_VERSION}' ${PACKER_CFG}
amd64:
	cd ISO && wget -c https://${OPENBSD_MIRROR}/pub/OpenBSD/${OPENBSD_VERSION}/$@/${ISO_IMAGE}
	packer build -var 'cpan_mirror=${CPAN_MIRROR}' \
		-var 'openbsd_mirror=${OPENBSD_MIRROR}' \
		-var 'openbsd_architecture=$@' \
		-var 'timezone=${TIMEZONE}' \
		-var 'iso_path=${PWD}/${ISO_DIR}/${ISO_IMAGE}' \
		-var 'iso_sha=${ISO_AMD64_SHA}' -var 'box=${AMD64_BOX}.box' \
		-var 'guest_os_type=OpenBSD_64' \
		-var 'openbsd_version=${OPENBSD_VERSION}' ${PACKER_CFG}
add-i386:
	@if vagrant box list | grep ${VAGRANT_BOX_USER}/${I386_BOX}; then vagrant box remove ${VAGRANT_BOX_USER}/${I386_BOX}; fi
	vagrant box add --name ${VAGRANT_BOX_USER}/${I386_BOX} ${I386_BOX}.box
add-amd64:
	@if vagrant box list | grep ${VAGRANT_BOX_USER}/${AMD64_BOX}; then vagrant box remove ${VAGRANT_BOX_USER}/${AMD64_BOX}; fi
	vagrant box add --name ${VAGRANT_BOX_USER}/${AMD64_BOX} ${AMD64_BOX}.box
clean: clean-iso
	@rm -f *.box
	@rm -f packer_openbsd_virtualbox-iso_sha256.checksum
	@rm -rf packer_cache
init:
	pip install -U pip wheel setuptools && pip install -U ansible
clean-iso:
	@rm -rf ${ISO_DIR} && mkdir -p ${ISO_DIR} && rm -rf packer_cache/
