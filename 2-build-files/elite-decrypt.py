#!/usr/bin/env python
#
# ******************************************************************************
#
# BBC MASTER ELITE DECRYPTION SCRIPT
#
# Written by Mark Moxon
#
# This script removes encryption and checksums from the compiled binaries for
# the main game code. It reads the encrypted "BCODE.bin" and "BDATA.bin"
# binaries and generates decrypted versions as "BCODE.decrypt.bin" and
# "BDATA.decrypt.bin
#
# Files are saved using the decrypt.bin suffix so they don't overwrite any
# existing unprot.bin files, so they can be compared if required
#
# Run this script by changing directory to the repository's root folder and
# running the script with "python 2-build-files/elite-decrypt.py"
#
# You can decrypt specific releases by adding the following arguments, as in
# "python 2-build-files/elite-decrypt.py -rel2" for example:
#
#   -rel1   Decrypt the SNG47 release
#   -rel2   Decrypt the Master Compact release
#
# If unspecified, the default is rel1
#
# ******************************************************************************

from __future__ import print_function
import sys

print()
print("BBC Master Elite decryption")

argv = sys.argv
release = 1
folder = "sng47"

for arg in argv[1:]:
    if arg == "-rel1":
        release = 1
        folder = "sng47"
    if arg == "-rel2":
        release = 2
        folder = "compact"

# Configuration variables for BCODE

load_address = 0x1300
seed = 0x19
scramble_from = 0x2CC1

if release == 1:
    # SNG47
    scramble_to = 0x7F47
elif release == 2:
    # Compact
    scramble_to = 0x7FEC

data_block = bytearray()

# Load assembled code file

elite_file = open("4-reference-binaries/" + folder + "/BCODE.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] 4-reference-binaries/" + folder + "/BCODE.bin")

# Do decryption

for n in range(scramble_to, scramble_from - 1, -1):
    new = (data_block[n - load_address] - seed) % 256
    data_block[n - load_address] = new
    seed = new

print("[ Decrypt ] 4-reference-binaries/" + folder + "/BCODE.bin")

# Write output file for BCODE.decrypt

output_file = open("4-reference-binaries/" + folder + "/BCODE.decrypt.bin", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] 4-reference-binaries/" + folder + "/BCODE.decrypt.bin")

# Configuration variables for BDATA

load_address = 0x1300 + 0x5D00
seed = 0x62
scramble_from = 0x8000
scramble_to = 0xB1FF

data_block = bytearray()

# Load assembled code file

elite_file = open("4-reference-binaries/" + folder + "/BDATA.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] 4-reference-binaries/" + folder + "/BDATA.bin")

# Do decryption

for n in range(scramble_to, scramble_from - 1, -1):
    new = (data_block[n - load_address] - seed) % 256
    data_block[n - load_address] = new
    seed = new

print("[ Decrypt ] 4-reference-binaries/" + folder + "/BDATA.bin")

# Write output file for BDATA.decrypt

output_file = open("4-reference-binaries/" + folder + "/BDATA.decrypt.bin", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] 4-reference-binaries/" + folder + "/BDATA.decrypt.bin")
print()
