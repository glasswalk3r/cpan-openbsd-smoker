CPAN_MIRROR:=$(shell echo 'o conf urllist' | cpan | awk '/0 \[/ {print $$2}' | tr -d '[]')
OPENBSD_MIRROR:=openbsd.c3sl.ufpr.br
OPENBSD_VERSION:=7.0
OPENBSD_ARCHITETURE:=amd64
TIMEZONE:=America/Sao_Paulo
ISO_DIR:=ISO
ISO_IMAGE:=install$(subst .,,${OPENBSD_VERSION}).iso

base:
	packer build -var 'local_mirror=${CPAN_MIRROR}' \
	-var 'openbsd_mirror=${OPENBSD_MIRROR}' \
	-var 'openbsd_architeture=${OPENBSD_ARCHITETURE}' \
	-var 'timezone=${TIMEZONE}' \
	-var 'iso_path=${PWD}/${ISO_DIR}/${ISO_IMAGE}' \
	-var 'openbsd_version=${OPENBSD_VERSION}' packer.json
init:
	rm -rf ${ISO_DIR} && mkdir -p ${ISO_DIR} && rm -rf packer_cache/
	cd ISO && wget -c https://${OPENBSD_MIRROR}/pub/OpenBSD/${OPENBSD_VERSION}/${OPENBSD_ARCHITETURE}/${ISO_IMAGE}
