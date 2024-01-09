CPAN_MIRROR:=$(shell echo 'o conf urllist' | cpan | awk '/0 \[/ {print $$2}' | tr -d '[]')
OPENBSD_MIRROR:=openbsd.c3sl.ufpr.br
OPENBSD_VERSION:=7.3
OPENBSD_STRIPPED_VERSION:=$(subst .,,${OPENBSD_VERSION})
TIMEZONE:=America/Sao_Paulo
ISO_DIR:=ISO
ISO_IMAGE:=install${OPENBSD_STRIPPED_VERSION}.iso
BASE_BOX:=openbsd-${OPENBSD_VERSION}-cpan-smoker
I386_BOX:=${BASE_BOX}-i386
AMD64_BOX:=${BASE_BOX}-amd64
VAGRANT_BOX_USER:=arfreitas
PACKER_CFG:=packer.pkr.hcl
MIRROR_BASE_URL:=https://${OPENBSD_MIRROR}/pub/OpenBSD/${OPENBSD_VERSION}

install_plugin:
	packer init packer.pkr.hcl
get_pub_key:
	mkdir -p ${ISO_DIR}
	cd ISO && wget -c https://ftp.openbsd.org/pub/OpenBSD/${OPENBSD_VERSION}/openbsd-${OPENBSD_STRIPPED_VERSION}-base.pub
i386: get_pub_key install_plugin
	cd ${ISO_DIR} && wget -c ${MIRROR_BASE_URL}/$@/${ISO_IMAGE} && wget -c ${MIRROR_BASE_URL}/$@/SHA256 && wget -c ${MIRROR_BASE_URL}/$@/SHA256.sig
	cd ${ISO_DIR} && signify-openbsd -Cp openbsd-${OPENBSD_STRIPPED_VERSION}-base.pub -x SHA256.sig install${OPENBSD_STRIPPED_VERSION}.iso
	packer build -var 'cpan_mirror=${CPAN_MIRROR}' \
		-var 'openbsd_mirror=${OPENBSD_MIRROR}' \
		-var 'openbsd_architecture=$@' \
		-var 'timezone=${TIMEZONE}' \
		-var 'iso_path=${PWD}/${ISO_DIR}/${ISO_IMAGE}' \
		-var "iso_sha=$(shell awk '/${ISO_IMAGE}/ {print $$4}' ISO/SHA256)" -var 'box=${I386_BOX}.box' \
		-var 'guest_os_type=OpenBSD' \
		-var 'openbsd_version=${OPENBSD_VERSION}' ${PACKER_CFG}
amd64: get_pub_key install_plugin
	cd ISO && wget -c ${MIRROR_BASE_URL}/$@/${ISO_IMAGE} && wget -c ${MIRROR_BASE_URL}/$@/SHA256 && wget -c ${MIRROR_BASE_URL}/$@/SHA256.sig
	cd ISO && signify-openbsd -Cp openbsd-${OPENBSD_STRIPPED_VERSION}-base.pub -x SHA256.sig install${OPENBSD_STRIPPED_VERSION}.iso
	packer build -var 'cpan_mirror=${CPAN_MIRROR}' \
		-var 'openbsd_mirror=${OPENBSD_MIRROR}' \
		-var 'openbsd_architecture=$@' \
		-var 'timezone=${TIMEZONE}' \
		-var 'iso_path=${PWD}/${ISO_DIR}/${ISO_IMAGE}' \
		-var "iso_sha=$(shell awk '/${ISO_IMAGE}/ {print $$4}' ISO/SHA256)" -var 'box=${AMD64_BOX}.box' \
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
	@rm -f ${ISO_DIR}/*.iso
	@rm -f ${ISO_DIR}/SHA256*
