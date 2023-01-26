BEEBASM?=beebasm
PYTHON?=python

# You can set the variant that gets built by adding 'variant=<rel>' to
# the make command, where <rel> is one of:
#
#   sng47
#   compact
#
# So, for example:
#
#   make encrypt verify variant=compact
#
# will build the Master Compact version. If you omit the variant
# parameter, it will build the SNG47 version.

ifeq ($(variant), compact)
  variant-master=2
  folder-master=/compact
  suffix-master=-compact
  boot-master=-opt 2
else
  variant-master=1
  folder-master=/sng47
  suffix-master=-sng47
  boot-master=-boot M128Elt
endif

.PHONY:build
build:
	echo _VERSION=4 > 1-source-files/main-sources/elite-build-options.asm
	echo _VARIANT=$(variant-master) >> 1-source-files/main-sources/elite-build-options.asm
	echo _REMOVE_CHECKSUMS=TRUE >> 1-source-files/main-sources/elite-build-options.asm
	echo _MATCH_ORIGINAL_BINARIES=FALSE >> 1-source-files/main-sources/elite-build-options.asm
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader.asm -v > 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-source.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-data.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-readme.asm -v >> 3-assembled-output/compile.txt
	$(PYTHON) 2-build-files/elite-checksum.py -u -rel$(variant-master)
	$(BEEBASM) -i 1-source-files/main-sources/elite-disc.asm $(boot-master) -do 5-compiled-game-discs/elite-master-flicker-free$(suffix-master).ssd -title "E L I T E"

.PHONY:encrypt
encrypt:
	echo _VERSION=4 > 1-source-files/main-sources/elite-build-options.asm
	echo _VARIANT=$(variant-master) >> 1-source-files/main-sources/elite-build-options.asm
	echo _REMOVE_CHECKSUMS=FALSE >> 1-source-files/main-sources/elite-build-options.asm
	echo _MATCH_ORIGINAL_BINARIES=TRUE >> 1-source-files/main-sources/elite-build-options.asm
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader.asm -v > 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-source.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-data.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-readme.asm -v >> 3-assembled-output/compile.txt
	$(PYTHON) 2-build-files/elite-checksum.py -rel$(variant-master)
	$(BEEBASM) -i 1-source-files/main-sources/elite-disc.asm $(boot-master) -do 5-compiled-game-discs/elite-master-flicker-free$(suffix-master).ssd -title "E L I T E"

.PHONY:verify
verify:
	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries$(folder-master) 3-assembled-output

.PHONY:b2
b2:
	curl -G "http://localhost:48075/reset/b2" --data-urlencode "config=Master 128 (MOS 3.20)"
	curl -H "Content-Type:application/binary" --upload-file "5-compiled-game-discs/elite-master-flicker-free$(suffix-master).ssd" "http://localhost:48075/run/b2?name=elite-master$(suffix-master).ssd"
