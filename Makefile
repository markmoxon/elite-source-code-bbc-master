BEEBASM?=beebasm
PYTHON?=python

rel-master=1
folder-master='/sng47'

.PHONY:build
build:
	echo _VERSION=4 > sources/elite-header.h.asm
	echo _RELEASE=$(rel-master) >> sources/elite-header.h.asm
	echo _REMOVE_CHECKSUMS=TRUE >> sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-loader.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-data.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py -u -rel$(rel-master)
	$(BEEBASM) -i sources/elite-disc.asm -do elite-master.ssd -boot M128Elt

.PHONY:encrypt
encrypt:
	echo _VERSION=4 > sources/elite-header.h.asm
	echo _RELEASE=$(rel-master) >> sources/elite-header.h.asm
	echo _REMOVE_CHECKSUMS=FALSE >> sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-loader.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-data.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-source.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py -rel$(rel-master)
	$(BEEBASM) -i sources/elite-disc.asm -do elite-master.ssd -boot M128Elt

.PHONY:verify
verify:
	@$(PYTHON) sources/crc32.py extracted$(folder-master) output
