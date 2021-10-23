BEEBASM?=beebasm
PYTHON?=python

# You can set the release that gets built by adding 'release=<rel>' to
# the make command, where <rel> is one of:
#
#   sng47
#   compact
#
# So, for example:
#
#   make encrypt verify release=compact
#
# will build the Master Compact version. If you omit the release
# parameter, it will build the SNG47 version.

ifeq ($(release), compact)
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
	echo _VERSION=4 > 1-source-files/main-sources/elite-header.h.asm
	echo _RELEASE=$(rel-master) >> 1-source-files/main-sources/elite-header.h.asm
	echo _REMOVE_CHECKSUMS=TRUE >> 1-source-files/main-sources/elite-header.h.asm
	echo _MATCH_ORIGINAL_BINARIES=FALSE >> 1-source-files/main-sources/elite-header.h.asm
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader.asm -v > 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-data.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-source.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-readme.asm -v >> 3-assembled-output/compile.txt
	$(PYTHON) 2-build-files/elite-checksum.py -u -rel$(rel-master)
	$(BEEBASM) -i 1-source-files/main-sources/elite-disc.asm $(boot-master) -do 5-compiled-game-discs/elite-master$(suffix-master).ssd -title "E L I T E"

.PHONY:encrypt
encrypt:
	echo _VERSION=4 > 1-source-files/main-sources/elite-header.h.asm
	echo _RELEASE=$(rel-master) >> 1-source-files/main-sources/elite-header.h.asm
	echo _REMOVE_CHECKSUMS=FALSE >> 1-source-files/main-sources/elite-header.h.asm
	echo _MATCH_ORIGINAL_BINARIES=TRUE >> 1-source-files/main-sources/elite-header.h.asm
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader.asm -v > 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-data.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-source.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-readme.asm -v >> 3-assembled-output/compile.txt
	$(PYTHON) 2-build-files/elite-checksum.py -rel$(rel-master)
	$(BEEBASM) -i 1-source-files/main-sources/elite-disc.asm $(boot-master) -do 5-compiled-game-discs/elite-master$(suffix-master).ssd -title "E L I T E"

.PHONY:verify
verify:
	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries$(folder-master) 3-assembled-output
