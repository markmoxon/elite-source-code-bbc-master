MODE7
tstaddr = &8008
values = &90
unique = &80
RomSel = &FE30
RamSel = &FE32
UsrDat = &FE60
UsrDDR = &FE62
romNumber = &0094 : REM Set to address of .musicRomNumber

PRINT"Acornsoft Elite... with music!"
PRINT"=============================="
PRINT'"For the BBC Master Compact"
PRINT'"Based on the Superior Software release"
PRINT"of Elite by Ian Bell and David Braben"
PRINT"Copyright (c) Acornsoft 1986"
PRINT'"Sound routines by Kieran Connell and"
PRINT"Simon Morris"
PRINT'"Original music by Aidan Bell and Julie"
PRINT"Dunn (c) D. Braben and I. Bell 1985,"
PRINT"ported from the C64 by Negative Charge"
PRINT'"Elite integration by Mark Moxon"
PRINT'"Sideways RAM detection and loading"
PRINT"routines by Tricky and J.G.Harston"

REM Find 16 values distinct from the 16 rom values and each other and save the original rom values
DIM CODE &100
FOR P = 0 TO 2 STEP 2
P%=CODE
[OPT P
SEI
LDY #15        \\ unique values (-1) to find
\\STY UsrDDR     \\ set user via DDRB low bits as output - required for Solidisk SW RAM
TYA            \\ A can start anywhere less than 256-64 as it just needs to allow for enough numbers not to clash with rom, tst and uninitialised tst values
.next_val
LDX #15        \\ sideways bank
ADC #1         \\ will inc mostly by 2, but doesn't matter
.next_slot
STX RomSel
CMP tstaddr
BEQ next_val
CMP unique,X   \\ doesn't matter that we haven't checked these yet as it just excludes unnecessary values, but is safe
BEQ next_val
DEX
BPL next_slot
STA unique,Y
LDX tstaddr
STX values,Y
DEY
BPL next_val
\\ Try to swap each rom value with a unique test value - top down wouldn't work for Solidisk
LDX #0         \\ count up to allow for Solidisk only having 3 select bits
.swap
\\STX UsrDat     \\ set Solidisk SWRAM index
STX RamSel     \\ set RamSel incase it is used
STX RomSel     \\ set RomSel as it will be needed to read, but is also sometimes used to select write
LDA unique,X
STA tstaddr
INX            \\ count up to allow for Solidisk only have 3 select bits
CPX #16
BNE swap
\\ count matching values and restore old values - reverse order to swapping is safe
LDY #16
LDX #15
.tst_restore
STX RomSel
LDA tstaddr
CMP unique,X   \\ if it has changed, but is not this value, it will be picked up in a later bank
BNE not_swr
\\STX UsrDat     \\ set Solidisk SWRAM index
STX RamSel     \\ set RamSel incase it is used
LDA values,X
STA tstaddr
DEY
STX values,Y
.not_swr
DEX
BPL tst_restore
STY values
LDA &F4
STA RomSel     \\ restore original ROM
CLI
RTS
]
NEXT
CALL CODE
N%=16-?&90
IF N%=0 THEN PRINT'"Can't run:";CHR$129;"no sideways RAM detected":END
PRINT'"Detected ";16-?&90;" sideways RAM bank";
IF N% > 1 THEN PRINT "s";
REM IF N% > 0 THEN FOR X% = ?&90 TO 15 : PRINT;" ";X%?&90; : NEXT
IF ?(&90+?&90) = 6 AND N% = 1 THEN PRINT", but Elite needs that one to run (RAM bank 6)":END
IF ?(&90+?&90) = 6 AND N% > 1 THEN ?(&90+?&90) = ?(&90+?&90+1) : REM Skip bank 6
?romNumber=?(&90+?&90):REM STORE RAM BANK USED SOMEWHERE IN ZERO PAGE
PRINT'"Loading music into RAM bank ";?romNumber;"...";
OSCLI "SRLOAD MUSIC 8000 "+STR$(?romNumber)
PRINT CHR$130;"OK"
PRINT'"Press any key to play Elite";
A$=GET$
*RUN M128Elt
