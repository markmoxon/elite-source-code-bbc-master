MODE7
tstaddr = &8008
values = &90
unique = &80
RomSel = &FE30
romNumber = &8E : REM Set to address of .musicRomNumber

PRINT"BBC Master Elite (Compendium version)"
PRINT"====================================="
PRINT'"Based on the Acornsoft SNG47 release"
PRINT"of Elite by Ian Bell and David Braben"
PRINT"Copyright (c) Acornsoft 1986"
PRINT'"Flicker-free routines, bug fixes and"
PRINT"music integration by Mark Moxon"
PRINT'"Sound routines by Kieran Connell and"
PRINT"Simon Morris"
PRINT'"Original music by Aidan Bell and Julie"
PRINT"Dunn (c) D. Braben and I. Bell 1985,"
PRINT"ported from the C64 by Negative Charge"
PRINT'"Sideways RAM detection and loading"
PRINT"routines by Tricky and J.G.Harston"

REM Find 16 values distinct from the 16 rom values and each other and save the original rom values
DIM CODE &100
FOR P = 0 TO 2 STEP 2
P%=CODE
[OPT P
SEI
LDA &F4                 \\ Store &F4 on stack
PHA
LDY #15                 \\ Unique values (-1) to find
TYA                     \\ A can start anywhere less than 256-64 as it just needs to allow for enough numbers not to clash with rom, tst and uninitialised tst values
.next_val
LDX #15                 \\ Sideways bank
ADC #1                  \\ Will inc mostly by 2, but doesn't matter
.next_slot
STX &F4
STX RomSel
CMP tstaddr
BEQ next_val
CMP unique,X            \\ Doesn't matter that we haven't checked these yet as it just excludes unnecessary values, but is safe
BEQ next_val
DEX
BPL next_slot
STA unique,Y
LDX tstaddr
STX values,Y
DEY
BPL next_val
LDX #0                  \\ Try to swap each rom value with a unique test value
.swap
STX &F4
STX RomSel              \\ Set RomSel as it will be needed to read, but is also sometimes used to select write
LDA unique,X
STA tstaddr
INX
CPX #16
BNE swap
LDY #16                 \\ Count matching values and restore old values - reverse order to swapping is safe
LDX #15
.tst_restore
STX &F4
STX RomSel
LDA tstaddr
CMP unique,X            \\ If it has changed, but is not this value, it will be picked up in a later bank
BNE not_swr
LDA values,X
STA tstaddr
DEY
STX values,Y
.not_swr
DEX
BPL tst_restore
STY values
PLA                     \\ Restore original value of &F4
STA &F4
STA RomSel              \\ Restore original ROM
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
P%=&70
[OPT 0
.platform       EQUB 128
.addrDNOIZ      EQUW &2C55
.addrplay1      EQUW &2D71+1
.addrDELAY      EQUW &1349
.addrSFX        EQUW 0
.addrBEEP       EQUW &1354
.addrVOL        EQUW &2C61
.keyE           EQUB &45
.keyM           EQUB &4D
.keyQ           EQUB &51
.keyVolDown     EQUB &2C
.keyVolUp       EQUB &2E
.end
]
OSCLI "SRWRITE 0070+"+STR$~(end-platform)+" 800F "+STR$(?romNumber)
PRINT CHR$130;"OK"
PRINT'"Press any key to play Elite";
A$=GET$
*RUN M128Elt
