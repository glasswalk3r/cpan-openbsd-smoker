OPENBSD_MIRROR:=openbsd.c3sl.ufpr.br
OPENBSD_VERSION:=7.4
BASE_BOX:=openbsd-${OPENBSD_VERSION}-cpan-smoker
I386_BOX:=${BASE_BOX}-i386
AMD64_BOX:=${BASE_BOX}-amd64
VAGRANT_BOX_USER:=arfreitas
PACKER_CFG:=packer.pkr.hcl

warning:
	@echo 'Make sure to adjust the version!'

amd64: warning
	@echo get-iso.pl -arch=$@ -version=${OPENBSD_VERSION} -mirror ${OPENBSD_MIRROR}
i386: warning
	@echo get-iso.pl -arch=$@ -version=${OPENBSD_VERSION} -mirror ${OPENBSD_MIRROR}
packer:
	packer init packer.pkr.hcl
box:
	packer build -var-file=basic.pkrvars.hcl packer.pkr.hcl
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
	@rm -rf ${HOME}/.cache/packer/
init:
	pip install -U pip wheel setuptools && pip install -U ansible
clean-iso:
	@rm -rf ${ISO_DIR}