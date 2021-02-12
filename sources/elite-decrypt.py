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
# running the script with "python sources/elite-decrypt.py"
#
# ******************************************************************************

from __future__ import print_function

print()
print("BBC Master Elite decryption")

release = 1
folder = "sng47"

# Configuration variables for BCODE

load_address = 0x1300
seed = 0x19
scramble_from = 0x2CC1
scramble_to = 0x7F47

data_block = bytearray()

# Load assembled code file

elite_file = open("extracted/" + folder + "/BCODE.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] extracted/" + folder + "/BCODE.bin")

# Do decryption

for n in range(scramble_to, scramble_from - 1, -1):
    new = (data_block[n - load_address] - seed) % 256
    data_block[n - load_address] = new
    seed = new

print("[ Decrypt ] extracted/" + folder + "/BCODE.bin")

# Write output file for BCODE.decrypt

output_file = open("extracted/" + folder + "/BCODE.decrypt.bin", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] extracted/" + folder + "/BCODE.decrypt.bin")

# Configuration variables for BDATA

load_address = 0x1300 + 0x5D00
seed = 0x62
scramble_from = 0x8000
scramble_to = 0xB1FF

data_block = bytearray()

# Load assembled code file

elite_file = open("extracted/" + folder + "/BDATA.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] extracted/" + folder + "/BDATA.bin")

# Do decryption

for n in range(scramble_to, scramble_from - 1, -1):
    new = (data_block[n - load_address] - seed) % 256
    data_block[n - load_address] = new
    seed = new

print("[ Decrypt ] extracted/" + folder + "/BDATA.bin")

# Write output file for BDATA.decrypt

output_file = open("extracted/" + folder + "/BDATA.decrypt.bin", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] extracted/" + folder + "/BDATA.decrypt.bin")
print()
