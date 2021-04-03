#!/usr/bin/env python
#
# ******************************************************************************
#
# BBC MASTER ELITE CHECKSUM SCRIPT
#
# Written by Mark Moxon, and inspired by Kieran Connell's version for the
# cassette version of Elite
#
# This script applies encryption and checksums to the compiled binary for the
# main parasite game code. It reads the unencrypted "BCODE.unprot.bin" and
# "BDATA.unprot.bin" binaries and generates encrypted versions as "BCODE.bin"
# and "BDATA.bin"
#
# ******************************************************************************

from __future__ import print_function
import sys

argv = sys.argv
Encrypt = True

for arg in argv[1:]:
    if arg == "-u":
        Encrypt = False

print("Elite Big Code File")
print("Encryption = ", Encrypt)

# Configuration variables for BCODE

load_address = 0x1300
seed = 0x19
scramble_from = 0x2cc1
scramble_to = 0x7f47

data_block = bytearray()

# Load assembled code file

elite_file = open("output/BCODE.unprot.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

# Commander data checksum

default_per_cent = 0x34CD
commander_start = default_per_cent - load_address
commander_offset = 0x52
CH = 0x4B - 2
CY = 0
for i in range(CH, 0, -1):
    CH = CH + CY + data_block[commander_start + i + 7]
    CY = (CH > 255) & 1
    CH = CH % 256
    CH = CH ^ data_block[commander_start + i + 8]

print("Commander checksum = ", CH)

# Must have Commander checksum otherwise game will lock

if Encrypt:
    data_block[commander_start + commander_offset] = CH ^ 0xA9
    data_block[commander_start + commander_offset + 1] = CH

# Encrypt game code

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = (data_block[n - load_address] + data_block[n + 1 - load_address]) % 256

data_block[scramble_to - load_address] = (data_block[scramble_to - load_address] + seed) % 256

# Write output file for BCODE

output_file = open("output/BCODE.bin", "wb")
output_file.write(data_block)
output_file.close()

print("output/BCODE.bin file saved")

# Configuration variables for BDATA

load_address = 0x1300 + 0x5D00
seed = 0x62
scramble_from = 0x8000
scramble_to = 0xB1FF

data_block = bytearray()

# Load assembled code file

elite_file = open("output/BDATA.unprot.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = (data_block[n - load_address] + data_block[n + 1 - load_address]) % 256

data_block[scramble_to - load_address] = (data_block[scramble_to - load_address] + seed) % 256

# Write output file for BDATA

output_file = open("output/BDATA.bin", "wb")
output_file.write(data_block)
output_file.close()

print("output/BDATA.bin file saved")
