.PHONY: packer
# the IP address and port of a local CPAN mirror
CPAN_MIRROR=192.168.1.114:8090

packer:
	packer build -var local_mirror=${CPAN_MIRROR} packer.json
