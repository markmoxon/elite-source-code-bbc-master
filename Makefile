BEEBASM?=beebasm
PYTHON?=python

# You can set the release that gets built by adding 'release-master=<rel>' to
# the make command, where <rel> is one of:
#
#   sng47
#   compact
#
# So, for example:
#
#   make encrypt verify release-master=compact
#
# will build the Master Compact version. If you omit the release-master
# parameter, it will build the SNG47 version.

ifeq ($(release-master), compact)
  rel-master=2
  folder-master=/compact
  suffix-master=-compact
  boot-master=-opt 2
else
  rel-master=1
  folder-master=/sng47
  suffix-master=-sng47
  boot-master=-boot M128Elt
endif

.PHONY:build
build:
	echo _VERSION=4 > sources/elite-header.h.asm
	echo _RELEASE=$(rel-master) >> sources/elite-header.h.asm
	echo _REMOVE_CHECKSUMS=TRUE >> sources/elite-header.h.asm
	echo _MATCH_EXTRACTED_BINARIES=FALSE >> sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-loader.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-data.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py -u -rel$(rel-master)
	$(BEEBASM) -i sources/elite-disc.asm $(boot-master) -do elite-master$(suffix-master).ssd

.PHONY:encrypt
encrypt:
	echo _VERSION=4 > sources/elite-header.h.asm
	echo _RELEASE=$(rel-master) >> sources/elite-header.h.asm
	echo _REMOVE_CHECKSUMS=FALSE >> sources/elite-header.h.asm
	echo _MATCH_EXTRACTED_BINARIES=TRUE >> sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-loader.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-data.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py -rel$(rel-master)
	$(BEEBASM) -i sources/elite-disc.asm $(boot-master) -do elite-master$(suffix-master).ssd

.PHONY:verify
verify:
	@$(PYTHON) sources/crc32.py extracted$(folder-master) output
