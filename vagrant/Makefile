.SHELLFLAGS:=-Command
SHELL:=powershell.exe

CPAN_MIRROR:=http://mirror.pop-sc.rnp.br/CPAN/
OPENBSD_MIRROR:=cdn.openbsd.org
OPENBSD_VERSION:=7.2
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
# far faster than Powershell wget cmdlet
WGET:=wget2 --progress bar --continue
PWD:=C:\Projetos\cpan-openbsd-smoker\vagrant

get_pub_key:
	@powershell wget -Uri https://ftp.openbsd.org/pub/OpenBSD/${OPENBSD_VERSION}/openbsd-${OPENBSD_STRIPPED_VERSION}-base.pub -OutFile openbsd-${OPENBSD_STRIPPED_VERSION}-base.pub
i386: get_pub_key
	cd ISO && ${WGET} -c ${MIRROR_BASE_URL}/$@/${ISO_IMAGE} && ${WGET} -c ${MIRROR_BASE_URL}/$@/SHA256 && ${WGET} -c ${MIRROR_BASE_URL}/$@/SHA256.sig
	packer build -var 'cpan_mirror=${CPAN_MIRROR}' \
		-var 'openbsd_mirror=${OPENBSD_MIRROR}' \
		-var 'openbsd_architecture=$@' \
		-var 'timezone=${TIMEZONE}' \
		-var 'iso_path=${PWD}/${ISO_DIR}/${ISO_IMAGE}' \
		-var "iso_sha=$(shell cat ISO/SHA256 | awk '/${ISO_IMAGE}/ {print $$4}')" -var 'box=${I386_BOX}.box' \
		-var 'openbsd_version=${OPENBSD_VERSION}' ${PACKER_CFG}
amd64: get_pub_key
	${WGET} ${MIRROR_BASE_URL}/$@/${ISO_IMAGE} --output-document .\ISO\${ISO_IMAGE}
	@powershell wget -Uri ${MIRROR_BASE_URL}/$@/SHA256 -OutFile .\ISO\SHA256 -Verbose
	@powershell wget -Uri ${MIRROR_BASE_URL}/$@/SHA256.sig -OutFile .\ISO\SHA256.sig -Verbose
	packer build -var 'cpan_mirror=${CPAN_MIRROR}' -var 'openbsd_mirror=${OPENBSD_MIRROR}' -var 'openbsd_architecture=$@' -var 'timezone=${TIMEZONE}' -var 'iso_path=${PWD}\${ISO_DIR}\${ISO_IMAGE}' -var 'box=${AMD64_BOX}.box' -var iso_sha=$(shell powershell Get-Content .\ISO\SHA256 | Where-Object{$$_ -match '${ISO_IMAGE}'} | ForEach-Object{($$_ -split "\s+")[3]}) -var 'openbsd_version=${OPENBSD_VERSION}' ${PACKER_CFG}
add-i386:
	@if vagrant box list | grep ${VAGRANT_BOX_USER}/${I386_BOX}; then vagrant box remove ${VAGRANT_BOX_USER}/${I386_BOX}; fi
	vagrant box add --name ${VAGRANT_BOX_USER}/${I386_BOX} ${I386_BOX}.box
add-amd64:
	vagrant box add --name ${VAGRANT_BOX_USER}/${AMD64_BOX} ${AMD64_BOX}.box
clean: clean-iso
	@rm -f *.box
	@rm -f packer_openbsd_virtualbox-iso_sha256.checksum
	@rm -rf packer_cache
init:
	pip install -U pip wheel setuptools; pip install -U ansible
clean-iso:
	@rm -f ${ISO_DIR}/*.iso
	@rm -f ${ISO_DIR}/SHA256*
