\ ******************************************************************************
\
\ BBC MASTER ELITE GAME SOURCE
\
\ BBC Master Elite was written by Ian Bell and David Braben and is copyright
\ Acornsoft 1986
\
\ The code on this site has been disassembled from the version released on Ian
\ Bell's personal website at http://www.elitehomepage.org/
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * output/BCODE.bin
\
\ ******************************************************************************

INCLUDE "sources/elite-header.h.asm"

CPU 1                   \ Switch to 65SC12 assembly, as this code runs on a
                        \ BBC Master

_CASSETTE_VERSION = (_VERSION = 1)
_DISC_VERSION = (_VERSION = 2)
_6502SP_VERSION = (_VERSION = 3)
_MASTER_VERSION = (_VERSION = 4)
_DISC_DOCKED = FALSE
_DISC_FLIGHT = FALSE

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

Q% = _REMOVE_CHECKSUMS  \ Set Q% to TRUE to max out the default commander, FALSE
                        \ for the standard default commander (this is set to
                        \ TRUE if checksums are disabled, just for convenience)

BRKV = &202             \ The break vector that we intercept to enable us to
                        \ handle and display system errors

NOST = 18               \ The number of stardust particles in normal space (this
                        \ goes down to 3 in witchspace)

NOSH = 12               \ The maximum number of ships in our local bubble of
                        \ universe

NTY = 34                \ The number of different ship types

MSL = 1                 \ Ship type for a missile
SST = 2                 \ Ship type for a Coriolis space station
ESC = 3                 \ Ship type for an escape pod
PLT = 4                 \ Ship type for an alloy plate
OIL = 5                 \ Ship type for a cargo canister
AST = 7                 \ Ship type for an asteroid
SPL = 8                 \ Ship type for a splinter
SHU = 9                 \ Ship type for a Shuttle
CYL = 11                \ Ship type for a Cobra Mk III
ANA = 14                \ Ship type for an Anaconda
HER = 15                \ Ship type for a rock hermit (asteroid)
COPS = 16               \ Ship type for a Viper
SH3 = 17                \ Ship type for a Sidewinder
KRA = 19                \ Ship type for a Krait
ADA = 20                \ Ship type for a Adder
WRM = 23                \ Ship type for a Worm
CYL2 = 24               \ Ship type for a Cobra Mk III (pirate)
ASP = 25                \ Ship type for an Asp Mk II
THG = 29                \ Ship type for a Thargoid
TGL = 30                \ Ship type for a Thargon
CON = 31                \ Ship type for a Constrictor
LGO = 32                \ Ship type for the Elite logo
COU = 33                \ Ship type for a Cougar
DOD = 34                \ Ship type for a Dodecahedron ("Dodo") space station

JL = ESC                \ Junk is defined as starting from the escape pod

JH = SHU+2              \ Junk is defined as ending before the Cobra Mk III
                        \
                        \ So junk is defined as the following: escape pod,
                        \ alloy plate, cargo canister, asteroid, splinter,
                        \ Shuttle or Transporter

PACK = SH3              \ The first of the eight pack-hunter ships, which tend
                        \ to spawn in groups. With the default value of PACK the
                        \ pack-hunters are the Sidewinder, Mamba, Krait, Adder,
                        \ Gecko, Cobra Mk I, Worm and Cobra Mk III (pirate)

POW = 15                \ Pulse laser power

Mlas = 50               \ Mining laser power

Armlas = INT(128.5+1.5*POW) \ Military laser power

NI% = 37                \ The number of bytes in each ship's data block (as
                        \ stored in INWK and K%)

OSCLI = &FFF7           \ The address for the OSCLI routine

VIA = &FE00             \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

IRQ1V = &204            \ The IRQ1V vector that we intercept to implement the
                        \ split-sceen mode

WRCHV = &20E            \ The WRCHV vector that we intercept to implement our
                        \ own custom OSWRCH commands for communicating over the
                        \ Tube

X = 128                 \ The centre x-coordinate of the 256 x 192 space view
Y = 96                  \ The centre y-coordinate of the 256 x 192 space view

\ Incorrect?
f0 = &20                \ Internal key number for red key f0 (Launch, Front)
f1 = &71                \ Internal key number for red key f1 (Buy Cargo, Rear)
f2 = &72                \ Internal key number for red key f2 (Sell Cargo, Left)
f3 = &73                \ Internal key number for red key f3 (Equip Ship, Right)
f4 = &14                \ Internal key number for red key f4 (Long-range Chart)
f5 = &74                \ Internal key number for red key f5 (Short-range Chart)
f6 = &75                \ Internal key number for red key f6 (Data on System)
f7 = &16                \ Internal key number for red key f7 (Market Price)
f8 = &76                \ Internal key number for red key f8 (Status Mode)

\ Correct
f9 = &89                \ Internal key number for red key f9 (Inventory)

YELLOW  = %00001111     \ Four mode 1 pixels of colour 1 (yellow)
RED     = %11110000     \ Four mode 1 pixels of colour 2 (red, magenta or white)
CYAN    = %11111111     \ Four mode 1 pixels of colour 3 (cyan or white)
GREEN   = %10101111     \ Four mode 1 pixels of colour 3, 1, 3, 1 (cyan/yellow)
WHITE   = %11111010     \ Four mode 1 pixels of colour 3, 2, 3, 2 (cyan/red)
MAGENTA = RED           \ Four mode 1 pixels of colour 2 (red, magenta or white)
DUST    = WHITE         \ Four mode 1 pixels of colour 3, 2, 3, 2 (cyan/red)

RED2    = %00000011     \ Two mode 2 pixels of colour 1    (red)
GREEN2  = %00001100     \ Two mode 2 pixels of colour 2    (green)
YELLOW2 = %00001111     \ Two mode 2 pixels of colour 3    (yellow)
BLUE2   = %00110000     \ Two mode 2 pixels of colour 4    (blue)
MAG2    = %00110011     \ Two mode 2 pixels of colour 5    (magenta)
CYAN2   = %00111100     \ Two mode 2 pixels of colour 6    (cyan)
WHITE2  = %00111111     \ Two mode 2 pixels of colour 7    (white)
STRIPE  = %00100011     \ Two mode 2 pixels of colour 5, 1 (magenta/red)

NRU% = 0                \ The number of planetary systems with extended system
                        \ description overrides in the RUTOK table. The value of
                        \ this variable is 0 in the original source, but this
                        \ appears to be a bug, as it should really be 26

VE = &57                \ The obfuscation byte used to hide the extended tokens
                        \ table from crackers viewing the binary code

LL = 30                 \ The length of lines (in characters) of justified text
                        \ in the extended tokens system

CODE% = &1300
LOAD% = &1300

ORG CODE%

\ New vars: L0098, L0099, L009B, L00FC
\ KL vars: L00C9, L00CB, L00D0, L00D1
\ Save block? L0791
\ L1229: distance for ship in TITLE?
\ L1264 - L1266
\ L12A6 - L12A9 (see IRQ1)

ZP = &0000
RAND = &0002
T1 = &0006
SC = &000A
SCH = &000B
P = &000C
XC = &0010
COL = &0011
YC = &0012
QQ17 = &0013
K3 = &0014
K4 = &0022
XX16 = &0024
XX0 = &0036
INF = &0038
V = &003A
XX = &003C
YY = &003E
SUNX = &0040
BETA = &0042
BET1 = &0043
QQ22 = &0044
ECMA = &0046
ALP1 = &0047
ALP2 = &0048
XX15 = &004A
X1 = &004A
Y1 = &004B
X2 = &004C
Y2 = &004D
XX12 = &0050
K = &0056
LAS = &005A
MSTG = &005B
DL = &005C
LSP = &005D
QQ15 = &005E
XX18 = &0064
K5 = &0064
K6 = &0068
QQ19 = &006D
BET2 = &0073
DELTA   = &0075
DELT4   = &0076
U = &0078
Q = &0079
R = &007A
S = &007B
T = &007C
XSAV = &007D
YSAV = &007E
XX17 = &007F
W  = &0080
QQ11 = &0081
ZZ = &0082
XX13 = &0083
MCNT = &0084
TYPE = &0085
ALPHA   = &0086
QQ12 = &0087
TGT = &0088
FLAG = &0089
CNT = &008A
CNT2 = &008B
STP = &008C
XX4 = &008D
XX20 = &008E
XX14 = &008F
RAT = &0091
RAT2 = &0092
K2 = &0093
widget  = &0097
L0098   = &0098
L0099   = &0099
messXC  = &009A
L009B   = &009B
INWK = &009C
XX19 = &00BD
NEWB = &00C0
JSTX = &00C1
JSTY = &00C2
KL = &00C3
KY17 = &00C4
KY14 = &00C5
KY15 = &00C6
KY20 = &00C7
KY7 = &00C8
L00C9   = &00C9
KY18 = &00CA
L00CB   = &00CB
KY19 = &00CC
KY12 = &00CD
KY2 = &00CE
KY16 = &00CF
L00D0   = &00D0
L00D1   = &00D1
KY1 = &00D2
KY13 = &00D3
LSX = &00D4
FSH = &00D5
ASH = &00D6
ENERGY  = &00D7
QQ3 = &00D8
QQ4 = &00D9
QQ5 = &00DA
QQ6 = &00DB
QQ7 = &00DD
QQ8 = &00DF
QQ9 = &00E1
QQ10 = &00E2
NOSTM   = &00E3
L00FC   = &00FC
XX3 = &0100
K% = &0400
L0401   = &0401
L0402   = &0402
L0404   = &0404
L0405   = &0405
L0406   = &0406
L0407   = &0407
L0408   = &0408
L0425   = &0425
L0427   = &0427
L0429   = &0429
L042D   = &042D
L042F   = &042F
L0431   = &0431
L0433   = &0433
L0449   = &0449
L06A9   = &06A9
L0791   = &0791
FRIN = &0E41
MANY = &0E4E
SSPR = &0E50
L0E58   = &0E58
L0E5E   = &0E5E
L0E6B   = &0E6B
L0E6D   = &0E6D
JUNK = &0E70
auto = &0E71
ECMP = &0E72
MJ = &0E73
CABTMP  = &0E74
LAS2 = &0E75
MSAR = &0E76
VIEW = &0E77
LASCT   = &0E78
GNTMP   = &0E79
HFX = &0E7A
EV = &0E7B
DLY = &0E7C
de = &0E7D
LSX2 = &0E7E
LSY2 = &0F7E
LSO = &107E
BUF = &1146
SX = &11A0
SXL = &11B5
SY = &11CA
SYL = &11DF
L11ED   = &11ED
SZ = &11F4
SZL = &1209
LASX = &121E
LASY = &121F
ALTIT   = &1221
SWAP = &1222
L1229   = &1229
NAME = &122C
TP = &1234
QQ0 = &1235
QQ1 = &1236
QQ21 = &1237
CASH = &123D
QQ14 = &1241
COK = &1242
GCNT = &1243
LASER   = &1244
CRGO = &124A
QQ20 = &124B
ECM = &125C
BST = &125D
BOMB = &125E
ENGY = &125F
DKCMP   = &1260
GHYP = &1261
ESCP = &1262
L1264   = &1264
L1265   = &1265
L1266   = &1266
NOMSL   = &1267
FIST = &1268
AVL = &1269
QQ26 = &127A
TALLY   = &127B
SVC = &127D
MCH = &1281
COMX = &1282
COMY = &1283
QQ24 = &1292
QQ25 = &1293
QQ28 = &1294
QQ29 = &1295
gov = &1296
tek = &1297
SLSP = &1298
QQ2 = &129A
KTRAN   = &129F
safehouse = &12A0
L12A6   = &12A6
L12A7   = &12A7
L12A8   = &12A8
L12A9   = &12A9
XX21 = &8000
L8002   = &8002
L8003   = &8003
L8007   = &8007
L8040   = &8040
L8041   = &8041
E% = &8042
L8062   = &8062
TALLYFRAC = &8063
L8083   = &8083
TALLYINT = &8084
QQ18 = &A000
SNE = &A3C0
ACT = &A3E0
TKN1 = &A400
RUPLA   = &AF48
RUGAL   = &AF62
RUTOK   = &AF7C

\ ******************************************************************************
\
\       Name: TVT3
\       Type: Variable
\   Category: Screen mode
\    Summary: Palette data for the mode 1 part of the screen (the top part)
\
\ ------------------------------------------------------------------------------
\
\ The following table contains four different mode 1 palettes, each of which
\ sets a four-colour palatte for the top part of the screen. Mode 1 supports
\ four colours on-screen and in Elite colour 0 is always set to black, so each
\ of the palettes in this table defines the three other colours (1 to 3).
\
\ There is some consistency between the palettes:
\
\   * Colour 0 is always black
\   * Colour 1 (#YELLOW) is always yellow
\   * Colour 2 (#RED) is normally red-like (i.e. red or magenta)
\              ... except in the title screen palette, when it is white
\   * Colour 3 (#CYAN) is always cyan-like (i.e. white or cyan)
\
\ The configuration variables of #YELLOW, #RED and #CYAN are a bit misleading,
\ but if you think of them in terms of hue rather than specific colours, they
\ work reasonably well (outside of the title screen palette, anyway).
\
\ The palettes are set in the IRQ1 handler that implements the split screen
\ mode, and can be changed by calling the SETVDU19 routine to set the offset to
\ the new palette in this table.
\
\ This table must start on a page boundary (i.e. an address that ends in two
\ zeroes in hexadecimal). In the release version of the game TVT3 is at &2C00.
\ This is so the SETVDU19 routine can switch palettes properly, as it does this
\ by overwriting the low byte of the palette data address with a new offset, so
\ the low byte for first palette's address must be 0.
\
\ Palette data is given as a set of bytes, with each byte mapping a logical
\ colour to a physical one. In each byte, the logical colour is given in bits
\ 4-7 and the physical colour in bits 0-3. See p.379 of the Advanced User Guide
\ for details of how palette mapping works, as in modes 1 and 2 we have to do
\ multiple palette commands to change the colours correctly, and the physical
\ colour value is EOR'd with 7, just to make things even more confusing.
\
\ ******************************************************************************

.TVT3

 EQUB &00, &34          \ 1 = yellow, 2 = red, 3 = cyan (space view)
 EQUB &24, &17          \
 EQUB &74, &64          \ Set with a call to SETVDU19 with A = 0, after which:
 EQUB &57, &47          \
 EQUB &B1, &A1          \   #YELLOW = yellow
 EQUB &96, &86          \   #RED    = red
 EQUB &F1, &E1          \   #CYAN   = cyan
 EQUB &D6, &C6          \   #GREEN  = cyan/yellow stripe
                        \   #WHITE  = cyan/red stripe

 EQUB &00, &34          \ 1 = yellow, 2 = red, 3 = white (chart view)
 EQUB &24, &17          \
 EQUB &74, &64          \ Set with a call to SETVDU19 with A = 16, after which:
 EQUB &57, &47          \
 EQUB &B0, &A0          \   #YELLOW = yellow
 EQUB &96, &86          \   #RED    = red
 EQUB &F0, &E0          \   #CYAN   = white
 EQUB &D6, &C6          \   #GREEN  = white/yellow stripe
                        \   #WHITE  = white/red stripe

 EQUB &00, &34          \ 1 = yellow, 2 = white, 3 = cyan (title screen)
 EQUB &24, &17          \
 EQUB &74, &64          \ Set with a call to SETVDU19 with A = 32, after which:
 EQUB &57, &47          \
 EQUB &B1, &A1          \   #YELLOW = yellow
 EQUB &90, &80          \   #RED    = white
 EQUB &F1, &E1          \   #CYAN   = cyan
 EQUB &D0, &C0          \   #GREEN  = cyan/yellow stripe
                        \   #WHITE  = cyan/white stripe

 EQUB &00, &34          \ 1 = yellow, 2 = magenta, 3 = white (trade view)
 EQUB &24, &17          \
 EQUB &74, &64          \ Set with a call to SETVDU19 with A = 48, after which:
 EQUB &57, &47          \
 EQUB &B0, &A0          \   #YELLOW = yellow
 EQUB &92, &82          \   #RED    = magenta
 EQUB &F0, &E0          \   #CYAN   = white
 EQUB &D2, &C2          \   #GREEN  = white/yellow stripe
                        \   #WHITE  = white/magenta stripe

\ ******************************************************************************
\
\       Name: VEC
\       Type: Variable
\   Category: Screen mode
\    Summary: The original value of the IRQ1 vector
\
\ ******************************************************************************

.VEC

 EQUW &8888             \ This gets set to the value of the original IRQ1 vector
                        \ by the STARTUP routine

\ ******************************************************************************
\
\       Name: WSCAN
\       Type: Subroutine
\   Category: Screen mode
\    Summary: Implement the #wscn command (wait for the vertical sync)
\
\ ------------------------------------------------------------------------------
\
\ Wait for vertical sync to occur on the video system - in other words, wait
\ for the screen to start its refresh cycle, which it does 50 times a second
\ (50Hz).
\
\ ******************************************************************************

.WSCAN

 STZ DL                 \ Set DL to 0

.WSCAN1

 LDA DL                 \ Loop round these two instructions until DL is no
 BEQ WSCAN1             \ longer 0 (DL gets set to 30 in the LINSCN routine,
                        \ which is run when vertical sync has occurred on the
                        \ video system, so DL will change to a non-zero value
                        \ at the start of each screen refresh)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DELAY
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Wait for a specified time, in 1/50s of a second
\
\ ------------------------------------------------------------------------------
\
\ Wait for the number of vertical syncs given in Y, so this effectively waits
\ for Y/50 of a second (as the vertical sync occurs 50 times a second).
\
\ Arguments:
\
\   Y                   The number of vertical sync events to wait for
\
\ ******************************************************************************

.DELAY

 JSR WSCAN              \ Call WSCAN to wait for the vertical sync, so the whole
                        \ screen gets drawn

 DEY                    \ Decrement the counter in Y

 BNE DELAY              \ If Y isn't yet at zero, jump back to DELAY to wait
                        \ for another vertical sync

 RTS                    \ Return from the subroutine

.BEEP_LONG_LOW

 LDY #&00
 BRA NOISE

\ ******************************************************************************
\
\       Name: BEEP
\       Type: Subroutine
\   Category: Sound
\    Summary: Make a short, high beep
\
\ ******************************************************************************

.BEEP

 LDY #1                 \ Call NOISE with Y = 1 to make a short, high beep,
 BRA NOISE              \ returning from the subroutine using a tail call

.L1358

 EQUB &C0

 EQUB &A0,&80

.L135B

 EQUB &FF,&BF,&9F,&DF,&EF

.MASTER_DKSn

 LDX #&FF
 STX VIA+&43
 STA VIA+&4F
 LDA #&00
 STA VIA+&40
 PHA
 PLA
 PHA
 PLA
 LDA #&08
 STA VIA+&40

.L1376

 RTS

.L1377

 LDY #&03
 LDA #&00

.L137B

 STA L144C,Y
 DEY
 BNE L137B

 SEI

.L1382

 LDA L135B,Y
 JSR MASTER_DKSn

 INY
 CPY #&05
 BNE L1382

 CLI
 RTS

.BEING_HIT_NOISE

 LDY #&09
 JSR NOISE

 LDY #&05
 BRA NOISE

.LASER_NOISE

 LDY #&03
 JSR NOISE

 LDY #&05

.NOISE

 LDA L2C55
 BNE L1376

 LDA L146E,Y
 LSR A
 CLV
 LDX #&00
 BCS L13B7

 INX
 LDA L145A
 CMP L145B
 BCC L13B7

 INX

.L13B7

 LDA L1462,Y
 CMP L1459,X
 BCC L1376

 SEI
 STA L1459,X
 LSR A
 AND #&07
 STA L1453,X
 LDA L1486,Y
 STA L1456,X
 LDA L146E,Y
 STA L1450,X
 AND #&0F
 LSR A
 STA L145C,X
 LDA L147A,Y
 BVC L13E1

 ASL A

.L13E1

 STA L145F,X
 LDA #&80
 STA L144D,X
 CLI
 SEC
 RTS

.L13EC

 LDY #&02

.L13EE

 LDA L144D,Y
 BEQ L1449

 BMI L13FB

 LDA L145C,Y
 BEQ L1416

 EQUB &2C

.L13FB

 LDA #&00
 CLC
 CLD
 ADC L145F,Y
 STA L145F,Y
 PHA
 ASL A
 ASL A
 AND #&0F
 ORA L1358,Y
 JSR MASTER_DKSn

 PLA
 LSR A
 LSR A
 JSR MASTER_DKSn

.L1416

 TYA
 TAX
 LDA L144D,Y
 BMI L1439

 DEC L1450,X
 BEQ L142F

 LDA L1450,X
 AND L1456,X
 BNE L1449

 DEC L1453,X
 BNE L143C

.L142F

 LDA #&00
 STA L144D,Y
 STA L1459,Y
 BEQ L1443

.L1439

 LSR L144D,X

.L143C

 LDA L1453,Y
 CLC
 ADC L2C61

.L1443

 EOR L135B,Y
 JSR MASTER_DKSn

.L1449

 DEY
 BPL L13EE

.L144C

 RTS

.L144D

 EQUB &00

 EQUB &00,&00

.L1450

 EQUB &00,&00,&00

.L1453

 EQUB &00,&00,&00

.L1456

 EQUB &00,&00,&00

.L1459

 EQUB &00

.L145A

 EQUB &00

.L145B

 EQUB &00

.L145C

 EQUB &00,&00,&00

.L145F

 EQUB &00,&00,&00

.L1462

 EQUB &4B,&5B,&3F,&EB,&FF,&09,&FF,&8B
 EQUB &CF,&E7,&FF,&EF

.L146E

 EQUB &40,&10,&01,&FC,&F3,&19,&F9,&7C
 EQUB &F1,&FA,&FE,&FE

.L147A

 EQUB &F0,&20,&10,&30,&03,&01,&08,&80
 EQUB &16,&38,&00,&80

.L1486

 EQUB &FF,&FF,&00,&03,&1F,&01,&07,&07
 EQUB &0F,&03,&0F,&0F

\ ******************************************************************************
\
\       Name: STARTUP
\       Type: Subroutine
\   Category: Loader
\    Summary: Set the various vectors, interrupts and timers
\
\ ******************************************************************************

.STARTUP

 SEI                    \ Disable interrupts

 LDA #%00111001         \ Set 6522 System VIA interrupt enable register IER
 STA VIA+&4E            \ (SHEILA &4E) bits 0 and 3-5 (i.e. disable the Timer1,
                        \ CB1, CB2 and CA2 interrupts from the System VIA)

 LDA #%01111111         \ Set 6522 User VIA interrupt enable register IER
 STA &FE6E              \ (SHEILA &6E) bits 0-7 (i.e. disable all hardware
                        \ interrupts from the User VIA)

 LDA IRQ1V              \ Store the current IRQ1V vector in VEC, so VEC(1 0) now
 STA VEC                \ contains the original address of the IRQ1 handler
 LDA IRQ1V+1
 STA VEC+1

 LDA #LO(IRQ1)          \ Set the IRQ1V vector to IRQ1, so IRQ1 is now the
 STA IRQ1V              \ interrupt handler
 LDA #HI(IRQ1)
 STA IRQ1V+1

 LDA VSCAN              \ Set 6522 System VIA T1C-L timer 1 high-order counter
 STA VIA+&45            \ (SHEILA &45) to the contents of VSCAN (57) to start
                        \ the T1 counter counting down from 14592 at a rate of
                        \ 1 MHz

 CLI                    \ Enable interrupts again

 RTS

\ ******************************************************************************
\
\       Name: TVT1
\       Type: Variable
\   Category: Screen mode
\    Summary: Palette data for the mode 2 part of the screen (the dashboard)
\
\ ------------------------------------------------------------------------------
\
\ This palette is applied in the IRQ1 routine. If we have an eacape pod fitted,
\ then the first byte is changed to &30, which maps logical colour 3 to actual
\ colour 0 (black) instead of colour 4 (blue).
\
\ ******************************************************************************

.TVT1

 EQUB &34, &43
 EQUB &25, &16
 EQUB &86, &70
 EQUB &61, &52
 EQUB &C3, &B4
 EQUB &A5, &96
 EQUB &07, &F0
 EQUB &E1, &D2

\ ******************************************************************************
\
\       Name: IRQ1
\       Type: Subroutine
\   Category: Screen mode
\    Summary: The main screen-mode interrupt handler (IRQ1V points here)
\  Deep dive: The split-screen mode
\
\ ------------------------------------------------------------------------------
\
\ The main interrupt handler, which implements Elite's split-screen mode (see
\ the deep dive on "The split-screen mode" for details).
\
\ IRQ1V is set to point to IRQ1 by the loading process.
\
\ ******************************************************************************

.IRQ1

 PHY                    \ Store Y on the stack

 LDY #15                \ Set Y as a counter for 16 bytes, to use when setting
                        \ the dashboard palette below

 LDA #%00000010         \ Read the 6522 System VIA status byte bit 1 (SHEILA
 BIT VIA+&4D            \ &4D), which is set if vertical sync has occurred on
                        \ the video system

 BNE LINSCN             \ If we are on the vertical sync pulse, jump to LINSCN
                        \ to set up the timers to enable us to switch the
                        \ screen mode between the space view and dashboard

 LDA #%00010100         \ Set the Video ULA control register (SHEILA &20) to
 STA VIA+&20            \ %00010100, which is the same as switching to mode 2,
                        \ (i.e. the bottom part of the screen) but with no
                        \ cursor

 LDA ESCP               \ Set A = ESCP, which is &FF if we have an escape pod
                        \ fitted, or 0 if we don't

 AND #4                 \ Set A = 4 if we have an escape pod fitted, or 0 if we
                        \ don't

 EOR #&34               \ Set A = &30 if we have an escape pod fitted, or &34 if
                        \ we don't

 STA &FE21              \ Store A in SHEILA &21 to map colour 3 (#YELLOW2) to
                        \ white if we have an escape pod fitted, or yellow if we
                        \ don't, so the outline colour of the dashboard changes
                        \ from yellow to white if we have an escape pod fitted

                        \ The following loop copies bytes #15 to #1 from TVT1 to
                        \ SHEILA &21, but not byte #0, as we just did that
                        \ colour mapping

.VNT2

 LDA TVT1,Y             \ Copy the Y-th palette byte from TVT1 to SHEILA &21
 STA &FE21              \ to map logical to actual colours for the bottom part
                        \ of the screen (i.e. the dashboard)

 DEY                    \ Decrement the palette byte counter

 BNE VNT2               \ Loop back to VNT2 until we have copied all the palette
                        \ bytes bar the first one

 LDA VIA+&18            \ ???
 AND #&03
 TAY
 LDA VIA+&19
 STA L12A7,Y
 INY
 TYA
 CMP #&03
 BCC P%+4

 LDA #&00
 STA VIA+&18
 PLY
 LDA VIA+&44
 LDA L00FC
 RTI

.LINSCN

 LDA VIA+&41            \ ???
 LDA L00FC
 PHA

 LDA DLCNT
 STA DL

 STA VIA+&44            \ Set 6522 System VIA T1C-L timer 1 low-order counter
                        \ (SHEILA &44) to 30

 LDA VSCAN              \ Set 6522 System VIA T1C-L timer 1 high-order counter
 STA VIA+&45            \ (SHEILA &45) to the contents of VSCAN (57) to start
                        \ the T1 counter counting down from 14622 at a rate of
                        \ 1 MHz

 LDA HFX                \ If the hyperspace effect flag in HFX is non-zero, then
 BNE jvec               \ jump up to jvec to pass control to the next interrupt
                        \ handler, instead of switching the palette to mode 1.
                        \ This will have the effect of blurring and colouring
                        \ the top screen in a mode 2 palette, making the
                        \ hyperspace rings turn multicoloured when we do a
                        \ hyperspace jump. This effect is triggered by the
                        \ parasite issuing a #DOHFX 1 command in routine LL164
                        \ and is disabled again by a #DOHFX 0 command

 LDA #%00011000         \ Set the Video ULA control register (SHEILA &20) to
 STA VIA+&20            \ %00011000, which is the same as switching to mode 1
                        \ (i.e. the top part of the screen) but with no cursor

.VNT3

                        \ The following instruction gets modified in-place by
                        \ the #SETVDU19 <offset> command, which changes the
                        \ value of TVT3+1 (i.e. the low byte of the address in
                        \ the LDA instruction). This changes the palette block
                        \ that gets copied to SHEILA &21, so a #SETVDU19 32
                        \ command applies the third palette from TVT3 in this
                        \ loop, for example

 LDA TVT3,Y             \ Copy the Y-th palette byte from TVT3 to SHEILA &21
 STA VIA+&21            \ to map logical to actual colours for the bottom part
                        \ of the screen (i.e. the dashboard)

 DEY                    \ Decrement the palette byte counter

 BNE VNT3               \ Loop back to VNT3 until we have copied all the
                        \ palette bytes

.jvec

 PHX                    \ ???
 JSR L13EC
 PLX

 PLA

 PLY                    \ Restore Y from the stack

 RTI                    \ Return from interrupts, so this interrupt is not
                        \ passed on to the next interrupt handler, but instead
                        \ the interrupt terminates here

\ ******************************************************************************
\
\       Name: VSCAN
\       Type: Variable
\   Category: Screen mode
\    Summary: Defines the split position in the split-screen mode
\
\ ******************************************************************************

.VSCAN

 EQUB 57

\ ******************************************************************************
\
\       Name: DLCNT
\       Type: Variable
\   Category: Screen mode
\    Summary: The line scan counter in DL gets reset to this value at each
\             vertical sync, before decrementing with each line scan
\
\ ******************************************************************************

.DLCNT

 EQUB 30

\ ******************************************************************************
\
\       Name: SETVDU19
\       Type: Subroutine
\   Category: Screen mode
\    Summary: Change the mode 1 palette
\
\ ------------------------------------------------------------------------------
\
\ This routine updates the VNT3+1 location in the IRQ1 handler to change the
\ palette that's applied to the top part of the screen (the four-colour mode 1
\ part). The parameter is the offset within the TVT3 palette block of the
\ desired palette.
\
\ Arguments:
\
\   A                   The offset within the TVT3 table of palettes:
\
\                         * 0 = Yellow, red, cyan palette (space view)
\
\                         * 16 = Yellow, red, white palette (charts)
\
\                         * 32 = Yellow, white, cyan palette (title screen)
\
\                         * 48 = Yellow, magenta, white palette (trading)
\
\ ******************************************************************************

.SETVDU19

 STA VNT3+1             \ Store the new colour in VNT3+1, in the IRQ1 routine,
                        \ which modifies which TVT3 palette block gets applied
                        \ to the mode 1 part of the screen

 RTS                    \ Return from the subroutine

.MASTER_MOVE_ZP_3000

 LDA #&0F
 STA VIA+&34
 LDX #&90

.L1547

 LDA ZP,X
 STA &3000,X
 INX
 BNE L1547

 LDA #&09
 STA VIA+&34
 RTS

.MASTER_SWAP_ZP_3000

 LDA #&0F
 STA VIA+&34
 LDX #&90

.L155C

 LDA ZP,X
 LDY &3000,X
 STY ZP,X
 STA &3000,X
 INX
 CPX #&F0
 BNE L155C

 LDA #&09
 STA VIA+&34
 LDA #&06
 STA VIA+&30
 RTS

\ ******************************************************************************
\
\       Name: ylookup
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Lookup table for converting pixel y-coordinate to page number of
\             screen address
\
\ ------------------------------------------------------------------------------
\
\ Elite's screen mode is based on mode 1, so it allocates two pages of screen
\ memory to each character row (where a character row is 8 pixels high). This
\ table enables us to convert a pixel y-coordinate in the range 0-247 into the
\ page number for the start of the character row containing that coordinate.
\
\ Screen memory is from &4000 to &7DFF, so the lookup works like this:

\   Y =   0 to  7,  lookup value = &40 (so row 1 is from &4000 to &41FF)
\   Y =   8 to 15,  lookup value = &42 (so row 2 is from &4200 to &43FF)
\   Y =  16 to 23,  lookup value = &44 (so row 3 is from &4400 to &45FF)
\   Y =  24 to 31,  lookup value = &46 (so row 4 is from &4600 to &47FF)
\
\   ...
\
\   Y = 232 to 239, lookup value = &7A (so row 31 is from &7A00 to &7BFF)
\   Y = 240 to 247, lookup value = &7C (so row 31 is from &7C00 to &7DFF)
\
\ There is also a lookup value for y-coordinates from 248 to 255, but that's off
\ the end of the screen, as the special Elite screen mode only has 31 character
\ rows.
\
\ ******************************************************************************

.ylookup

FOR I%, 0, 255
  EQUB &40 + ((I% DIV 8) * 2)
NEXT

\ ******************************************************************************
\
\       Name: SCAN
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Display the current ship on the scanner
\  Deep dive: The 3D scanner
\
\ ------------------------------------------------------------------------------
\
\ This is used both to display a ship on the scanner, and to erase it again.
\
\ Arguments:
\
\   INWK                The ship's data block
\
\ ******************************************************************************

.SC5

 RTS                    \ Return from the subroutine

.SCAN

 LDA INWK+31            \ Fetch the ship's scanner flag from byte #31

 AND #%00010000         \ If bit 4 is clear then the ship should not be shown
 BEQ SC5                \ on the scanner, so return from the subroutine (as SC5
                        \ contains an RTS)

 LDX TYPE               \ Fetch the ship's type from TYPE into X

 BMI SC5                \ If this is the planet or the sun, then the type will
                        \ have bit 7 set and we don't want to display it on the
                        \ scanner, so return from the subroutine (as SC5
                        \ contains an RTS)

 LDA scacol,X           \ Set A to the scanner colour for this ship type from
                        \ the X-th entry in the scacol table

 STA COL                \ Store the scanner colour in COL so it can be used to
                        \ draw this ship in the correct colour

 LDA INWK+1             \ If any of x_hi, y_hi and z_hi have a 1 in bit 6 or 7,
 ORA INWK+4             \ then the ship is too far away to be shown on the
 ORA INWK+7             \ scanner, so return from the subroutine (as SC5
 AND #%11000000         \ contains an RTS)
 BNE SC5

                        \ If we get here, we know x_hi, y_hi and z_hi are all
                        \ 63 (%00111111) or less

                        \ Now, we convert the x_hi coordinate of the ship into
                        \ the screen x-coordinate of the dot on the scanner,
                        \ using the following (see the deep dive on "The 3D
                        \ scanner" for an explanation):
                        \
                        \   X1 = 123 + (x_sign x_hi)

 LDA INWK+1             \ Set x_hi

 CLC                    \ Clear the C flag so we can do addition below

 LDX INWK+2             \ Set X = x_sign

 BPL SC2                \ If x_sign is positive, skip the following

 EOR #%11111111         \ x_sign is negative, so flip the bits in A and subtract
 ADC #1                 \ 1 to make it a negative number (bit 7 will now be set
                        \ as we confirmed above that bits 6 and 7 are clear). So
                        \ this gives A the sign of x_sign and gives it a value
                        \ range of -63 (%11000001) to 0

 CLC                    \ ???

.SC2

 ADC #125               \ ???
 AND #&FE
 STA X1
 TAX
 DEX
 DEX

                        \ Next, we convert the z_hi coordinate of the ship into
                        \ the y-coordinate of the base of the ship's stick,
                        \ like this (see the deep dive on "The 3D scanner" for
                        \ an explanation):
                        \
                        \   SC = 220 - (z_sign z_hi) / 4
                        \
                        \ though the following code actually does it like this:
                        \
                        \   SC = 255 - (35 + z_hi / 4)

 LDA INWK+7             \ Set A = z_hi / 4
 LSR A                  \
 LSR A                  \ So A is in the range 0-15

 CLC                    \ Clear the C flag

 LDY INWK+8             \ Set Y = z_sign

 BPL SC3                \ If z_sign is positive, skip the following

 EOR #%11111111         \ z_sign is negative, so flip the bits in A and set the
 SEC                    \ C flag. As above, this makes A negative, this time
                        \ with a range of -16 (%11110000) to -1 (%11111111). And
                        \ as we are about to do an ADC, the SEC effectively adds
                        \ another 1 to that value, giving a range of -15 to 0

.SC3

 ADC #35                \ Set A = 35 + A to give a number in the range 20 to 50

 EOR #%11111111         \ Flip all the bits and store in Y2, so Y2 is in the
 STA Y2                 \ range 205 to 235, with a higher z_hi giving a lower Y2

                        \ Now for the stick height, which we calculate using the
                        \ following (see the deep dive on "The 3D scanner" for
                        \ an explanation):
                        \
                        \ A = - (y_sign y_hi) / 2

 LDA INWK+4             \ Set A = y_hi / 2
 LSR A

 CLC                    \ Clear the C flag

 LDY INWK+5             \ Set Y = y_sign

 BMI SCD6               \ If y_sign is negative, skip the following, as we
                        \ already have a positive value in A

 EOR #%11111111         \ y_sign is positive, so flip the bits in A and set the
 SEC                    \ C flag. This makes A negative, and as we are about to
                        \ do an ADC below, the SEC effectively adds another 1 to
                        \ that value to implement two's complement negation, so
                        \ we don't need to add another 1 here

.SCD6

                        \ We now have all the information we need to draw this
                        \ ship on the scanner, namely:
                        \
                        \   X1 = the screen x-coordinate of the ship's dot
                        \
                        \   SC = the screen y-coordinate of the base of the
                        \        stick
                        \
                        \   A = the screen height of the ship's stick, with the
                        \       correct sign for adding to the base of the stick
                        \       to get the dot's y-coordinate
                        \
                        \ First, though, we have to make sure the dot is inside
                        \ the dashboard, by moving it if necessary

 ADC Y2                 \ Set A = Y2 + A, so A now contains the y-coordinate of
                        \ the end of the stick, plus the length of the stick, to
                        \ give us the screen y-coordinate of the dot

 BPL FIXIT              \ If the result has bit 0 clear, then the result has
                        \ overflowed and is bigger than 256, so jump to FIXIT to
                        \ set A to the maximum allowed value of 246 (this
                        \ instruction isn't required as we test both the maximum
                        \ and minimum below, but it might save a few cycles)

 CMP #194               \ If A >= 194, skip the following instruction, as 194 is
 BCS P%+4               \ the minimum allowed value of A

 LDA #194               \ A < 194, so set A to 194, the minimum allowed value
                        \ for the y-coordinate of our ship's dot

 CMP #247               \ If A < 247, skip the following instruction, as 246 is
 BCC P%+4               \ the maximum allowed value of A

.FIXIT

 LDA #246               \ A >= 247, so set A to 246, the maximum allowed value
                        \ for the y-coordinate of our ship's dot

 LDY #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STY VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 JSR CPIX2

 LDA Y1

 SEC                    \ Set A = A - Y2 to get the stick length, by reversing
 SBC Y2                 \ the ADC Y2 we did above. This clears the C flag if the
                        \ result is negative (i.e. the stick length is negative)
                        \ and sets it if the result is positive (i.e. the stick
                        \ length is negative)

                        \ So now we have the following:
                        \
                        \   X1 = the screen x-coordinate of the ship's dot,
                        \        clipped to fit into the dashboard
                        \
                        \   Y1 = the screen y-coordinate of the ship's dot,
                        \        clipped to fit into the dashboard
                        \
                        \   SC = the screen y-coordinate of the base of the
                        \        stick
                        \
                        \   A = the screen height of the ship's stick, with the
                        \       correct sign for adding to the base of the stick
                        \       to get the dot's y-coordinate
                        \
                        \   C = 0 if A is negative, 1 if A is positive
                        \
                        \ and we can get on with drawing the dot and stick

 BEQ RTS                \ ???

 BCC RTS_PLUS_1

 TAX
 INX
 JMP VL1

.VLL1

 LDA R
 EOR (SC),Y
 STA (SC),Y

.VL1

 DEY
 BPL L16F9

 LDA SC+1
 SBC #&02
 STA SC+1
 LDY #&07

.L16F9

 DEX
 BNE VLL1

.RTS

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 RTS

.RTS_PLUS_1

 LDA Y2
 SEC
 SBC Y1
 TAX
 INX
 JMP VL2

.VLL2

 LDA R
 EOR (SC),Y
 STA (SC),Y

.VL2

 INY
 CPY #&08
 BNE L171F

 LDA SC+1
 ADC #&01
 STA SC+1
 LDY #&00

.L171F

 DEX
 BNE VLL2

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 RTS

\ ******************************************************************************
\
\       Name: LL30
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a one-segment line
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X1                  The screen x-coordinate of the start of the line
\
\   Y1                  The screen y-coordinate of the start of the line
\
\   X2                  The screen x-coordinate of the end of the line
\
\   Y2                  The screen y-coordinate of the end of the line
\
\ ******************************************************************************

.LL30

 STY YSAV               \ ???

 LDA #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 JSR LOIN

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 LDY YSAV

 RTS

\ ******************************************************************************
\
\       Name: TWOS
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made single-pixel character row bytes for mode 1
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting one-pixel points in mode 1 (the top part of the
\ split screen).
\
\ ******************************************************************************

.TWOS

 EQUB %10001000
 EQUB %01000100
 EQUB %00100010
 EQUB %00010001

\ ******************************************************************************
\
\       Name: TWOS2
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made double-pixel character row bytes for mode 1
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting two-pixel dashes in mode 1 (the top part of the
\ split screen).
\
\ ******************************************************************************

.TWOS2

 EQUB %11001100
 EQUB %01100110
 EQUB %00110011
 EQUB %00110011

\ ******************************************************************************
\
\       Name: CTWOS
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made single-pixel character row bytes for mode 2
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting one-pixel points in mode 2 (the bottom part of
\ the split screen).
\
\ In mode 2, each character row is one byte, which is two pixels. Rows 0 and 1
\ of the table contain a character row byte with just the left pixel plotted,
\ while rows 2 and 3 contain a character row byte with just the right pixel
\ plotted.
\
\ In other words, looking up row X will return a character row byte with pixel
\ X/2 plotted (if the pixels are numbered 0 and 1).
\
\ There are two extra rows to support the use of CTWOS+2,X indexing in the CPIX2
\ routine. The extra rows are repeats of the first two rows, and save us from
\ having to work out whether CTWOS+2+X needs to be wrapped around when drawing a
\ two-pixel dash that crosses from one character block into another. See CPIX2
\ for more details.
\
\ ******************************************************************************

.CTWOS

 EQUB %10101010
 EQUB %10101010
 EQUB %01010101
 EQUB %01010101
 EQUB %10101010
 EQUB %10101010

\ ******************************************************************************
\
\       Name: LOIN (Part 1 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a line: Calculate the line gradient in the form of deltas
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ This stage calculates the line deltas.
\
\ Arguments:
\
\   X1                  The screen x-coordinate of the start of the line
\
\   Y1                  The screen y-coordinate of the start of the line
\
\   X2                  The screen x-coordinate of the end of the line
\
\   Y2                  The screen y-coordinate of the end of the line
\
\ ******************************************************************************

 JMP HLOIN3             \ This instruction doesn't appear to be used anywhere

                        \ In the cassette and disc versions of Elite, LL30 and
                        \ LOIN are synonyms for the same routine, presumably
                        \ because the two developers each had their own line
                        \ routines to start with, and then chose one of them for
                        \ the final game
                        \
                        \ In the BBC Master version, there are two different
                        \ routines: LL30 draws a one-segment line, while LOIN
                        \ draws multi-segment lines

.LOIN

 LDA #128               \ Set S = 128, which is the starting point for the
 STA S                  \ slope error (representing half a pixel)

 ASL A                  \ Set SWAP = 0, as %10000000 << 1 = 0
 STA SWAP

 LDA X2                 \ Set A = X2 - X1
 SBC X1                 \       = delta_x
                        \
                        \ This subtraction works as the ASL A above sets the C
                        \ flag

 BCS LI1                \ If X2 > X1 then A is already positive and we can skip
                        \ the next three instructions

 EOR #%11111111         \ Negate the result in A by flipping all the bits and
 ADC #1                 \ adding 1, i.e. using two's complement to make it
                        \ positive

 SEC                    \ Set the C flag, ready for the subtraction below

.LI1

 STA P                  \ Store A in P, so P = |X2 - X1|, or |delta_x|

 LDA Y2                 \ Set A = Y2 - Y1
 SBC Y1                 \       = delta_y
                        \
                        \ This subtraction works as we either set the C flag
                        \ above, or we skipped that SEC instruction with a BCS

 BCS LI2                \ If Y2 > Y1 then A is already positive and we can skip
                        \ the next two instructions

 EOR #%11111111         \ Negate the result in A by flipping all the bits and
 ADC #1                 \ adding 1, i.e. using two's complement to make it
                        \ positive

.LI2

 STA Q                  \ Store A in Q, so Q = |Y2 - Y1|, or |delta_y|

 CMP P                  \ If Q < P, jump to STPX to step along the x-axis, as
 BCC STPX               \ the line is closer to being horizontal than vertical

 JMP STPY               \ Otherwise Q >= P so jump to STPY to step along the
                        \ y-axis, as the line is closer to being vertical than
                        \ horizontal

\ ******************************************************************************
\
\       Name: LOIN (Part 2 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a line: Line has a shallow gradient, step right along x-axis
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * |delta_y| < |delta_x|
\
\   * The line is closer to being horizontal than vertical
\
\   * We are going to step right along the x-axis
\
\   * We potentially swap coordinates to make sure X1 < X2
\
\ ******************************************************************************

.STPX

 LDX X1                 \ Set X = X1

 CPX X2                 \ If X1 < X2, jump down to LI3, as the coordinates are
 BCC LI3                \ already in the order that we want

 DEC SWAP               \ Otherwise decrement SWAP from 0 to &FF, to denote that
                        \ we are swapping the coordinates around

 LDA X2                 \ Swap the values of X1 and X2
 STA X1
 STX X2

 TAX                    \ Set X = X1

 LDA Y2                 \ Swap the values of Y1 and Y2
 LDY Y1
 STA Y1
 STY Y2

.LI3

                        \ By this point we know the line is horizontal-ish and
                        \ X1 < X2, so we're going from left to right as we go
                        \ from X1 to X2

 LDY Y1                 \ Look up the page number of the character row that
 LDA ylookup,Y          \ contains the pixel with the y-coordinate in Y1, and
 STA SC+1               \ store it in SC+1, so the high byte of SC is set
                        \ correctly for drawing our line

 LDA Y1                 \ Set Y = Y1 mod 8, which is the pixel row within the
 AND #7                 \ character block at which we want to draw the start of
 TAY                    \ our line (as each character block has 8 rows)

 TXA                    \ Set A = 2 * bits 2-6 of X1
 AND #%11111100         \
 ASL A                  \ and shift bit 7 of X1 into the C flag

 STA SC                 \ Store this value in SC, so SC(1 0) now contains the
                        \ screen address of the far left end (x-coordinate = 0)
                        \ of the horizontal pixel row that we want to draw the
                        \ start of our line on

 BCC P%+4               \ If bit 7 of X1 was set, so X1 > 127, increment the
 INC SC+1               \ high byte of SC(1 0) to point to the second page on
                        \ this screen row, as this page contains the right half
                        \ of the row

 TXA                    \ Set R = X1 mod 4, which is the horizontal pixel number
 AND #3                 \ within the character block where the line starts (as
 STA R                  \ each pixel line in the character block is 4 pixels
                        \ wide)

                        \ The following section calculates:
                        \
                        \   Q = Q / P
                        \     = |delta_y| / |delta_x|
                        \
                        \ using the log tables at logL and log to calculate:
                        \
                        \   A = log(Q) - log(P)
                        \     = log(|delta_y|) - log(|delta_x|)
                        \
                        \ by first subtracting the low bytes of the logarithms
                        \ from the table at LogL, and then subtracting the high
                        \ bytes from the table at log, before applying the
                        \ antilog to get the result of the division and putting
                        \ it in Q

 LDX Q                  \ Set X = |delta_y|

 BEQ LIlog7             \ If |delta_y| = 0, jump to LIlog7 to return 0 as the
                        \ result of the division

 LDA logL,X             \ Set A = log(Q) - log(P)
 LDX P                  \       = log(|delta_y|) - log(|delta_x|)
 SEC                    \
 SBC logL,X             \ by first subtracting the low bytes of log(Q) - log(P)

 LDX Q                  \ And then subtracting the high bytes of log(Q) - log(P)
 LDA log,X              \ so now A contains the high byte of log(Q) - log(P)
 LDX P
 SBC log,X

 BCS LIlog5             \ If the subtraction fitted into one byte and didn't
                        \ underflow, then log(Q) - log(P) < 256, so we jump to
                        \ LIlog5 to return a result of 255

 TAX                    \ Otherwise we set A to the A-th entry from the antilog
 LDA antilog,X          \ table so the result of the division is now in A

 JMP LIlog6             \ Jump to LIlog6 to return the result

.LIlog5

 LDA #255               \ The division is very close to 1, so set A to the
 BNE LIlog6             \ closest possible answer to 256, i.e. 255, and jump to
                        \ LIlog6 to return the result (this BNE is effectively a
                        \ JMP as A is never zero)

.LIlog7

 LDA #0                 \ The numerator in the division is 0, so set A to 0

.LIlog6

 STA Q                  \ Store the result of the division in Q, so we have:
                        \
                        \   Q = |delta_y| / |delta_x|

 LDX P                  \ Set X = P
                        \       = |delta_x|

 BEQ LIEXS              \ If |delta_x| = 0, return from the subroutine, as LIEXS
                        \ contains a BEQ LIEX instruction, and LIEX contains an
                        \ RTS

 INX                    \ Set X = P + 1
                        \       = |delta_x| + 1
                        \
                        \ We add 1 so we can skip the first pixel plot if the
                        \ line is being drawn with swapped coordinates

 LDA Y2                 \ If Y2 < Y1 then skip the following instruction
 CMP Y1
 BCC P%+5

 JMP DOWN               \ Y2 >= Y1, so jump to DOWN, as we need to draw the line
                        \ to the right and down

\ ******************************************************************************
\
\       Name: LOIN (Part 3 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a shallow line going right and up or left and down
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going right and up (no swap) or left and down (swap)
\
\   * X1 < X2 and Y1 > Y2
\
\   * Draw from (X1, Y1) at bottom left to (X2, Y2) at top right
\
\ This routine looks complex, but that's because the loop that's used in the
\ cassette and disc versions has been unrolled to speed it up. The algorithm is
\ unchanged, it's just a lot longer.
\
\ ******************************************************************************

 LDA #%10001000         \ Modify the value in the LDA instruction at LI100 below
 AND COL                \ to contain a pixel mask for the first pixel in the
 STA LI100+1            \ 4-pixel byte, in the colour COL, so that it draws in
                        \ the correct colour

 LDA #%01000100         \ Modify the value in the LDA instruction at LI110 below
 AND COL                \ to contain a pixel mask for the second pixel in the
 STA LI110+1            \ 4-pixel byte, in the colour COL, so that it draws in
                        \ the correct colour

 LDA #%00100010         \ Modify the value in the LDA instruction at LI120 below
 AND COL                \ to contain a pixel mask for the third pixel in the
 STA LI120+1            \ 4-pixel byte, in the colour COL, so that it draws in
                        \ the correct colour

 LDA #%00010001         \ Modify the value in the LDA instruction at LI130 below
 AND COL                \ to contain a pixel mask for the fourth pixel in the
 STA LI130+1            \ 4-pixel byte, in the colour COL, so that it draws in
                        \ the correct colour

                        \ We now work our way along the line from left to right,
                        \ using X as a decreasing counter, and at each count we
                        \ plot a single pixel using the pixel mask in R

 LDA SWAP               \ If SWAP = 0 then we didn't swap the coordinates above,
 BEQ LI190              \ so jump down to LI190 to plot the first pixel

                        \ If we get here then we want to omit the first pixel

 LDA R                  \ Fetch the pixel byte from R, which we set in part 2 to
                        \ the horizontal pixel number within the character block
                        \ where the line starts (so it's 0, 1, 2 or 3)

 BEQ LI100+6            \ If R = 0, jump to LI100+6 to start plotting from the
                        \ second pixel in this byte (LI100+6 points to the DEX
                        \ instruction after the EOR/STA instructions, so the
                        \ pixel doesn't get plotted but we join at the right
                        \ point to decrement X correctly to plot the next three)

 CMP #2                 \ If R < 2 (i.e. R = 1), jump to LI110+6 to skip the
 BCC LI110+6            \ first two pixels but plot the next two

 CLC                    \ Clear the C flag so it doesn't affect the additions
                        \ below

 BEQ LI120+6            \ If R = 2, jump to LI120+6 to to skip the first three
                        \ pixels but plot the last one

 BNE LI130+6            \ If we get here then R must be 3, so jump to LI130+6 to
                        \ skip plotting any of the pixels, but making sure we
                        \ join the routine just after the plotting instructions

.LI190

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

 LDA R                  \ Fetch the pixel byte from R, which we set in part 2 to
                        \ the horizontal pixel number within the character block
                        \ where the line starts (so it's 0, 1, 2 or 3)

 BEQ LI100              \ If R = 0, jump to LI100 to start plotting from the
                        \ first pixel in this byte

 CMP #2                 \ If R < 2 (i.e. R = 1), jump to LI110 to start plotting
 BCC LI110              \ from the second pixel in this byte

 CLC                    \ Clear the C flag so it doesn't affect the additions
                        \ below

 BEQ LI120              \ If R = 2, jump to LI120 to start plotting from the
                        \ third pixel in this byte

 JMP LI130              \ If we get here then R must be 3, so jump to LI130 to
                        \ start plotting from the fourth pixel in this byte

.LI100

 LDA #%10001000         \ Set a mask in A to the first pixel in the 4-pixel byte
                        \ (note that this value is modified by the code at the
                        \ start of this section to be a bit mask for the colour
                        \ in COL)

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

.LIEXS

 BEQ LIEX               \ If we have just reached the right end of the line,
                        \ jump to LIEX to return from the subroutine

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LI110              \ If the addition didn't overflow, jump to LI110

 CLC                    \ Otherwise we just overflowed, so clear the C flag and
 DEY                    \ decrement Y to move to the pixel line above

 BMI LI101              \ If Y is negative we need to move up into the character
                        \ block above, so jump to LI101 to decrement the screen
                        \ address accordingly (jumping back to LI110 afterwards)

.LI110

 LDA #%01000100         \ Set a mask in A to the second pixel in the 4-pixel
                        \ byte (note that this value is modified by the code at
                        \ the start of this section to be a bit mask for the
                        \ colour in COL)

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX               \ If we have just reached the right end of the line,
                        \ jump to LIEX to return from the subroutine

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LI120              \ If the addition didn't overflow, jump to LI120

 CLC                    \ Otherwise we just overflowed, so clear the C flag and
 DEY                    \ decrement Y to move to the pixel line above

 BMI LI111              \ If Y is negative we need to move up into the character
                        \ block above, so jump to LI111 to decrement the screen
                        \ address accordingly (jumping back to LI120 afterwards)

.LI120

 LDA #%00100010         \ Set a mask in A to the third pixel in the 4-pixel byte
                        \ (note that this value is modified by the code at the
                        \ start of this section to be a bit mask for the colour
                        \ in COL)

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX               \ If we have just reached the right end of the line,
                        \ jump to LIEX to return from the subroutine

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LI130              \ If the addition didn't overflow, jump to LI130

 CLC                    \ Otherwise we just overflowed, so clear the C flag and
 DEY                    \ decrement Y to move to the pixel line above

 BMI LI121              \ If Y is negative we need to move up into the character
                        \ block above, so jump to LI121 to decrement the screen
                        \ address accordingly (jumping back to LI130 afterwards)

.LI130

 LDA #%00010001         \ Set a mask in A to the fourth pixel in the 4-pixel
                        \ byte (note that this value is modified by the code at
                        \ the start of this section to be a bit mask for the
                        \ colour in COL)

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LI140              \ If the addition didn't overflow, jump to LI140

 CLC                    \ Otherwise we just overflowed, so clear the C flag and
 DEY                    \ decrement Y to move to the pixel line above

 BMI LI131              \ If Y is negative we need to move up into the character
                        \ block above, so jump to LI131 to decrement the screen
                        \ address accordingly (jumping back to LI140 afterwards)

.LI140

 DEX                    \ Decrement the counter in X

 BEQ LIEX               \ If we have just reached the right end of the line,
                        \ jump to LIEX to return from the subroutine

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #8                 \ character along to the right
 STA SC

 BCC LI100              \ If the addition didn't overflow, jump back to LI100
                        \ to plot the next pixel

 INC SC+1               \ Otherwise the low byte of SC(1 0) just overflowed, so
                        \ increment the high byte SC+1 as we just crossed over
                        \ into the right half of the screen

 CLC                    \ Clear the C flag to avoid breaking any arithmetic

 BCC LI100              \ Jump back to LI100 to plot the next pixel

.LI101

 DEC SC+1               \ If we get here then we need to move up into the
 DEC SC+1               \ character block above, so we decrement the high byte
 LDY #7                 \ of the screen twice (as there are two pages per screen
                        \ row) and set the pixel line to the last line in
                        \ that character block

 BPL LI110              \ Jump back to the instruction after the BMI that called
                        \ this routine

.LI111

 DEC SC+1               \ If we get here then we need to move up into the
 DEC SC+1               \ character block above, so we decrement the high byte
 LDY #7                 \ of the screen twice (as there are two pages per screen
                        \ row) and set the pixel line to the last line in
                        \ that character block

 BPL LI120              \ Jump back to the instruction after the BMI that called
                        \ this routine

.LI121

 DEC SC+1               \ If we get here then we need to move up into the
 DEC SC+1               \ character block above, so we decrement the high byte
 LDY #7                 \ of the screen twice (as there are two pages per screen
                        \ row) and set the pixel line to the last line in
                        \ that character block

 BPL LI130              \ Jump back to the instruction after the BMI that called
                        \ this routine

.LI131

 DEC SC+1               \ If we get here then we need to move up into the
 DEC SC+1               \ character block above, so we decrement the high byte
 LDY #7                 \ of the screen twice (as there are two pages per screen
                        \ row) and set the pixel line to the last line in
                        \ that character block

 BPL LI140              \ Jump back to the instruction after the BMI that called
                        \ this routine

.LIEX

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LOIN (Part 4 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a shallow line going right and down or left and up
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going right and down (no swap) or left and up (swap)
\
\   * X1 < X2 and Y1 <= Y2
\
\   * Draw from (X1, Y1) at top left to (X2, Y2) at bottom right
\
\ This routine looks complex, but that's because the loop that's used in the
\ cassette and disc versions has been unrolled to speed it up. The algorithm is
\ unchanged, it's just a lot longer.
\
\ ******************************************************************************

.DOWN

 LDA #%10001000         \ Modify the value in the LDA instruction at LI200 below
 AND COL                \ to contain a pixel mask for the first pixel in the
 STA LI200+1            \ 4-pixel byte, in the colour COL, so that it draws in
                        \ the correct colour

 LDA #%01000100         \ Modify the value in the LDA instruction at LI210 below
 AND COL                \ to contain a pixel mask for the second pixel in the
 STA LI210+1            \ 4-pixel byte, in the colour COL, so that it draws in
                        \ the correct colour

 LDA #%00100010         \ Modify the value in the LDA instruction at LI220 below
 AND COL                \ to contain a pixel mask for the third pixel in the
 STA LI220+1            \ 4-pixel byte, in the colour COL, so that it draws in
                        \ the correct colour

 LDA #%00010001         \ Modify the value in the LDA instruction at LI230 below
 AND COL                \ to contain a pixel mask for the fourth pixel in the
 STA LI230+1            \ 4-pixel byte, in the colour COL, so that it draws in
                        \ the correct colour

 LDA SC                 \ Set SC(1 0) = SC(1 0) - 248
 SBC #248
 STA SC
 LDA SC+1
 SBC #0
 STA SC+1

 TYA                    \ Set bits 3-7 of Y, which contains the pixel row within
 EOR #%11111000         \ the character, and is therefore in the range 0-7, so
 TAY                    \ this does Y = 248 + Y
                        \
                        \ We therefore have the following:
                        \
                        \   SC(1 0) + Y = SC(1 0) - 248 + 248 + Y
                        \               = SC(1 0) + Y
                        \
                        \ so the screen location we poke hasn't changed, but Y
                        \ is now a larger number and SC is smaller. This means
                        \ we can increment Y to move down a line, as per usual,
                        \ but we can test for when it reaches the bottom of the
                        \ character block with a simple BEQ rather than checking
                        \ whether it's reached 8, so this appears to be a code
                        \ optimisation

                        \ We now work our way along the line from left to right,
                        \ using X as a decreasing counter, and at each count we
                        \ plot a single pixel using the pixel mask in R

 LDA SWAP               \ If SWAP = 0 then we didn't swap the coordinates above,
 BEQ LI191              \ so jump down to LI191 to plot the first pixel

                        \ If we get here then we want to omit the first pixel

 LDA R                  \ Fetch the pixel byte from R, which we set in part 2 to
                        \ the horizontal pixel number within the character block
                        \ where the line starts (so it's 0, 1, 2 or 3)

 BEQ LI200+6            \ If R = 0, jump to LI200+6 to start plotting from the
                        \ second pixel in this byte (LI200+6 points to the DEX
                        \ instruction after the EOR/STA instructions, so the
                        \ pixel doesn't get plotted but we join at the right
                        \ point to decrement X correctly to plot the next three)

 CMP #2                 \ If R < 2 (i.e. R = 1), jump to LI210+6 to skip the
 BCC LI210+6            \ first two pixels but plot the next two

 CLC                    \ Clear the C flag so it doesn't affect the additions
                        \ below

 BEQ LI220+6            \ If R = 2, jump to LI220+6 to to skip the first three
                        \ pixels but plot the last one

 BNE LI230+6            \ If we get here then R must be 3, so jump to LI230+6 to
                        \ skip plotting any of the pixels, but making sure we
                        \ join the routine just after the plotting instructions

.LI191

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

 LDA R                  \ Fetch the pixel byte from R, which we set in part 2 to
                        \ the horizontal pixel number within the character block
                        \ where the line starts (so it's 0, 1, 2 or 3)

 BEQ LI200              \ If R = 0, jump to LI200 to start plotting from the
                        \ first pixel in this byte

 CMP #2                 \ If R < 2 (i.e. R = 1), jump to LI210 to start plotting
 BCC LI210              \ from the second pixel in this byte

 CLC                    \ Clear the C flag so it doesn't affect the additions
                        \ below

 BEQ LI220              \ If R = 2, jump to LI220 to start plotting from the
                        \ third pixel in this byte

 BNE LI230              \ If we get here then R must be 3, so jump to LI130 to
                        \ start plotting from the fourth pixel in this byte
                        \ (this BNE is effectively a JMP as by now R is never
                        \ zero)

.LI200

 LDA #%10001000         \ Set a mask in A to the first pixel in the 4-pixel byte
                        \ (note that this value is modified by the code at the
                        \ start of this section to be a bit mask for the colour
                        \ in COL)

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX               \ If we have just reached the right end of the line,
                        \ jump to LIEX to return from the subroutine

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LI210              \ If the addition didn't overflow, jump to L2110

 CLC                    \ Otherwise we just overflowed, so clear the C flag and
 INY                    \ increment Y to move to the pixel line below

 BEQ LI201              \ If Y is zero we need to move down into the character
                        \ block below, so jump to LI201 to increment the screen
                        \ address accordingly (jumping back to LI210 afterwards)

.LI210

 LDA #%01000100         \ Set a mask in A to the second pixel in the 4-pixel
                        \ byte (note that this value is modified by the code at
                        \ the start of this section to be a bit mask for the
                        \ colour in COL)

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX               \ If we have just reached the right end of the line,
                        \ jump to LIEX to return from the subroutine

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LI220              \ If the addition didn't overflow, jump to LI220

 CLC                    \ Otherwise we just overflowed, so clear the C flag and
 INY                    \ increment Y to move to the pixel line below

 BEQ LI211              \ If Y is zero we need to move down into the character
                        \ block below, so jump to LI211 to increment the screen
                        \ address accordingly (jumping back to LI220 afterwards)

.LI220

 LDA #%00100010         \ Set a mask in A to the third pixel in the 4-pixel byte
                        \ (note that this value is modified by the code at the
                        \ start of this section to be a bit mask for the colour
                        \ in COL)

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX2              \ If we have just reached the right end of the line,
                        \ jump to LIEX2 to return from the subroutine

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LI230              \ If the addition didn't overflow, jump to LI230

 CLC                    \ Otherwise we just overflowed, so clear the C flag and
 INY                    \ increment Y to move to the pixel line below

 BEQ LI221              \ If Y is zero we need to move down into the character
                        \ block below, so jump to LI221 to increment the screen
                        \ address accordingly (jumping back to LI230 afterwards)

.LI230

 LDA #%00010001         \ Set a mask in A to the fourth pixel in the 4-pixel
                        \ byte (note that this value is modified by the code at
                        \ the start of this section to be a bit mask for the
                        \ colour in COL)

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LI240              \ If the addition didn't overflow, jump to LI240

 CLC                    \ Otherwise we just overflowed, so clear the C flag and
 INY                    \ increment Y to move to the pixel line below

 BEQ LI231              \ If Y is zero we need to move down into the character
                        \ block below, so jump to LI231 to increment the screen
                        \ address accordingly (jumping back to LI240 afterwards)

.LI240

 DEX                    \ Decrement the counter in X

 BEQ LIEX2              \ If we have just reached the right end of the line,
                        \ jump to LIEX2 to return from the subroutine

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #8                 \ character along to the right
 STA SC

 BCC LI200              \ If the addition didn't overflow, jump back to LI200
                        \ to plot the next pixel

 INC SC+1               \ Otherwise the low byte of SC(1 0) just overflowed, so
                        \ increment the high byte SC+1 as we just crossed over
                        \ into the right half of the screen

 CLC                    \ Clear the C flag to avoid breaking any arithmetic

 BCC LI200              \ Jump back to LI200 to plot the next pixel

.LI201

 INC SC+1               \ If we get here then we need to move down into the
 INC SC+1               \ character block below, so we increment the high byte
 LDY #248               \ of the screen twice (as there are two pages per screen
                        \ row) and set the pixel line to the first line in that
                        \ character block (as we subtracted 248 from SC above)

 BNE LI210              \ Jump back to the instruction after the BMI that called
                        \ this routine

.LI211

 INC SC+1               \ If we get here then we need to move down into the
 INC SC+1               \ character block below, so we increment the high byte
 LDY #248               \ of the screen twice (as there are two pages per screen
                        \ row) and set the pixel line to the first line in that
                        \ character block (as we subtracted 248 from SC above)

 BNE LI220              \ Jump back to the instruction after the BMI that called
                        \ this routine

.LI221

 INC SC+1               \ If we get here then we need to move down into the
 INC SC+1               \ character block below, so we increment the high byte
 LDY #248               \ of the screen twice (as there are two pages per screen
                        \ row) and set the pixel line to the first line in that
                        \ character block (as we subtracted 248 from SC above)

 BNE LI230              \ Jump back to the instruction after the BMI that called
                        \ this routine

.LI231

 INC SC+1               \ If we get here then we need to move down into the
 INC SC+1               \ character block below, so we increment the high byte
 LDY #248               \ of the screen twice (as there are two pages per screen
                        \ row) and set the pixel line to the first line in that
                        \ character block (as we subtracted 248 from SC above)

 BNE LI240              \ Jump back to the instruction after the BMI that called
                        \ this routine

.LIEX2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LOIN (Part 5 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a line: Line has a steep gradient, step up along y-axis
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * |delta_y| >= |delta_x|
\
\   * The line is closer to being vertical than horizontal
\
\   * We are going to step up along the y-axis
\
\   * We potentially swap coordinates to make sure Y1 >= Y2
\
\ ******************************************************************************

.STPY

 LDY Y1                 \ Set A = Y = Y1
 TYA

 LDX X1                 \ Set X = X1

 CPY Y2                 \ If Y1 >= Y2, jump down to LI15, as the coordinates are
 BCS LI15               \ already in the order that we want

 DEC SWAP               \ Otherwise decrement SWAP from 0 to &FF, to denote that
                        \ we are swapping the coordinates around

 LDA X2                 \ Swap the values of X1 and X2
 STA X1
 STX X2

 TAX                    \ Set X = X1

 LDA Y2                 \ Swap the values of Y1 and Y2
 STA Y1
 STY Y2

 TAY                    \ Set Y = A = Y1

.LI15

                        \ By this point we know the line is vertical-ish and
                        \ Y1 >= Y2, so we're going from top to bottom as we go
                        \ from Y1 to Y2

 LDA ylookup,Y          \ Look up the page number of the character row that
 STA SC+1               \ contains the pixel with the y-coordinate in Y1, and
                        \ store it in the high byte of SC(1 0) at SC+1, so the
                        \ high byte of SC is set correctly for drawing our line

 TXA                    \ Set A = 2 * bits 2-6 of X1
 AND #%11111100         \
 ASL A                  \ and shift bit 7 of X1 into the C flag

 STA SC                 \ Store this value in SC, so SC(1 0) now contains the
                        \ screen address of the far left end (x-coordinate = 0)
                        \ of the horizontal pixel row that we want to draw the
                        \ start of our line on

 BCC P%+4               \ If bit 7 of X1 was set, so X1 > 127, increment the
 INC SC+1               \ high byte of SC(1 0) to point to the second page on
                        \ this screen row, as this page contains the right half
                        \ of the row

 TXA                    \ Set X = X1 mod 4, which is the horizontal pixel number
 AND #3                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 4 pixels
                        \ wide)

 LDA TWOS,X             \ Fetch a 1-pixel byte from TWOS where pixel X is set,
 STA R                  \ and store it in R

                        \ The following section calculates:
                        \
                        \   P = P / Q
                        \     = |delta_x| / |delta_y|
                        \
                        \ using the log tables at logL and log to calculate:
                        \
                        \   A = log(P) - log(Q)
                        \     = log(|delta_x|) - log(|delta_y|)
                        \
                        \ by first subtracting the low bytes of the logarithms
                        \ from the table at LogL, and then subtracting the high
                        \ bytes from the table at log, before applying the
                        \ antilog to get the result of the division and putting
                        \ it in P

 LDX P                  \ Set X = |delta_x|

 BEQ LIfudge            \ If |delta_x| = 0, jump to LIfudge to return 0 as the
                        \ result of the division

 LDA logL,X             \ Set A = log(P) - log(Q)
 LDX Q                  \       = log(|delta_x|) - log(|delta_y|)
 SEC                    \
 SBC logL,X             \ by first subtracting the low bytes of log(P) - log(Q)

 LDX P                  \ And then subtracting the high bytes of log(P) - log(Q)
 LDA log,X              \ so now A contains the high byte of log(P) - log(Q)
 LDX Q
 SBC log,X

 BCS LIlog3             \ If the subtraction fitted into one byte and didn't
                        \ underflow, then log(P) - log(Q) < 256, so we jump to
                        \ LIlog3 to return a result of 255

 TAX                    \ Otherwise we set A to the A-th entry from the antilog
 LDA antilog,X          \ table so the result of the division is now in A

 JMP LIlog2             \ Jump to LIlog2 to return the result

.LIlog3

 LDA #255               \ The division is very close to 1, so set A to the
                        \ closest possible answer to 256, i.e. 255

.LIlog2

 STA P                  \ Store the result of the division in P, so we have:
                        \
                        \   P = |delta_x| / |delta_y|

.LIfudge

 LDX Q                  \ Set X = Q
                        \       = |delta_y|

 BEQ LIEX7              \ If |delta_y| = 0, jump down to LIEX7 to return from
                        \ the subroutine

 INX                    \ Set X = Q + 1
                        \       = |delta_y| + 1
                        \
                        \ We add 1 so we can skip the first pixel plot if the
                        \ line is being drawn with swapped coordinates

 LDA X2                 \ Set A = X2 - X1
 SEC
 SBC X1

 BCS P%+6               \ If X2 >= X1 then skip the following two instructions

 JMP LFT                \ If X2 < X1 then jump to LFT, as we need to draw the
                        \ line to the left and down

.LIEX7

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LOIN (Part 6 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a steep line going up and left or down and right
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going up and left (no swap) or down and right (swap)
\
\   * X1 < X2 and Y1 >= Y2
\
\   * Draw from (X1, Y1) at top left to (X2, Y2) at bottom right
\
\ This routine looks complex, but that's because the loop that's used in the
\ cassette and disc versions has been unrolled to speed it up. The algorithm is
\ unchanged, it's just a lot longer.
\
\ ******************************************************************************

 LDA SWAP               \ If SWAP = 0 then we didn't swap the coordinates above,
 BEQ LI290              \ so jump down to LI290 to plot the first pixel

 TYA                    \ Fetch bits 0-2 of the y-coordinate, so Y contains the
 AND #7                 \ y-coordinate mod 8
 TAY

 BNE P%+5               \ If Y = 0, jump to LI307+8 to start plotting from the
 JMP LI307+8            \ pixel above the top row of this character block
                        \ (LI307+8 points to the DEX instruction after the
                        \ EOR/STA instructions, so the pixel at row 0 doesn't
                        \ get plotted but we join at the right point to
                        \ decrement X and Y correctly to continue plotting from
                        \ the character row above)

 CPY #2                 \ If Y < 2 (i.e. Y = 1), jump to LI306+8 to start
 BCS P%+5               \ plotting from row 0 of this character block, missing
 JMP LI306+8            \ out row 1

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BNE P%+5               \ If Y = 2, jump to LI305+8 to start plotting from row
 JMP LI305+8            \ 1 of this character block, missing out row 2

 CPY #4                 \ If Y < 4 (i.e. Y = 3), jump to LI304+8 to start
 BCS P%+5               \ plotting from row 2 of this character block, missing
 JMP LI304+8            \ out row 3

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BNE P%+5               \ If Y = 4, jump to LI303+8 to start plotting from row
 JMP LI303+8            \ 3 of this character block, missing out row 4

 CPY #6                 \ If Y < 6 (i.e. Y = 5), jump to LI302+8 to start
 BCS P%+5               \ plotting from row 4 of this character block, missing
 JMP LI302+8            \ out row 5

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BEQ P%+5               \ If Y <> 6 (i.e. Y = 7), jump to LI300+8 to start
 JMP LI300+8            \ plotting from row 6 of this character block, missing
                        \ out row 7

 JMP LI301+8            \ Otherwise Y = 6, so jump to LI301+8 to start plotting
                        \ from row 5 of this character block, missing out row 6

.LI290

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

 TYA                    \ Fetch bits 0-2 of the y-coordinate, so Y contains the
 AND #7                 \ y-coordinate mod 8
 TAY

 BNE P%+5               \ If Y = 0, jump to LI307 to start plotting from row 0
 JMP LI307              \ of this character block

 CPY #2                 \ If Y < 2 (i.e. Y = 1), jump to LI306 to start plotting
 BCS P%+5               \ from row 1 of this character block
 JMP LI306

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BNE P%+5               \ If Y = 2, jump to LI305 to start plotting from row 2
 JMP LI305              \ of this character block

 CPY #4                 \ If Y < 4 (i.e. Y = 3), jump to LI304 (via LI304S) to
 BCC LI304S             \ start plotting from row 3 of this character block

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BEQ LI303S             \ If Y = 4, jump to LI303 (via LI303S) to start plotting
                        \ from row 4 of this character block

 CPY #6                 \ If Y < 6 (i.e. Y = 5), jump to LI302 (via LI302S) to
 BCC LI302S             \ start plotting from row 5 of this character block

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BEQ LI301S             \ If Y = 6, jump to LI301 (via LI301S) to start plotting
                        \ from row 6 of this character block

 JMP LI300              \ Otherwise Y = 7, so jump to LI300 to start plotting
                        \ from row 7 of this character block

.LI310

 LSR R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI300, so shift the single
                        \ pixel in R to the right, so the next pixel we plot
                        \ will be at the next x-coordinate along

 BCC LI301              \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI301 to plot the pixel
                        \ on the next character row up

 LDA #%10001000         \ Set a mask in R to the first pixel in the 4-pixel byte
 STA R

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #7                 \ character along to the right (the C flag is set as we
 STA SC                 \ didn't take the above BCC, so the ADC adds 8)

 BCC LI301              \ If the addition didn't overflow, jump to LI301 to plot
                        \ the pixel on the next character row up

 INC SC+1               \ The addition overflowed, so increment the high byte in
                        \ SC(1 0) to move to the next page in screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

.LI301S

 BCC LI301              \ Jump to LI301 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LI311

 LSR R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI301, so shift the single
                        \ pixel in R to the right, so the next pixel we plot
                        \ will be at the next x-coordinate along

 BCC LI302              \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI302 to plot the pixel
                        \ on the next character row up

 LDA #%10001000         \ Set a mask in R to the first pixel in the 4-pixel byte
 STA R

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #7                 \ character along to the right (the C flag is set as we
 STA SC                 \ didn't take the above BCC, so the ADC adds 8)

 BCC LI302              \ If the addition didn't overflow, jump to LI302 to plot
                        \ the pixel on the next character row up

 INC SC+1               \ The addition overflowed, so increment the high byte in
                        \ SC(1 0) to move to the next page in screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

.LI302S

 BCC LI302              \ Jump to LI302 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LI312

 LSR R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI302, so shift the single
                        \ pixel in R to the right, so the next pixel we plot
                        \ will be at the next x-coordinate along

 BCC LI303              \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI303 to plot the pixel
                        \ on the next character row up

 LDA #%10001000         \ Set a mask in R to the first pixel in the 4-pixel byte
 STA R

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #7                 \ character along to the right (the C flag is set as we
 STA SC                 \ didn't take the above BCC, so the ADC adds 8)

 BCC LI303              \ If the addition didn't overflow, jump to LI303 to plot
                        \ the pixel on the next character row up

 INC SC+1               \ The addition overflowed, so increment the high byte in
                        \ SC(1 0) to move to the next page in screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

.LI303S

 BCC LI303              \ Jump to LI303 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LI313

 LSR R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI303, so shift the single
                        \ pixel in R to the right, so the next pixel we plot
                        \ will be at the next x-coordinate along

 BCC LI304              \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI304 to plot the pixel
                        \ on the next character row up

 LDA #%10001000         \ Set a mask in R to the first pixel in the 4-pixel byte
 STA R

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #7                 \ character along to the right (the C flag is set as we
 STA SC                 \ didn't take the above BCC, so the ADC adds 8)

 BCC LI304              \ If the addition didn't overflow, jump to LI304 to plot
                        \ the pixel on the next character row up

 INC SC+1               \ The addition overflowed, so increment the high byte in
                        \ SC(1 0) to move to the next page in screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

.LI304S

 BCC LI304              \ Jump to LI304 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LIEX3

 RTS                    \ Return from the subroutine

.LI300

                        \ Plot a pixel on row 7 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX3              \ If we have just reached the right end of the line,
                        \ jump to LIEX3 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI310              \ If the addition overflowed, jump to LI310 to move to
                        \ the pixel in the next character block along, which
                        \ returns us to LI301 below

.LI301

                        \ Plot a pixel on row 6 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX3              \ If we have just reached the right end of the line,
                        \ jump to LIEX3 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI311              \ If the addition overflowed, jump to LI311 to move to
                        \ the pixel in the next character block along, which
                        \ returns us to LI302 below

.LI302

                        \ Plot a pixel on row 5 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX3              \ If we have just reached the right end of the line,
                        \ jump to LIEX3 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI312              \ If the addition overflowed, jump to LI312 to move to
                        \ the pixel in the next character block along, which
                        \ returns us to LI303 below

.LI303

                        \ Plot a pixel on row 4 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX3              \ If we have just reached the right end of the line,
                        \ jump to LIEX3 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI313              \ If the addition overflowed, jump to LI313 to move to
                        \ the pixel in the next character block along, which
                        \ returns us to LI304 below

.LI304

                        \ Plot a pixel on row 3 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX4              \ If we have just reached the right end of the line,
                        \ jump to LIEX4 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI314              \ If the addition overflowed, jump to LI314 to move to
                        \ the pixel in the next character block along, which
                        \ returns us to LI305 below

.LI305

                        \ Plot a pixel on row 2 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX4              \ If we have just reached the right end of the line,
                        \ jump to LIEX4 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI315              \ If the addition overflowed, jump to LI315 to move to
                        \ the pixel in the next character block along, which
                        \ returns us to LI306 below

.LI306

                        \ Plot a pixel on row 1 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX4              \ If we have just reached the right end of the line,
                        \ jump to LIEX4 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI316              \ If the addition overflowed, jump to LI316 to move to
                        \ the pixel in the next character block along, which
                        \ returns us to LI307 below

.LI307

                        \ Plot a pixel on row 0 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX4              \ If we have just reached the right end of the line,
                        \ jump to LIEX4 to return from the subroutine

 DEC SC+1               \ We just reached the top of the character block, so
 DEC SC+1               \ decrement the high byte in SC(1 0) twice to point to
 LDY #7                 \ the screen row above (as there are two pages per
                        \ screen row) and set Y to point to the last row in the
                        \ new character block

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS P%+5               \ If the addition didn't overflow, jump to LI300 to
 JMP LI300              \ continue plotting in the next character block along

 LSR R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI307 above, so shift the
                        \ single pixel in R to the right, so the next pixel we
                        \ plot will be at the next x-coordinate

 BCS P%+5               \ If the pixel didn't fall out of the right end of R
 JMP LI300              \ into the C flag, then jump to LI400 to continue
                        \ plotting in the next character block along

 LDA #%10001000         \ Otherwise we need to move over to the next character
 STA R                  \ along, so set a mask in R to the first pixel in the
                        \ 4-pixel byte

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #7                 \ character along to the right (the C flag is set as we
 STA SC                 \ took the above BCS, so the ADC adds 8)

 BCS P%+5               \ If the addition didn't overflow, ump to LI300 to
 JMP LI300              \ continue plotting in the next character block along

 INC SC+1               \ The addition overflowed, so increment the high byte in
                        \ SC(1 0) to move to the next page in screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 JMP LI300              \ Jump to LI300 to continue plotting in the next
                        \ character block along

.LIEX4

 RTS                    \ Return from the subroutine

.LI314

 LSR R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI304, so shift the single
                        \ pixel in R to the right, so the next pixel we plot
                        \ will be at the next x-coordinate along

 BCC LI305              \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI305 to plot the pixel
                        \ on the next character row up

 LDA #%10001000         \ Set a mask in R to the first pixel in the 4-pixel byte
 STA R

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #7                 \ character along to the right (the C flag is set as we
 STA SC                 \ didn't take the above BCC, so the ADC adds 8)

 BCC LI305              \ If the addition didn't overflow, jump to LI305 to plot
                        \ the pixel on the next character row up

 INC SC+1               \ The addition overflowed, so increment the high byte in
                        \ SC(1 0) to move to the next page in screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BCC LI305              \ Jump to LI305 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LI315

 LSR R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI305, so shift the single
                        \ pixel in R to the right, so the next pixel we plot
                        \ will be at the next x-coordinate along

 BCC LI306              \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI306 to plot the pixel
                        \ on the next character row up

 LDA #%10001000         \ Set a mask in R to the first pixel in the 4-pixel byte
 STA R

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #7                 \ character along to the right (the C flag is set as we
 STA SC                 \ didn't take the above BCC, so the ADC adds 8)

 BCC LI306              \ If the addition didn't overflow, jump to LI306 to plot
                        \ the pixel on the next character row up

 INC SC+1               \ The addition overflowed, so increment the high byte in
                        \ SC(1 0) to move to the next page in screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BCC LI306              \ Jump to LI306 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LI316

 LSR R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI306, so shift the single
                        \ pixel in R to the right, so the next pixel we plot
                        \ will be at the next x-coordinate along

 BCC LI307              \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI307 to plot the pixel
                        \ on the next character row up

 LDA #%10001000         \ Set a mask in R to the first pixel in the 4-pixel byte
 STA R

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #7                 \ character along to the right (the C flag is set as we
 STA SC                 \ didn't take the above BCC, so the ADC adds 8)

 BCC LI307              \ If the addition didn't overflow, jump to LI307 to plot
                        \ the pixel on the next character row up

 INC SC+1               \ The addition overflowed, so increment the high byte in
                        \ SC(1 0) to move to the next page in screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BCC LI307              \ Jump to LI307 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

\ ******************************************************************************
\
\       Name: LOIN (Part 7 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a steep line going up and right or down and left
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going up and right (no swap) or down and left (swap)
\
\   * X1 >= X2 and Y1 >= Y2
\
\   * Draw from (X1, Y1) at bottom left to (X2, Y2) at top right
\
\ This routine looks complex, but that's because the loop that's used in the
\ cassette and disc versions has been unrolled to speed it up. The algorithm is
\ unchanged, it's just a lot longer.
\
\ ******************************************************************************

.LFT

 LDA SWAP               \ If SWAP = 0 then we didn't swap the coordinates above,
 BEQ LI291              \ so jump down to LI291 to plot the first pixel

 TYA                    \ Fetch bits 0-2 of the y-coordinate, so Y contains the
 AND #7                 \ y-coordinate mod 8
 TAY

 BNE P%+5               \ If Y = 0, jump to LI407+8 to start plotting from the
 JMP LI407+8            \ pixel above the top row of this character block
                        \ (LI407+8 points to the DEX instruction after the
                        \ EOR/STA instructions, so the pixel at row 0 doesn't
                        \ get plotted but we join at the right point to
                        \ decrement X and Y correctly to continue plotting from
                        \ the character row above)

 CPY #2                 \ If Y < 2 (i.e. Y = 1), jump to LI406+8 to start
 BCS P%+5               \ plotting from row 0 of this character block, missing
 JMP LI406+8            \ out row 1

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BNE P%+5               \ If Y = 2, jump to LI405+8 to start plotting from row
 JMP LI405+8            \ 1 of this character block, missing out row 2

 CPY #4                 \ If Y < 4 (i.e. Y = 3), jump to LI404+8 to start
 BCS P%+5               \ plotting from row 2 of this character block, missing
 JMP LI404+8            \ out row 3

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BNE P%+5               \ If Y = 4, jump to LI403+8 to start plotting from row
 JMP LI403+8            \ 3 of this character block, missing out row 4

 CPY #6                 \ If Y < 6 (i.e. Y = 5), jump to LI402+8 to start
 BCS P%+5               \ plotting from row 4 of this character block, missing
 JMP LI402+8            \ out row 5

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BEQ P%+5               \ If Y <> 6 (i.e. Y = 7), jump to LI400+8 to start
 JMP LI400+8            \ plotting from row 6 of this character block, missing
                        \ out row 7

 JMP LI401+8            \ Otherwise Y = 6, so jump to LI401+8 to start plotting
                        \ from row 5 of this character block, missing out row 6

.LI291

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

 TYA                    \ Fetch bits 0-2 of the y-coordinate, so Y contains the
 AND #7                 \ y-coordinate mod 8
 TAY

 BNE P%+5               \ If Y = 0, jump to LI407 to start plotting from row 0
 JMP LI407              \ of this character block

 CPY #2                 \ If Y < 2 (i.e. Y = 1), jump to LI406 to start plotting
 BCS P%+5               \ from row 1 of this character block
 JMP LI406

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BNE P%+5               \ If Y = 2, jump to LI405 to start plotting from row 2
 JMP LI405              \ of this character block

 CPY #4                 \ If Y < 4 (i.e. Y = 3), jump to LI404 (via LI404S) to
 BCC LI404S             \ start plotting from row 3 of this character block

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BEQ LI403S             \ If Y = 4, jump to LI403 (via LI403S) to start plotting
                        \ from row 4 of this character block

 CPY #6                 \ If Y < 6 (i.e. Y = 5), jump to LI402 (via LI402S) to
 BCC LI402S             \ start plotting from row 5 of this character block

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BEQ LI401S             \ If Y = 6, jump to LI401 (via LI401S) to start plotting
                        \ from row 6 of this character block

 JMP LI400              \ Otherwise Y = 7, so jump to LI400 to start plotting
                        \ from row 7 of this character block

.LI410

 ASL R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI400, so shift the single
                        \ pixel in R to the left, so the next pixel we plot will
                        \ be at the previous x-coordinate

 BCC LI401              \ If the pixel didn't fall out of the left end of R
                        \ into the C flag, then jump to LI401 to plot the pixel
                        \ on the next character row up

 LDA #%00010001         \ Otherwise we need to move over to the next character
 STA R                  \ block to the left, so set a mask in R to the fourth
                        \ pixel in the 4-pixel byte

 LDA SC                 \ Subtract 8 from SC, so SC(1 0) now points to the
 SBC #8                 \ previous character along to the left
 STA SC

 BCS P%+4               \ If the subtraction underflowed, decrement the high
 DEC SC+1               \ byte in SC(1 0) to move to the previous page in
                        \ screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

.LI401S

 BCC LI401              \ Jump to LI401 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LI411

 ASL R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI410, so shift the single
                        \ pixel in R to the left, so the next pixel we plot will
                        \ be at the previous x-coordinate

 BCC LI402              \ If the pixel didn't fall out of the left end of R
                        \ into the C flag, then jump to LI402 to plot the pixel
                        \ on the next character row up

 LDA #%00010001         \ Otherwise we need to move over to the next character
 STA R                  \ block to the left, so set a mask in R to the fourth
                        \ pixel in the 4-pixel byte

 LDA SC                 \ Subtract 8 from SC, so SC(1 0) now points to the
 SBC #8                 \ previous character along to the left
 STA SC

 BCS P%+4               \ If the subtraction underflowed, decrement the high
 DEC SC+1               \ byte in SC(1 0) to move to the previous page in
                        \ screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

.LI402S

 BCC LI402              \ Jump to LI402 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LI412

 ASL R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI420, so shift the single
                        \ pixel in R to the left, so the next pixel we plot will
                        \ be at the previous x-coordinate

 BCC LI403              \ If the pixel didn't fall out of the left end of R
                        \ into the C flag, then jump to LI403 to plot the pixel
                        \ on the next character row up

 LDA #%00010001         \ Otherwise we need to move over to the next character
 STA R                  \ block to the left, so set a mask in R to the fourth
                        \ pixel in the 4-pixel byte

 LDA SC                 \ Subtract 8 from SC, so SC(1 0) now points to the
 SBC #8                 \ previous character along to the left
 STA SC

 BCS P%+4               \ If the subtraction underflowed, decrement the high
 DEC SC+1               \ byte in SC(1 0) to move to the previous page in
                        \ screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

.LI403S

 BCC LI403              \ Jump to LI403 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LI413

 ASL R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI430, so shift the single
                        \ pixel in R to the left, so the next pixel we plot will
                        \ be at the previous x-coordinate

 BCC LI404              \ If the pixel didn't fall out of the left end of R
                        \ into the C flag, then jump to LI404 to plot the pixel
                        \ on the next character row up

 LDA #%00010001         \ Otherwise we need to move over to the next character
 STA R                  \ block to the left, so set a mask in R to the fourth
                        \ pixel in the 4-pixel byte

 LDA SC                 \ Subtract 8 from SC, so SC(1 0) now points to the
 SBC #8                 \ previous character along to the left
 STA SC

 BCS P%+4               \ If the subtraction underflowed, decrement the high
 DEC SC+1               \ byte in SC(1 0) to move to the previous page in
                        \ screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

.LI404S

 BCC LI404              \ Jump to LI404 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LIEX5

 RTS                    \ Return from the subroutine

.LI400

                        \ Plot a pixel on row 7 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX5              \ If we have just reached the right end of the line,
                        \ jump to LIEX5 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI410              \ If the addition overflowed, jump to LI410 to move to
                        \ the pixel in the row above, which returns us to LI401
                        \ below

.LI401

                        \ Plot a pixel on row 6 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX5              \ If we have just reached the right end of the line,
                        \ jump to LIEX5 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI411              \ If the addition overflowed, jump to LI411 to move to
                        \ the pixel in the row above, which returns us to LI402
                        \ below

.LI402

                        \ Plot a pixel on row 5 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX5              \ If we have just reached the right end of the line,
                        \ jump to LIEX5 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI412              \ If the addition overflowed, jump to LI412 to move to
                        \ the pixel in the row above, which returns us to LI403
                        \ below

.LI403

                        \ Plot a pixel on row 4 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX5              \ If we have just reached the right end of the line,
                        \ jump to LIEX5 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI413              \ If the addition overflowed, jump to LI413 to move to
                        \ the pixel in the row above, which returns us to LI404
                        \ below

.LI404

                        \ Plot a pixel on row 3 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX6              \ If we have just reached the right end of the line,
                        \ jump to LIEX6 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI414              \ If the addition overflowed, jump to LI414 to move to
                        \ the pixel in the row above, which returns us to LI405
                        \ below

.LI405

                        \ Plot a pixel on row 2 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX6              \ If we have just reached the right end of the line,
                        \ jump to LIEX6 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI415              \ If the addition overflowed, jump to LI415 to move to
                        \ the pixel in the row above, which returns us to LI406
                        \ below

.LI406

                        \ Plot a pixel on row 1 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX6              \ If we have just reached the right end of the line,
                        \ jump to LIEX6 to return from the subroutine

 DEY                    \ Decrement Y to step up along the y-axis

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS LI416              \ If the addition overflowed, jump to LI416 to move to
                        \ the pixel in the row above, which returns us to LI407
                        \ below

.LI407

                        \ Plot a pixel on row 0 of this character block

 LDA R                  \ Fetch the pixel byte from R and apply the colour in
 AND COL                \ COL to it

 EOR (SC),Y             \ Store A into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

 DEX                    \ Decrement the counter in X

 BEQ LIEX6              \ If we have just reached the right end of the line,
                        \ jump to LIEX6 to return from the subroutine

 DEC SC+1               \ We just reached the top of the character block, so
 DEC SC+1               \ decrement the high byte in SC(1 0) twice to point to
 LDY #7                 \ the screen row above (as there are two pages per
                        \ screen row) and set Y to point to the last row in the
                        \ new character block

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCS P%+5               \ If the addition didn't overflow, jump to LI400 to
 JMP LI400              \ continue plotting from row 7 of the new character
                        \ block

 ASL R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI407 above, so shift the
                        \ single pixel in R to the left, so the next pixel we
                        \ plot will be at the previous x-coordinate

 BCS P%+5               \ If the pixel didn't fall out of the left end of R
 JMP LI400              \ into the C flag, then jump to LI400 to continue
                        \ plotting from row 7 of the new character block

 LDA #%00010001         \ Otherwise we need to move over to the next character
 STA R                  \ block to the left, so set a mask in R to the fourth
                        \ pixel in the 4-pixel byte

 LDA SC                 \ Subtract 8 from SC, so SC(1 0) now points to the
 SBC #8                 \ previous character along to the left
 STA SC

 BCS P%+4               \ If the subtraction underflowed, decrement the high
 DEC SC+1               \ byte in SC(1 0) to move to the previous page in
                        \ screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 JMP LI400              \ Jump to LI400 to continue plotting from row 7 of the
                        \ new character block

.LIEX6

 RTS                    \ Return from the subroutine

.LI414

 ASL R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI440, so shift the single
                        \ pixel in R to the left, so the next pixel we plot will
                        \ be at the previous x-coordinate

 BCC LI405              \ If the pixel didn't fall out of the left end of R
                        \ into the C flag, then jump to LI405 to plot the pixel
                        \ on the next character row up

 LDA #%00010001         \ Otherwise we need to move over to the next character
 STA R                  \ block to the left, so set a mask in R to the fourth
                        \ pixel in the 4-pixel byte

 LDA SC                 \ Subtract 8 from SC, so SC(1 0) now points to the
 SBC #8                 \ previous character along to the left
 STA SC

 BCS P%+4               \ If the subtraction underflowed, decrement the high
 DEC SC+1               \ byte in SC(1 0) to move to the previous page in
                        \ screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BCC LI405              \ Jump to LI405 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LI415

 ASL R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI450, so shift the single
                        \ pixel in R to the left, so the next pixel we plot will
                        \ be at the previous x-coordinate

 BCC LI406              \ If the pixel didn't fall out of the left end of R
                        \ into the C flag, then jump to LI406 to plot the pixel
                        \ on the next character row up

 LDA #%00010001         \ Otherwise we need to move over to the next character
 STA R                  \ block to the left, so set a mask in R to the fourth
                        \ pixel in the 4-pixel byte

 LDA SC                 \ Subtract 8 from SC, so SC(1 0) now points to the
 SBC #8                 \ previous character along to the left
 STA SC

 BCS P%+4               \ If the subtraction underflowed, decrement the high
 DEC SC+1               \ byte in SC(1 0) to move to the previous page in
                        \ screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 BCC LI406              \ Jump to LI406 to rejoin the pixel plotting routine
                        \ (this BCC is effectively a JMP as the C flag is clear)

.LI416

 ASL R                  \ If we get here then the slope error just overflowed
                        \ after plotting the pixel in LI460, so shift the single
                        \ pixel in R to the left, so the next pixel we plot will
                        \ be at the previous x-coordinate

 BCC LI407              \ If the pixel didn't fall out of the left end of R
                        \ into the C flag, then jump to LI407 to plot the pixel
                        \ on the next character row up

 LDA #%00010001         \ Otherwise we need to move over to the next character
 STA R                  \ block to the left, so set a mask in R to the fourth
                        \ pixel in the 4-pixel byte

 LDA SC                 \ Subtract 8 from SC, so SC(1 0) now points to the
 SBC #8                 \ previous character along to the left
 STA SC

 BCS P%+4               \ If the subtraction underflowed, decrement the high
 DEC SC+1               \ byte in SC(1 0) to move to the previous page in
                        \ screen memory

 CLC                    \ Clear the C flag so it doesn't affect the arithmetic
                        \ below

 JMP LI407              \ Jump to LI407 to rejoin the pixel plotting routine

\ ******************************************************************************
\
\       Name: HLOIN
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line from (X1, Y1) to (X2, Y1)
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a horizontal orange line in the space view.
\
\ We do not draw a pixel at the end point (X2, X1).
\
\ To understand how this routine works, you might find it helpful to read the
\ deep dive on "Drawing monochrome pixels in mode 5".
\
\ Returns:
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   HLOIN3              Draw a line from (X, Y1) to (X2, Y1) in the colour given
\                       in A
\
\ ******************************************************************************

.HLOIN

 LDA Y1                 \ ???

 AND #3                 \ Set A to the correct order of red/yellow pixels to
 TAX                    \ make this line an orange colour (by using bits 0-1 of
 LDA orange,X           \ the pixel y-coordinate as the index into the orange
                        \ lookup table)

 STA COL                \ Store the correct orange colour in COL

.HLOIN3

 STY YSAV               \ ???

 LDY #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STY VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 LDX X1

 CPX X2                 \ If X1 = X2 then the start and end points are the same,
 BEQ HL6                \ so return from the subroutine (as HL6 contains an RTS)

 BCC HL5                \ If X1 < X2, jump to HL5 to skip the following code, as
                        \ (X1, Y1) is already the left point

 LDA X2                 \ Swap the values of X1 and X2, so we know that (X1, Y1)
 STA X1                 \ is on the left and (X2, Y1) is on the right
 STX X2

 TAX                    \ Set X = X1

.HL5

 DEC X2                 \ Decrement X2 so we do not draw a pixel at the end
                        \ point

 LDY Y1                 \ Look up the page number of the character row that
 LDA ylookup,Y          \ contains the pixel with the y-coordinate in Y1, and
 STA SC+1               \ store it in SC+1, so the high byte of SC is set
                        \ correctly for drawing our line

 TYA                    \ Set A = Y1 mod 8, which is the pixel row within the
 AND #7                 \ character block at which we want to draw our line (as
                        \ each character block has 8 rows)

 STA SC                 \ Store this value in SC, so SC(1 0) now contains the
                        \ screen address of the far left end (x-coordinate = 0)
                        \ of the horizontal pixel row that we want to draw our
                        \ horizontal line on

 TXA                    \ Set Y = 2 * bits 2-6 of X1
 AND #%11111100         \
 ASL A                  \ and shift bit 7 of X1 into the C flag
 TAY

 BCC P%+4               \ If bit 7 of X1 was set, so X1 > 127, increment the
 INC SC+1               \ high byte of SC(1 0) to point to the second page on
                        \ this screen row, as this page contains the right half
                        \ of the row

.HL1

 TXA                    \ Set T = bits 2-7 of X1, which will contain the
 AND #%11111100         \ the character number of the start of the line * 4
 STA T

 LDA X2                 \ Set A = bits 2-7 of X2, which will contain the
 AND #%11111100         \ the character number of the end of the line * 4

 SEC                    \ Set A = A - T, which will contain the number of
 SBC T                  \ character blocks we need to fill - 1 * 4

 BEQ HL2                \ If A = 0 then the start and end character blocks are
                        \ the same, so the whole line fits within one block, so
                        \ jump down to HL2 to draw the line

                        \ Otherwise the line spans multiple characters, so we
                        \ start with the left character, then do any characters
                        \ in the middle, and finish with the right character

 LSR A                  \ Set R = A / 4, so R now contains the number of
 LSR A                  \ character blocks we need to fill - 1
 STA R

 LDA X1                 \ Set X = X1 mod 4, which is the horizontal pixel number
 AND #3                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 4 pixels
                        \ wide)

 LDA TWFR,X             \ Fetch a ready-made byte with X pixels filled in at the
                        \ right end of the byte (so the filled pixels start at
                        \ point X and go all the way to the end of the byte),
                        \ which is the shape we want for the left end of the
                        \ line

 AND COL                \ Apply the pixel mask in A to the four-pixel block of
                        \ coloured pixels in COL, so we now know which bits to
                        \ set in screen memory to paint the relevant pixels in
                        \ the required colour

 EOR (SC),Y             \ Store this into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen,
                        \ so we have now drawn the line's left cap

 TYA                    \ Set Y = Y + 8 so (SC),Y points to the next character
 ADC #8                 \ block along, on the same pixel row as before
 TAY

 BCS HL7                \ If the above addition overflowed, then we have just
                        \ crossed over from the left half of the screen into the
                        \ right half, so call HL7 to increment the high byte in
                        \ SC+1 so that SC(1 0) points to the page in screen
                        \ memory for the right half of the screen row. HL7 also
                        \ clears the C flag and jumps back to HL8, so this acts
                        \ like a conditional JSR instruction

.HL8

 LDX R                  \ Fetch the number of character blocks we need to fill
                        \ from R

 DEX                    \ Decrement the number of character blocks in X

 BEQ HL3                \ If X = 0 then we only have the last block to do (i.e.
                        \ the right cap), so jump down to HL3 to draw it

 CLC                    \ Otherwise clear the C flag so we can do some additions
                        \ while we draw the character blocks with full-width
                        \ lines in them

.HLL1

 LDA COL                \ Store a full-width 4-pixel horizontal line of colour
 EOR (SC),Y             \ COL in SC(1 0) so that it draws the line on-screen,
 STA (SC),Y             \ using EOR logic so it merges with whatever is already
                        \ on-screen

 TYA                    \ Set Y = Y + 8 so (SC),Y points to the next character
 ADC #8                 \ block along, on the same pixel row as before
 TAY

 BCS HL9                \ If the above addition overflowed, then we have just
                        \ crossed over from the left half of the screen into the
                        \ right half, so call HL9 to increment the high byte in
                        \ SC+1 so that SC(1 0) points to the page in screen
                        \ memory for the right half of the screen row. HL9 also
                        \ clears the C flag and jumps back to HL10, so this acts
                        \ like a conditional JSR instruction

.HL10

 DEX                    \ Decrement the number of character blocks in X

 BNE HLL1               \ Loop back to draw more full-width lines, if we have
                        \ any more to draw

.HL3

 LDA X2                 \ Now to draw the last character block at the right end
 AND #3                 \ of the line, so set X = X2 mod 3, which is the
 TAX                    \ horizontal pixel number where the line ends

 LDA TWFL,X             \ Fetch a ready-made byte with X pixels filled in at the
                        \ left end of the byte (so the filled pixels start at
                        \ the left edge and go up to point X), which is the
                        \ shape we want for the right end of the line

 AND COL                \ Apply the pixel mask in A to the four-pixel block of
                        \ coloured pixels in COL, so we now know which bits to
                        \ set in screen memory to paint the relevant pixels in
                        \ the required colour

 EOR (SC),Y             \ Store this into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen,
                        \ so we have now drawn the line's right cap

.HL6

 LDY #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STY VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 LDY YSAV

 RTS                    \ Return from the subroutine

.HL2

                        \ If we get here then the entire horizontal line fits
                        \ into one character block

 LDA X1                 \ Set X = X1 mod 4, which is the horizontal pixel number
 AND #3                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 4 pixels
                        \ wide)

 LDA TWFR,X             \ Fetch a ready-made byte with X pixels filled in at the
 STA T                  \ right end of the byte (so the filled pixels start at
                        \ point X and go all the way to the end of the byte)

 LDA X2                 \ Set X = X2 mod 4, which is the horizontal pixel number
 AND #3                 \ where the line ends
 TAX

 LDA TWFL,X             \ Fetch a ready-made byte with X pixels filled in at the
                        \ left end of the byte (so the filled pixels start at
                        \ the left edge and go up to point X)

 AND T                  \ We now have two bytes, one (T) containing pixels from
                        \ the starting point X1 onwards, and the other (A)
                        \ containing pixels up to the end point at X2, so we can
                        \ get the actual line we want to draw by AND'ing them
                        \ together. For example, if we want to draw a line from
                        \
                        \   T       = %00111111
                        \   A       = %11111100
                        \   T AND A = %00111100
                        \
                        \ so if we stick T AND A in screen memory, that's what
                        \ we do here, setting A = A AND T

 AND COL                \ Apply the pixel mask in A to the four-pixel block of
                        \ coloured pixels in COL, so we now know which bits to
                        \ set in screen memory to paint the relevant pixels in
                        \ the required colour

 EOR (SC),Y             \ Store our horizontal line byte into screen memory at
 STA (SC),Y             \ SC(1 0), using EOR logic so it merges with whatever is
                        \ already on-screen

 LDY #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STY VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 LDY YSAV

 RTS                    \ Return from the subroutine

.HL7

 INC SC+1               \ We have just crossed over from the left half of the
                        \ screen into the right half, so increment the high byte
                        \ in SC+1 so that SC(1 0) points to the page in screen
                        \ memory for the right half of the screen row

 CLC                    \ Clear the C flag (as HL7 is called with the C flag
                        \ set, which this instruction reverts)

 JMP HL8                \ Jump back to HL8, just after the instruction that
                        \ called HL7

.HL9

 INC SC+1               \ We have just crossed over from the left half of the
                        \ screen into the right half, so increment the high byte
                        \ in SC+1 so that SC(1 0) points to the page in screen
                        \ memory for the right half of the screen row

 CLC                    \ Clear the C flag (as HL9 is called with the C flag
                        \ set, which this instruction reverts)

 JMP HL10               \ Jump back to HL10, just after the instruction that
                        \ called HL9

\ ******************************************************************************
\
\       Name: TWFL
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made character rows for the left end of a horizontal line
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting horizontal line end caps in mode 1 (the top part
\ of the split screen). This table provides a byte with pixels at the left end,
\ which is used for the right end of the line.
\
\ See the HLOIN routine for details.
\
\ ******************************************************************************

.TWFL

 EQUB %10001000
 EQUB %11001100
 EQUB %11101110
 EQUB %11111111

\ ******************************************************************************
\
\       Name: TWFR
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made character rows for the right end of a horizontal line
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting horizontal line end caps in mode 1 (the top part
\ of the split screen). This table provides a byte with pixels at the left end,
\ which is used for the right end of the line.
\
\ See the HLOIN routine for details.
\
\ ******************************************************************************

.TWFR

 EQUB %11111111
 EQUB %01110111
 EQUB %00110011
 EQUB %00010001

\ ******************************************************************************
\
\       Name: orange
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Lookup table for 2-pixel mode 1 orange pixels for the sun
\
\ ------------------------------------------------------------------------------
\
\ Blocks of orange (as used when drawing the sun) have alternate red and yellow
\ pixels in a cross-hatch pattern. The cross-hatch pattern is made up of offset
\ rows that are 2 pixels high, and it is made up of red and yellow rectangles,
\ each of which is 2 pixels high and 1 pixel wide. The result looks like this:
\
\   ...ryryryryryryryry...
\   ...ryryryryryryryry...
\   ...yryryryryryryryr...
\   ...yryryryryryryryr...
\   ...ryryryryryryryry...
\   ...ryryryryryryryry...
\
\ and so on, repeating every four pixel rows.
\
\ This is implemented with the following lookup table, where bits 0-1 of the
\ pixel y-coordinate are used as the index, to fetch the correct pattern to use.
\
\ Rows with y-coordinates ending in %00 or %01 fetch the red/yellow pattern from
\ the table, while rows with y-coordinates ending in %10 or %11 fetch the
\ yellow/red pattern, so the pattern repeats every four pixel rows.
\
\ ******************************************************************************

.orange

 EQUB %10100101         \ Four mode 1 pixels of colour 2, 1, 2, 1 (red/yellow)
 EQUB %10100101
 EQUB %01011010         \ Four mode 1 pixels of colour 1, 2, 1, 2 (yellow/red)
 EQUB %01011010

\ ******************************************************************************
\
\       Name: PIX1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (YY+1 SYL+Y) = (A P) + (S R) and draw stardust particle
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   (YY+1 SYL+Y) = (A P) + (S R)
\
\ and draw a stardust particle at (X1,Y1) with distance ZZ.
\
\ Arguments:
\
\   (A P)               A is the angle ALPHA or BETA, P is always 0
\
\   (S R)               YY(1 0) or YY(1 0) + Q * A
\
\   Y                   Stardust particle number
\
\   X1                  The x-coordinate offset
\
\   Y1                  The y-coordinate offset
\
\   ZZ                  The distance of the point (further away = smaller point)
\
\ ******************************************************************************

.PIX1

 JSR ADD_DUPLICATE      \ Set (A X) = (A P) + (S R)

 STA YY+1               \ Set YY+1 to A, the high byte of the result

 TXA                    \ Set SYL+Y to X, the low byte of the result
 STA SYL,Y

                        \ Fall through into PIX1 to draw the stardust particle
                        \ at (X1,Y1)

\ ******************************************************************************
\
\       Name: PIXEL2
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a stardust particle relative to the screen centre
\
\ ------------------------------------------------------------------------------
\
\ Draw a point (X1, Y1) from the middle of the screen with a size determined by
\ a distance value. Used to draw stardust particles.
\
\ Arguments:
\
\   X1                  The x-coordinate offset
\
\   Y1                  The y-coordinate offset (positive means up the screen
\                       from the centre, negative means down the screen)
\
\   ZZ                  The distance of the point (further away = smaller point)
\
\ ******************************************************************************

.PIXEL2

 LDA X1                 \ Fetch the x-coordinate offset into A

 BPL PX1                \ If the x-coordinate offset is positive, jump to PX1
                        \ to skip the following negation

 EOR #%01111111         \ The x-coordinate offset is negative, so flip all the
 CLC                    \ bits apart from the sign bit and add 1, to negate
 ADC #1                 \ it to a positive number, i.e. A is now |X1|

.PX1

 EOR #%10000000         \ Set X = -|A|
 TAX                    \       = -|X1|

 LDA Y1                 \ Fetch the y-coordinate offset into A and clear the
 AND #%01111111         \ sign bit, so A = |Y1|

 CMP #96                \ If |Y1| >= 96 then it's off the screen (as 96 is half
 BCS PX4                \ the screen height), so return from the subroutine (as
                        \ PX4 contains an RTS)

 LDA Y1                 \ Fetch the y-coordinate offset into A

 BPL PX2                \ If the y-coordinate offset is positive, jump to PX2
                        \ to skip the following negation

 EOR #%01111111         \ The y-coordinate offset is negative, so flip all the
 ADC #1                 \ bits apart from the sign bit and subtract 1, to negate
                        \ it to a positive number, i.e. A is now |Y1|

.PX2

 STA T                  \ Set A = 97 - A
 LDA #97                \       = 97 - |Y1|
 SBC T                  \
                        \ so if Y is positive we display the point up from the
                        \ centre, while a negative Y means down from the centre

                        \ Fall through into PIXEL to draw the stardust at the
                        \ screen coordinates in (X, A)

\ ******************************************************************************
\
\       Name: PIXEL
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a 1-pixel dot, 2-pixel dash or 4-pixel square
\  Deep dive: Drawing monochrome pixels in mode 5
\
\ ------------------------------------------------------------------------------
\
\ Draw a point at screen coordinate (X, A) with the point size determined by the
\ distance in ZZ. This applies to the top part of the screen (the 4-colour mode
\ 5 portion).
\
\ Arguments:
\
\   X                   The screen x-coordinate of the point to draw
\
\   A                   The screen y-coordinate of the point to draw
\
\   ZZ                  The distance of the point (further away = smaller point)
\
\ Returns:
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   PX4                 Contains an RTS
\
\ ******************************************************************************

.PIXEL

 STY T1                 \ ????

 LDY #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STY VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 TAY

 LDA ylookup,Y          \ Look up the page number of the character row that
 STA SC+1               \ contains the pixel with the y-coordinate in Y, and
                        \ store it in the high byte of SC(1 0) at SC+1

 TXA                    \ Each character block contains 8 pixel rows, so to get
 AND #%11111100         \ the address of the first byte in the character block
 ASL A                  \ that we need to draw into, as an offset from the start
                        \ of the row, we clear bits 0-1 and shift left to double
                        \ it (as each character row contains two pages of bytes,
                        \ or 512 bytes, which cover 256 pixels). This also
                        \ shifts bit 7 of the x-coordinate into the C flag

 STA SC                 \ Store the address of the character block in the low
                        \ byte of SC(1 0), so now SC(1 0) points to the
                        \ character block we need to draw into

 BCC P%+4               \ If the C flag is clear then skip the next instruction

 INC SC+1               \ The C flag is set, which means bit 7 of X1 was set
                        \ before the ASL above, so the x-coordinate is in the
                        \ right half of the screen (i.e. in the range 128-255).
                        \ Each row takes up two pages in memory, so the right
                        \ half is in the second page but SC+1 contains the value
                        \ we looked up from ylookup, which is the page number of
                        \ the first memory page for the row... so we need to
                        \ increment SC+1 to point to the correct page

 TYA                    \ Set Y to just bits 0-2 of the y-coordinate, which will
 AND #%00000111         \ be the number of the pixel row we need to draw into
 TAY                    \ within the character block

 TXA                    \ Copy bits 0-1 of the x-coordinate to bits 0-1 of X,
 AND #%00000011         \ which will now be in the range 0-3, and will contain
 TAX                    \ the two pixels to show in the character row

 LDA ZZ                 \ Set A to the pixel's distance in ZZ

 CMP #80                \ If the pixel's ZZ distance is < 80, then the dot is
 BCC PX21               \ pretty close, so jump to PX21 to to draw a four-pixel
                        \ square

 LDA TWOS2,X            \ Fetch a mode 1 2-pixel byte with the pixels set as in
 AND COL                \ X, and AND with the colour byte we fetched into COL
                        \ so that pixel takes on the colour we want to draw
                        \ (i.e. A is acting as a mask on the colour byte)

 EOR (SC),Y             \ Draw the pixel on-screen using EOR logic, so we can
 STA (SC),Y             \ remove it later without ruining the background that's
                        \ already on-screen

 LDY #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STY VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 LDY T1

.PX4

 RTS                    \ Return from the subroutine

.PX21

                        \ If we get here, we need to plot a 4-pixel square in
                        \ in the correct colour for this pixel's distance

 LDA TWOS2,X            \ Fetch a mode 1 2-pixel byte with the pixels set as in
 AND COL                \ X, and AND with the colour byte we fetched into COL
                        \ so that pixel takes on the colour we want to draw
                        \ (i.e. A is acting as a mask on the colour byte)

 EOR (SC),Y             \ Draw the pixel on-screen using EOR logic, so we can
 STA (SC),Y             \ remove it later without ruining the background that's
                        \ already on-screen

 DEY                    \ Reduce Y by 1 to point to the pixel row above the one
 BPL P%+4               \ we just plotted, and if it is still positive, skip the
                        \ next instruction

 LDY #1                 \ Reducing Y by 1 made it negative, which means Y was
                        \ 0 before we did the DEY above, so set Y to 1 to point
                        \ to the pixel row after the one we just plotted

                        \ We now draw our second dash

 LDA TWOS2,X            \ Fetch a mode 1 2-pixel byte with the pixels set as in
 AND COL                \ X, and AND with the colour byte we fetched into COL
                        \ so that pixel takes on the colour we want to draw
                        \ (i.e. A is acting as a mask on the colour byte)

 EOR (SC),Y             \ Draw the pixel on-screen using EOR logic, so we can
 STA (SC),Y             \ remove it later without ruining the background that's
                        \ already on-screen

 LDY #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STY VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 LDY T1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PXCL
\       Type: Variable
\   Category: Drawing pixels
\    Summary: A four-colour mode 1 pixel byte that represents a dot's distance
\
\ ------------------------------------------------------------------------------
\
\ The following table contains colour bytes for 2-pixel mode 1 pixels, with the
\ index into the table representing distance. Closer pixels are at the top, so
\ the closest pixels are cyan/red, then yellow, then red, then red/yellow, then
\ yellow.
\
\ That said, this table is only used with odd distance values, as set in the
\ parasite's PIXEL3 routine, so in practice the four distances are yellow, red,
\ red/yellow, yellow.
\
\ ******************************************************************************

.PXCL

 EQUB WHITE             \ Four mode 1 pixels of colour 3, 2, 3, 2 (cyan/red)
 EQUB %00001111         \ Four mode 1 pixels of colour 1 (yellow)
 EQUB %00001111         \ Four mode 1 pixels of colour 1 (yellow)
 EQUB %11110000         \ Four mode 1 pixels of colour 2 (red)
 EQUB %11110000         \ Four mode 1 pixels of colour 2 (red)
 EQUB %10100101         \ Four mode 1 pixels of colour 2, 1, 2, 1 (red/yellow)
 EQUB %10100101         \ Four mode 1 pixels of colour 2, 1, 2, 1 (red/yellow)
 EQUB %00001111         \ Four mode 1 pixels of colour 1, 1, 1, 1 (yellow)

\ ******************************************************************************
\
\       Name: DOT
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Draw a dot on the compass
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   COMX                The screen pixel x-coordinate of the dot
\
\   COMY                The screen pixel y-coordinate of the dot
\
\   COMC                The colour and thickness of the dot:
\
\                         * &F0 = a double-height dot in yellow/white, for when
\                           the object in the compass is in front of us
\
\                         * &FF = a single-height dot in green/cyan, for when
\                           the object in the compass is behind us
\
\ ******************************************************************************

.DOT

 LDA #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 LDA COMX               \ Set X1 = COMX, the x-coordinate of the dot
 STA X1

 LDX COMC               \ Set COL = COMC, the mode 2 colour byte for the dot
 STX COL

 LDA COMY               \ Set Y1 = COMY, the y-coordinate of the dot

 CPX #&0F               \ ???
 BNE L1EA5

 JSR CPIX2

 LDA Y1
 DEC A

.L1EA5

 JSR CPIX2

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 RTS

\ ******************************************************************************
\
\       Name: CPIX2
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a single-height dot on the dashboard
\
\ ------------------------------------------------------------------------------
\
\ Draw a single-height mode 2 dash (1 pixel high, 2 pixels wide).
\
\ Arguments:
\
\   X1                  The screen pixel x-coordinate of the dash
\
\   Y1                  The screen pixel y-coordinate of the dash
\
\   COL                 The colour of the dash as a mode 2 character row byte
\
\ ******************************************************************************

.CPIX2

 STA Y1                 \ ???

\.CPIX                  \ This label is commented out in the original source. It
                        \ would provide a new entry point with A specifying the
                        \ y-coordinate instead of Y1, but it isn't used anywhere

 TAY                    \ Store the y-coordinate in Y

 LDA ylookup,Y          \ Look up the page number of the character row that
 STA SC+1               \ contains the pixel with the y-coordinate in Y, and
                        \ store it in the high byte of SC(1 0) at SC+1

 LDA X1                 \ Each character block contains 8 pixel rows, so to get
 AND #%11111100         \ the address of the first byte in the character block
 ASL A                  \ that we need to draw into, as an offset from the start
                        \ of the row, we clear bits 0-1 and shift left to double
                        \ it (as each character row contains two pages of bytes,
                        \ or 512 bytes, which cover 256 pixels). This also
                        \ shifts bit 7 of X1 into the C flag

 STA SC                 \ Store the address of the character block in the low
                        \ byte of SC(1 0), so now SC(1 0) points to the
                        \ character block we need to draw into

 BCC P%+5               \ If the C flag is clear then skip the next two
                        \ instructions

 INC SC+1               \ The C flag is set, which means bit 7 of X1 was set
                        \ before the ASL above, so the x-coordinate is in the
                        \ right half of the screen (i.e. in the range 128-255).
                        \ Each row takes up two pages in memory, so the right
                        \ half is in the second page but SC+1 contains the value
                        \ we looked up from ylookup, which is the page number of
                        \ the first memory page for the row... so we need to
                        \ increment SC+1 to point to the correct page

 CLC                    \ Clear the C flag

 TYA                    \ Set Y to just bits 0-2 of the y-coordinate, which will
 AND #%00000111         \ be the number of the pixel row we need to draw into
 TAY                    \ within the character block

 LDA X1                 \ Copy bit 1 of X1 to bit 1 of X. X will now be either
 AND #%00000010         \ 0 or 2, and will be double the pixel number in the
 TAX                    \ character row for the left pixel in the dash (so 0
                        \ means the left pixel in the 2-pixel character row,
                        \ while 2 means the right pixel)

 LDA CTWOS,X            \ Fetch a mode 2 1-pixel byte with the pixel position
 AND COL                \ at X/2, and AND with the colour byte so that pixel
                        \ takes on the colour we want to draw (i.e. A is acting
                        \ as a mask on the colour byte)

 EOR (SC),Y             \ Draw the pixel on-screen using EOR logic, so we can
 STA (SC),Y             \ remove it later without ruining the background that's
                        \ already on-screen

 LDA CTWOS+2,X          \ Fetch a mode 2 1-pixel byte with the pixel position
                        \ at (X+1)/2, so we can draw the right pixel of the dash

 BPL CP1                \ The CTWOS table has 2 extra rows at the end of it that
                        \ repeat the first values, %10101010, so if we have not
                        \ fetched that value, then the right pixel of the dash
                        \ is in the same character block as the left pixel, so
                        \ jump to CP1 to draw it

 LDA SC                 \ Otherwise the left pixel we drew was at the last
 ADC #8                 \ position of four in this character block, so we add
 STA SC                 \ 8 to the screen address to move onto the next block
                        \ along (as there are 8 bytes in a character block).
                        \ The C flag was cleared above, so this ADC is correct

 BCC P%+4               \ If the addition we just did overflowed, then increment
 INC SC+1               \ the high byte of SC(1 0), as this means we just moved
                        \ into the right half of the screen row

 LDA CTWOS+2,X          \ Refetch the mode 2 1-pixel byte, as we just overwrote
                        \ A (the byte will still be the fifth or sixth byte from
                        \ the table, which is correct as we want to draw the
                        \ leftmost pixel in the next character along as the
                        \ dash's right pixel)

.CP1

 AND COL                \ Apply the colour mask to the pixel byte, as above

 STA R                  \ ???

 EOR (SC),Y             \ Draw the dash's right pixel according to the mask in
 STA (SC),Y             \ A, with the colour in COL, using EOR logic, just as
                        \ above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ECBLB2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Start up the E.C.M. (indicator, start countdown and make sound)
\
\ ------------------------------------------------------------------------------
\
\ Light up the E.C.M. indicator bulb on the dashboard, set the E.C.M. countdown
\ timer to 32, and start making the E.C.M. sound.
\
\ ******************************************************************************

.ECBLB2

 LDA #32                \ Set the E.C.M. countdown timer in ECMA to 32
 STA ECMA

                        \ Fall through into ECBLB to light up the E.C.M. bulb

\ ******************************************************************************
\
\       Name: ECBLB
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Light up the E.C.M. indicator bulb ("E") on the dashboard
\
\ ******************************************************************************

.ECBLB

 LDA #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 LDA #8*14              \ The E.C.M. bulb is in character block number 14 with
 STA SC                 \ each character taking 8 bytes, so this sets the low
                        \ byte of the screen address of the character block we
                        \ want to draw to

 LDA #&7A               \ Set the high byte of SC(1 0) to &7A, as the bulbs are
 STA SC+1               \ both in the character row from &7A00 to &7BFF, and the
                        \ E.C.M. bulb is in the left half, which is from &7A00
                        \ to &7AFF

 LDY #15                \ Now to poke the bulb bitmap into screen memory, and
                        \ there are two character blocks' worth, each with eight
                        \ lines of one byte, so set a counter in Y for 16 bytes

.BULL2

 LDA ECBT,Y             \ Fetch the Y-th byte of the bulb bitmap

 EOR (SC),Y             \ EOR the byte with the current contents of screen
                        \ memory, so drawing the bulb when it is already
                        \ on-screen will erase it

 STA (SC),Y             \ Store the Y-th byte of the bulb bitmap in screen
                        \ memory

 DEY                    \ Decrement the loop counter

 BPL BULL2              \ Loop back to poke the next byte until we have done
                        \ all 16 bytes across two character blocks

 BMI BULB2              \ ???

\ ******************************************************************************
\
\       Name: SPBLB
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Draw (or erase) the space station indicator ("S") on the dashboard
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   BULB2               ???
\
\ ******************************************************************************

.SPBLB

 LDA #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 LDA #16*8              \ The space station bulb is in character block number 48
 STA SC                 \ (counting from the left edge of the screen), with the
                        \ first half of the row in one page, and the second half
                        \ in another. We want to set the screen address to point
                        \ to the second part of the row, as the bulb is in that
                        \ half, so that's character block number 16 within that
                        \ second half (as the first half takes up 32 character
                        \ blocks, so given that each character block takes up 8
                        \ bytes, this sets the low byte of the screen address
                        \ of the character block we want to draw to

 LDA #&7B               \ Set the high byte of SC(1 0) to &7B, as the bulbs are
 STA SC+1               \ both in the character row from &7A00 to &7BFF, and the
                        \ space station bulb is in the right half, which is from
                        \ &7B00 to &7BFF

 LDY #15                \ Now to poke the bulb bitmap into screen memory, and
                        \ there are two character blocks' worth, each with eight
                        \ lines of one byte, so set a counter in Y for 16 bytes

.BULL

 LDA SPBT,Y             \ Fetch the Y-th byte of the bulb bitmap

 EOR (SC),Y             \ EOR the byte with the current contents of screen
                        \ memory, so drawing the bulb when it is already
                        \ on-screen will erase it

 STA (SC),Y             \ Store the Y-th byte of the bulb bitmap in screen
                        \ memory

 DEY                    \ Decrement the loop counter

 BPL BULL               \ Loop back to poke the next byte until we have done
                        \ all 16 bytes across two character blocks

.BULB2

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 RTS

\ ******************************************************************************
\
\       Name: SPBT
\       Type: Variable
\   Category: Dashboard
\    Summary: The bitmap definition for the space station indicator bulb
\
\ ------------------------------------------------------------------------------
\
\ The bitmap definition for the space station indicator's "S" bulb that gets
\ displayed on the dashboard.
\
\ The bulb is four pixels wide, so it covers two mode 2 character blocks, one
\ containing the left half of the "S", and the other the right half, which are
\ displayed next to each other. Each pixel is in mode 2 colour 7 (%1111), which
\ is white.
\
\ ******************************************************************************

.SPBT

                        \ Left half of the "S" bulb
                        \
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x
 EQUB %10101010         \ x .
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x
 EQUB %00000000         \ . .
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x

                        \ Right half of the "S" bulb
                        \
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x
 EQUB %00000000         \ . .
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x
 EQUB %01010101         \ . x
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x

                        \ Combined "S" bulb
                        \
                        \ x x x x
                        \ x x x x
                        \ x . . .
                        \ x x x x
                        \ x x x x
                        \ . . . x
                        \ x x x x
                        \ x x x x

\ ******************************************************************************
\
\       Name: ECBT
\       Type: Variable
\   Category: Dashboard
\    Summary: The character bitmap for the E.C.M. indicator bulb
\
\ ------------------------------------------------------------------------------
\
\ The character bitmap for the E.C.M. indicator's "E" bulb that gets displayed
\ on the dashboard.
\
\ The bulb is four pixels wide, so it covers two mode 2 character blocks, one
\ containing the left half of the "E", and the other the right half, which are
\ displayed next to each other. Each pixel is in mode 2 colour 7 (%1111), which
\ is white.
\
\ ******************************************************************************

.ECBT

                        \ Left half of the "E" bulb
                        \
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x
 EQUB %10101010         \ x .
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x
 EQUB %10101010         \ x .
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x

                        \ Right half of the "E" bulb
                        \
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x
 EQUB %00000000         \ . .
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x
 EQUB %00000000         \ . .
 EQUB %11111111         \ x x
 EQUB %11111111         \ x x

                        \ Combined "E" bulb
                        \
                        \ x x x x
                        \ x x x x
                        \ x . . .
                        \ x x x x
                        \ x x x x
                        \ x . . .
                        \ x x x x
                        \ x x x x

\ ******************************************************************************
\
\       Name: MSBAR
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Draw a specific indicator in the dashboard's missile bar
\
\ ------------------------------------------------------------------------------
\
\ Each indicator is a rectangle that's 3 pixels wide and 5 pixels high. If the
\ indicator is set to black, this effectively removes a missile.
\
\ Arguments:
\
\   X                   The number of the missile indicator to update (counting
\                       from right to left, so indicator NOMSL is the leftmost
\                       indicator)
\
\   Y                   The colour of the missile indicator:
\
\                         * &00 = black (no missile)
\
\                         * #RED2 = red (armed and locked)
\
\                         * #YELLOW2 = yellow/white (armed)
\
\                         * #GREEN2 = green (disarmed)
\
\ Returns:
\
\   X                   X is preserved
\
\   Y                   Y is set to 0
\
\ ******************************************************************************

.MSBAR

 LDA #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 TXA
 PHA

 ASL A                  \ Set T = A * 8
 ASL A
 ASL A
 ASL A
 STA T

 LDA #97                \ Set SC = 97 - T
 SBC T                  \        = 96 + 1 - (X * 8)
 STA SC

                        \ So the low byte of SC(1 0) contains the row address
                        \ for the rightmost missile indicator, made up as
                        \ follows:
                        \
                        \   * 96 (character block 14, as byte #14 * 8 = 96), the
                        \     character block of the rightmost missile
                        \
                        \   * 1 (so we start drawing on the second row of the
                        \     character block)
                        \
                        \   * Move right one character (8 bytes) for each count
                        \     of X, so when X = 0 we are drawing the rightmost
                        \     missile, for X = 1 we hop to the left by one
                        \     character, and so on

 LDA #&7C               \ Set the high byte of SC(1 0) to &7C, the character row
 STA SCH                \ that contains the missile indicators (i.e. the bottom
                        \ row of the screen)

 TYA                    \ ???

 LDY #5                 \ We now want to draw this line five times to do the
                        \ left two pixels of the indicator, so set a counter in
                        \ Y

.MBL1

 STA (SC),Y             \ Draw the 3-pixel row, and as we do not use EOR logic,
                        \ this will overwrite anything that is already there
                        \ (so drawing a black missile will delete what's there)

 DEY                    \ Decrement the counter for the next row

 BNE MBL1               \ Loop back to MBL1 if have more rows to draw

 PHA                    \ Store the value of A on the stack so we can retrieve
                        \ it after the following addition

 LDA SC                 \ Set SC = SC + 8
 CLC                    \
 ADC #8                 \ so SC(1 0) now points to the next character block on
 STA SC                 \ the row (for the right half of the indicator)

 PLA                    \ Retrieve A from the stack

 AND #%10101010         \ Mask the character row to plot just the first pixel
                        \ in the next character block, as we already did a
                        \ two-pixel wide band in the previous character block,
                        \ so we need to plot just one more pixel, width-wise

 LDY #5                 \ We now want to draw this line five times, so set a
                        \ counter in Y

.MBL2

 STA (SC),Y             \ Draw the 1-pixel row, and as we do not use EOR logic,
                        \ this will overwrite anything that is already there
                        \ (so drawing a black missile will delete what's there)

 DEY                    \ Decrement the counter for the next row

 BNE MBL2               \ Loop back to MBL2 if have more rows to draw

 PLX                    \ ???

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: HCNT
\       Type: Variable
\   Category: Ship hanger
\    Summary: The number of ships being displayed in the ship hanger
\
\ ******************************************************************************

.HCNT

 EQUB 0

\ ******************************************************************************
\
\       Name: HANGER
\       Type: Subroutine
\   Category: Ship hanger
\    Summary: Display the ship hanger
\
\ ------------------------------------------------------------------------------
\
\ This routine is called after the ships in the hanger have been drawn, so all
\ it has to do is draw the hanger's background.
\
\ The hanger background is made up of two parts:
\
\   * The hanger floor consists of 11 screen-wide horizontal lines, which start
\     out quite spaced out near the bottom of the screen, and bunch ever closer
\     together as the eye moves up towards the horizon, where they merge to give
\     a sense of perspective
\
\   * The back wall of the hanger consists of 15 equally spaced vertical lines
\     that join the horizon to the top of the screen
\
\ The ships in the hangar have already been drawn by this point, so the lines
\ are drawn so they don't overlap anything that's already there, which makes
\ them look like they are behind and below the ships. This is achieved by
\ drawing the lines in from the screen edges until they bump into something
\ already on-screen. For the horizontal lines, when there are multiple ships in
\ the hanger, this also means drawing lines between the ships, as well as in
\ from each side.
\
\ Other entry points:
\
\   HA3                 Contains an RTS
\
\ ******************************************************************************

.HANGER

                        \ We start by drawing the floor

 LDX #2                 \ We start with a loop using a counter in T that goes
                        \ from 2 to 12, one for each of the 11 horizontal lines
                        \ in the floor, so set the initial value in X

 LDA #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

.HAL1

 STX T                  \ Store the loop counter in T

 LDA #130               \ Set A = 130

 STX Q                  \ Set Q = T

 JSR DVID4_DUPLICATE    \ Calculate the following:

                        \
                        \   (P R) = 256 * A / Q
                        \         = 256 * 130 / T
                        \
                        \ so P = 130 / T, and as the counter T goes from 2 to
                        \ 12, P goes 65, 43, 32 ... 13, 11, 10, with the
                        \ difference between two consecutive numbers getting
                        \ smaller as P gets smaller
                        \
                        \ We can use this value as a y-coordinate to draw a set
                        \ of horizontal lines, spaced out near the bottom of the
                        \ screen (high value of P, high y-coordinate, lower down
                        \ the screen) and bunching up towards the horizon (low
                        \ value of P, low y-coordinate, higher up the screen)

 LDA P                  \ Set Y = #Y + P
 CLC                    \
 ADC #Y                 \ where #Y is the y-coordinate of the centre of the
 TAY                    \ screen, so Y is now the horizontal pixel row of the
                        \ line we want to draw to display the hanger floor

 LDA ylookup,Y          \ Look up the page number of the character row that
 STA SC+1               \ contains the pixel with the y-coordinate in Y, and
                        \ store it in the high byte of SC(1 0) at SC+1

 STA R                  \ Also store the page number in R

 LDA P                  \ Set the low byte of SC(1 0) to the y-coordinate mod 7,
 AND #7                 \ which determines the pixel row in the character block
 STA SC                 \ we need to draw in (as each character row is 8 pixels
                        \ high), so SC(1 0) now points to the address of the
                        \ start of the horizontal line we want to draw

 LDY #0                 \ Set Y = 0 so the call to HAS2 starts drawing the line
                        \ in the first byte of the screen row, at the left edge
                        \ of the screen

 JSR HAS2               \ Draw a horizontal line from the left edge of the
                        \ screen, going right until we bump into something
                        \ already on-screen, at which point stop drawing

 LDY R                  \ Fetch the page number of the line from R, increment it
 INY                    \ so it points to the right half of the character row
 STY SC+1               \ (as each row takes up 2 pages), and store it in the
                        \ high byte of SC(1 0) at SC+1

 LDA #%01000000         \ Now to draw the same line but from the right edge of
                        \ the screen, so set a pixel mask in A to check the
                        \ second pixel of the last byte, so we skip the 2-pixel
                        \ scren border at the right edge of the screen

 LDY #248               \ Set Y = 248 so the call to HAS3 starts drawing the
                        \ line in the last byte of the screen row, at the right
                        \ edge of the screen

 JSR HAS3               \ Draw a horizontal line from the right edge of the
                        \ screen, going left until we bump into something
                        \ already on-screen, at which point stop drawing

 LDY HCNT               \ Fetch the value of HCNT, which gets set to 0 in the
                        \ HALL routine above if there is only one ship

 BEQ HA2                \ If HCNT is zero, jump to HA2 to skip the following
                        \ as there is only one ship in the hanger

                        \ If we get here then there are multiple ships in the
                        \ hanger, so we also need to draw the horizontal line in
                        \ the gap between the ships

 LDY #0                 \ First we draw the line from the centre of the screen
                        \ to the right. SC(1 0) points to the start address of
                        \ the second half of the screen row, so we set Y to 0 so
                        \ the call to HAL3 starts drawing from the first
                        \ character in that second half

 LDA #%10001000         \ We want to start drawing from the first pixel, so we
                        \ set a mask in A to the first pixel in the 4-pixel byte

 JSR HAL3               \ Call HAL3, which draws a line from the halfway point
                        \ across the right half of the screen, going right until
                        \ we bump into something already on-screen, at which
                        \ point it stops drawing

 DEC SC+1               \ Decrement the high byte of SC(1 0) in SC+1 to point to
                        \ the previous page (i.e. the left half of this screen
                        \ row)

 LDY #248               \ We now draw the line from the centre of the screen
                        \ to the left. SC(1 0) points to the start address of
                        \ the first half of the screen row, so we set Y to 248
                        \ so the call to HAS3 starts drawing from the last
                        \ character in that first half

 LDA #%00010000         \ We want to start drawing from the last pixel, so we
                        \ set a mask in A to the last pixel in the 4-pixel byte

 JSR HAS3               \ Call HAS3, which draws a line from the halfway point
                        \ across the left half of the screen, going left until
                        \ we bump into something already on-screen, at which
                        \ point it stops drawing

.HA2

                        \ We have finished threading our horizontal line behind
                        \ the ships already on-screen, so now for the next line

 LDX T                  \ Fetch the loop counter from T and increment it
 INX

 CPX #13                \ If the loop counter is less than 13 (i.e. T = 2 to 12)
 BCC HAL1               \ then loop back to HAL1 to draw the next line

                        \ The floor is done, so now we move on to the back wall

 LDA #60                \ Set S = 60, so we run the following 60 times (though I
 STA S                  \ have no idea why it's 60 times, when it should be 15,
                        \ as this has the effect of drawing each vertical line
                        \ four times, each time starting one character row lower
                        \ on-screen)

 LDA #16                \ We want to draw 15 vertical lines, one every 16 pixels
                        \ across the screen, with the first at x-coordinate 16,
                        \ so set this in A to act as the x-coordinate of each
                        \ line as we work our way through them from left to
                        \ right, incrementing by 16 for each new line

 LDX #&40               \ Set X = &40, the high byte of the start of screen
 STX R                  \ memory (the screen starts at location &4000) and the
                        \ page number of the first screen row

.HAL6

 LDX R                  \ Set the high byte of SC(1 0) to R
 STX SC+1

 STA T                  \ Store A in T so we can retrieve it later

 AND #%11111100         \ A contains the x-coordinate of the line to draw, and
 STA SC                 \ each character block is 4 pixels wide, so setting the
                        \ low byte of SC(1 0) to A mod 4 points SC(1 0) to the
                        \ correct character block on the top screen row for this
                        \ x-coordinate

 LDX #%10001000         \ Set a mask in X to the first pixel in the 4-pixel byte

 LDY #1                 \ We are going to start drawing the line from the second
                        \ pixel from the top (to avoid drawing on the 1-pixel
                        \ border), so set Y to 1 to point to the second row in
                        \ the first character block

.HAL7

 TXA                    \ Copy the pixel mask to A

 AND (SC),Y             \ If the pixel we want to draw is non-zero (using A as a
 BNE HA6                \ mask), then this means it already contains something,
                        \ so jump to HA6 to stop drawing this line

 TXA                    \ Copy the pixel mask to A again

 AND #RED               \ Apply the pixel mask in A to a four-pixel block of
                        \ red pixels, so we now know which bits to set in screen
                        \ memory

 ORA (SC),Y             \ OR the byte with the current contents of screen
                        \ memory, so the pixel we want is set to red (because
                        \ we know the bits are already 0 from the above test)

 STA (SC),Y             \ Store the updated pixel in screen memory

 INY                    \ Increment Y to point to the next row in the character
                        \ block, i.e. the next pixel down

 CPY #8                 \ Loop back to HAL7 to draw this next pixel until we
 BNE HAL7               \ have drawn all 8 in the character block

 INC SC+1               \ There are two pages of memory for each character row,
 INC SC+1               \ so we increment the high byte of SC(1 0) twice to
                        \ point to the same character but in the next row down

 LDY #0                 \ Set Y = 0 to point to the first row in this character
                        \ block

 BEQ HAL7               \ Loop back up to HAL7 to keep drawing the line (this
                        \ BEQ is effectively a JMP as Y is always zero)

.HA6

 LDA T                  \ Fetch the x-coordinate of the line we just drew from T
 CLC                    \ into A, and add 16 so that A contains the x-coordinate
 ADC #16                \ of the next line to draw

 BCC P%+4               \ If the addition overflowed, increment the page number
 INC R                  \ in R to point to the second half of the screen row

 DEC S                  \ Decrement the loop counter in S

 BNE HAL6               \ Loop back to HAL6 until we have run through the loop
                        \ 60 times, by which point we are most definitely done

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 RTS                    \ Return from the subroutine (this instruction is not
                        \ needed as we could just fall through into the RTS at
                        \ HA3 below)

.HA3

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: HAS2
\       Type: Subroutine
\   Category: Ship hanger
\    Summary: Draw a hanger background line from left to right
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line to the right, starting with the third pixel of the
\ pixel row at screen address SC(1 0), and aborting if we bump into something
\ that's already on-screen. HAL2 draws from the left edge of the screen to the
\ halfway point, and then HAL3 takes over to draw from the halfway point across
\ the right half of the screen.
\
\ ******************************************************************************

.HAS2

 LDA #%00100010         \ Set A to the pixel pattern for a mode 1 character row
                        \ byte with the third pixel set, so we start drawing the
                        \ horizontal line just to the right of the 2-pixel
                        \ border along the edge of the screen

.HAL2

 TAX                    \ Store A in X so we can retrieve it after the following
                        \ check and again after updating screen memory

 AND (SC),Y             \ If the pixel we want to draw is non-zero (using A as a
 BNE HA3                \ mask), then this means it already contains something,
                        \ so we stop drawing because we have run into something
                        \ that's already on-screen, and return from the
                        \ subroutine (as HA3 contains an RTS)

 TXA                    \ Retrieve the value of A we stored above, so A now
                        \ contains the pixel mask again

 AND #RED               \ Apply the pixel mask in A to a four-pixel block of
                        \ red pixels, so we now know which bits to set in screen
                        \ memory

 ORA (SC),Y             \ OR the byte with the current contents of screen
                        \ memory, so the pixel we want is set to red (because
                        \ we know the bits are already 0 from the above test)

 STA (SC),Y             \ Store the updated pixel in screen memory

 TXA                    \ Retrieve the value of A we stored above, so A now
                        \ contains the pixel mask again

 LSR A                  \ Shift A to the right to move on to the next pixel

 BCC HAL2               \ If bit 0 before the shift was clear (i.e. we didn't
                        \ just do the fourth pixel in this block), loop back to
                        \ HAL2 to check and draw the next pixel

 TYA                    \ Set Y = Y + 8 (as we know the C flag is set) to point
 ADC #7                 \ to the next character block along
 TAY

 LDA #%10001000         \ Reset the pixel mask in A to the first pixel in the
                        \ new 4-pixel character block

 BCC HAL2               \ If the above addition didn't overflow, jump back to
                        \ HAL2 to keep drawing the line in the next character
                        \ block

 INC SC+1               \ The addition overflowed, so we have reached the last
                        \ character block in this page of memory, so increment
                        \ the high byte of SC(1 0) in SC+1 to point to the next
                        \ page (i.e. the right half of this screen row) and fall
                        \ into HAL3 to repeat the performamce

.HAL3

 TAX                    \ Store A in X so we can retrieve it after the following
                        \ check and again after updating screen memory

 AND (SC),Y             \ If the pixel we want to draw is non-zero (using A as a
 BNE HA3                \ mask), then this means it already contains something,
                        \ so we stop drawing because we have run into something
                        \ that's already on-screen, and return from the
                        \ subroutine (as HA3 contains an RTS)

 TXA                    \ Retrieve the value of A we stored above, so A now
                        \ contains the pixel mask again

 AND #RED               \ Apply the pixel mask in A to a four-pixel block of
                        \ red pixels, so we now know which bits to set in screen
                        \ memory

 ORA (SC),Y             \ OR the byte with the current contents of screen
                        \ memory, so the pixel we want is set to red (because
                        \ we know the bits are already 0 from the above test)

 STA (SC),Y             \ Store the updated pixel in screen memory

 TXA                    \ Retrieve the value of A we stored above, so A now
                        \ contains the pixel mask again

 LSR A                  \ Shift A to the right to move on to the next pixel

 BCC HAL3               \ If bit 0 before the shift was clear (i.e. we didn't
                        \ just do the fourth pixel in this block), loop back to
                        \ HAL3 to check and draw the next pixel

 TYA                    \ Set Y = Y + 8 (as we know the C flag is set) to point
 ADC #7                 \ to the next character block along
 TAY

 LDA #%10001000         \ Reset the pixel mask in A to the first pixel in the
                        \ new 4-pixel character block

 BCC HAL3               \ If the above addition didn't overflow, jump back to
                        \ HAL3 to keep drawing the line in the next character
                        \ block

 RTS                    \ The addition overflowed, so we have reached the last
                        \ character block in this page of memory, which is the
                        \ end of the line, so we return from the subroutine

\ ******************************************************************************
\
\       Name: HAS3
\       Type: Subroutine
\   Category: Ship hanger
\    Summary: Draw a hanger background line from right to left
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line to the left, starting with the pixel mask in A at
\ screen address SC(1 0) and character block offset Y, and aborting if we bump
\ into something that's already on-screen.
\
\ ******************************************************************************

.HAS3

 TAX                    \ Store A in X so we can retrieve it after the following
                        \ check and again after updating screen memory

 AND (SC),Y             \ If the pixel we want to draw is non-zero (using A as a
 BNE HA3                \ mask), then this means it already contains something,
                        \ so we stop drawing because we have run into something
                        \ that's already on-screen, and return from the
                        \ subroutine (as HA3 contains an RTS)

 TXA                    \ Retrieve the value of A we stored above, so A now
                        \ contains the pixel mask again

 ORA (SC),Y             \ OR the byte with the current contents of screen
                        \ memory, so the pixel we want is set to red (because
                        \ we know the bits are already 0 from the above test)

 STA (SC),Y             \ Store the updated pixel in screen memory

 TXA                    \ Retrieve the value of A we stored above, so A now
                        \ contains the pixel mask again

 ASL A                  \ Shift A to the left to move to the next pixel to the
                        \ left

 BCC HAS3               \ If bit 7 before the shift was clear (i.e. we didn't
                        \ just do the first pixel in this block), loop back to
                        \ HAS3 to check and draw the next pixel to the left

 TYA                    \ Set Y = Y - 8 (as we know the C flag is set) to point
 SBC #8                 \ to the next character block to the left
 TAY

 LDA #%00010000         \ Set a mask in A to the last pixel in the 4-pixel byte

 BCS HAS3               \ If the above subtraction didn't underflow, jump back
                        \ to HAS3 to keep drawing the line in the next character
                        \ block to the left

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DVID4_DUPLICATE
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (P R) = 256 * A / Q
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following division and remainder:
\
\   P = A / Q
\
\   R = remainder as a fraction of Q, where 1.0 = 255
\
\ Another way of saying the above is this:
\
\   (P R) = 256 * A / Q
\
\ This uses the same shift-and-subtract algorithm as TIS2, but this time we
\ keep the remainder.
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.DVID4_DUPLICATE

 LDX #8                 \ Set a counter in X to count the 8 bits in A

 ASL A                  \ Shift A left and store in P (we will build the result
 STA P                  \ in P)

 LDA #0                 \ Set A = 0 for us to build a remainder

.DVL4

 ROL A                  \ Shift A to the left

 BCS DV8                \ If the C flag is set (i.e. bit 7 of A was set) then
                        \ skip straight to the subtraction

 CMP Q                  \ If A < Q skip the following subtraction
 BCC DV5

.DV8

 SBC Q                  \ A >= Q, so set A = A - Q

.DV5

 ROL P                  \ Shift P to the left, pulling the C flag into bit 0

 DEX                    \ Decrement the loop counter

 BNE DVL4               \ Loop back for the next bit until we have done all 8
                        \ bits of P

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: cls
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear the top part of the screen and draw a white border
\
\ ******************************************************************************

.cls

 JSR TTX66              \ Call TTX66 to clear the top part of the screen and
                        \ draw a white border

 JMP RR4                \ Jump to RR4 to restore X and Y from the stack and A
                        \ from K3, and return from the subroutine using a tail
                        \ call

\ ******************************************************************************
\
\       Name: TT67_DUPLICATE
\       Type: Subroutine
\   Category: Text
\    Summary: Print a newline
\
\ ******************************************************************************

.TT67_DUPLICATE

 LDA #12                \ Set A to a carriage return character

                        \ Fall through into TT26 to print the newline

\ ******************************************************************************
\
\       Name: CHPR
\       Type: Subroutine
\   Category: Text
\    Summary: Print a character at the text cursor by poking into screen memory
\  Deep dive: Drawing text
\
\ ------------------------------------------------------------------------------
\
\ Print a character at the text cursor (XC, YC), do a beep, print a newline,
\ or delete left (backspace).
\
\ Calls to OSWRCH will end up here when A is not in the range 128-147, as those
\ are reserved for the special jump table OSWRCH commands.
\
\ Arguments:
\
\   A                   The character to be printed. Can be one of the
\                       following:
\
\                         * 7 (beep)
\
\                         * 10 (line feed)
\
\                         * 11 (clear the top part of the screen and draw a
\                           border)
\
\                         * 12-13 (carriage return)
\
\                         * 32-95 (ASCII capital letters, numbers and
\                           punctuation)
\
\                         * 127 (delete the character to the left of the text
\                           cursor and move the cursor to the left)
\
\   XC                  Contains the text column to print at (the x-coordinate)
\
\   YC                  Contains the line number to print on (the y-coordinate)
\
\ Returns:
\
\   A                   A is preserved
\
\   X                   X is preserved
\
\   Y                   Y is preserved
\
\   C flag              The C flag is cleared
\
\ Other entry points:
\
\   RR4                 Restore the registers and return from the subroutine
\
\ ******************************************************************************

.CHPR

 STA K3                 \ Store the A, X and Y registers, so we can restore
 PHY                    \ them at the end (so they don't get changed by this
 PHX                    \ routine)

 LDY QQ17               \ Load the QQ17 flag, which contains the text printing
                        \ flags

 CPY #255               \ If QQ17 = 255 then printing is disabled, so jump to
 BEQ RR4S               \ RR4S (via the JMP in RR4S) to restore the registers
                        \ and return from the subroutine using a tail call

 LDY #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STY VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 TAY                    \ Set Y = the character to be printed

 BEQ RR4S               \ If the character is zero, which is typically a string
                        \ terminator character, jump down to RR4 (via the JMP in
                        \ RR4S) to restore the registers and return from the
                        \ subroutine using a tail call

 BMI RR4S               \ If A > 127 then there is nothing to print, so jump to
                        \ RR4 (via the JMP in RR4S) to restore the registers and
                        \ return from the subroutine

 CMP #11                \ If this is control code 11 (clear screen), jump to cls
 BEQ cls                \ to clear the top part of the screen, draw a white
                        \ border and return from the subroutine via RR4

 CMP #7                 \ If this is not control code 7 (beep), skip the next
 BNE P%+5               \ instruction

 JMP R5                 \ This is control code 7 (beep), so jump to R5 to make
                        \ a beep and return from the subroutine via RR4

 CMP #32                \ If this is an ASCII character (A >= 32), jump to RR1
 BCS RR1                \ below, which will print the character, restore the
                        \ registers and return from the subroutine

 CMP #10                \ If this is control code 10 (line feed) then jump to
 BEQ RRX1               \ RRX1, which will move down a line, restore the
                        \ registers and return from the subroutine

 LDX #1                 \ If we get here, then this is control code 12 or 13,
 STX XC                 \ both of which are used. This code prints a newline,
                        \ which we can achieve by moving the text cursor
                        \ to the start of the line (carriage return) and down
                        \ one line (line feed). These two lines do the first
                        \ bit by setting XC = 1, and we then fall through into
                        \ the line feed routine that's used by control code 10

.RRX1

 CMP #13                \ If this is control code 13 (carriage return) then jump
 BEQ RR4S               \ to RR4 (via the JMP in RR4S) to restore the registers
                        \ and return from the subroutine using a tail call

 INC YC                 \ Increment the text cursor y-coordinate to move it
                        \ down one row

.RR4S

 JMP RR4                \ Jump to RR4 to restore the registers and return from
                        \ the subroutine using a tail call

.RR1

                        \ If we get here, then the character to print is an
                        \ ASCII character in the range 32-95. The quickest way
                        \ to display text on-screen is to poke the character
                        \ pixel by pixel, directly into screen memory, so
                        \ that's what the rest of this routine does
                        \
                        \ The first step, then, is to get hold of the bitmap
                        \ definition for the character we want to draw on the
                        \ screen (i.e. we need the pixel shape of this
                        \ character). The MOS ROM contains bitmap definitions
                        \ of the BBC's ASCII characters, starting from &C000
                        \ for space (ASCII 32) and ending with the £ symbol
                        \ (ASCII 126)
                        \
                        \ There are definitions for 32 characters in each of the
                        \ three pages of MOS memory, as each definition takes up
                        \ 8 bytes (8 rows of 8 pixels) and 32 * 8 = 256 bytes =
                        \ 1 page. So:
                        \
                        \   ASCII 32-63  are defined in &C000-&C0FF (page 0)
                        \   ASCII 64-95  are defined in &C100-&C1FF (page 1)
                        \   ASCII 96-126 are defined in &C200-&C2F0 (page 2)
                        \
                        \ The following code reads the relevant character
                        \ those values into the correct position in screen
                        \ memory, thus printing the character on-screen
                        \
                        \ It's a long way from 10 PRINT "Hello world!":GOTO 10

                        \ Now we want to set X to point to the relevant page

                        \ The following logic is easier to follow if we look
                        \ at the three character number ranges in binary:
                        \
                        \   Bit #  76543210
                        \
                        \   32  = %00100000     Page 0 of bitmap definitions
                        \   63  = %00111111
                        \
                        \   64  = %01000000     Page 1 of bitmap definitions
                        \   95  = %01011111
                        \
                        \   96  = %01100000     Page 2 of bitmap definitions
                        \   125 = %01111101
                        \
                        \ We'll refer to this below

 LDX #&23               \ ??? Need to change comments above to reflect address
                        \ of Master character definitions (at &2300 and &2500?)

 ASL A                  \ If bit 6 of the character is clear (A is 32-63)
 ASL A                  \ then skip the following instruction
 BCC P%+4

 LDX #&25               \ ???

 ASL A                  \ If bit 5 of the character is clear (A is 64-95)
 BCC P%+3               \ then skip the following instruction

 INX                    \ Increment X
                        \
                        \ In other words, X points to the relevant page. But
                        \ what about the value of A? That gets shifted to the
                        \ left three times during the above code, which
                        \ multiplies the number by 8 but also drops bits 7, 6
                        \ and 5 in the process. Look at the above binary
                        \ figures and you can see that if we cleared bits 5-7,
                        \ then that would change 32-53 to 0-31... but it would
                        \ do exactly the same to 64-95 and 96-125. And because
                        \ we also multiply this figure by 8, A now points to
                        \ the start of the character's definition within its
                        \ page (because there are 8 bytes per character
                        \ definition)
                        \
                        \ Or, to put it another way, X contains the high byte
                        \ (the page) of the address of the definition that we
                        \ want, while A contains the low byte (the offset into
                        \ the page) of the address

 STA P                  \ Store the address of this character's definition in
 STX P+1                \ P(1 0)

 LDA XC                 \ Fetch XC, the x-coordinate (column) of the text cursor
                        \ into A

 LDX CATF               \ If CATF = 0, jump to RR5, otherwise we are printing a
 BEQ RR5                \ disc catalogue

 CPY #' '               \ If the character we want to print in Y is a space,
 BNE RR5                \ jump to RR5

                        \ If we get here, then CATF is non-zero, so we are
                        \ printing a disc catalogue and we are not printing a
                        \ space, so we drop column 17 from the output so the
                        \ catalogue will fit on-screen (column 17 is a blank
                        \ column in the middle of the catalogue, between the
                        \ two lists of filenames, so it can be dropped without
                        \ affecting the layout). Without this, the catalogue
                        \ would be one character too wide for the square screen
                        \ mode (it's 34 characters wide, while the screen mode
                        \ is only 33 characters across)

 CMP #17                \ If A = 17, i.e. the text cursor is in column 17, jump
 BEQ RR4                \ to RR4 to restore the registers and return from the
                        \ subroutine, thus omitting this column

.RR5

 ASL A                  \ Multiply A by 8, and store in SC, so we now have:
 ASL A                  \
 ASL A                  \   SC = XC * 8
 STA SC

 LDA YC                 \ Fetch YC, the y-coordinate (row) of the text cursor

 CPY #127               \ If the character number (which is in Y) <> 127, then
 BNE RR2                \ skip to RR2 to print that character, otherwise this is
                        \ the delete character, so continue on

 DEC XC                 \ We want to delete the character to the left of the
                        \ text cursor and move the cursor back one, so let's
                        \ do that by decrementing YC. Note that this doesn't
                        \ have anything to do with the actual deletion below,
                        \ we're just updating the cursor so it's in the right
                        \ position following the deletion

 ASL A                  \ A contains YC (from above), so this sets A = YC * 2

 ASL SC                 \ Double the low byte of SC(1 0), catching bit 7 in the
                        \ C flag. As each character is 8 pixels wide, and the
                        \ special screen mode Elite uses for the top part of the
                        \ screen is 256 pixels across with two bits per pixel,
                        \ this value is not only double the screen address
                        \ offset of the text cursor from the left side of the
                        \ screen, it's also the least significant byte of the
                        \ screen address where we want to print this character,
                        \ as each row of on-screen pixels corresponds to two
                        \ pages. To put this more explicitly, the screen starts
                        \ at &4000, so the text rows are stored in screen
                        \ memory like this:
                        \
                        \   Row 1: &4000 - &41FF    YC = 1, XC = 0 to 31
                        \   Row 2: &4200 - &43FF    YC = 2, XC = 0 to 31
                        \   Row 3: &4400 - &45FF    YC = 3, XC = 0 to 31
                        \
                        \ and so on

 ADC #&3F               \ Set X = A
 TAX                    \       = A + &3F + C
                        \       = YC * 2 + &3F + C

                        \ Because YC starts at 0 for the first text row, this
                        \ means that X will be &3F for row 0, &41 for row 1 and
                        \ so on. In other words, X is now set to the page number
                        \ for the row before the one containing the text cursor,
                        \ and given that we set SC above to point to the offset
                        \ in memory of the text cursor within the row's page,
                        \ this means that (X SC) now points to the character
                        \ above the text cursor

 LDY #&F0               \ Set Y = &F0, so the following call to ZES2 will count
                        \ Y upwards from &F0 to &FF

 JSR ZES2               \ Call ZES2, which zero-fills from address (X SC) + Y to
                        \ (X SC) + &FF. (X SC) points to the character above the
                        \ text cursor, and adding &FF to this would point to the
                        \ cursor, so adding &F0 points to the character before
                        \ the cursor, which is the one we want to delete. So
                        \ this call zero-fills the character to the left of the
                        \ cursor, which erases it from the screen

 BEQ RR4                \ We are done deleting, so restore the registers and
                        \ return from the subroutine (this BNE is effectively
                        \ a JMP as ZES2 always returns with the Z flag set)

.RR2

                        \ Now to actually print the character

 INC XC                 \ Once we print the character, we want to move the text
                        \ cursor to the right, so we do this by incrementing
                        \ XC. Note that this doesn't have anything to do
                        \ with the actual printing below, we're just updating
                        \ the cursor so it's in the right position following
                        \ the print

 CMP #24                \ If the text cursor is on the screen (i.e. YC < 24, so
 BCC RR3                \ we are on rows 1-23), then jump to RR3 to print the
                        \ character

 JSR TTX66              \ Otherwise we are off the bottom of the screen, so
                        \ clear the screen and draw a white border

 LDA #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 LDA #1                 \ Move the text cursor to column 1, row 1
 STA XC
 STA YC

 LDA K3                 \ Set A to the character to be printed, though again
                        \ this has no effect, as the following call to RR4 does
                        \ the exact same thing

 JMP RR4                \ And restore the registers and return from the
                        \ subroutine

.RR3

                        \ A contains the value of YC - the screen row where we
                        \ want to print this character - so now we need to
                        \ convert this into a screen address, so we can poke
                        \ the character data to the right place in screen
                        \ memory

 ASL A                  \ Set A = 2 * A
                        \       = 2 * YC

 ASL SC                 \ Back in RR5 we set SC = XC * 8, so this does the
                        \ following:
                        \
                        \   SC = SC * 2
                        \      = XC * 16
                        \
                        \ so SC contains the low byte of the screen address we
                        \ want to poke the character into, as each text
                        \ character is 8 pixels wide, and there are four pixels
                        \ per byte, so the offset within the row's 512 bytes
                        \ is XC * 8 pixels * 2 bytes for each 8 pixels = XC * 16

 ADC #&40               \ Set A = &40 + A
                        \       = &40 + (2 * YC)
                        \
                        \ so A contains the high byte of the screen address we
                        \ want to poke the character into, as screen memory
                        \ starts at &4000 (page &40) and each screen row takes
                        \ up 2 pages (512 bytes)

.RREN

 STA SC+1               \ Store the page number of the destination screen
                        \ location in SC+1, so SC now points to the full screen
                        \ location where this character should go

 LDA SC                 \ Set P(3 2) = SC(1 0) + 8
 CLC                    \
 ADC #8                 \ starting with the low bytes
 STA P+2

 LDA SC+1               \ And then adding the high bytes, so P(3 2) points to
 STA P+3                \ the character block after the one pointed to by
                        \ SC(1 0)

 LDY #7                 \ We want to print the 8 bytes of character data to the
                        \ screen (one byte per row), so set up a counter in Y
                        \ to count these bytes

.RRL1

                        \ We print the character's 8-pixel row in two parts,
                        \ starting with the first four pixels (one byte of
                        \ screen memory), and then the second four (a second
                        \ byte of screen memory)

 LDA (P),Y              \ The character definition is at P(1 0) - we set this up
                        \ above - so load the Y-th byte from P(1 0), which will
                        \ contain the bitmap for the Y-th row of the character

 AND #%11110000         \ Extract the top nibble of the character definition
                        \ byte, so the first four pixels on this row of the
                        \ character are in the first nibble, i.e. xxxx 0000
                        \ where xxxx is the pattern of those four pixels in the
                        \ character

 STA W                  \ Set A = (A >> 4) OR A
 LSR A                  \
 LSR A                  \ which duplicates the top nibble into the bottom nibble
 LSR A                  \ to give xxxx xxxx
 LSR A
 ORA W

 AND COL                \ AND with the colour byte so that the pixels take on
                        \ the colour we want to draw (i.e. A is acting as a mask
                        \ on the colour byte)

 EOR (SC),Y             \ If we EOR this value with the existing screen
                        \ contents, then it's reversible (so reprinting the
                        \ same character in the same place will revert the
                        \ screen to what it looked like before we printed
                        \ anything); this means that printing a white pixel on
                        \ onto a white background results in a black pixel, but
                        \ that's a small price to pay for easily erasable text

 STA (SC),Y             \ Store the Y-th byte at the screen address for this
                        \ character location

                        \ We now repeat the process for the second batch of four
                        \ pixels in this character row

 LDA (P),Y              \ Fetch the the bitmap for the Y-th row of the character
                        \ again

 AND #%00001111         \ This time we extract the bottom nibble of the
                        \ character definition, to get 0000 xxxx

 STA W                  \ Set A = (A << 4) OR A
 ASL A                  \
 ASL A                  \ which duplicates the bottom nibble into the top nibble
 ASL A                  \ to give xxxx xxxx
 ASL A
 ORA W

 AND COL                \ AND with the colour byte so that the pixels take on
                        \ the colour we want to draw (i.e. A is acting as a mask
                        \ on the colour byte)

 EOR (P+2),Y            \ EOR this value with the existing screen contents of
                        \ P(3 2), which is equal to SC(1 0) + 8, the next four
                        \ pixels along from the first four pixels we just
                        \ plotted in SC(1 0)

 STA (P+2),Y            \ Store the Y-th byte at the screen address for this
                        \ character location

 DEY                    \ Decrement the loop counter

 BPL RRL1               \ Loop back for the next byte to print to the screen

.RR4

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 PLX                    \ ???
 PLY
 LDA K3
 CLC

 RTS                    \ Return from the subroutine

.R5

 JSR BEEP               \ Call the BEEP subroutine to make a short, high beep

 JMP RR4                \ Jump to RR4 to restore the registers and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TTX66
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear the top part of the screen and draw a white border
\
\ ------------------------------------------------------------------------------
\
\ Clear the top part of the screen (the space view) and draw a white border
\ along the top and sides.
\
\ ******************************************************************************

.TTX66

 LDX #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STX VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 LDX #&40               \ Set X to point to page &40, which is the start of the
                        \ screen memory at &4000

.BOL1

 JSR ZES1               \ Call ZES1 below to zero-fill the page in X, which will
                        \ clear half a character row

 INX                    \ Increment X to point to the next page in screen
                        \ memory

 CPX #&70               \ Loop back to keep clearing character rows until we
 BNE BOL1               \ have cleared up to &7000, which is where the dashoard
                        \ starts

.BOX

 LDX #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STX VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 LDA COL                \ ???
 PHA

 LDA #%00001111         \ Set COL = %00001111 to act as a four-pixel yellow
 STA COL                \ character byte (i.e. set the line colour to yellow)

 LDY #1                 \ Move the text cursor to row 1
 STY YC

 STY XC                 \ Move the text cursor to column 1 ???

 LDX #0                 \ Set X1 = Y1 = Y2 = 0
 STX Y1
 STX Y2
 STX X1

\STX QQ17               \ This instruction is commented out in the original
                        \ source

 DEX                    \ Set X2 = 255
 STX X2

 JSR LOIN               \ Draw a line from (X1, Y1) to (X2, Y2), so that's from
                        \ (0, 0) to (255, 0), along the very top of the screen

 LDA #2                 \ Set X1 = X2 = 2
 STA X1
 STA X2

 JSR BOS2               \ Call BOS2 below, which will call BOS1 twice, and then
                        \ fall through into BOS2 again, so we effectively do
                        \ BOS1 four times, decrementing X1 and X2 each time
                        \ before calling LOIN, so this whole loop-within-a-loop
                        \ mind-bender ends up drawing these four lines:
                        \
                        \   (1, 0)   to (1, 191)
                        \   (0, 0)   to (0, 191)
                        \   (255, 0) to (255, 191)
                        \   (254, 0) to (254, 191)
                        \
                        \ So that's a 2-pixel wide vertical border along the
                        \ left edge of the upper part of the screen, and a
                        \ 2-pixel wide vertical border along the right edge

 JSR BOS2               \ ???

 LDA COL
 STA &4000
 STA &41F8
 PLA
 STA COL

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 RTS                    \ Return from the subroutine

.BOS2

 JSR BOS1               \ Call BOS1 below and then fall through into it, which
                        \ ends up running BOS1 twice. This is all part of the
                        \ loop-the-loop border-drawing mind-bender explained
                        \ above

.BOS1

 STZ Y1                 \ Set Y1 = 0

 LDA #2*Y-1             \ Set Y2 = 2 * #Y - 1. The constant #Y is 96, the
 STA Y2                 \ y-coordinate of the mid-point of the space view, so
                        \ this sets Y2 to 191, the y-coordinate of the bottom
                        \ pixel row of the space view

 DEC X1                 \ Decrement X1 and X2
 DEC X2

 JMP LOIN               \ Draw a line from (X1, Y1) to (X2, Y2) and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: ZES1
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Zero-fill the page whose number is in X
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The page we want to zero-fill
\
\ ******************************************************************************

.ZES1

 LDY #0                 \ If we set Y = SC = 0 and fall through into ZES2
 STY SC                 \ below, then we will zero-fill 255 bytes starting from
                        \ SC - in other words, we will zero-fill the whole of
                        \ page X

\ ******************************************************************************
\
\       Name: ZES2
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Zero-fill a specific page
\
\ ------------------------------------------------------------------------------
\
\ Zero-fill from address (X SC) + Y to (X SC) + &FF.
\
\ Arguments:
\
\   X                   The high byte (i.e. the page) of the starting point of
\                       the zero-fill
\
\   Y                   The offset from (X SC) where we start zeroing, counting
\                       up to to &FF
\
\   SC                  The low byte (i.e. the offset into the page) of the
\                       starting point of the zero-fill
\
\ Returns:
\
\   Z flag              Z flag is set
\
\ ******************************************************************************

.ZES2

 LDA #0                 \ Load A with the byte we want to fill the memory block
                        \ with - i.e. zero

 STX SC+1               \ We want to zero-fill page X, so store this in the
                        \ high byte of SC, so the 16-bit address in SC and
                        \ SC+1 is now pointing to the SC-th byte of page X

.ZEL1

 STA (SC),Y             \ Zero the Y-th byte of the block pointed to by SC,
                        \ so that's effectively the Y-th byte before SC

 INY                    \ Increment the loop counter

 BNE ZEL1               \ Loop back to zero the next byte

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CLYNS
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear the bottom three text rows of the mode 4 screen
\
\ ******************************************************************************

.CLYNS

 STZ DLY                \ ???
 STZ de

 LDA #%11111111         \ Set DTW2 = %11111111 to denote that we are not
 STA DTW2               \ currently printing a word

 LDA #&80               \ ???
 STA QQ17

 LDA #20                \ Move the text cursor to row 20, near the bottom of
 STA YC                 \ the screen

 JSR TT67_DUPLICATE     \ Print a newline

 LDA #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 LDA #&6A               \ Set SC+1 = &6A, for the high byte of SC(1 0)
 STA SC+1

 LDA #0                 \ Set SC = 0, so now SC(1 0) = &6A00
 STA SC

 LDX #3                 \ We want to clear three text rows, so set a counter in
                        \ X for 3 rows

.CLYL

 LDY #8                 \ We want to clear each text row, starting from the
                        \ left, but we don't want to overwrite the border, so we
                        \ start from the second character block, which is byte
                        \ #8 from the edge, so set Y to 8 to act as the byte
                        \ counter within the row

.EE2

 STA (SC),Y             \ Zero the Y-th byte from SC(1 0), which clears it by
                        \ setting it to colour 0, black

 INY                    \ Increment the byte counter in Y

 BNE EE2                \ Loop back to EE2 to blank the next byte along, until
                        \ we have done one page's worth (from byte #8 to #255)

 INC SC+1               \ We have just finished the first page - which covers
                        \ the left half of the text row - so we increment SC+1
                        \ so SC(1 0) points to the start of the next page, or
                        \ the start of the right half of the row

 STA (SC),Y             \ Clear the byte at SC(1 0), as that won't be caught by
                        \ the next loop

 LDY #247               \ The second page covers the right half of the text row,
                        \ and as before we don't want to overwrite the border,
                        \ which we can do by starting from the last-but-one
                        \ character block and working our way left towards the
                        \ centre of the row. The last-but-one character block
                        \ ends at byte 247 (that's 255 - 8, as each character
                        \ is 8 bytes), so we put this in Y to act as a byte
                        \ counter, as before

{
.EE3                    \ This label is a duplicate of a label in TT23 (which is
                        \ why we need to surround it with braces, as BeebAsm
                        \ doesn't allow us to redefine labels, unlike BBC
                        \ BASIC)

 STA (SC),Y             \ Zero the Y-th byte from SC(1 0), which clears it by
                        \ setting it to colour 0, black

 DEY                    \ Decrement the byte counter in Y

 BNE EE3                \ Loop back to EE2 to blank the next byte to the left,
                        \ until we have done one page's worth (from byte #247 to
                        \ #1)
}

 INC SC+1               \ We have now blanked a whole text row, so increment
                        \ SC+1 so that SC(1 0) points to the next row

 DEX                    \ Decrement the row counter in X

 BNE CLYL               \ Loop back to blank another row, until we have done the
                        \ number of rows in X

\INX                    \ These instructions are commented out in the original
\STX SC                 \ source

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF

 LDA #0                 \ Set A = 0 as this is a return value for this routine

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DIALS (Part 1 of 4)
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the dashboard: speed indicator
\  Deep dive: The dashboard indicators
\
\ ------------------------------------------------------------------------------
\
\ This routine updates the dashboard. First we draw all the indicators in the
\ right part of the dashboard, from top (speed) to bottom (energy banks), and
\ then we move on to the left part, again drawing from top (forward shield) to
\ bottom (altitude).
\
\ This first section starts us off with the speedometer in the top right.
\
\ ******************************************************************************

.DIALS

 LDA #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch screen memory into &3000-&7FFF

 LDA #&01               \ ???
 STA &DDEB

 LDA #&A0               \ Set SC(1 0) = &71A0, which is the screen address for
 STA SC                 \ the character block containing the left end of the
 LDA #&71               \ top indicator in the right part of the dashboard, the
 STA SC+1               \ one showing our speed

 JSR PZW2               \ Call PZW2 to set A to the colour for dangerous values
                        \ and X to the colour for safe values, suitable for
                        \ non-striped indicators

 STX K+1                \ Set K+1 (the colour we should show for low values) to
                        \ X (the colour to use for safe values)

 STA K                  \ Set K (the colour we should show for high values) to
                        \ A (the colour to use for dangerous values)

                        \ The above sets the following indicators to show red
                        \ for high values and yellow/white for low values

 LDA #14                \ Set T1 to 14, the threshold at which we change the
 STA T1                 \ indicator's colour

 LDA DELTA              \ Fetch our ship's speed into A, in the range 0-40

\LSR A                  \ Draw the speed indicator using a range of 0-31, and
 JSR DIL-1              \ increment SC to point to the next indicator (the roll
                        \ indicator). The LSR is commented out as it isn't
                        \ required with a call to DIL-1, so perhaps this was
                        \ originally a call to DIL that got optimised

\ ******************************************************************************
\
\       Name: DIALS (Part 2 of 4)
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the dashboard: pitch and roll indicators
\  Deep dive: The dashboard indicators
\
\ ******************************************************************************

 STZ R                  \ Set R = P = 0 for the low bytes in the call to the ADD
 STZ P                  \ routine below

 LDA #8                 \ Set S = 8, which is the value of the centre of the
 STA S                  \ roll indicator

 LDA ALP1               \ Fetch the roll angle alpha as a value between 0 and
 LSR A                  \ 31, and divide by 4 to get a value of 0 to 7
 LSR A

 ORA ALP2               \ Apply the roll sign to the value, and flip the sign,
 EOR #%10000000         \ so it's now in the range -7 to +7, with a positive
                        \ roll angle alpha giving a negative value in A

 JSR ADD_DUPLICATE      \ We now add A to S to give us a value in the range 1 to
                        \ 15, which we can pass to DIL2 to draw the vertical
                        \ bar on the indicator at this position. We use the ADD
                        \ routine like this:
                        \
                        \ (A X) = (A 0) + (S 0)
                        \
                        \ and just take the high byte of the result. We use ADD
                        \ rather than a normal ADC because ADD separates out the
                        \ sign bit and does the arithmetic using absolute values
                        \ and separate sign bits, which we want here rather than
                        \ the two's complement that ADC uses

 JSR DIL2               \ Draw a vertical bar on the roll indicator at offset A
                        \ and increment SC to point to the next indicator (the
                        \ pitch indicator)

 LDA BETA               \ Fetch the pitch angle beta as a value between -8 and
                        \ +8

 LDX BET1               \ Fetch the magnitude of the pitch angle beta, and if it
 BEQ P%+4               \ is 0 (i.e. we are not pitching), skip the next
                        \ instruction

 SBC #1                 \ The pitch angle beta is non-zero, so set A = A - 1
                        \ (the C flag is set by the call to DIL2 above, so we
                        \ don't need to do a SEC). This gives us a value of A
                        \ from -7 to +7 because these are magnitude-based
                        \ numbers with sign bits, rather than two's complement
                        \ numbers

 JSR ADD_DUPLICATE      \ We now add A to S to give us a value in the range 1 to
                        \ 15, which we can pass to DIL2 to draw the vertical
                        \ bar on the indicator at this position (see the JSR ADD
                        \ above for more on this)

 JSR DIL2               \ Draw a vertical bar on the pitch indicator at offset A
                        \ and increment SC to point to the next indicator (the
                        \ four energy banks)

\ ******************************************************************************
\
\       Name: DIALS (Part 3 of 4)
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the dashboard: four energy banks
\  Deep dive: The dashboard indicators
\
\ ******************************************************************************

 LDY #0                 \ Set Y = 0, for use in various places below

 JSR PZW                \ Call PZW to set A to the colour for dangerous values
                        \ and X to the colour for safe values

 STX K                  \ Set K (the colour we should show for high values) to X
                        \ (the colour to use for safe values)

 STA K+1                \ Set K+1 (the colour we should show for low values) to
                        \ A (the colour to use for dangerous values)

                        \ The above sets the following indicators to show red
                        \ for low values and yellow/white for high values, which
                        \ we use not only for the energy banks, but also for the
                        \ shield levels and current fuel

 LDX #3                 \ Set up a counter in X so we can zero the four bytes at
                        \ XX15, so we can then calculate each of the four energy
                        \ banks' values before drawing them later

 STX T1                 \ Set T1 to 3, the threshold at which we change the
                        \ indicator's colour

.DLL23

 STY XX15,X             \ Set the X-th byte of XX15 to 0

 DEX                    \ Decrement the counter

 BPL DLL23              \ Loop back for the next byte until the four bytes at
                        \ XX12 are all zeroed

 LDX #3                 \ Set up a counter in X to loop through the 4 energy
                        \ bank indicators, so we can calculate each of the four
                        \ energy banks' values and store them in XX12

 LDA ENERGY             \ Set A = Q = ENERGY / 4, so they are both now in the
 LSR A                  \ range 0-63 (so that's a maximum of 16 in each of the
 LSR A                  \ banks, and a maximum of 15 in the top bank)

 STA Q                  \ Set Q to A, so we can use Q to hold the remaining
                        \ energy as we work our way through each bank, from the
                        \ full ones at the bottom to the empty ones at the top

.DLL24

 SEC                    \ Set A = A - 16 to reduce the energy count by a full
 SBC #16                \ bank

 BCC DLL26              \ If the C flag is clear then A < 16, so this bank is
                        \ not full to the brim, and is therefore the last one
                        \ with any energy in it, so jump to DLL26

 STA Q                  \ This bank is full, so update Q with the energy of the
                        \ remaining banks

 LDA #16                \ Store this bank's level in XX15 as 16, as it is full,
 STA XX15,X             \ with XX15+3 for the bottom bank and XX15+0 for the top

 LDA Q                  \ Set A to the remaining energy level again

 DEX                    \ Decrement X to point to the next bank, i.e. the one
                        \ above the bank we just processed

 BPL DLL24              \ Loop back to DLL24 until we have either processed all
                        \ four banks, or jumped out early to DLL26 if the top
                        \ banks have no charge

 BMI DLL9               \ Jump to DLL9 as we have processed all four banks (this
                        \ BMI is effectively a JMP as A will never be positive)

.DLL26

 LDA Q                  \ If we get here then the bank we just checked is not
 STA XX15,X             \ fully charged, so store its value in XX15 (using Q,
                        \ which contains the energy of the remaining banks -
                        \ i.e. this one)

                        \ Now that we have the four energy bank values in XX12,
                        \ we can draw them, starting with the top bank in XX12
                        \ and looping down to the bottom bank in XX12+3, using Y
                        \ as a loop counter, which was set to 0 above

.DLL9

 LDA XX15,Y             \ Fetch the value of the Y-th indicator, starting from
                        \ the top

 STY P                  \ Store the indicator number in P for retrieval later

 JSR DIL                \ Draw the energy bank using a range of 0-15, and
                        \ increment SC to point to the next indicator (the
                        \ next energy bank down)

 LDY P                  \ Restore the indicator number into Y

 INY                    \ Increment the indicator number

 CPY #4                 \ Check to see if we have drawn the last energy bank

 BNE DLL9               \ Loop back to DLL9 if we have more banks to draw,
                        \ otherwise we are done

\ ******************************************************************************
\
\       Name: DIALS (Part 4 of 4)
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the dashboard: shields, fuel, laser & cabin temp, altitude
\  Deep dive: The dashboard indicators
\
\ ******************************************************************************

 LDA #&70               \ Set SC(1 0) = &7020, which is the screen address for
 STA SC+1               \ the character block containing the left end of the
 LDA #&20               \ top indicator in the left part of the dashboard, the
 STA SC                 \ one showing the forward shield

 LDA FSH                \ Draw the forward shield indicator using a range of
 JSR DILX               \ 0-255, and increment SC to point to the next indicator
                        \ (the aft shield)

 LDA ASH                \ Draw the aft shield indicator using a range of 0-255,
 JSR DILX               \ and increment SC to point to the next indicator (the
                        \ fuel level)

 LDA #YELLOW2           \ Set K (the colour we should show for high values) to
 STA K                  \ yellow

 STA K+1                \ Set K+1 (the colour we should show for low values) to
                        \ yellow, so the fuel indicator always shows in this
                        \ colour

 LDA QQ14               \ Draw the fuel level indicator using a range of 0-63,
 JSR DILX+2             \ and increment SC to point to the next indicator (the
                        \ cabin temperature)

 JSR PZW2               \ Call PZW2 to set A to the colour for dangerous values
                        \ and X to the colour for safe values, suitable for
                        \ non-striped indicators

 STX K+1                \ Set K+1 (the colour we should show for low values) to
                        \ X (the colour to use for safe values)

 STA K                  \ Set K (the colour we should show for high values) to
                        \ A (the colour to use for dangerous values)

                        \ The above sets the following indicators to show red
                        \ for high values and yellow/white for low values, which
                        \ we use for the cabin and laser temperature bars

 LDX #11                \ Set T1 to 11, the threshold at which we change the
 STX T1                 \ cabin and laser temperature indicators' colours

 LDA CABTMP             \ Draw the cabin temperature indicator using a range of
 JSR DILX               \ 0-255, and increment SC to point to the next indicator
                        \ (the laser temperature)

 LDA GNTMP              \ Draw the laser temperature indicator using a range of
 JSR DILX               \ 0-255, and increment SC to point to the next indicator
                        \ (the altitude)

 LDA #240               \ Set T1 to 240, the threshold at which we change the
 STA T1                 \ altitude indicator's colour. As the altitude has a
                        \ range of 0-255, pixel 16 will not be filled in, and
                        \ 240 would change the colour when moving between pixels
                        \ 15 and 16, so this effectively switches off the colour
                        \ change for the altitude indicator

 LDA #YELLOW2           \ Set K (the colour we should show for high values) to
 STA K                  \ yellow

 STA K+1                \ Set K+1 (the colour we should show for low values) to
                        \ 240, or &F0 (dashboard colour 2, yellow/white), so the
                        \ altitude indicator always shows in this colour

 LDA ALTIT              \ Draw the altitude indicator using a range of 0-255
 JSR DILX

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA+&34 to switch main memory back into &3000-&7FFF
 

 JMP COMPAS             \ We have now drawn all the indicators, so jump to
                        \ COMPAS to draw the compass, returning from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: PZW2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Fetch the current dashboard colours for non-striped indicators, to
\             support flashing
\
\ ******************************************************************************

.PZW2

 LDX #WHITE2            \ Set X to white, so we can return that as the safe
                        \ colour in PZW below

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &23, or BIT &23A9, which does nothing apart
                        \ from affect the flags

                        \ Fall through into PZW to fetch the current dashboard
                        \ colours, returning white for safe colours rather than
                        \ stripes

\ ******************************************************************************
\
\       Name: PZW
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Fetch the current dashboard colours, to support flashing
\
\ ------------------------------------------------------------------------------
\
\ Set A and X to the colours we should use for indicators showing dangerous and
\ safe values respectively. This enables us to implement flashing indicators,
\ which is one of the game's configurable options.
\
\ If flashing is enabled, the colour returned in A (dangerous values) will be
\ red for 8 iterations of the main loop, and green for the next 8, before
\ going back to red. If we always use PZW to decide which colours we should use
\ when updating indicators, flashing colours will be automatically taken care of
\ for us.
\
\ The values returned are #GREEN2 for green and #RED2 for red. These are mode 2
\ bytes that contain 2 pixels, with the colour of each pixel given in four bits.
\
\ Returns:
\
\   A                   The colour to use for indicators with dangerous values
\
\   X                   The colour to use for indicators with safe values
\
\ ******************************************************************************

.PZW

 LDX #STRIPE            \ Set X to the dashboard stripe colour, which is stripe
                        \ 5-1 (magenta/red)

 LDA MCNT               \ A will be non-zero for 8 out of every 16 main loop
 AND #%00001000         \ counts, when bit 4 is set, so this is what we use to
                        \ flash the "danger" colour

 AND FLH                \ A will be zeroed if flashing colours are disabled

 BEQ P%+5               \ If A is zero, skip the next two instructions

 LDA #GREEN2            \ Otherwise flashing colours are enabled and it's the
 RTS                    \ main loop iteration where we flash them, so set A to
                        \ dashboard colour 2 (green) and return from the
                        \ subroutine

 LDA #RED2              \ Set A to dashboard colour 1 (red)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DILX
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update a bar-based indicator on the dashboard
\  Deep dive: The dashboard indicators
\
\ ------------------------------------------------------------------------------
\
\ The range of values shown on the indicator depends on which entry point is
\ called. For the default entry point of DILX, the range is 0-255 (as the value
\ passed in A is one byte). The other entry points are shown below.
\
\ Arguments:
\
\   A                   The value to be shown on the indicator (so the larger
\                       the value, the longer the bar)
\
\   T1                  The threshold at which we change the indicator's colour
\                       from the low value colour to the high value colour. The
\                       threshold is in pixels, so it should have a value from
\                       0-16, as each bar indicator is 16 pixels wide
\
\   K                   The colour to use when A is a high value, as a 2-pixel
\                       mode 2 character row byte
\
\   K+1                 The colour to use when A is a low value, as a 2-pixel
\                       mode 2 character row byte
\
\   SC(1 0)             The screen address of the first character block in the
\                       indicator
\
\ Other entry points:
\
\   DILX+2              The range of the indicator is 0-64 (for the fuel
\                       indicator)
\
\   DIL-1               The range of the indicator is 0-32 (for the speed
\                       indicator)
\
\   DIL                 The range of the indicator is 0-16 (for the energy
\                       banks)
\
\ ******************************************************************************

.DILX

 LSR A                  \ If we call DILX, we set A = A / 16, so A is 0-15
 LSR A

 LSR A                  \ If we call DILX+2, we set A = A / 4, so A is 0-15

 LSR A                  \ If we call DIL-1, we set A = A / 2, so A is 0-15

.DIL

                        \ If we call DIL, we leave A alone, so A is 0-15

 STA Q                  \ Store the indicator value in Q, now reduced to 0-15,
                        \ which is the length of the indicator to draw in pixels

 LDX #&FF               \ Set R = &FF, to use as a mask for drawing each row of
 STX R                  \ each character block of the bar, starting with a full
                        \ character's width of 4 pixels

 CMP T1                 \ If A >= T1 then we have passed the threshold where we
 BCS DL30               \ change bar colour, so jump to DL30 to set A to the
                        \ "high value" colour

 LDA K+1                \ Set A to K+1, the "low value" colour to use

 BNE DL31               \ Jump down to DL31 (this BNE is effectively a JMP as A
                        \ will never be zero)

.DL30

 LDA K                  \ Set A to K, the "high value" colour to use

.DL31

 STA COL                \ Store the colour of the indicator in COL

 LDY #2                 \ We want to start drawing the indicator on the third
                        \ line in this character row, so set Y to point to that
                        \ row's offset

 LDX #7                 \ Set up a counter in X for the width of the indicator,
                        \ which is 8 characters (each of which is 2 pixels wide,
                        \ to give a total width of 16 pixels)

.DL1

 LDA Q                  \ Fetch the indicator value (0-15) from Q into A

 CMP #2                 \ If Q < 2, then we need to draw the end cap of the
 BCC DL2                \ indicator, which is less than a full character's
                        \ width, so jump down to DL2 to do this

 SBC #2                 \ Otherwise we can draw a 2-pixel wide block, so
 STA Q                  \ subtract 2 from Q so it contains the amount of the
                        \ indicator that's left to draw after this character

 LDA R                  \ Fetch the shape of the indicator row that we need to
                        \ display from R, so we can use it as a mask when
                        \ painting the indicator. It will be &FF at this point
                        \ (i.e. a full 4-pixel row)

.DL5

 AND COL                \ Fetch the 2-pixel mode 2 colour byte from COL, and
                        \ only keep pixels that have their equivalent bits set
                        \ in the mask byte in A

 STA (SC),Y             \ Draw the shape of the mask on pixel row Y of the
                        \ character block we are processing

 INY                    \ Draw the next pixel row, incrementing Y
 STA (SC),Y

 INY                    \ And draw the third pixel row, incrementing Y
 STA (SC),Y

 TYA                    \ Add 6 to Y, so Y is now 8 more than when we started
 CLC                    \ this loop iteration, so Y now points to the address
 ADC #6                 \ of the first line of the indicator bar in the next
 TAY                    \ character block (as each character is 8 bytes of
                        \ screen memory)

 DEX                    \ Decrement the loop counter for the next character
                        \ block along in the indicator

 BMI DL6                \ If we just drew the last character block then we are
                        \ done drawing, so jump down to DL6 to finish off

 BPL DL1                \ Loop back to DL1 to draw the next character block of
                        \ the indicator (this BPL is effectively a JMP as A will
                        \ never be negative following the previous BMI)

.DL2

 EOR #1                 \ If we get here then we are drawing the indicator's
 STA Q                  \ end cap, so Q is < 2, and this EOR flips the bits, so
                        \ instead of containing the number of indicator columns
                        \ we need to fill in on the left side of the cap's
                        \ character block, Q now contains the number of blank
                        \ columns there should be on the right side of the cap's
                        \ character block

 LDA R                  \ Fetch the current mask from R, which will be &FF at
                        \ this point, so we need to turn Q of the columns on the
                        \ right side of the mask to black to get the correct end
                        \ cap shape for the indicator

.DL3

 ASL A                  \ Shift the mask left and clear bits 0, 2, 4 and 8,
 AND #%10101010         \ which has the effect of shifting zeroes from the left
                        \ into each two-bit segment (i.e. xx xx xx xx becomes
                        \ x0 x0 x0 x0, which blanks out the last column in the
                        \ 2-pixel mode 2 character block)

 DEC Q                  \ Decrement the counter for the number of columns to
                        \ blank out

 BPL DL3                \ If we still have columns to blank out in the mask,
                        \ loop back to DL3 until the mask is correct for the
                        \ end cap

 PHA                    \ Store the mask byte on the stack while we use the
                        \ accumulator for a bit

 STZ R                  \ Change the mask so no bits are set, so the characters
                        \ after the one we're about to draw will be all blank

 LDA #99                \ Set Q to a high number (99, why not) so we will keep
 STA Q                  \ drawing blank characters until we reach the end of
                        \ the indicator row

 PLA                    \ Restore the mask byte from the stack so we can use it
                        \ to draw the end cap of the indicator

 JMP DL5                \ Jump back up to DL5 to draw the mask byte on-screen

.DL6

 INC SC+1               \ Increment the high byte of SC to point to the next
 INC SC+1               \ character row on-screen (as each row takes up exactly
                        \ two pages of 256 bytes) - so this sets up SC to point
                        \ to the next indicator, i.e. the one below the one we
                        \ just drew

.DL9                    \ This label is not used but is in the original source

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DIL2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the roll or pitch indicator on the dashboard
\  Deep dive: The dashboard indicators
\
\ ------------------------------------------------------------------------------
\
\ The indicator can show a vertical bar in 16 positions, with a value of 8
\ showing the bar in the middle of the indicator.
\
\ In practice this routine is only ever called with A in the range 1 to 15, so
\ the vertical bar never appears in the leftmost position (though it does appear
\ in the rightmost).
\
\ Arguments:
\
\   A                   The offset of the vertical bar to show in the indicator,
\                       from 0 at the far left, to 8 in the middle, and 15 at
\                       the far right
\
\ Returns:
\
\   C flag              The C flag is set
\
\ ******************************************************************************

.DIL2

 LDY #1                 \ We want to start drawing the vertical indicator bar on
                        \ the second line in the indicator's character block, so
                        \ set Y to point to that row's offset

 STA Q                  \ Store the offset of the vertical bar to draw in Q

                        \ We are now going to work our way along the indicator
                        \ on the dashboard, from left to right, working our way
                        \ along one character block at a time. Y will be used as
                        \ a pixel row counter to work our way through the
                        \ character blocks, so each time we draw a character
                        \ block, we will increment Y by 8 to move on to the next
                        \ block (as each character block contains 8 rows)

.DLL10

 SEC                    \ Set A = Q - 2, so that A contains the offset of the
 LDA Q                  \ vertical bar from the start of this character block
 SBC #2

 BCS DLL11              \ If Q >= 2 then the character block we are drawing does
                        \ not contain the vertical indicator bar, so jump to
                        \ DLL11 to draw a blank character block

 LDA #&FF               \ Set A to a high number (and &FF is as high as they go)

 LDX Q                  \ Set X to the offset of the vertical bar, which we know
                        \ is within this character block

 STA Q                  \ Set Q to a high number (&FF, why not) so we will keep
                        \ drawing blank characters after this one until we reach
                        \ the end of the indicator row

 LDA CTWOS,X            \ CTWOS is a table of ready-made 1-pixel mode 2 bytes,
                        \ just like the TWOS and TWOS2 tables for mode 1 (see
                        \ the PIXEL routine for details of how they work). This
                        \ fetches a mode 2 1-pixel byte with the pixel position
                        \ at X, so the pixel is at the offset that we want for
                        \ our vertical bar

 AND #WHITE2            \ The 2-pixel mode 2 byte in #WHITE2 represents two
                        \ pixels of colour %0111 (7), which is white in both
                        \ dashboard palettes. We AND this with A so that we only
                        \ keep the pixel that matches the position of the
                        \ vertical bar (i.e. A is acting as a mask on the
                        \ 2-pixel colour byte)

 BNE DLL12              \ Jump to DLL12 to skip the code for drawing a blank,
                        \ and move on to drawing the indicator (this BNE is
                        \ effectively a JMP as A is always non-zero)

.DLL11

                        \ If we get here then we want to draw a blank for this
                        \ character block

 STA Q                  \ Update Q with the new offset of the vertical bar, so
                        \ it becomes the offset after the character block we
                        \ are about to draw

 LDA #0                 \ Change the mask so no bits are set, so all of the
                        \ character blocks we display from now on will be blank
.DLL12

 STA (SC),Y             \ Draw the shape of the mask on pixel row Y of the
                        \ character block we are processing

 INY                    \ Draw the next pixel row, incrementing Y
 STA (SC),Y

 INY                    \ And draw the third pixel row, incrementing Y
 STA (SC),Y

 INY                    \ And draw the fourth pixel row, incrementing Y
 STA (SC),Y

 TYA                    \ Add 5 to Y, so Y is now 8 more than when we started
 CLC                    \ this loop iteration, so Y now points to the address
 ADC #5                 \ of the first line of the indicator bar in the next
 TAY                    \ character block (as each character is 8 bytes of
                        \ screen memory)

 CPY #60                \ If Y < 60 then we still have some more character
 BCC DLL10              \ blocks to draw, so loop back to DLL10 to display the
                        \ next one along

 INC SC+1               \ Increment the high byte of SC to point to the next
 INC SC+1               \ character row on-screen (as each row takes up exactly
                        \ two pages of 256 bytes) - so this sets up SC to point
                        \ to the next indicator, i.e. the one below the one we
                        \ just drew

 RTS                    \ Return from the subroutine

.ADD_DUPLICATE

 STA T1
 AND #&80
 STA T
 EOR S
 BMI MU8_DUPLICATE

 LDA R
 CLC
 ADC P
 TAX
 LDA S
 ADC T1
 ORA T
 RTS

.MU8_DUPLICATE

 LDA S
 AND #&7F
 STA U
 LDA P
 SEC
 SBC R
 TAX
 LDA T1
 AND #&7F
 SBC U
 BCS MU9_DUPLICATE

 STA U
 TXA
 EOR #&FF
 ADC #&01
 TAX
 LDA #&00
 SBC U
 ORA #&80

.MU9_DUPLICATE

 EOR T
 RTS

 EQUB &41,&23,&6D,&65,&6D,&3A,&53,&54
 EQUB &41,&6C,&61,&74,&63,&68,&3A,&52
 EQUB &54,&53,&0D,&13,&74,&09,&5C,&2E
 EQUB &2E,&2E,&2E,&0D,&18,&60,&05,&20
 EQUB &0D,&1A,&F4,&21,&5C,&2E,&2E,&2E
 EQUB &2E,&2E,&2E,&2E,&2E,&2E,&2E,&42
 EQUB &61,&79,&20,&56,&69,&65,&77,&2E
 EQUB &2E,&2E,&2E,&2E,&2E,&2E,&2E,&2E
 EQUB &2E,&0D,&1A,&FE,&05,&20,&0D,&1B
 EQUB &08,&11,&2E,&48,&41

 EQUB &00,&00,&00,&00,&00,&00,&00,&00
 EQUB &18,&18,&18,&18,&18,&00,&18,&00
 EQUB &6C,&6C,&6C,&00,&00,&00,&00,&00
 EQUB &36,&36,&7F,&36,&7F,&36,&36,&00
 EQUB &0C,&3F,&68,&3E,&0B,&7E,&18,&00
 EQUB &60,&66,&0C,&18,&30,&66,&06,&00
 EQUB &38,&6C,&6C,&38,&6D,&66,&3B,&00
 EQUB &0C,&18,&30,&00,&00,&00,&00,&00
 EQUB &0C,&18,&30,&30,&30,&18,&0C,&00
 EQUB &30,&18,&0C,&0C,&0C,&18,&30,&00
 EQUB &00,&18,&7E,&3C,&7E,&18,&00,&00
 EQUB &00,&18,&18,&7E,&18,&18,&00,&00
 EQUB &00,&00,&00,&00,&00,&18,&18,&30
 EQUB &00,&00,&00,&7E,&00,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&18,&18,&00
 EQUB &00,&06,&0C,&18,&30,&60,&00,&00
 EQUB &3C,&66,&6E,&7E,&76,&66,&3C,&00
 EQUB &18,&38,&18,&18,&18,&18,&7E,&00
 EQUB &3C,&66,&06,&0C,&18,&30,&7E,&00
 EQUB &3C,&66,&06,&1C,&06,&66,&3C,&00
 EQUB &0C,&1C,&3C,&6C,&7E,&0C,&0C,&00
 EQUB &7E,&60,&7C,&06,&06,&66,&3C,&00
 EQUB &1C,&30,&60,&7C,&66,&66,&3C,&00
 EQUB &7E,&06,&0C,&18,&30,&30,&30,&00
 EQUB &3C,&66,&66,&3C,&66,&66,&3C,&00
 EQUB &3C,&66,&66,&3E,&06,&0C,&38,&00
 EQUB &00,&00,&18,&18,&00,&18,&18,&00
 EQUB &00,&00,&18,&18,&00,&18,&18,&30
 EQUB &0C,&18,&30,&60,&30,&18,&0C,&00
 EQUB &00,&00,&7E,&00,&7E,&00,&00,&00
 EQUB &30,&18,&0C,&06,&0C,&18,&30,&00
 EQUB &3C,&66,&0C,&18,&18,&00,&18,&00
 EQUB &3C,&66,&6E,&6A,&6E,&60,&3C,&00
 EQUB &3C,&66,&66,&7E,&66,&66,&66,&00
 EQUB &7C,&66,&66,&7C,&66,&66,&7C,&00
 EQUB &3C,&66,&60,&60,&60,&66,&3C,&00
 EQUB &78,&6C,&66,&66,&66,&6C,&78,&00
 EQUB &7E,&60,&60,&7C,&60,&60,&7E,&00
 EQUB &7E,&60,&60,&7C,&60,&60,&60,&00
 EQUB &3C,&66,&60,&6E,&66,&66,&3C,&00
 EQUB &66,&66,&66,&7E,&66,&66,&66,&00
 EQUB &7E,&18,&18,&18,&18,&18,&7E,&00
 EQUB &3E,&0C,&0C,&0C,&0C,&6C,&38,&00
 EQUB &66,&6C,&78,&70,&78,&6C,&66,&00
 EQUB &60,&60,&60,&60,&60,&60,&7E,&00
 EQUB &63,&77,&7F,&6B,&6B,&63,&63,&00
 EQUB &66,&66,&76,&7E,&6E,&66,&66,&00
 EQUB &3C,&66,&66,&66,&66,&66,&3C,&00
 EQUB &7C,&66,&66,&7C,&60,&60,&60,&00
 EQUB &3C,&66,&66,&66,&6A,&6C,&36,&00
 EQUB &7C,&66,&66,&7C,&6C,&66,&66,&00
 EQUB &3C,&66,&60,&3C,&06,&66,&3C,&00
 EQUB &7E,&18,&18,&18,&18,&18,&18,&00
 EQUB &66,&66,&66,&66,&66,&66,&3C,&00
 EQUB &66,&66,&66,&66,&66,&3C,&18,&00
 EQUB &63,&63,&6B,&6B,&7F,&77,&63,&00
 EQUB &66,&66,&3C,&18,&3C,&66,&66,&00
 EQUB &66,&66,&66,&3C,&18,&18,&18,&00
 EQUB &7E,&06,&0C,&18,&30,&60,&7E,&00
 EQUB &7C,&60,&60,&60,&60,&60,&7C,&00
 EQUB &00,&60,&30,&18,&0C,&06,&00,&00
 EQUB &3E,&06,&06,&06,&06,&06,&3E,&00
 EQUB &18,&3C,&66,&42,&00,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&FF
 EQUB &1C,&36,&30,&7C,&30,&30,&7E,&00
 EQUB &00,&00,&3C,&06,&3E,&66,&3E,&00
 EQUB &60,&60,&7C,&66,&66,&66,&7C,&00
 EQUB &00,&00,&3C,&66,&60,&66,&3C,&00
 EQUB &06,&06,&3E,&66,&66,&66,&3E,&00
 EQUB &00,&00,&3C,&66,&7E,&60,&3C,&00
 EQUB &1C,&30,&30,&7C,&30,&30,&30,&00
 EQUB &00,&00,&3E,&66,&66,&3E,&06,&3C
 EQUB &60,&60,&7C,&66,&66,&66,&66,&00
 EQUB &18,&00,&38,&18,&18,&18,&3C,&00
 EQUB &18,&00,&38,&18,&18,&18,&18,&70
 EQUB &60,&60,&66,&6C,&78,&6C,&66,&00
 EQUB &38,&18,&18,&18,&18,&18,&3C,&00
 EQUB &00,&00,&36,&7F,&6B,&6B,&63,&00
 EQUB &00,&00,&7C,&66,&66,&66,&66,&00
 EQUB &00,&00,&3C,&66,&66,&66,&3C,&00
 EQUB &00,&00,&7C,&66,&66,&7C,&60,&60
 EQUB &00,&00,&3E,&66,&66,&3E,&06,&07
 EQUB &00,&00,&6C,&76,&60,&60,&60,&00
 EQUB &00,&00,&3E,&60,&3C,&06,&7C,&00
 EQUB &30,&30,&7C,&30,&30,&30,&1C,&00
 EQUB &00,&00,&66,&66,&66,&66,&3E,&00
 EQUB &00,&00,&66,&66,&66,&3C,&18,&00
 EQUB &00,&00,&63,&6B,&6B,&7F,&36,&00
 EQUB &00,&00,&66,&3C,&18,&3C,&66,&00
 EQUB &00,&00,&66,&66,&66,&3E,&06,&3C
 EQUB &00,&00,&7E,&0C,&18,&30,&7E,&00
 EQUB &0C,&18,&18,&70,&18,&18,&0C,&00
 EQUB &18,&18,&18,&00,&18,&18,&18,&00
 EQUB &30,&18,&18,&0E,&18,&18,&30,&00
 EQUB &31,&6B,&46,&00,&00,&00,&00,&00
 EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF

.log

 EQUB &00,&00,&20,&32,&40,&4A,&52,&59
 EQUB &60,&65,&6A,&6E,&72,&76,&79,&7D
 EQUB &80,&82,&85,&87,&8A,&8C,&8E,&90
 EQUB &92,&94,&96,&98,&99,&9B,&9D,&9E
 EQUB &A0,&A1,&A2,&A4,&A5,&A6,&A7,&A9
 EQUB &AA,&AB,&AC,&AD,&AE,&AF,&B0,&B1
 EQUB &B2,&B3,&B4,&B5,&B6,&B7,&B8,&B9
 EQUB &B9,&BA,&BB,&BC,&BD,&BD,&BE,&BF
 EQUB &C0,&C0,&C1,&C2,&C2,&C3,&C4,&C4
 EQUB &C5,&C6,&C6,&C7,&C7,&C8,&C9,&C9
 EQUB &CA,&CA,&CB,&CC,&CC,&CD,&CD,&CE
 EQUB &CE,&CF,&CF,&D0,&D0,&D1,&D1,&D2
 EQUB &D2,&D3,&D3,&D4,&D4,&D5,&D5,&D5
 EQUB &D6,&D6,&D7,&D7,&D8,&D8,&D9,&D9
 EQUB &D9,&DA,&DA,&DB,&DB,&DB,&DC,&DC
 EQUB &DD,&DD,&DD,&DE,&DE,&DE,&DF,&DF
 EQUB &E0,&E0,&E0,&E1,&E1,&E1,&E2,&E2
 EQUB &E2,&E3,&E3,&E3,&E4,&E4,&E4,&E5
 EQUB &E5,&E5,&E6,&E6,&E6,&E7,&E7,&E7
 EQUB &E7,&E8,&E8,&E8,&E9,&E9,&E9,&EA
 EQUB &EA,&EA,&EA,&EB,&EB,&EB,&EC,&EC
 EQUB &EC,&EC,&ED,&ED,&ED,&ED,&EE,&EE
 EQUB &EE,&EE,&EF,&EF,&EF,&EF,&F0,&F0
 EQUB &F0,&F1,&F1,&F1,&F1,&F1,&F2,&F2
 EQUB &F2,&F2,&F3,&F3,&F3,&F3,&F4,&F4
 EQUB &F4,&F4,&F5,&F5,&F5,&F5,&F5,&F6
 EQUB &F6,&F6,&F6,&F7,&F7,&F7,&F7,&F7
 EQUB &F8,&F8,&F8,&F8,&F9,&F9,&F9,&F9
 EQUB &F9,&FA,&FA,&FA,&FA,&FA,&FB,&FB
 EQUB &FB,&FB,&FB,&FC,&FC,&FC,&FC,&FC
 EQUB &FD,&FD,&FD,&FD,&FD,&FD,&FE,&FE
 EQUB &FE,&FE,&FE,&FF,&FF,&FF,&FF,&FF

.logL

 EQUB &60,&00,&00,&B8,&00,&4D,&B8,&D6
 EQUB &00,&70,&4D,&B4,&B8,&6A,&D6,&05
 EQUB &00,&CC,&70,&EF,&4D,&8E,&B4,&C1
 EQUB &B8,&9A,&6A,&28,&D6,&75,&05,&89
 EQUB &00,&6C,&CC,&23,&70,&B4,&EF,&22
 EQUB &4D,&71,&8E,&A4,&B4,&BD,&C1,&BF
 EQUB &B8,&AC,&9A,&85,&6A,&4B,&28,&01
 EQUB &D6,&A7,&75,&3F,&05,&C9,&89,&46
 EQUB &00,&B7,&6C,&1D,&CC,&79,&23,&CB
 EQUB &70,&13,&B4,&52,&EF,&8A,&22,&B9
 EQUB &4D,&E0,&71,&00,&8E,&1A,&A4,&2D
 EQUB &B4,&39,&BD,&40,&C1,&41,&BF,&3C
 EQUB &B8,&32,&AC,&24,&9A,&10,&85,&F8
 EQUB &6A,&DB,&4B,&BA,&28,&95,&01,&6C
 EQUB &D6,&3F,&A7,&0E,&75,&DA,&3F,&A2
 EQUB &05,&67,&C9,&29,&89,&E8,&46,&A3
 EQUB &00,&5C,&B7,&12,&6C,&C5,&1D,&75
 EQUB &CC,&23,&79,&CE,&23,&77,&CB,&1E
 EQUB &70,&C2,&13,&64,&B4,&03,&52,&A1
 EQUB &EF,&3D,&8A,&D6,&22,&6E,&B9,&03
 EQUB &4D,&97,&E0,&29,&71,&B9,&00,&47
 EQUB &8E,&D4,&1A,&5F,&A4,&E8,&2D,&70
 EQUB &B4,&F7,&39,&7B,&BD,&FF,&40,&81
 EQUB &C1,&01,&41,&80,&BF,&FE,&3C,&7A
 EQUB &B8,&F5,&32,&6F,&AC,&E8,&24,&5F
 EQUB &9A,&D5,&10,&4A,&85,&BE,&F8,&31
 EQUB &6A,&A3,&DB,&13,&4B,&83,&BA,&F1
 EQUB &28,&5F,&95,&CB,&01,&36,&6C,&A1
 EQUB &D6,&0A,&3F,&73,&A7,&DB,&0E,&42
 EQUB &75,&A7,&DA,&0C,&3F,&71,&A2,&D4
 EQUB &05,&36,&67,&98,&C9,&F9,&29,&59
 EQUB &89,&B8,&E8,&17,&46,&75,&A3,&D2

.antilog

 EQUB &01,&01,&01,&01,&01,&01,&01,&01
 EQUB &01,&01,&01,&01,&01,&01,&01,&01
 EQUB &01,&01,&01,&01,&01,&01,&01,&01
 EQUB &01,&01,&01,&01,&01,&01,&01,&01
 EQUB &02,&02,&02,&02,&02,&02,&02,&02
 EQUB &02,&02,&02,&02,&02,&02,&02,&02
 EQUB &02,&02,&02,&03,&03,&03,&03,&03
 EQUB &03,&03,&03,&03,&03,&03,&03,&03
 EQUB &04,&04,&04,&04,&04,&04,&04,&04
 EQUB &04,&04,&04,&05,&05,&05,&05,&05
 EQUB &05,&05,&05,&06,&06,&06,&06,&06
 EQUB &06,&06,&07,&07,&07,&07,&07,&07
 EQUB &08,&08,&08,&08,&08,&08,&09,&09
 EQUB &09,&09,&09,&0A,&0A,&0A,&0A,&0B
 EQUB &0B,&0B,&0B,&0C,&0C,&0C,&0C,&0D
 EQUB &0D,&0D,&0E,&0E,&0E,&0E,&0F,&0F
 EQUB &10,&10,&10,&11,&11,&11,&12,&12
 EQUB &13,&13,&13,&14,&14,&15,&15,&16
 EQUB &16,&17,&17,&18,&18,&19,&19,&1A
 EQUB &1A,&1B,&1C,&1C,&1D,&1D,&1E,&1F
 EQUB &20,&20,&21,&22,&22,&23,&24,&25
 EQUB &26,&26,&27,&28,&29,&2A,&2B,&2C
 EQUB &2D,&2E,&2F,&30,&31,&32,&33,&34
 EQUB &35,&36,&38,&39,&3A,&3B,&3D,&3E
 EQUB &40,&41,&42,&44,&45,&47,&48,&4A
 EQUB &4C,&4D,&4F,&51,&52,&54,&56,&58
 EQUB &5A,&5C,&5E,&60,&62,&64,&67,&69
 EQUB &6B,&6D,&70,&72,&75,&77,&7A,&7D
 EQUB &80,&82,&85,&88,&8B,&8E,&91,&94
 EQUB &98,&9B,&9E,&A2,&A5,&A9,&AD,&B1
 EQUB &B5,&B8,&BD,&C1,&C5,&C9,&CE,&D2
 EQUB &D7,&DB,&E0,&E5,&EA,&EF,&F5,&FA

 EQUB &01,&02,&03,&04,&05,&06,&00,&01
 EQUB &02,&03,&04,&05,&06,&00,&01,&02
 EQUB &03,&04,&05,&06,&00,&01,&02,&03
 EQUB &04,&05,&06,&00,&01,&02,&03,&04
 EQUB &05,&06,&00,&01,&02,&03,&04,&05
 EQUB &06,&00,&01,&02,&03,&04,&05,&06
 EQUB &00,&01,&02,&03,&04,&05,&06,&00
 EQUB &01,&02,&03,&04,&05,&06,&00,&01
 EQUB &02,&03,&04,&05,&06,&00,&01,&02
 EQUB &03,&04,&05,&06,&00,&01,&02,&03
 EQUB &04,&05,&06,&00,&01,&02,&03,&04
 EQUB &05,&06,&00,&01,&02,&03,&04,&05
 EQUB &06,&00,&01,&02,&03,&04,&05,&06
 EQUB &00,&01,&02,&03,&04,&05,&06,&00
 EQUB &01,&02,&03,&04,&05,&06,&00,&01
 EQUB &02,&03,&04,&05,&06,&00,&01,&02
 EQUB &03,&04,&05,&06,&00,&01,&02,&03
 EQUB &04,&05,&06,&00,&01,&02,&03,&04
 EQUB &05,&06,&00,&01,&02,&03,&04,&05
 EQUB &06,&00,&01,&02,&03,&04,&05,&06
 EQUB &00,&01,&02,&03,&04,&05,&06,&00
 EQUB &01,&02,&03,&04,&05,&06,&00,&01
 EQUB &02,&03,&04,&05,&06,&00,&01,&02
 EQUB &03,&04,&05,&06,&00,&01,&02,&03
 EQUB &04,&05,&06,&00,&01,&02,&03,&04
 EQUB &05,&06,&00,&01,&02,&03,&04,&05
 EQUB &06,&00,&01,&02,&03,&04,&05,&06
 EQUB &00,&01,&02,&03,&04,&05,&06,&00
 EQUB &01,&02,&03,&04,&05,&06,&00,&01
 EQUB &02,&03,&04,&05,&06,&00,&01,&02
 EQUB &03,&04,&05,&06,&00,&01,&02,&03
 EQUB &04,&05,&06,&00,&01,&02,&03,&04
 EQUB &01,&01,&01,&01,&01,&01,&02,&02
 EQUB &02,&02,&02,&02,&02,&03,&03,&03
 EQUB &03,&03,&03,&03,&04,&04,&04,&04
 EQUB &04,&04,&04,&05,&05,&05,&05,&05
 EQUB &05,&05,&06,&06,&06,&06,&06,&06
 EQUB &06,&07,&07,&07,&07,&07,&07,&07
 EQUB &08,&08,&08,&08,&08,&08,&08,&09
 EQUB &09,&09,&09,&09,&09,&09,&0A,&0A
 EQUB &0A,&0A,&0A,&0A,&0A,&0B,&0B,&0B
 EQUB &0B,&0B,&0B,&0B,&0C,&0C,&0C,&0C
 EQUB &0C,&0C,&0C,&0D,&0D,&0D,&0D,&0D
 EQUB &0D,&0D,&0E,&0E,&0E,&0E,&0E,&0E
 EQUB &0E,&0F,&0F,&0F,&0F,&0F,&0F,&0F
 EQUB &10,&10,&10,&10,&10,&10,&10,&11
 EQUB &11,&11,&11,&11,&11,&11,&12,&12
 EQUB &12,&12,&12,&12,&12,&13,&13,&13
 EQUB &13,&13,&13,&13,&14,&14,&14,&14
 EQUB &14,&14,&14,&15,&15,&15,&15,&15
 EQUB &15,&15,&16,&16,&16,&16,&16,&16
 EQUB &16,&17,&17,&17,&17,&17,&17,&17
 EQUB &18,&18,&18,&18,&18,&18,&18,&19
 EQUB &19,&19,&19,&19,&19,&19,&1A,&1A
 EQUB &1A,&1A,&1A,&1A,&1A,&1B,&1B,&1B
 EQUB &1B,&1B,&1B,&1B,&1C,&1C,&1C,&1C
 EQUB &1C,&1C,&1C,&1D,&1D,&1D,&1D,&1D
 EQUB &1D,&1D,&1E,&1E,&1E,&1E,&1E,&1E
 EQUB &1E,&1F,&1F,&1F,&1F,&1F,&1F,&1F
 EQUB &20,&20,&20,&20,&20,&20,&20,&21
 EQUB &21,&21,&21,&21,&21,&21,&22,&22
 EQUB &22,&22,&22,&22,&22,&23,&23,&23
 EQUB &23,&23,&23,&23,&24,&24,&24,&24
 EQUB &24,&24,&24,&25,&25,&25,&25,&25
 EQUB &96,&97,&9A,&9B,&9D,&9E,&9F,&A6
 EQUB &A7,&AB,&AC,&AD,&AE,&AF,&B2,&B3
 EQUB &B4,&B5,&B6,&B7,&B9,&BA,&BB,&BC
 EQUB &BD,&BE,&BF,&CB,&CD,&CE,&CF,&D3
 EQUB &D6,&D7,&D9,&DA,&DB,&DC,&DD,&DE
 EQUB &DF,&E5,&E6,&E7,&E9,&EA,&EB,&EC
 EQUB &ED,&EE,&EF,&F2,&F3,&F4,&F5,&F6
 EQUB &F7,&F9,&FA,&FB,&FC,&FD,&FE,&FF

.COMC

 EQUB &00

 EQUB &00,&00,&00,&00,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&00,&00

.CATF

 EQUB &00,&00

.L2C55

 EQUB &00

.DAMP

 EQUB &00

.DJD

 EQUB &00

.PATG

 EQUB &00

.FLH

 EQUB &00

.L2C5A

 EQUB &00

.L2C5B

 EQUB &00

.JSTK

 EQUB &00,&00

.L2C5E

 EQUB &00

.BSTK

 EQUB &00,&00

.L2C61

 EQUB &07

.L2C62

 EQUB &01,&41,&58,&46,&59,&4A,&4B,&55
 EQUB &54,&60

.S%

 CLD
 JSR MOVE_CODE

 JSR BRKBK

 JMP BEGIN

.MOVE_CODE

 LDA #&C0
 STA FRIN
 LDA #&2C
 STA FRIN+1
 LDA #&7F
 LDY #&47
 LDX #&19
 JSR MOVE_CODE_L1

 LDA #&FF
 STA FRIN
 LDA #&7F
 STA FRIN+1
 LDA #&B1
 LDY #&FF
 LDX #&62

.MOVE_CODE_L1

 STX T
 STA SC+1
 LDA #&00
 STA SC

.MOVE_CODE_L2

 LDA (SC),Y
 SEC
 SBC T
 STA (SC),Y
 STA T
 TYA
 BNE L2CAF

 DEC SC+1

.L2CAF

 DEY
 CPY FRIN
 BNE MOVE_CODE_L2

 LDA SC+1
 CMP FRIN+1
 BNE MOVE_CODE_L2

 RTS

 EQUB &B7,&AA,&45,&23

\ ******************************************************************************
\
\       Name: DOENTRY
\       Type: Subroutine
\   Category: Flight
\    Summary: Dock at the space station, show the ship hanger and work out any
\             mission progression
\
\ ******************************************************************************

.DOENTRY

 JSR RES2               \ Reset a number of flight variables and workspaces

 JSR LAUN               \ Show the space station docking tunnel

 LDA #0                 \ Reduce the speed to 0
 STA DELTA

 STA GNTMP              \ Cool down the lasers completely

 STA QQ22+1             \ Reset the on-screen hyperspace counter

 LDA #&FF               \ Recharge the forward and aft shields
 STA FSH
 STA ASH

 STA ENERGY             \ Recharge the energy banks

 JSR HALL               \ Show the ship hanger

 LDY #44                \ Wait for 44/50 of a second (0.88 seconds)
 JSR DELAY

 LDA TP                 \ Fetch bits 0 and 1 of TP, and if they are non-zero
 AND #%00000011         \ (i.e. mission 1 is either in progress or has been
 BNE EN1                \ completed), skip to EN1

 LDA TALLY+1            \ If the high byte of TALLY is zero (so we have a combat
 BEQ EN4                \ rank below Competent), jump to EN4 as we are not yet
                        \ good enough to qualify for a mission

 LDA GCNT               \ Fetch the galaxy number into A, and if any of bits 1-7
 LSR A                  \ are set (i.e. A > 1), jump to EN4 as mission 1 can
 BNE EN4                \ only be triggered in the first two galaxies

 JMP BRIEF              \ If we get here, mission 1 hasn't started, we have
                        \ reached a combat rank of Competent, and we are in
                        \ galaxy 0 or 1 (shown in-game as galaxy 1 or 2), so
                        \ it's time to start mission 1 by calling BRIEF

.EN1

                        \ If we get here then mission 1 is either in progress or
                        \ has been completed

 CMP #%00000011         \ If bits 0 and 1 are not both set, then jump to EN2
 BNE EN2

 JMP DEBRIEF            \ Bits 0 and 1 are both set, so mission 1 is both in
                        \ progress and has been completed, which means we have
                        \ only just completed it, so jump to DEBRIEF to end the
                        \ mission get our reward

.EN2

                        \ Mission 1 has been completed, so now to check for
                        \ mission 2

 LDA GCNT               \ Fetch the galaxy number into A

 CMP #2                 \ If this is not galaxy 2 (shown in-game as galaxy 3),
 BNE EN4                \ jump to EN4 as we can only start mission 2 in the
                        \ third galaxy

 LDA TP                 \ Extract bits 0-3 of TP into A
 AND #%00001111

 CMP #%00000010         \ If mission 1 is complete and no longer in progress,
 BNE EN3                \ and mission 2 is not yet started, then bits 0-3 of TP
                        \ will be %0010, so this jumps to EN3 if this is not the
                        \ case

 LDA TALLY+1            \ If the high byte of TALLY is < 5 (so we have a combat
 CMP #5                 \ rank that is less than 3/8 of the way from Dangerous
 BCC EN4                \ to Deadly), jump to EN4 as our rank isn't high enough
                        \ for mission 2

 JMP BRIEF2             \ If we get here, mission 1 is complete and no longer in
                        \ progress, mission 2 hasn't started, we have reached a
                        \ combat rank of 3/8 of the way from Dangerous to
                        \ Deadly, and we are in galaxy 2 (shown in-game as
                        \ galaxy 3), so it's time to start mission 2 by calling
                        \ BRIEF2

.EN3

 CMP #%00000110         \ If mission 1 is complete and no longer in progress,
 BNE EN5                \ and mission 2 has started but we have not yet been
                        \ briefed and picked up the plans, then bits 0-3 of TP
                        \ will be %0110, so this jumps to EN5 if this is not the
                        \ case

 LDA QQ0                \ Set A = the current system's galactic x-coordinate

 CMP #215               \ If A <> 215 then jump to EN4
 BNE EN4

 LDA QQ1                \ Set A = the current system's galactic y-coordinate

 CMP #84                \ If A <> 84 then jump to EN4
 BNE EN4

 JMP BRIEF3             \ If we get here, mission 1 is complete and no longer in
                        \ progress, mission 2 has started but we have not yet
                        \ picked up the plans, and we have just arrived at
                        \ Ceerdi at galactic coordinates (215, 84), so we jump
                        \ to BRIEF3 to get a mission brief and pick up the plans
                        \ that we need to carry to Birera

.EN5

 CMP #%00001010         \ If mission 1 is complete and no longer in progress,
 BNE EN4                \ and mission 2 has started and we have picked up the
                        \ plans, then bits 0-3 of TP will be %1010, so this
                        \ jumps to EN5 if this is not the case

 LDA QQ0                \ Set A = the current system's galactic x-coordinate

 CMP #63                \ If A <> 63 then jump to EN4
 BNE EN4

 LDA QQ1                \ Set A = the current system's galactic y-coordinate

 CMP #72
 BNE EN4                \ If A <> 72 then jump to EN4

 JMP DEBRIEF2           \ If we get here, mission 1 is complete and no longer in
                        \ progress, mission 2 has started and we have picked up
                        \ the plans, and we have just arrived at Birera at
                        \ galactic coordinates (63, 72), so we jump to DEBRIEF2
                        \ to end the mission and get our reward

.EN4

 JMP BAY                \ If we get here them we didn't start or any missions,
                        \ so jump to BAY to go to the docking bay (i.e. show the
                        \ Status Mode screen)

 EQUB &FB,&04,&F7,&08,&EF,&10,&DF,&20,&BF
 EQUB &40,&7F,&80

\ ******************************************************************************
\
\       Name: Main flight loop (Part 1 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Seed the random number generator
\  Deep dive: Program flow of the main game loop
\             Generating random numbers
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Seed the random number generator
\
\ Other entry points:
\
\   M%                  The entry point for the main flight loop
\
\ ******************************************************************************

.M%

 LDA K%                 \ We want to seed the random number generator with a
                        \ pretty random number, so fetch the contents of K%,
                        \ which is the x_lo coordinate of the planet. This value
                        \ will be fairly unpredictable, so it's a pretty good
                        \ candidate

 STA RAND               \ Store the seed in the first byte of the four-byte
                        \ random number seed that's stored in RAND

\ ******************************************************************************
\
\       Name: Main flight loop (Part 2 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Calculate the alpha and beta angles from the current pitch and
\             roll of our ship
\  Deep dive: Program flow of the main game loop
\             Pitching and rolling
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Calculate the alpha and beta angles from the current pitch and roll
\
\ Here we take the current rate of pitch and roll, as set by the joystick or
\ keyboard, and convert them into alpha and beta angles that we can use in the
\ matrix functions to rotate space around our ship. The alpha angle covers
\ roll, while the beta angle covers pitch (there is no yaw in this version of
\ Elite). The angles are in radians, which allows us to use the small angle
\ approximation when moving objects in the sky (see the MVEIT routine for more
\ on this). Also, the signs of the two angles are stored separately, in both
\ the sign and the flipped sign, as this makes calculations easier.
\
\ ******************************************************************************

 LDX JSTX               \ Set X to the current rate of roll in JSTX, and
 JSR cntr               \ apply keyboard damping twice (if enabled) so the roll
 JSR cntr               \ rate in X creeps towards the centre by 2

                        \ The roll rate in JSTX increases if we press ">" (and
                        \ the RL indicator on the dashboard goes to the right).
                        \ This rolls our ship to the right (clockwise), but we
                        \ actually implement this by rolling everything else
                        \ to the left (anticlockwise), so a positive roll rate
                        \ in JSTX translates to a negative roll angle alpha

 TXA                    \ Set A and Y to the roll rate but with the sign bit
 EOR #%10000000         \ flipped (i.e. set them to the sign we want for alpha)
 TAY

 AND #%10000000         \ Extract the flipped sign of the roll rate and store
 STA ALP2               \ in ALP2 (so ALP2 contains the sign of the roll angle
                        \ alpha)

 STX JSTX               \ Update JSTX with the damped value that's still in X

 EOR #%10000000         \ Extract the correct sign of the roll rate and store
 STA ALP2+1             \ in ALP2+1 (so ALP2+1 contains the flipped sign of the
                        \ roll angle alpha)

 TYA                    \ Set A to the roll rate but with the sign bit flipped

 BPL P%+7               \ If the value of A is positive, skip the following
                        \ three instructions

 EOR #%11111111         \ A is negative, so change the sign of A using two's
 CLC                    \ complement so that A is now positive and contains
 ADC #1                 \ the absolute value of the roll rate, i.e. |JSTX|

 LSR A                  \ Divide the (positive) roll rate in A by 4
 LSR A

 CMP #8                 \ If A >= 8, skip the following instruction
 BCS P%+3

 LSR A                  \ A < 8, so halve A again

 STA ALP1               \ Store A in ALP1, so we now have:
                        \
                        \   ALP1 = |JSTX| / 8    if |JSTX| < 32
                        \
                        \   ALP1 = |JSTX| / 4    if |JSTX| >= 32
                        \
                        \ This means that at lower roll rates, the roll angle is
                        \ reduced closer to zero than at higher roll rates,
                        \ which gives us finer control over the ship's roll at
                        \ lower roll rates
                        \
                        \ Because JSTX is in the range -127 to +127, ALP1 is
                        \ in the range 0 to 31

 ORA ALP2               \ Store A in ALPHA, but with the sign set to ALP2 (so
 STA ALPHA              \ ALPHA has a different sign to the actual roll rate)

 LDX JSTY               \ Set X to the current rate of pitch in JSTY, and
 JSR cntr               \ apply keyboard damping so the pitch rate in X creeps
                        \ towards the centre by 1

 TXA                    \ Set A and Y to the pitch rate but with the sign bit
 EOR #%10000000         \ flipped
 TAY

 AND #%10000000         \ Extract the flipped sign of the pitch rate into A

 STX JSTY               \ Update JSTY with the damped value that's still in X

 STA BET2+1             \ Store the flipped sign of the pitch rate in BET2+1

 EOR #%10000000         \ Extract the correct sign of the pitch rate and store
 STA BET2               \ it in BET2

 TYA                    \ Set A to the pitch rate but with the sign bit flipped

 BPL P%+4               \ If the value of A is positive, skip the following
                        \ instruction

 EOR #%11111111         \ A is negative, so flip the bits

 ADC #4                 \ Add 4 to the (positive) pitch rate, so the maximum
                        \ value is now up to 131 (rather than 127)

 LSR A                  \ Divide the (positive) pitch rate in A by 16
 LSR A
 LSR A
 LSR A

 CMP #3                 \ If A >= 3, skip the following instruction
 BCS P%+3

 LSR A                  \ A < 3, so halve A again

 STA BET1               \ Store A in BET1, so we now have:
                        \
                        \   BET1 = |JSTY| / 32    if |JSTY| < 48
                        \
                        \   BET1 = |JSTY| / 16    if |JSTY| >= 48
                        \
                        \ This means that at lower pitch rates, the pitch angle
                        \ is reduced closer to zero than at higher pitch rates,
                        \ which gives us finer control over the ship's pitch at
                        \ lower pitch rates
                        \
                        \ Because JSTY is in the range -131 to +131, BET1 is in
                        \ the range 0 to 8

 ORA BET2               \ Store A in BETA, but with the sign set to BET2 (so
 STA BETA               \ BETA has the same sign as the actual pitch rate)

 LDA BSTK               \ If BSTK = 0 then the Bitstik is not configured, so
 BEQ BS2                \ jump to BS2 to skip the following

 LDA L12A9              \ ???

 LSR A                  \ Divide A by 4
 LSR A

 CMP #40                \ If A < 40, skip the following instruction
 BCC P%+4

 LDA #40                \ Set A = 40, which ensures a maximum speed of 40

 STA DELTA              \ Update our speed in DELTA

 BNE MA4                \ If the speed we just set is non-zero, then jump to MA4
                        \ to skip the following, as we don't need to check the
                        \ keyboard for speed keys, otherwise do check the
                        \ keyboard (so Bitstik users can still use the keyboard
                        \ for speed adjustments if they twist the stick to zero)

\ ******************************************************************************
\
\       Name: Main flight loop (Part 3 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Scan for flight keys and process the results
\  Deep dive: Program flow of the main game loop
\             The key logger
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Scan for flight keys and process the results
\
\ Flight keys are logged in the key logger at location KY1 onwards, with a
\ non-zero value in the relevant location indicating a key press. See the deep
\ dive on "The key logger" for more details.
\
\ The key presses that are processed are as follows:
\
\   * SPACE and "?" to speed up and slow down
\   * "U", "T" and "M" to disarm, arm and fire missiles
\   * TAB to fire an energy bomb
\   * ESCAPE to launch an escape pod
\   * "J" to initiate an in-system jump
\   * "E" to deploy E.C.M. anti-missile countermeasures
\   * "C" to use the docking computer
\   * "A" to fire lasers
\
\ ******************************************************************************

.BS2

 LDA KY2                \ If Space is being pressed, keep going, otherwise jump
 BEQ MA17               \ down to MA17 to skip the following

 LDA DELTA              \ The "go faster" key is being pressed, so first we
 CMP #40                \ fetch the current speed from DELTA into A, and if
 BCS MA17               \ A >= 40, we are already going at full pelt, so jump
                        \ down to MA17 to skip the following

 INC DELTA              \ We can go a bit faster, so increment the speed in
                        \ location DELTA

.MA17

 LDA KY1                \ If "?" is being pressed, keep going, otherwise jump
 BEQ MA4                \ down to MA4 to skip the following

 DEC DELTA              \ The "slow down" key is being pressed, so we decrement
                        \ the current ship speed in DELTA

 BNE MA4                \ If the speed is still greater than zero, jump to MA4

 INC DELTA              \ Otherwise we just braked a little too hard, so bump
                        \ the speed back up to the minimum value of 1

.MA4

 LDA KY15               \ If "U" is being pressed and the number of missiles
 AND NOMSL              \ in NOMSL is non-zero, keep going, otherwise jump down
 BEQ MA20               \ to MA20 to skip the following

 LDY #GREEN2            \ The "disarm missiles" key is being pressed, so call
 JSR ABORT              \ ABORT to disarm the missile and update the missile
                        \ indicators on the dashboard to green (Y = &EE)

 JSR BEEP_LONG_LOW      \ ???

 LDA #0                 \ Set MSAR to 0 to indicate that no missiles are
 STA MSAR               \ currently armed

.MA20

 LDA MSTG               \ If MSTG is positive (i.e. it does not have bit 7 set),
 BPL MA25               \ then it indicates we already have a missile locked on
                        \ a target (in which case MSTG contains the ship number
                        \ of the target), so jump to MA25 to skip targeting. Or
                        \ to put it another way, if MSTG = &FF, which means
                        \ there is no current target lock, keep going

 LDA KY14               \ If "T" is being pressed, keep going, otherwise jump
 BEQ MA25               \ down to MA25 to skip the following

 LDX NOMSL              \ If the number of missiles in NOMSL is zero, jump down
 BEQ MA25               \ to MA25 to skip the following

 STA MSAR               \ The "target missile" key is being pressed and we have
                        \ at least one missile, so set MSAR = &FF to denote that
                        \ our missile is currently armed (we know A has the
                        \ value &FF, as we just loaded it from MSTG and checked
                        \ that it was negative)

 LDY #YELLOW2           \ Change the leftmost missile indicator to yellow
 JSR MSBAR              \ on the missile bar (this call changes the leftmost
                        \ indicator because we set X to the number of missiles
                        \ in NOMSL above, and the indicators are numbered from
                        \ right to left, so X is the number of the leftmost
                        \ indicator)

.MA25

 LDA KY16               \ If "M" is being pressed, keep going, otherwise jump
 BEQ MA24               \ down to MA24 to skip the following

 LDA MSTG               \ If MSTG = &FF then there is no target lock, so jump to
 BMI MA64               \ MA64 to skip the following (also skipping the checks
                        \ for TAB, ESCAPE, "J" and "E")

 JSR FRMIS              \ The "fire missile" key is being pressed and we have
                        \ a missile lock, so call the FRMIS routine to fire
                        \ the missile

.MA24

 LDA KY12               \ If TAB is being pressed, keep going, otherwise jump
 BEQ MA76               \ jump down to MA76 to skip the following

 LDA BOMB               \ ???
 BMI MA76

 ASL BOMB               \ The "energy bomb" key is being pressed, so double
                        \ the value in BOMB. If we have an energy bomb fitted,
                        \ BOMB will contain &7F (%01111111) before this shift
                        \ and will contain &FE (%11111110) after the shift; if
                        \ we don't have an energy bomb fitted, BOMB will still
                        \ contain 0. The bomb explosion is dealt with in the
                        \ MAL1 routine below - this just registers the fact that
                        \ we've set the bomb ticking

 BEQ MA76               \ ???

 JSR L31ED

.MA76

 LDA KY20               \ If "P" is being pressed, keep going, otherwise skip
 BEQ MA78               \ the next two instructions

 LDA #0                 \ The "cancel docking computer" key is bring pressed,
 STA auto               \ so turn it off by setting auto to 0

.MA78

 LDA KY13               \ If ESCAPE is being pressed and we have an escape pod
 AND ESCP               \ fitted, keep going, otherwise jump to noescp to skip
 BEQ noescp             \ the following instructions

 LDA MJ                 \ If we are in witchspace, we can't launch our escape
 BNE noescp             \ pod, so jump down to noescp

 JMP ESCAPE             \ The "launch escape pod" button is being pressed and
                        \ we have an escape pod fitted, so jump to ESCAPE to
                        \ launch it, and exit the main flight loop using a tail
                        \ call

.noescp

 LDA KY18               \ If "J" is being pressed, keep going, otherwise skip
 BEQ P%+5               \ the next instruction

 JSR WARP               \ Call the WARP routine to do an in-system jump

 LDA KY17               \ If "E" is being pressed and we have an E.C.M. fitted,
 AND ECM                \ keep going, otherwise jump down to MA64 to skip the
 BEQ MA64               \ following

 LDA ECMA               \ If ECMA is non-zero, that means an E.C.M. is already
 BNE MA64               \ operating and is counting down (this can be either
                        \ our E.C.M. or an opponent's), so jump down to MA64 to
                        \ skip the following (as we can't have two E.C.M.
                        \ systems operating at the same time)

 DEC ECMP               \ The "E.C.M." button is being pressed and nobody else
                        \ is operating their E.C.M., so decrease the value of
                        \ ECMP to make it non-zero, to denote that our E.C.M.
                        \ is now on

 JSR ECBLB2             \ Call ECBLB2 to light up the E.C.M. indicator bulb on
                        \ the dashboard, set the E.C.M. countdown timer to 32,
                        \ and start making the E.C.M. sound

.MA64

 LDA KY19               \ If "C" is being pressed, and we have a docking
 AND DKCMP              \ computer fitted, keep going, otherwise jump down to
 BEQ MA68               \ MA68 to skip the following

 STA auto               \ Set auto to the non-zero value of A, so the docking
                        \ computer is activated

.MA68

 LDA #0                 \ Set LAS = 0, to switch the laser off while we do the
 STA LAS                \ following logic

 STA DELT4              \ Take the 16-bit value (DELTA 0) - i.e. a two-byte
 LDA DELTA              \ number with DELTA as the high byte and 0 as the low
 LSR A                  \ byte - and divide it by 4, storing the 16-bit result
 ROR DELT4              \ in DELT4(1 0). This has the effect of storing the
 LSR A                  \ current speed * 64 in the 16-bit location DELT4(1 0)
 ROR DELT4
 STA DELT4+1

 LDA LASCT              \ If LASCT is zero, keep going, otherwise the laser is
 BNE MA3                \ a pulse laser that is between pulses, so jump down to
                        \ MA3 to skip the following

 LDA KY7                \ If "A" is being pressed, keep going, otherwise jump
 BEQ MA3                \ down to MA3 to skip the following

 LDA GNTMP              \ If the laser temperature >= 242 then the laser has
 CMP #242               \ overheated, so jump down to MA3 to skip the following
 BCS MA3

 LDX VIEW               \ If the current space view has a laser fitted (i.e. the
 LDA LASER,X            \ laser power for this view is greater than zero), then
 BEQ MA3                \ keep going, otherwise jump down to MA3 to skip the
                        \ following

                        \ If we get here, then the "fire" button is being
                        \ pressed, our laser hasn't overheated and isn't already
                        \ being fired, and we actually have a laser fitted to
                        \ the current space view, so it's time to hit me with
                        \ those laser beams

 PHA                    \ Store the current view's laser power on the stack

 AND #%01111111         \ Set LAS and LAS2 to bits 0-6 of the laser power
 STA LAS
 STA LAS2

 JSR LASER_NOISE        \ ???

 JSR LASLI              \ Call LASLI to draw the laser lines

 PLA                    \ Restore the current view's laser power into A

 BPL ma1                \ If the laser power has bit 7 set, then it's an "always
                        \ on" laser rather than a pulsing laser, so keep going,
                        \ otherwise jump down to ma1 to skip the following
                        \ instruction

 LDA #0                 \ This is an "always on" laser (i.e. a beam laser,
                        \ as the cassette version of Elite doesn't have military
                        \ lasers), so set A = 0, which will be stored in LASCT
                        \ to denote that this is not a pulsing laser

.ma1

 AND #%11111010         \ LASCT will be set to 0 for beam lasers, and to the
 STA LASCT              \ laser power AND %11111010 for pulse lasers, which
                        \ comes to 10 (as pulse lasers have a power of 15). See
                        \ MA23 below for more on laser pulsing and LASCT

\ ******************************************************************************
\
\       Name: Main flight loop (Part 4 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Copy the ship's data block from K% to the
\             zero-page workspace at INWK
\  Deep dive: Program flow of the main game loop
\             Ship data blocks
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Start looping through all the ships in the local bubble, and for each
\     one:
\
\     * Copy the ship's data block from K% to INWK
\
\     * Set XX0 to point to the ship's blueprint (if this is a ship)
\
\ Other entry points:
\
\   MAL1                Marks the beginning of the ship analysis loop, so we
\                       can jump back here from part 12 of the main flight loop
\                       to work our way through each ship in the local bubble.
\                       We also jump back here when a ship is removed from the
\                       bubble, so we can continue processing from the next ship
\
\ ******************************************************************************

.MA3

 LDX #0                 \ We're about to work our way through all the ships in
                        \ our local bubble of universe, so set a counter in X,
                        \ starting from 0, to refer to each ship slot in turn

.MAL1

 STX XSAV               \ Store the current slot number in XSAV

 LDA FRIN,X             \ Fetch the contents of this slot into A. If it is 0
 BNE P%+5               \ then this slot is empty and we have no more ships to
 JMP MA18               \ process, so jump to MA18 below, otherwise A contains
                        \ the type of ship that's in this slot, so skip over the
                        \ JMP MA18 instruction and keep going

 STA TYPE               \ Store the ship type in TYPE

 JSR GINF               \ Call GINF to fetch the address of the ship data block
                        \ for the ship in slot X and store it in INF. The data
                        \ block is in the K% workspace, which is where all the
                        \ ship data blocks are stored

                        \ Next we want to copy the ship data block from INF to
                        \ the zero-page workspace at INWK, so we can process it
                        \ more efficiently

 LDY #NI%-1             \ There are NI% bytes in each ship data block (and in
                        \ the INWK workspace, so we set a counter in Y so we can
                        \ loop through them

.MAL2

 LDA (INF),Y            \ Load the Y-th byte of INF and store it in the Y-th
 STA INWK,Y             \ byte of INWK

 DEY                    \ Decrement the loop counter

 BPL MAL2               \ Loop back for the next byte until we have copied the
                        \ last byte from INF to INWK

 LDA TYPE               \ If the ship type is negative then this indicates a
 BMI MA21               \ planet or sun, so jump down to MA21, as the next bit
                        \ sets up a pointer to the ship blueprint, and then
                        \ checks for energy bomb damage, and neither of these
                        \ apply to planets and suns

 ASL A                  \ Set Y = ship type * 2
 TAY

 LDA XX21-2,Y           \ The ship blueprints at XX21 start with a lookup
 STA XX0                \ table that points to the individual ship blueprints,
                        \ so this fetches the low byte of this particular ship
                        \ type's blueprint and stores it in XX0

 LDA XX21-1,Y           \ Fetch the high byte of this particular ship type's
 STA XX0+1              \ blueprint and store it in XX0+1

\ ******************************************************************************
\
\       Name: Main flight loop (Part 5 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: If an energy bomb has been set off,
\             potentially kill this ship
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * If an energy bomb has been set off and this ship can be killed, kill it
\       and increase the kill tally
\
\ ******************************************************************************

 LDA BOMB               \ If we set off our energy bomb by pressing TAB (see
 BPL MA21               \ MA24 above), then BOMB is now negative, so this skips
                        \ to MA21 if our energy bomb is not going off

 CPY #2*SST             \ If the ship in Y is the space station, jump to BA21
 BEQ MA21               \ as energy bombs are useless against space stations

 CPY #2*THG             \ ???
 BEQ MA21

 CPY #2*CON             \ If the ship in Y is the Constrictor, jump to BA21
 BCS MA21               \ as energy bombs are useless against the Constrictor
                        \ (the Constrictor is the target of mission 1, and it
                        \ would be too easy if it could just be blown out of
                        \ the sky with a single key press)

 LDA INWK+31            \ If the ship we are checking has bit 5 set in its ship
 AND #%00100000         \ byte #31, then it is already exploding, so jump to
 BNE MA21               \ BA21 as ships can't explode more than once

 ASL INWK+31            \ The energy bomb is killing this ship, so set bit 7 of
 SEC                    \ the ship byte #31 to indicate that it has now been
 ROR INWK+31            \ killed

 LDX TYPE               \ ???

 JSR EXNO2              \ Call EXNO2 to process the fact that we have killed a
                        \ ship (so increase the kill tally, make an explosion
                        \ sound and possibly display "RIGHT ON COMMANDER!")

\ ******************************************************************************
\
\       Name: Main flight loop (Part 6 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Move the ship in space and copy the updated
\             INWK data block back to K%
\  Deep dive: Program flow of the main game loop
\             Program flow of the ship-moving routine
\             Ship data blocks
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Move the ship in space
\
\     * Copy the updated ship's data block from INWK back to K%
\
\ ******************************************************************************

.MA21

 JSR MVEIT              \ Call MVEIT to move the ship we are processing in space

                        \ Now that we are done processing this ship, we need to
                        \ copy the ship data back from INWK to the correct place
                        \ in the K% workspace. We already set INF in part 4 to
                        \ point to the ship's data block in K%, so we can simply
                        \ do the reverse of the copy we did before, this time
                        \ copying from INWK to INF

 LDY #(NI%-1)           \ Set a counter in Y so we can loop through the NI%
                        \ bytes in the ship data block

.MAL3

 LDA INWK,Y             \ Load the Y-th byte of INWK and store it in the Y-th
 STA (INF),Y            \ byte of INF

 DEY                    \ Decrement the loop counter

 BPL MAL3               \ Loop back for the next byte, until we have copied the
                        \ last byte from INWK back to INF

\ ******************************************************************************
\
\       Name: Main flight loop (Part 7 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Check whether we are docking, scooping or
\             colliding with it
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Check how close we are to this ship and work out if we are docking,
\       scooping or colliding with it
\
\ ******************************************************************************

 LDA INWK+31            \ Fetch the status of this ship from bits 5 (is ship
 AND #%10100000         \ exploding?) and bit 7 (has ship been killed?) from
                        \ ship byte #31 into A

 JSR MAS4               \ Or this value with x_hi, y_hi and z_hi

 BNE MA65               \ If this value is non-zero, then either the ship is
                        \ far away (i.e. has a non-zero high byte in at least
                        \ one of the three axes), or it is already exploding,
                        \ or has been flagged as being killed - in which case
                        \ jump to MA65 to skip the following, as we can't dock
                        \ scoop or collide with it

 LDA INWK               \ Set A = (x_lo OR y_lo OR z_lo), and if bit 7 of the
 ORA INWK+3             \ result is set, the ship is still a fair distance
 ORA INWK+6             \ away (further than 127 in at least one axis), so jump
 BMI MA65               \ to MA65 to skip the following, as it's too far away to
                        \ dock, scoop or collide with

 LDX TYPE               \ If the current ship type is negative then it's either
 BMI MA65               \ a planet or a sun, so jump down to MA65 to skip the
                        \ following, as we can't dock with it or scoop it

 CPX #SST               \ If this ship is the space station, jump to ISDK to
 BEQ ISDK               \ check whether we are docking with it

 AND #%11000000         \ If bit 6 of (x_lo OR y_lo OR z_lo) is set, then the
 BNE MA65               \ ship is still a reasonable distance away (further than
                        \ 63 in at least one axis), so jump to MA65 to skip the
                        \ following, as it's too far away to dock, scoop or
                        \ collide with

 CPX #MSL               \ If this ship is a missile, jump down to MA65 to skip
 BEQ MA65               \ the following, as we can't scoop or dock with a
                        \ missile, and it has its own dedicated collision
                        \ checks in the TACTICS routine

 LDA BST                \ If we have fuel scoops fitted then BST will be &FF,
                        \ otherwise it will be 0

 AND INWK+5             \ Ship byte #5 contains the y_sign of this ship, so a
                        \ negative value here means the canister is below us,
                        \ which means the result of the AND will be negative if
                        \ the canister is below us and we have a fuel scoop
                        \ fitted

 BPL MA58               \ If the result is positive, then we either have no
                        \ scoop or the canister is above us, and in both cases
                        \ this means we can't scoop the item, so jump to MA58
                        \ to process a collision

\ ******************************************************************************
\
\       Name: Main flight loop (Part 8 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Process us potentially scooping this item
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Process us potentially scooping this item
\
\ ******************************************************************************

 CPX #OIL               \ If this is a cargo canister, jump to oily to randomly
 BEQ oily               \ decide the canister's contents

 LDY #0                 \ Fetch byte #0 of the ship's blueprint
 LDA (XX0),Y

 LSR A                  \ Shift it right four times, so A now contains the high
 LSR A                  \ nibble (i.e. bits 4-7)
 LSR A
 LSR A

 BEQ MA58               \ If A = 0, jump to MA58 to skip all the docking and
                        \ scooping checks

                        \ Only the Thargon, alloy plate, splinter and escape pod
                        \ have non-zero upper nibbles in their blueprint byte #0
                        \ so if we get here, our ship is one of those, and the
                        \ upper nibble gives the market item number of the item
                        \ when scooped, less 1

 ADC #1                 \ Add 1 to the upper nibble to get the market item
                        \ number

 BNE slvy2              \ Skip to slvy2 so we scoop the ship as a market item

.oily

 JSR DORND              \ Set A and X to random numbers and reduce A to a
 AND #7                 \ random number in the range 0-7

.slvy2

                        \ By the time we get here, we are scooping, and A
                        \ contains the type of item we are scooping (a random
                        \ number 0-7 if we are scooping a cargo canister, 3 if
                        \ we are scooping an escape pod, or 16 if we are
                        \ scooping a Thargon). These numbers correspond to the
                        \ relevant market items (see QQ23 for a list), so a
                        \ cargo canister can contain anything from food to
                        \ computers, while escape pods contain slaves, and
                        \ Thargons become alien items when scooped

 JSR tnpr1              \ Call tnpr1 with the scooped cargo type stored in A
                        \ to work out whether we have room in the hold for one
                        \ tonne of this cargo (A is set to 1 by this call, and
                        \ the C flag contains the result)

 LDY #78                \ This instruction has no effect, so presumably it used
                        \ to do something, but didn't get removed

 BCS MA59               \ If the C flag is set then we have no room in the hold
                        \ for the scooped item, so jump down to MA59 make a
                        \ sound to indicate failure, before destroying the
                        \ canister

 LDY QQ29               \ Scooping was successful, so set Y to the type of
                        \ item we just scooped, which we stored in QQ29 above

 ADC QQ20,Y             \ Add A (which we set to 1 above) to the number of items
 STA QQ20,Y             \ of type Y in the cargo hold, as we just successfully
                        \ scooped one canister of type Y

 TYA                    \ Print recursive token 48 + A as an in-flight token,
 ADC #208               \ which will be in the range 48 ("FOOD") to 64 ("ALIEN
 JSR MESS               \ ITEMS"), so this prints the scooped item's name

 ASL NEWB               \ The item has now been scooped, so set bit 7 of its
 SEC                    \ NEWB flags to indicate this
 ROR NEWB

.MA65

 JMP MA26               \ If we get here, then the ship we are processing was
                        \ too far away to be scooped, docked or collided with,
                        \ so jump to MA26 to skip over the collision routines
                        \ and move on to missile targeting

\ ******************************************************************************
\
\       Name: Main flight loop (Part 9 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: If it is a space station, check whether we
\             are successfully docking with it
\  Deep dive: Program flow of the main game loop
\             Docking checks
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Process docking with a space station
\
\ For details on the various docking checks in this routine, see the deep dive
\ on "Docking checks".
\
\ Other entry points:
\
\   GOIN                We jump here from part 3 of the main flight loop if the
\                       docking computer is activated by pressing "C"
\
\ ******************************************************************************

.ISDK

 LDA K%+NI%+36          \ 1. Fetch the NEWB flags (byte #36) of the second ship
 AND #%00000100         \ in the ship data workspace at K%, which is reserved
 BNE MA62               \ for the sun or the space station (in this case it's
                        \ the latter), and if bit 2 is set, meaning the station
                        \ is hostile, jump down to MA62 to fail docking (so
                        \ trying to dock at a station that we have annoyed does
                        \ not end well)

 LDA INWK+14            \ 2. If nosev_z_hi < 214, jump down to MA62 to fail
 CMP #214               \ docking, as the angle of approach is greater than 26
 BCC MA62               \ degrees

 JSR SPS1               \ Call SPS1 to calculate the vector to the planet and
                        \ store it in XX15

 LDA XX15+2             \ Set A to the z-axis of the vector

 CMP #89                \ 4. If z-axis < 89, jump to MA62 to fail docking, as
 BCC MA62               \ we are not in the 22.0 degree safe cone of approach

 LDA INWK+16            \ 5. If |roofv_x_hi| < 80, jump to MA62 to fail docking,
 AND #%01111111         \ as the slot is more than 36.6 degrees from horizontal
 CMP #80
 BCC MA62

.GOIN

                        \ If we arrive here, either the docking computer has
                        \ been activated, or we just docked successfully

 JMP DOENTRY            \ Go to the docking bay (i.e. show the ship hanger)

.MA62

                        \ If we arrive here, docking has just failed

 LDA DELTA              \ If the ship's speed is < 5, jump to MA67 to register
 CMP #5                 \ some damage, but not a huge amount
 BCC MA67

 JMP DEATH              \ Otherwise we have just crashed into the station, so
                        \ process our death

\ ******************************************************************************
\
\       Name: Main flight loop (Part 10 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Remove if scooped, or process collisions
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Remove scooped item after both successful and failed scoopings
\
\     * Process collisions
\
\ ******************************************************************************

.MA59

                        \ If we get here then scooping failed

 JSR EXNO3              \ Make the sound of the cargo canister being destroyed
                        \ and fall through into MA60 to remove the canister
                        \ from our local bubble

.MA60

                        \ If we get here then scooping was successful

 ASL INWK+31            \ Set bit 7 of the scooped or destroyed item, to denote
 SEC                    \ that it has been killed and should be removed from
 ROR INWK+31            \ the local bubble

.MA61                   \ This label is not used but is in the original source

 BNE MA26               \ Jump to MA26 to skip over the collision routines and
                        \ to move on to missile targeting (this BNE is
                        \ effectively a JMP as A will never be zero)

.MA67

                        \ If we get here then we have collided with something,
                        \ but not fatally

 LDA #1                 \ Set the speed in DELTA to 1 (i.e. a sudden stop)
 STA DELTA

 LDA #5                 \ Set the amount of damage in A to 5 (a small dent) and
 BNE MA63               \ jump down to MA63 to process the damage (this BNE is
                        \ effectively a JMP as A will never be zero)

.MA58

                        \ If we get here, we have collided with something in a
                        \ potentially fatal way

 ASL INWK+31            \ Set bit 7 of the ship we just collided with, to
 SEC                    \ denote that it has been killed and should be removed
 ROR INWK+31            \ from the local bubble

 LDA INWK+35            \ Load A with the energy level of the ship we just hit

 SEC                    \ Set the amount of damage in A to 128 + A / 2, so
 ROR A                  \ this is quite a big dent, and colliding with higher
                        \ energy ships will cause more damage

.MA63

 JSR OOPS               \ The amount of damage is in A, so call OOPS to reduce
                        \ our shields, and if the shields are gone, there's a
                        \ a chance of cargo loss or even death

 JSR EXNO3              \ Make the sound of colliding with the other ship and
                        \ fall through into MA26 to try targeting a missile

\ ******************************************************************************
\
\       Name: Main flight loop (Part 11 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Process missile lock and firing our laser
\  Deep dive: Program flow of the main game loop
\             Flipping axes between space views
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * If this is not the front space view, flip the axes of the ship's
\        coordinates in INWK
\
\     * Process missile lock
\
\     * Process our laser firing
\
\ ******************************************************************************

.MA26

 LDA NEWB               \ If bit 7 of the ship's NEWB flags is clear, skip the
 BPL P%+5               \ following instruction

 JSR SCAN               \ Bit 7 of the ship's NEWB flags is set, which means the
                        \ ship has docked or been scooped, so we draw the ship
                        \ on the scanner, which has the effect of removing it

 LDA QQ11               \ If this is not a space view, jump to MA15 to skip
 BNE MA15               \ missile and laser locking

 JSR PLUT               \ Call PLUT to update the geometric axes in INWK to
                        \ match the view (front, rear, left, right)

 JSR HITCH              \ Call HITCH to see if this ship is in the crosshairs,
 BCC MA8                \ in which case the C flag will be set (so if there is
                        \ no missile or laser lock, we jump to MA8 to skip the
                        \ following)

 LDA MSAR               \ We have missile lock, so check whether the leftmost
 BEQ MA47               \ missile is currently armed, and if not, jump to MA47
                        \ to process laser fire, as we can't lock an unarmed
                        \ missile

 JSR BEEP               \ We have missile lock and an armed missile, so call
                        \ the BEEP subroutine to make a short, high beep

 LDX XSAV               \ Call ABORT2 to store the details of this missile
 LDY #RED2              \ lock, with the targeted ship's slot number in X
 JSR ABORT2             \ (which we stored in XSAV at the start of this ship's
                        \ loop at MAL1), and set the colour of the missile
                        \ indicator to the colour in Y (red = &0E)

.MA47

                        \ If we get here then the ship is in our sights, but
                        \ we didn't lock a missile, so let's see if we're
                        \ firing the laser

 LDA LAS                \ If we are firing the laser then LAS will contain the
 BEQ MA8                \ laser power (which we set in MA68 above), so if this
                        \ is zero, jump down to MA8 to skip the following

 LDX #15                \ We are firing our laser and the ship in INWK is in
 JSR EXNO               \ the crosshairs, so call EXNO to make the sound of
                        \ us making a laser strike on another ship

 LDA TYPE               \ Did we just hit the space station? If so, jump to
 CMP #SST               \ MA14+2 to make the station hostile, skipping the
 BEQ MA14+2             \ following as we can't destroy a space station

 CMP #CON               \ If the ship we hit is less than #CON - i.e. it's not
 BCC BURN               \ a Constrictor, Cougar, Dodo station or the Elite logo,
                        \ jump to BURN to skip the following

 LDA LAS                \ Set A to the power of the laser we just used to hit
                        \ the ship (i.e. the laser in the current view)

 CMP #(Armlas AND 127)  \ If the laser is not a military laser, jump to MA14+2
 BNE MA14+2             \ to skip the following, as only military lasers have
                        \ any effect on the Constrictor or Cougar (or the Elite
                        \ logo, should you ever bump into one of those out there
                        \ in the black...)

 LSR LAS                \ Divide the laser power of the current view by 4, so
 LSR LAS                \ the damage inflicted on the super-ship is a quarter of
                        \ the damage our military lasers would inflict on a
                        \ normal ship

.BURN

 LDA INWK+35            \ Fetch the hit ship's energy from byte #35 and subtract
 SEC                    \ our current laser power, and if the result is greater
 SBC LAS                \ than zero, the other ship has survived the hit, so
 BCS MA14               \ jump down to MA14

 ASL INWK+31            \ Set bit 7 of the ship byte #31 to indicate that it has
 SEC                    \ now been killed
 ROR INWK+31

 LDA TYPE               \ Did we just kill an asteroid? If not, jump to nosp,
 CMP #AST               \ otherwise keep going
 BNE nosp

 LDA LAS                \ Did we kill the asteroid using mining lasers? If not,
 CMP #Mlas              \ jump to nosp, otherwise keep going
 BNE nosp

 JSR DORND              \ Set A and X to random numbers

 LDX #SPL               \ Set X to the ship type for a splinter

 AND #3                 \ Reduce the random number in A to the range 0-3

 JSR SPIN2              \ Call SPIN2 to spawn A items of type X (i.e. spawn
                        \ 0-3 spliters)

.nosp

 LDY #PLT               \ Randomly spawn some alloy plates
 JSR SPIN

 LDY #OIL               \ Randomly spawn some cargo canisters
 JSR SPIN

 LDX TYPE               \ ???

 JSR EXNO2              \ Call EXNO2 to process the fact that we have killed a
                        \ ship (so increase the kill tally, make an explosion
                        \ sound and so on)

.MA14

 STA INWK+35            \ Store the hit ship's updated energy in ship byte #35

 LDA TYPE               \ Call ANGRY to make this ship hostile, now that we
 JSR ANGRY              \ have hit it

\ ******************************************************************************
\
\       Name: Main flight loop (Part 12 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Draw the ship, remove if killed, loop back
\  Deep dive: Program flow of the main game loop
\             Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Draw the ship
\
\     * Process removal of killed ships
\
\   * Loop back up to MAL1 to move onto the next ship in the local bubble
\
\ ******************************************************************************

.MA8

 JSR LL9                \ Call LL9 to draw the ship we're processing on-screen

.MA15

 LDY #35                \ Fetch the ship's energy from byte #35 and copy it to
 LDA INWK+35            \ byte #35 in INF (so the ship's data in K% gets
 STA (INF),Y            \ updated)

 LDA NEWB               \ If bit 7 of the ship's NEWB flags is set, which means
 BMI KS1S               \ the ship has docked or been scooped, jump to KS1S to
                        \ skip the following, as we can't get a bounty for a
                        \ ship that's no longer around

 LDA INWK+31            \ If bit 7 of the ship's byte #31 is clear, then the
 BPL MAC1               \ ship hasn't been killed by energy bomb, collision or
                        \ laser fire, so jump to MAC1 to skip the following

 AND #%00100000         \ If bit 5 of the ship's byte #31 is clear then the
 BEQ MAC1               \ ship is no longer exploding, so jump to MAC1 to skip
                        \ the following

 LDA NEWB               \ Extract bit 6 of the ship's NEWB flags, so A = 64 if
 AND #%01000000         \ bit 6 is set, or 0 if it is clear. Bit 6 is set if
                        \ this ship is a cop, so A = 64 if we just killed a
                        \ policeman, otherwise it is 0

 ORA FIST               \ Update our FIST flag ("fugitive/innocent status") to
 STA FIST               \ at least the value in A, which will instantly make us
                        \ a fugitive if we just shot the sheriff, but won't
                        \ affect our status if the enemy wasn't a copper

 LDA DLY                \ If we already have an in-flight message on-screen (in
 ORA MJ                 \ which case DLY > 0), or we are in witchspace (in
 BNE KS1S               \ which case MJ > 0), jump to KS1S to skip showing an
                        \ on-screen bounty for this kill

 LDY #10                \ Fetch byte #10 of the ship's blueprint, which is the
 LDA (XX0),Y            \ low byte of the bounty awarded when this ship is
 BEQ KS1S               \ killed (in Cr * 10), and if it's zero jump to KS1S as
                        \ there is no on-screen bounty to display

 TAX                    \ Put the low byte of the bounty into X

 INY                    \ Fetch byte #11 of the ship's blueprint, which is the
 LDA (XX0),Y            \ high byte of the bounty awarded (in Cr * 10), and put
 TAY                    \ it into Y

 JSR MCASH              \ Call MCASH to add (Y X) to the cash pot

 LDA #0                 \ Print control code 0 (current cash, right-aligned to
 JSR MESS               \ width 9, then " CR", newline) as an in-flight message

.KS1S

 JMP KS1                \ Process the killing of this ship (which removes this
                        \ ship from its slot and shuffles all the other ships
                        \ down to close up the gap)

.MAC1

 LDA TYPE               \ If the ship we are processing is a planet or sun,
 BMI MA27               \ jump to MA27 to skip the following two instructions

 JSR FAROF              \ If the ship we are processing is a long way away (its
 BCC KS1S               \ distance in any one direction is > 224, jump to KS1S
                        \ to remove the ship from our local bubble, as it's just
                        \ left the building

.MA27

 LDY #31                \ Fetch the ship's explosion/killed state from byte #31
 LDA INWK+31            \ and copy it to byte #31 in INF (so the ship's data in
 STA (INF),Y            \ K% gets updated)

 LDX XSAV               \ We're done processing this ship, so fetch the ship's
                        \ slot number, which we saved in XSAV back at the start
                        \ of the loop

 INX                    \ Increment the slot number to move on to the next slot

 JMP MAL1               \ And jump back up to the beginning of the loop to get
                        \ the next ship in the local bubble for processing

\ ******************************************************************************
\
\       Name: Main flight loop (Part 13 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Show energy bomb effect, charge shields and energy banks
\  Deep dive: Program flow of the main game loop
\             Scheduling tasks with the main loop counter
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Show energy bomb effect (if applicable)
\
\   * Charge shields and energy banks (every 7 iterations of the main loop)
\
\ ******************************************************************************

.MA18

 LDA BOMB               \ If we set off our energy bomb by pressing TAB (see
 BPL MA77               \ MA24 above), then BOMB is now negative, so this skips
                        \ to MA77 if our energy bomb is not going off

 JSR WSCAN_DUPLICATE

 ASL BOMB
 BMI MA77

 JSR L31AC

.MA77

 LDA MCNT               \ Fetch the main loop counter and calculate MCNT mod 7,
 AND #7                 \ jumping to MA22 if it is non-zero (so the following
 BNE MA22               \ code only runs every 8 iterations of the main loop)

 LDX ENERGY             \ Fetch our ship's energy levels and skip to b if bit 7
 BPL b                  \ is not set, i.e. only charge the shields from the
                        \ energy banks if they are at more than 50% charge

 LDX ASH                \ Call SHD to recharge our aft shield and update the
 JSR SHD                \ shield status in ASH
 STX ASH

 LDX FSH                \ Call SHD to recharge our forward shield and update
 JSR SHD                \ the shield status in FSH
 STX FSH

.b

 SEC                    \ Set A = ENERGY + ENGY + 1, so our ship's energy
 LDA ENGY               \ level goes up by 2 if we have an energy unit fitted,
 ADC ENERGY             \ otherwise it goes up by 1

 BCS P%+4               \ If the value of A did not overflow (the maximum
 STA ENERGY             \ energy level is &FF), then store A in ENERGY ???

\ ******************************************************************************
\
\       Name: Main flight loop (Part 14 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Spawn a space station if we are close enough to the planet
\  Deep dive: Program flow of the main game loop
\             Scheduling tasks with the main loop counter
\             Ship data blocks
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Spawn a space station if we are close enough to the planet (every 32
\     iterations of the main loop)
\
\ ******************************************************************************

 LDA MJ                 \ If we are in witchspace, jump down to MA23S to skip
 BNE MA23S              \ the following, as there are no space stations in
                        \ witchspace

 LDA MCNT               \ Fetch the main loop counter and calculate MCNT mod 32,
 AND #31                \ jumping to MA93 if it is on-zero (so the following
 BNE MA93               \ code only runs every 32 iterations of the main loop

 LDA SSPR               \ If we are inside the space station safe zone, jump to
 BNE MA23S              \ MA23S to skip the following, as we already have a
                        \ space station and don't need another

 TAY                    \ Set Y = A = 0 (A is 0 as we didn't branch with the
                        \ previous BNE instruction)

 JSR MAS2               \ Call MAS2 to calculate the largest distance to the
 BNE MA23S              \ planet in any of the three axes, and if it's
                        \ non-zero, jump to MA23S to skip the following, as we
                        \ are too far from the planet to bump into a space
                        \ station

                        \ We now want to spawn a space station, so first we
                        \ need to set up a ship data block for the station in
                        \ INWK that we can then pass to NWSPS to add a new
                        \ station to our bubble of universe. We do this by
                        \ copying the planet data block from K% to INWK so we
                        \ can work on it, but we only need the first 29 bytes,
                        \ as we don't need to worry about bytes #29 to #35
                        \ for planets (as they don't have rotation counters,
                        \ AI, explosions, missiles, a ship line heap or energy
                        \ levels)

 LDX #28                \ So we set a counter in X to copy 29 bytes from K%+0
                        \ to K%+28

.MAL4

 LDA K%,X               \ Load the X-th byte of K% and store in the X-th byte
 STA INWK,X             \ of the INWK workspace

 DEX                    \ Decrement the loop counter

 BPL MAL4               \ Loop back for the next byte until we have copied the
                        \ first 28 bytes of K% to INWK

                        \ We now check the distance from our ship (at the
                        \ origin) towards the planet's surface, by adding the
                        \ planet's nosev vector to the planet's centre at
                        \ (x, y, z) and checking our distance to the end
                        \ point along the relevant axis

 INX                    \ Set X = 0 (as we ended the above loop with X as &FF)

 LDY #9                 \ Call MAS1 with X = 0, Y = 9 to do the following:
 JSR MAS1               \
                        \   (x_sign x_hi x_lo) += (nosev_x_hi nosev_x_lo) * 2
                        \
                        \   A = |x_hi|

 BNE MA23S              \ If A > 0, jump to MA23S to skip the following, as we
                        \ are too far from the planet in the x-direction to
                        \ bump into a space station

 LDX #3                 \ Call MAS1 with X = 3, Y = 11 to do the following:
 LDY #11                \
 JSR MAS1               \   (y_sign y_hi y_lo) += (nosev_y_hi nosev_y_lo) * 2
                        \
                        \   A = |y_hi|

 BNE MA23S              \ If A > 0, jump to MA23S to skip the following, as we
                        \ are too far from the planet in the y-direction to
                        \ bump into a space station

 LDX #6                 \ Call MAS1 with X = 6, Y = 13 to do the following:
 LDY #13                \
 JSR MAS1               \   (z_sign z_hi z_lo) += (nosev_z_hi nosev_z_lo) * 2
                        \
                        \   A = |z_hi|

 BNE MA23S              \ If A > 0, jump to MA23S to skip the following, as we
                        \ are too far from the planet in the z-direction to
                        \ bump into a space station

 LDA #192               \ Call FAROF2 to compare x_hi, y_hi and z_hi with 192,
 JSR FAROF2             \ which will set the C flag if all three are < 192, or
                        \ clear the C flag if any of them are >= 192

 BCC MA23S              \ Jump to MA23S if any one of x_hi, y_hi or z_hi are
                        \ >= 192 (i.e. they must all be < 192 for us to be near
                        \ enough to the planet to bump into a space station)

 JSR WPLS               \ Call WPLS to remove the sun from the screen, as we
                        \ can't have both the sun and the space station at the
                        \ same time

 JSR NWSPS              \ Add a new space station to our local bubble of
                        \ universe

.MA23S

 JMP MA23               \ Jump to MA23 to skip the following planet and sun
                        \ altitude checks

\ ******************************************************************************
\
\       Name: Main flight loop (Part 15 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Perform altitude checks with planet and sun, process fuel scooping
\  Deep dive: Program flow of the main game loop
\             Scheduling tasks with the main loop counter
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Perform an altitude check with the planet (every 32 iterations of the main
\     loop, on iteration 10 of each 32)
\
\   * Perform an an altitude check with the sun and process fuel scooping (every
\     32 iterations of the main loop, on iteration 20 of each 32)
\
\ ******************************************************************************

.MA22

 LDA MJ                 \ If we are in witchspace, jump down to MA23S to skip
 BNE MA23S              \ the following, as there are no planets or suns to
                        \ bump into in witchspace

 LDA MCNT               \ Fetch the main loop counter and calculate MCNT mod 32,
 AND #31                \ which tells us the position of this loop in each block
                        \ of 32 iterations

.MA93

 CMP #10                \ If this is the tenth iteration in this block of 32,
 BNE MA29               \ do the following, otherwise jump to MA29 to skip the
                        \ planet altitude check and move on to the sun distance
                        \ check

 LDA #50                \ If our energy bank status in ENERGY is >= 50, skip
 CMP ENERGY             \ printing the following message (so the message is
 BCC P%+6               \ only shown if our energy is low)

 ASL A                  \ Print recursive token 100 ("ENERGY LOW{beep}") as an
 JSR MESS               \ in-flight message

 LDY #&FF               \ Set our altitude in ALTIT to &FF, the maximum
 STY ALTIT

 INY                    \ Set Y = 0

 JSR m                  \ Call m to calculate the maximum distance to the
                        \ planet in any of the three axes, returned in A

 BNE MA23               \ If A > 0 then we are a fair distance away from the
                        \ planet in at least one axis, so jump to MA23 to skip
                        \ the rest of the altitude check

 JSR MAS3               \ Set A = x_hi^2 + y_hi^2 + z_hi^2, so using Pythagoras
                        \ we now know that A now contains the square of the
                        \ distance between our ship (at the origin) and the
                        \ centre of the planet at (x_hi, y_hi, z_hi)

 BCS MA23               \ If the C flag was set by MAS3, then the result
                        \ overflowed (was greater than &FF) and we are still a
                        \ fair distance from the planet, so jump to MA23 as we
                        \ haven't crashed into the planet

 SBC #36                \ Subtract 36 from x_hi^2 + y_hi^2 + z_hi^2. The radius
                        \ of the planet is defined as 6 units and 6^2 = 36, so
                        \ A now contains the high byte of our altitude above
                        \ the planet surface, squared

 BCC MA28               \ If A < 0 then jump to MA28 as we have crashed into
                        \ the planet

 STA R                  \ We are getting close to the planet, so we need to
 JSR LL5                \ work out how close. We know from the above that A
                        \ contains our altitude squared, so we store A in R
                        \ and call LL5 to calculate:
                        \
                        \   Q = SQRT(R Q) = SQRT(A Q)
                        \
                        \ Interestingly, Q doesn't appear to be set to 0 for
                        \ this calculation, so presumably this doesn't make a
                        \ difference

 LDA Q                  \ Store the result in ALTIT, our altitude
 STA ALTIT

 BNE MA23               \ If our altitude is non-zero then we haven't crashed,
                        \ so jump to MA23 to skip to the next section

.MA28

 JMP DEATH              \ If we get here then we just crashed into the planet
                        \ or got too close to the sun, so call DEATH to start
                        \ the funeral preparations

.MA29

 CMP #15                \ If this is the 15th iteration in this block of 32,
 BNE MA33               \ do the following, otherwise jump to MA33 to skip the
                        \ docking computer manoeuvring

 LDA auto               \ If auto is zero, then the docking computer is not
 BEQ MA23               \ activated, so jump to MA33 to skip the
                        \ docking computer manoeuvring

 LDA #123               \ Set A = 123 and jump down to MA34 to print token 123
 BNE MA34               \ ("DOCKING COMPUTERS ON") as an in-flight message

.MA33

 CMP #20                \ If this is the 20th iteration in this block of 32,
 BNE MA23               \ do the following, otherwise jump to MA23 to skip the
                        \ sun altitude check

 LDA #30                \ Set CABTMP to 30, the cabin temperature in deep space
 STA CABTMP             \ (i.e. one notch on the dashboard bar)

 LDA SSPR               \ If we are inside the space station safe zone, jump to
 BNE MA23               \ MA23 to skip the following, as we can't have both the
                        \ sun and space station at the same time, so we clearly
                        \ can't be flying near the sun

 LDY #NI%               \ Set Y to NI%, which is the offset in K% for the sun's
                        \ data block, as the second block at K% is reserved for
                        \ the sun (or space station)

 JSR MAS2               \ Call MAS2 to calculate the largest distance to the
 BNE MA23               \ sun in any of the three axes, and if it's non-zero,
                        \ jump to MA23 to skip the following, as we are too far
                        \ from the sun for scooping or temperature changes

 JSR MAS3               \ Set A = x_hi^2 + y_hi^2 + z_hi^2, so using Pythagoras
                        \ we now know that A now contains the square of the
                        \ distance between our ship (at the origin) and the
                        \ heart of the sun at (x_hi, y_hi, z_hi)

 EOR #%11111111         \ Invert A, so A is now small if we are far from the
                        \ sun and large if we are close to the sun, in the
                        \ range 0 = far away to &FF = extremely close, ouch,
                        \ hot, hot, hot!

 ADC #30                \ Add the minimum cabin temperature of 30, so we get
                        \ one of the following:
                        \
                        \   * If the C flag is clear, A contains the cabin
                        \     temperature, ranging from 30 to 255, that's hotter
                        \     the closer we are to the sun
                        \
                        \   * If the C flag is set, the addition has rolled over
                        \     and the cabin temperature is over 255

 STA CABTMP             \ Store the updated cabin temperature

 BCS MA28               \ If the C flag is set then jump to MA28 to die, as
                        \ our temperature is off the scale

 CMP #&E0               \ If the cabin temperature < 224 then jump to MA23 to
 BCC MA23               \ to skip fuel scooping, as we aren't close enough

 LDA BST                \ If we don't have fuel scoops fitted, jump to BA23 to
 BEQ MA23               \ skip fuel scooping, as we can't scoop without fuel
                        \ scoops

 LDA DELT4+1            \ We are now successfully fuel scooping, so it's time
 LSR A                  \ to work out how much fuel we're scooping. Fetch the
                        \ high byte of DELT4, which contains our current speed
                        \ divided by 4, and halve it to get our current speed
                        \ divided by 8 (so it's now a value between 1 and 5, as
                        \ our speed is normally between 1 and 40). This gives
                        \ us the amount of fuel that's being scooped in A, so
                        \ the faster we go, the more fuel we scoop, and because
                        \ the fuel levels are stored as 10 * the fuel in light
                        \ years, that means we just scooped between 0.1 and 0.5
                        \ light years of free fuel

 ADC QQ14               \ Set A = A + the current fuel level * 10 (from QQ14)

 CMP #70                \ If A > 70 then set A = 70 (as 70 is the maximum fuel
 BCC P%+4               \ level, or 7.0 light years)
 LDA #70

 STA QQ14               \ Store the updated fuel level in QQ14

 LDA #160               \ Set A to token 160 ("FUEL SCOOPS ON")

.MA34

 JSR MESS               \ Print the token in A as an in-flight message

\ ******************************************************************************
\
\       Name: Main flight loop (Part 16 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Process laser pulsing, E.C.M. energy drain, call stardust routine
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Process laser pulsing
\
\   * Process E.C.M. energy drain
\
\   * Jump to the stardust routine if we are in a space view
\
\   * Return from the main flight loop
\
\ ******************************************************************************

.MA23

 LDA LAS2               \ If the current view has no laser, jump to MA16 to skip
 BEQ MA16               \ the following

 LDA LASCT              \ If LASCT >= 8, jump to MA16 to skip the following, so
 CMP #8                 \ for a pulse laser with a LASCT between 8 and 10, the
 BCS MA16               \ the laser stays on, but for a LASCT of 7 or less it
                        \ gets turned off and stays off until LASCT reaches zero
                        \ and the next pulse can start (if the fire button is
                        \ still being pressed)
                        \
                        \ For pulse lasers, LASCT gets set to 10 in ma1 above,
                        \ and it decrements every vertical sync (50 times a
                        \ second), so this means it pulses five times a second,
                        \ with the laser being on for the first 3/10 of each
                        \ pulse and off for the rest of the pulse
                        \
                        \ If this is a beam laser, LASCT is 0 so we always keep
                        \ going here. This means the laser doesn't pulse, but it
                        \ does get drawn and removed every cycle, in a slightly
                        \ different place each time, so the beams still flicker
                        \ around the screen

 JSR LASLI2             \ Redraw the existing laser lines, which has the effect
                        \ of removing them from the screen

 LDA #0                 \ Set LAS2 to 0 so if this is a pulse laser, it will
 STA LAS2               \ skip over the above until the next pulse (this has no
                        \ effect if this is a beam laser)

.MA16

 LDA ECMP               \ If our E.C.M is not on, skip to MA69, otherwise keep
 BEQ MA69               \ going to drain some energy

 JSR DENGY              \ Call DENGY to deplete our energy banks by 1

 BEQ MA70               \ If we have no energy left, jump to MA70 to turn our
                        \ E.C.M. off

.MA69

 LDA ECMA               \ If an E.C.M is going off (our's or an opponent's) then
 BEQ MA66               \ keep going, otherwise skip to MA66

 LDY #&07               \ ???
 JSR NOISE

 DEC ECMA               \ Decrement the E.C.M. countdown timer, and if it has
 BNE MA66               \ reached zero, keep going, otherwise skip to MA66

.MA70

 JSR ECMOF              \ If we get here then either we have either run out of
                        \ energy, or the E.C.M. timer has run down, so switch
                        \ off the E.C.M.

.MA66

 LDA QQ11               \ If this is not a space view (i.e. QQ11 is non-zero)
 BNE oh                 \ then jump to oh to return from the main flight loop
                        \ (as oh is an RTS)

 JMP STARS              \ This is a space view, so jump to the STARS routine to
                        \ process the stardust, and return from the main flight
                        \ loop using a tail call

\ ******************************************************************************
\
\       Name: SPIN
\       Type: Subroutine
\   Category: Universe
\    Summary: Randomly spawn cargo from a destroyed ship
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   Y                   The type of cargo to consider spawning (typically #PLT
\                       or #OIL)
\
\ Other entry points:
\
\   oh                  Contains an RTS
\
\   SPIN2               Remove any randomness: spawn cargo of a specific type
\                       (given in X), and always spawn the number given in A
\
\ ******************************************************************************

.SPIN

 JSR DORND              \ Fetch a random number, and jump to oh if it is
 BPL oh                 \ positive (50% chance)

 TYA                    \ Copy the cargo type from Y into A and X
 TAX

 LDY #0                 \ Fetch the first byte of the hit ship's blueprint,
 AND (XX0),Y            \ which determines the maximum number of bits of
                        \ debris shown when the ship is destroyed, and AND
                        \ with the random number we just fetched

 AND #15                \ Reduce the random number in A to the range 0-15

.SPIN2

 STA CNT                \ Store the result in CNT, so CNT contains a random
                        \ number between 0 and the maximum number of bits of
                        \ debris that this ship will release when destroyed
                        \ (to a maximum of 15 bits of debris)

.spl

 BEQ oh                 \ We're going to go round a loop using CNT as a counter
                        \ so this checks whether the counter is zero and jumps
                        \ to oh when it gets there (which might be straight
                        \ away)

 LDA #0                 \ Call SFS1 to spawn the specified cargo from the now
 JSR SFS1               \ deceased parent ship, giving the spawned canister an
                        \ AI flag of 0 (no AI, no E.C.M., non-hostile)

 DEC CNT                \ Decrease the loop counter

 BNE spl+2              \ Jump back up to the LDA &0 instruction above (this BPL
                        \ is effectively a JMP as CNT will never be negative)

.oh

 RTS                    \ Return from the subroutine

.L31AC

 LDA #&FF
 STA COL
 LDA QQ11
 BNE L31DE

 LDY #&01
 LDA L321D
 STA XX12
 LDA L3227
 STA XX12+1

.L31C0

 LDA XX12
 STA XX15
 LDA XX12+1
 STA Y1
 LDA L321D,Y
 STA X2
 STA XX12
 LDA L3227,Y
 STA Y2
 STA XX12+1
 JSR LL30

 INY
 CPY #&0A
 BCC L31C0

.L31DE

 RTS

.WSCAN_DUPLICATE

 JSR L31E2

.L31E2

 JSR L31E5

.L31E5

 LDY #&06
 JSR NOISE

 JSR L31AC

.L31ED

 LDY #&00

.L31EF

 JSR DORND

 AND #&7F
 ADC #&03
 STA L3227,Y
 TXA
 AND #&1F
 CLC
 ADC L3213,Y
 STA L321D,Y
 INY
 CPY #&0A
 BCC L31EF

 LDX #&00
 STX L3226
 DEX
 STX L321D
 BCS L31AC

.L3213

 CPX #&E0
 CPY #&A0
 BRA &3279

 EQUB &40

 EQUB &20,&00,&00

.L321D

 EQUB &00,&00,&00,&00,&00,&00,&00,&00
 EQUB &00

.L3226

 EQUB &00

.L3227

 EQUB &00,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&00

\ ******************************************************************************
\
\       Name: MT27
\       Type: Subroutine
\   Category: Text
\    Summary: Print the captain's name during mission briefings
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine prints the following tokens, depending on the galaxy number:
\
\   * Token 217 ("CURRUTHERS") in galaxy 0
\
\   * Token 218 ("FOSDYKE SMYTHE") in galaxy 1
\
\   * Token 219 ("FORTESQUE") in galaxy 2
\
\ This is used when printing extended token 213 as part of the mission
\ briefings, which looks like this when printed:
\
\   Commander {commander name}, I am Captain {mission captain's name} of Her
\   Majesty's Space Navy
\
\ where {mission captain's name} is replaced by one of the names above.
\
\ ******************************************************************************

.MT27

 LDA #217               \ Set A = 217, so when we fall through into MT28, the
                        \ 217 gets added to the current galaxy number, so the
                        \ extended token that is printed is 217-219 (as this is
                        \ only called in galaxies 0 through 2)

 BNE P%+4               \ Skip the next instruction

\ ******************************************************************************
\
\       Name: MT28
\       Type: Subroutine
\   Category: Text
\    Summary: Print the location hint during the mission 1 briefing
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine prints the following tokens, depending on the galaxy number:
\
\   * Token 220 ("WAS LAST SEEN AT {single cap}REESDICE") in galaxy 0
\
\   * Token 221 ("IS BELIEVED TO HAVE JUMPED TO THIS GALAXY") in galaxy 1
\
\ This is used when printing extended token 10 as part of the mission 1
\ briefing, which looks like this when printed:
\
\   It went missing from our ship yard on Xeer five months ago and {mission 1
\   location hint}
\
\ where {mission 1 location hint} is replaced by one of the names above.
\
\ ******************************************************************************

.MT28

 LDA #220               \ Set A = galaxy number in GCNT + 220, which is in the
 CLC                    \ range 220-221, as this is only called in galaxies 0
 ADC GCNT               \ and 1

 BNE DETOK              \ Jump to DETOK to print extended token 220-221,
                        \ returning from the subroutine using a tail call (this
                        \ BNE is effectively a JMP as A is never zero)

\ ******************************************************************************
\
\       Name: DETOK3
\       Type: Subroutine
\   Category: Text
\    Summary: Print an extended recursive token from the RUTOK token table
\  Deep dive: Extended system descriptions
\             Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The recursive token to be printed, in the range 0-255
\
\ Returns:
\
\   A                   A is preserved
\
\   Y                   Y is preserved
\
\   V(1 0)              V(1 0) is preserved
\
\ ******************************************************************************

.DETOK3

 PHA                    \ Store A on the stack, so we can retrieve it later

 TAX                    \ Copy the token number from A into X

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 LDA #LO(RUTOK)         \ Set V to the low byte of RUTOK
 STA V

 LDA #HI(RUTOK)         \ Set A to the high byte of RUTOK

 BNE DTEN               \ Call DTEN to print token number X from the RUTOK
                        \ table and restore the values of A, Y and V(1 0) from
                        \ the stack, returning from the subroutine using a tail
                        \ call (this BNE is effectively a JMP as A is never
                        \ zero)

\ ******************************************************************************
\
\       Name: DETOK
\       Type: Subroutine
\   Category: Text
\    Summary: Print an extended recursive token from the TKN1 token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The recursive token to be printed, in the range 1-255
\
\ Returns:
\
\   A                   A is preserved
\
\   Y                   Y is preserved
\
\   V(1 0)              V(1 0) is preserved
\
\ Other entry points:
\
\   DTEN                Print recursive token number X from the token table
\                       pointed to by (A V), used to print tokens from the RUTOK
\                       table via calls to DETOK3
\
\ ******************************************************************************

.DETOK

 PHA                    \ Store A on the stack, so we can retrieve it later

 TAX                    \ Copy the token number from A into X

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 LDA #LO(TKN1)          \ Set V to the low byte of TKN1
 STA V

 LDA #HI(TKN1)          \ Set A to the high byte of TKN1, so when we fall
                        \ through into DTEN, V(1 0) gets set to the address of
                        \ the TKN1 token table

.DTEN

 STA V+1                \ Set the high byte of V(1 0) to A, so V(1 0) now points
                        \ to the start of the token table to use

 LDY #0                 \ First, we need to work our way through the table until
                        \ we get to the token that we want to print. Tokens are
                        \ delimited by #VE, and VE EOR VE = 0, so we work our
                        \ way through the table in, counting #VE delimiters
                        \ until we have passed X of them, at which point we jump
                        \ down to DTL2 to do the actual printing. So first, we
                        \ set a counter Y to point to the character offset as we
                        \ scan through the table
.DTL1

 LDA (V),Y              \ Load the character at offset Y in the token table,
                        \ which is the next character from the token table

 EOR #VE                \ Tokens are stored in memory having been EOR'd with
                        \ #VE, so we repeat the EOR to get the actual character
                        \ in this token

 BNE DT1                \ If the result is non-zero, then this is a character
                        \ in a token rather than the delimiter (which is #VE),
                        \ so jump to DT1

 DEX                    \ We have just scanned the end of a token, so decrement
                        \ X, which contains the token number we are looking for

 BEQ DTL2               \ If X has now reached zero then we have found the token
                        \ we are looking for, so jump down to DTL2 to print it

.DT1

 INY                    \ Otherwise this isn't the token we are looking for, so
                        \ increment the character pointer

 BNE DTL1               \ If Y hasn't just wrapped around to 0, loop back to
                        \ DTL1 to process the next character

 INC V+1                \ We have just crossed into a new page, so increment
                        \ V+1 so that V points to the start of the new page

 BNE DTL1               \ Jump back to DTL1 to process the next character (this
                        \ BNE is effectively a JMP as V+1 won't reach zero
                        \ before we reach the end of the token table)

.DTL2

 INY                    \ We just detected the delimiter byte before the token
                        \ that we want to print, so increment the character
                        \ pointer to point to the first character of the token,
                        \ rather than the delimiter

 BNE P%+4               \ If Y hasn't just wrapped around to 0, skip the next
                        \ instruction

 INC V+1                \ We have just crossed into a new page, so increment
                        \ V+1 so that V points to the start of the new page

 LDA (V),Y              \ Load the character at offset Y in the token table,
                        \ which is the next character from the token we want to
                        \ print

 EOR #VE                \ Tokens are stored in memory having been EOR'd with
                        \ #VE, so we repeat the EOR to get the actual character
                        \ in this token

 BEQ DTEX               \ If the result is zero, then this is the delimiter at
                        \ the end of the token to print (which is #VE), so jump
                        \ to DTEX to return from the subroutine, as we are done
                        \ printing

 JSR DETOK2             \ Otherwise call DETOK2 to print this part of the token

 JMP DTL2               \ Jump back to DTL2 to process the next character

.DTEX

 PLA                    \ Restore V(1 0) from the stack, so it is preserved
 STA V+1                \ through calls to this routine
 PLA
 STA V

 PLA                    \ Restore Y from the stack, so it is preserved through
 TAY                    \ calls to this routine

 PLA                    \ Restore A from the stack, so it is preserved through
                        \ calls to this routine

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DETOK2
\       Type: Subroutine
\   Category: Text
\    Summary: Print an extended text token (1-255)
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The token to be printed (1-255)
\
\ Returns:
\
\   A                   A is preserved
\
\   Y                   Y is preserved
\
\   V(1 0)              V(1 0) is preserved
\
\ Other entry points:
\
\   DTS                 Print the single letter pointed to by A, where A is an
\                       address within the extended two-letter token tables of
\                       TKN2 and QQ16
\
\ ******************************************************************************

.DETOK2

 CMP #32                \ If A < 32 then this is a jump token, so skip to DT3 to
 BCC DT3                \ process it

 BIT DTW3               \ If bit 7 of DTW3 is clear, then extended tokens are
 BPL DT8                \ enabled, so jump to DT8 to process them

                        \ If we get there then this is not a jump token and
                        \ extended tokens are not enabled, so we can call the
                        \ standard text token routine at TT27 to print the token

 TAX                    \ Copy the token number from A into X

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 TXA                    \ Copy the token number from X back into A

 JSR TT27               \ Call TT27 to print the text token

 JMP DT7                \ Jump to DT7 to restore V(1 0) and Y from the stack and
                        \ return from the subroutine

.DT8

                        \ If we get here then this is not a jump token and
                        \ extended tokens are enabled

 CMP #'['               \ If A < ASCII "[" (i.e. A <= ASCII "Z", or 90) then
 BCC DTS                \ this is a printable ASCII character, so jump down to
                        \ DTS to print it

 CMP #129               \ If A < 129, so A is in the range 91-128, jump down to
 BCC DT6                \ DT6 to print a randomised token from the MTIN table

 CMP #215               \ If A < 215, so A is in the range 129-214, jump to
 BCC DETOK              \ DETOK as this is a recursive token, returning from the
                        \ subroutine using a tail call

                        \ If we get here then A >= 215, so this is a two-letter
                        \ token from the extended TKN2/QQ16 table

 SBC #215               \ Subtract 215 to get a token number in the range 0-12
                        \ (the C flag is set as we passed through the BCC above,
                        \ so this subtraction is correct)

 ASL A                  \ Set A = A * 2, so it can be used as a pointer into the
                        \ two-letter token tables at TKN2 and QQ16

 PHA                    \ Store A on the stack, so we can restore it for the
                        \ second letter below

 TAX                    \ Fetch the first letter of the two-letter token from
 LDA TKN2,X             \ TKN2, which is at TKN2 + X

 JSR DTS                \ Call DTS to print it

 PLA                    \ Restore A from the stack and transfer it into X
 TAX

 LDA TKN2+1,X           \ Fetch the second letter of the two-letter token from
                        \ TKN2, which is at TKN2 + X + 1, and fall through into
                        \ DTS to print it

.DTS

 CMP #'A'               \ If A < ASCII "A", jump to DT9 to print this as ASCII
 BCC DT9

 BIT DTW6               \ If bit 7 of DTW6 is set, then lower case has been
 BMI DT10               \ enabled by jump token 13, {lower case}, so jump to
                        \ DT10 to apply the lower case and single cap masks

 BIT DTW2               \ If bit 7 of DTW2 is set, then we are not currently
 BMI DT5                \ printing a word, so jump to DT5 so we skip the setting
                        \ of lower case in Sentence Case (which we only want to
                        \ do when we are already printing a word)

.DT10

 ORA DTW1               \ Convert the character to lower case if DTW1 is
                        \ %00100000 (i.e. if we are in {sentence case} mode)

.DT5

 AND DTW8               \ Convert the character to upper case if DTW8 is
                        \ %11011111 (i.e. after a {single cap} token)

.DT9

 JMP DASC               \ Jump to DASC to print the ASCII character in A,
                        \ returning from the routine using a tail call

.DT3

                        \ If we get here then the token number in A is in the
                        \ range 1 to 32, so this is a jump token that should
                        \ call the corresponding address in the jump table at
                        \ JMTB

 TAX                    \ Copy the token number from A into X

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 TXA                    \ Copy the token number from X back into A

 ASL A                  \ Set A = A * 2, so it can be used as a pointer into the
                        \ jump table at JMTB, though because the original range
                        \ of values is 1-32, so the doubled range is 2-64, we
                        \ need to take the offset into the jump table from
                        \ JMTB-2 rather than JMTB

 TAX                    \ Copy the doubled token number from A into X

 LDA JMTB-2,X           \ Set DTM(2 1) to the X-th address from the table at
 STA DTM+1              \ JTM-2, which modifies the JSR DASC instruction at
 LDA JMTB-1,X           \ label DTM below so that it calls the subroutine at the
 STA DTM+2              \ relevant address from the JMTB table

 TXA                    \ Copy the doubled token number from X back into A

 LSR A                  \ Halve A to get the original token number

.DTM

 JSR DASC               \ Call the relevant JMTB subroutine, as this instruction
                        \ will have been modified by the above to point to the
                        \ relevant address

.DT7

 PLA                    \ Restore V(1 0) from the stack, so it is preserved
 STA V+1                \ through calls to this routine
 PLA
 STA V

 PLA                    \ Restore Y from the stack, so it is preserved through
 TAY                    \ calls to this routine

 RTS                    \ Return from the subroutine

.DT6

                        \ If we get here then the token number in A is in the
                        \ range 91-128, which means we print a randomly picked
                        \ token from the token range given in the corresponding
                        \ entry in the MTIN table

 STA SC                 \ Store the token number in SC

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 JSR DORND              \ Set X to a random number
 TAX

 LDA #0                 \ Set A to 0, so we can build a random number from 0 to
                        \ 4 in A plus the C flag, with each number being equally
                        \ likely

 CPX #51                \ Add 1 to A if X >= 51
 ADC #0

 CPX #102               \ Add 1 to A if X >= 102
 ADC #0

 CPX #153               \ Add 1 to A if X >= 153
 ADC #0

 CPX #204               \ Set the C flag if X >= 204

 LDX SC                 \ Fetch the token number from SC into X, so X is now in
                        \ the range 91-128

 ADC MTIN-91,X          \ Set A = MTIN-91 + token number (91-128) + random (0-4)
                        \       = MTIN + token number (0-37) + random (0-4)

 JSR DETOK              \ Call DETOK to print the extended recursive token in A

 JMP DT7                \ Jump to DT7 to restore V(1 0) and Y from the stack and
                        \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: MT1
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to ALL CAPS when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW1 = %00000000 (do not change case to lower case)
\
\   * DTW6 = %00000000 (lower case is not enabled)
\
\ ******************************************************************************

.MT1

 LDA #%00000000         \ Set A = %00000000, so when we fall through into MT2,
                        \ both DTW1 and DTW6 get set to %00000000

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &20, or BIT &20A9, which does nothing apart
                        \ from affect the flags

\ ******************************************************************************
\
\       Name: MT2
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to Sentence Case when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW1 = %00100000 (apply lower case to the second letter of a word onwards)
\
\   * DTW6 = %00000000 (lower case is not enabled)
\
\ ******************************************************************************

.MT2

 LDA #%00100000         \ Set DTW1 = %00100000
 STA DTW1

 LDA #00000000          \ Set DTW6 = %00000000
 STA DTW6

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MT8
\       Type: Subroutine
\   Category: Text
\    Summary: Tab to column 6 and start a new word when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * XC = 6 (tab to column 6)
\
\   * DTW2 = %11111111 (we are not currently printing a word)
\
\ ******************************************************************************

.MT8

 LDA #6                 \ Move the text cursor to column 6
 JSR DOXC

 LDA #%11111111         \ Set all the bits in DTW2
 STA DTW2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MT9
\       Type: Subroutine
\   Category: Text
\    Summary: Clear the screen and set the current view type to 1
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * XC = 1 (tab to column 1)
\
\ before calling TT66 to clear the screen and set the view type to 1.
\
\ ******************************************************************************

.MT9

 LDA #1                 \ Move the text cursor to column 1
 STA XC

 JMP TT66               \ Jump to TT66 to clear the screen and set the current
                        \ view type to 1, returning from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: MT13
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to lower case when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW1 = %00100000 (apply lower case to the second letter of a word onwards)
\
\   * DTW6 = %10000000 (lower case is enabled)
\
\ ******************************************************************************

.MT13

 LDA #%10000000         \ Set DTW6 = %10000000
 STA DTW6

 LDA #%00100000         \ Set DTW1 = %00100000
 STA DTW1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MT6
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to standard tokens in Sentence Case
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * QQ17 = %10000000 (set Sentence Case for standard tokens)
\
\   * DTW3 = %11111111 (print standard tokens)
\
\ ******************************************************************************

.MT6

 LDA #%10000000         \ Set bit 7 of QQ17 to switch standard tokens to
 STA QQ17               \ Sentence Case

 LDA #%11111111         \ Set A = %11111111, so when we fall through into MT5,
                        \ DTW3 gets set to %11111111 and calls to DETOK print
                        \ standard tokens

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &00, or BIT &00A9, which does nothing apart
                        \ from affect the flags

\ ******************************************************************************
\
\       Name: MT5
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW3 = %00000000 (print extended tokens)
\
\ ******************************************************************************

.MT5

 LDA #%00000000         \ Set DTW3 = %00000000, so that calls to DETOK print
 STA DTW3               \ extended tokens

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MT14
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to justified text when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW4 = %10000000 (justify text, print buffer on carriage return)
\
\   * DTW5 = 0 (reset line buffer size)
\
\ ******************************************************************************

.MT14

 LDA #%10000000         \ Set A = %10000000, so when we fall through into MT15,
                        \ DTW4 gets set to %10000000

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &00, or BIT &00A9, which does nothing apart
                        \ from affect the flags

\ ******************************************************************************
\
\       Name: MT15
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to left-aligned text when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW4 = %00000000 (do not justify text, print buffer on carriage return)
\
\   * DTW5 = 0 (reset line buffer size)
\
\ ******************************************************************************

.MT15

 LDA #0                 \ Set DTW4 = %00000000
 STA DTW4

 ASL A                  \ Set DTW5 = 0 (even when we fall through from MT14 with
 STA DTW5               \ A set to %10000000)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MT17
\       Type: Subroutine
\   Category: Text
\    Summary: Print the selected system's adjective, e.g. Lavian for Lave
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The adjective for the current system is generated by taking the system name,
\ removing the last character if it is a vowel, and adding "-ian" to the end,
\ so:
\
\   * Lave gives Lavian (as in "Lavian tree grub")
\
\   * Leesti gives Leestian (as in "Leestian Evil Juice")
\
\ This routine is called by jump token 17, {system name adjective}, and it can
\ only be used when justified text is being printed - i.e. following jump token
\ 14, {justify} - because the routine needs to use the line buffer to work.
\
\ ******************************************************************************

.MT17

 LDA QQ17               \ Set QQ17 = %10111111 to switch to Sentence Case
 AND #%10111111
 STA QQ17

 LDA #3                 \ Print control code 3 (selected system name) into the
 JSR TT27               \ line buffer

 LDX DTW5               \ Load the last character of the line buffer BUF into A
 LDA BUF-1,X            \ (as DTW5 contains the buffer size, so character DTW5-1
                        \ is the last character in the buffer BUF)

 JSR VOWEL              \ Test whether the character is a vowel, in which case
                        \ this will set the C flag

 BCC MT171              \ If the character is not a vowel, skip the following
                        \ instruction

 DEC DTW5               \ The character is a vowel, so decrement DTW5, which
                        \ removes the last character from the line buffer (i.e.
                        \ it removes the trailing vowel from the system name)

.MT171

 LDA #153               \ Print extended token 153 ("IAN"), returning from the
 JMP DETOK              \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: MT18
\       Type: Subroutine
\   Category: Text
\    Summary: Print a random 1-8 letter word in Sentence Case
\  Deep dive: Extended text tokens
\
\ ******************************************************************************

.MT18

 JSR MT19               \ Call MT19 to capitalise the next letter (i.e. set
                        \ Sentence Case for this word only)

 JSR DORND              \ Set A and X to random numbers and reduce A to a
 AND #3                 \ random number in the range 0-3

 TAY                    \ Copy the random number into Y, so we can use Y as a
                        \ loop counter to print 1-4 words (i.e. Y+1 words)

.MT18L

 JSR DORND              \ Set A and X to random numbers and reduce A to an even
 AND #62                \ random number in the range 0-62 (as bit 0 of 62 is 0)

 TAX                    \ Copy the random number into X, so X contains the table
                        \ offset of a random extended two-letter token from 0-31
                        \ which we can now use to pick a token from the combined
                        \ tables at TKN2+2 and QQ16 (we intentionally exclude
                        \ the first token in TKN2, which contains a newline)

 LDA TKN2+2,X           \ Print the first letter of the token at TKN2+2 + X
 JSR DTS

 LDA TKN2+3,X           \ Print the second letter of the token at TKN2+2 + X
 JSR DTS

 DEY                    \ Decrement the loop counter

 BPL MT18L              \ Loop back to MT18L to print another two-letter token
                        \ until we have printed Y+1 of them

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MT19
\       Type: Subroutine
\   Category: Text
\    Summary: Capitalise the next letter
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW8 = %11011111 (capitalise the next letter)
\
\ ******************************************************************************

.MT19

 LDA #%11011111         \ Set DTW8 = %11011111
 STA DTW8

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: VOWEL
\       Type: Subroutine
\   Category: Text
\    Summary: Test whether a character is a vowel
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The character to be tested
\
\ Returns:
\
\   C flag              The C flag is set if the character is a vowel, otherwise
\                       it is clear
\
\ ******************************************************************************

.VOWEL

 ORA #%00100000         \ Set bit 5 of the character to make it lower case

 CMP #'a'               \ If the letter is a vowel, jump to VRTS to return from
 BEQ VRTS               \ the subroutine with the C flag set (as the CMP will
 CMP #'e'               \ set the C flag if the comparison is equal)
 BEQ VRTS
 CMP #'i'
 BEQ VRTS
 CMP #'o'
 BEQ VRTS
 CMP #'u'
 BEQ VRTS

 CLC                    \ The character is not a vowel, so clear the C flag

.VRTS

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: JMTB
\       Type: Variable
\   Category: Text
\    Summary: The extended token table for jump tokens 1-32 (DETOK)
\  Deep dive: Extended text tokens
\
\ ******************************************************************************

.JMTB

 EQUW MT1               \ Token  1: Switch to ALL CAPS
 EQUW MT2               \ Token  2: Switch to Sentence Case
 EQUW TT27              \ Token  3: Print the selected system name
 EQUW TT27              \ Token  4: Print the commander's name
 EQUW MT5               \ Token  5: Switch to extended tokens
 EQUW MT6               \ Token  6: Switch to standard tokens, in Sentence Case
 EQUW DASC              \ Token  7: Beep
 EQUW MT8               \ Token  8: Tab to column 6
 EQUW MT9               \ Token  9: Clear screen, tab to column 1, view type = 1
 EQUW DASC              \ Token 10: Line feed
 EQUW NLIN4             \ Token 11: Draw box around title (line at pixel row 19)
 EQUW DASC              \ Token 12: Carriage return
 EQUW MT13              \ Token 13: Switch to lower case
 EQUW MT14              \ Token 14: Switch to justified text
 EQUW MT15              \ Token 15: Switch to left-aligned text
 EQUW MT16              \ Token 16: Print the character in DTW7 (drive number)
 EQUW MT17              \ Token 17: Print system name adjective in Sentence Case
 EQUW MT18              \ Token 18: Randomly print 1 to 4 two-letter tokens
 EQUW MT19              \ Token 19: Capitalise first letter of next word only
 EQUW DASC              \ Token 20: Unused
 EQUW CLYNS             \ Token 21: Clear the bottom few lines of the space view
 EQUW PAUSE             \ Token 22: Display ship and wait for key press
 EQUW MT23              \ Token 23: Move to row 10, white text, set lower case
 EQUW PAUSE2            \ Token 24: Wait for a key press
 EQUW BRIS              \ Token 25: Show incoming message screen, wait 2 seconds
 EQUW MT26              \ Token 26: Fetch line input from keyboard (filename)
 EQUW MT27              \ Token 27: Print mission captain's name (217-219)
 EQUW MT28              \ Token 28: Print mission 1 location hint (220-221)
 EQUW MT29              \ Token 29: Column 6, white text, lower case in words
 EQUW L6960             \ ???
 EQUW L6969             \ ???
 EQUW DASC              \ Token 32: Unused

\ ******************************************************************************
\
\       Name: TKN2
\       Type: Variable
\   Category: Text
\    Summary: The extended two-letter token lookup table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ Two-letter token lookup table for extended tokens 215-227.
\
\ ******************************************************************************

.TKN2

 EQUB 12, 10            \ Token 215 = {crlf}
 EQUS "AB"              \ Token 216
 EQUS "OU"              \ Token 217
 EQUS "SE"              \ Token 218
 EQUS "IT"              \ Token 219
 EQUS "IL"              \ Token 220
 EQUS "ET"              \ Token 221
 EQUS "ST"              \ Token 222
 EQUS "ON"              \ Token 223
 EQUS "LO"              \ Token 224
 EQUS "NU"              \ Token 225
 EQUS "TH"              \ Token 226
 EQUS "NO"              \ Token 227

\ ******************************************************************************
\
\       Name: QQ16
\       Type: Variable
\   Category: Text
\    Summary: The two-letter token lookup table
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ Two-letter token lookup table for tokens 128-159. See the deep dive on
\ "Printing text tokens" for details of how the two-letter token system works.
\
\ ******************************************************************************

.QQ16

 EQUS "AL"              \ Token 128
 EQUS "LE"              \ Token 129
 EQUS "XE"              \ Token 130
 EQUS "GE"              \ Token 131
 EQUS "ZA"              \ Token 132
 EQUS "CE"              \ Token 133
 EQUS "BI"              \ Token 134
 EQUS "SO"              \ Token 135
 EQUS "US"              \ Token 136
 EQUS "ES"              \ Token 137
 EQUS "AR"              \ Token 138
 EQUS "MA"              \ Token 139
 EQUS "IN"              \ Token 140
 EQUS "DI"              \ Token 141
 EQUS "RE"              \ Token 142
 EQUS "A?"              \ Token 143
 EQUS "ER"              \ Token 144
 EQUS "AT"              \ Token 145
 EQUS "EN"              \ Token 146
 EQUS "BE"              \ Token 147
 EQUS "RA"              \ Token 148
 EQUS "LA"              \ Token 149
 EQUS "VE"              \ Token 150
 EQUS "TI"              \ Token 151
 EQUS "ED"              \ Token 152
 EQUS "OR"              \ Token 153
 EQUS "QU"              \ Token 154
 EQUS "AN"              \ Token 155
 EQUS "TE"              \ Token 156
 EQUS "IS"              \ Token 157
 EQUS "RI"              \ Token 158
 EQUS "ON"              \ Token 159

\ ******************************************************************************
\
\       Name: S1%
\       Type: Variable
\   Category: Save and load
\    Summary: The drive and directory number used when saving or loading a
\             commander file
\  Deep dive: Commander save files.
\
\ ------------------------------------------------------------------------------
\
\ The drive part of this string (the "0") is updated with the chosen drive in
\ the QUS1 routine, but the directory part (the "E") is fixed. The variable is
\ followed directly by the commander file at NA%, which starts with the
\ commander name, so the full string at S1% is in the format ":0.E.JAMESON",
\ which gives the full filename of the commander file.
\
\ ******************************************************************************

.S1%

 EQUS ":0.E."

.NA%

 EQUS "jameson"         \ The current commander name, which defaults to JAMESON
 EQUB 13

 SKIP 53                \ Placeholders for bytes #0 to #52

 EQUB 16                \ AVL+0  = Market availability of Food, #53
 EQUB 15                \ AVL+1  = Market availability of Textiles, #54
 EQUB 17                \ AVL+2  = Market availability of Radioactives, #55
 EQUB 0                 \ AVL+3  = Market availability of Slaves, #56
 EQUB 3                 \ AVL+4  = Market availability of Liquor/Wines, #57
 EQUB 28                \ AVL+5  = Market availability of Luxuries, #58
 EQUB 14                \ AVL+6  = Market availability of Narcotics, #59
 EQUB 0                 \ AVL+7  = Market availability of Computers, #60
 EQUB 0                 \ AVL+8  = Market availability of Machinery, #61
 EQUB 10                \ AVL+9  = Market availability of Alloys, #62
 EQUB 0                 \ AVL+10 = Market availability of Firearms, #63
 EQUB 17                \ AVL+11 = Market availability of Furs, #64
 EQUB 58                \ AVL+12 = Market availability of Minerals, #65
 EQUB 7                 \ AVL+13 = Market availability of Gold, #66
 EQUB 9                 \ AVL+14 = Market availability of Platinum, #67
 EQUB 8                 \ AVL+15 = Market availability of Gem-Stones, #68
 EQUB 0                 \ AVL+16 = Market availability of Alien Items, #69

 SKIP 3                 \ Placeholders for bytes #70 to #72

 EQUB 128               \ SVC = Save count, #73

\ ******************************************************************************
\
\       Name: CHK2
\       Type: Variable
\   Category: Save and load
\    Summary: Second checksum byte for the saved commander data file
\  Deep dive: Commander save files
\             The competition code
\
\ ------------------------------------------------------------------------------
\
\ Second commander checksum byte. If the default commander is changed, a new
\ checksum will be calculated and inserted by the elite-checksum.py script.
\
\ The offset of this byte within a saved commander file is also shown (it's at
\ byte #74).
\
\ ******************************************************************************

.CHK2

 EQUB 0

\ ******************************************************************************
\
\       Name: CHK
\       Type: Variable
\   Category: Save and load
\    Summary: First checksum byte for the saved commander data file
\  Deep dive: Commander save files
\             The competition code
\
\ ------------------------------------------------------------------------------
\
\ Commander checksum byte. If the default commander is changed, a new checksum
\ will be calculated and inserted by the elite-checksum.py script.
\
\ The offset of this byte within a saved commander file is also shown (it's at
\ byte #75).
\
\ ******************************************************************************

.CHK

 EQUB 0

 SKIP 12

\ ******************************************************************************
\
\       Name: DEFAULT%
\       Type: Variable
\   Category: Save and load
\    Summary: The data block for the default commander
\  Deep dive: Commander save files
\             The competition code
\
\ ------------------------------------------------------------------------------
\
\ Contains the default commander data, with the name at NA% and the data at
\ NA%+8 onwards. The size of the data block is given in NT% (which also includes
\ the two checksum bytes that follow this block. This block is initially set up
\ with the default commander, which can be maxed out for testing purposes by
\ setting Q% to TRUE.
\
\ The commander's name is stored at NA%, and can be up to 7 characters long
\ (the DFS filename limit). It is terminated with a carriage return character,
\ ASCII 13.
\
\ The offset of each byte within a saved commander file is also shown as #0, #1
\ and so on, so the kill tally, for example, is in bytes #71 and #72 of the
\ saved file. The related variable name from the current commander block is
\ also shown.
\
\ ******************************************************************************

 EQUS ":0.E."

.DEFAULT%

 EQUS "JAMESON"         \ The current commander name, which defaults to JAMESON
 EQUB 13                \
                        \ The commander name can be up to 7 characters (the DFS
                        \ limit for file names), and is terminated by a carriage
                        \ return

                        \ NA%+8 is the start of the commander data block
                        \
                        \ This block contains the last saved commander data
                        \ block. As the game is played it uses an identical
                        \ block at location TP to store the current commander
                        \ state, and that block is copied here when the game is
                        \ saved. Conversely, when the game starts up, the block
                        \ here is copied to TP, which restores the last saved
                        \ commander when we die
                        \
                        \ The initial state of this block defines the default
                        \ commander. Q% can be set to TRUE to give the default
                        \ commander lots of credits and equipment

 EQUB 0                 \ TP = Mission status, #0

 EQUB 20                \ QQ0 = Current system X-coordinate (Lave), #1
 EQUB 173               \ QQ1 = Current system Y-coordinate (Lave), #2

 EQUW &5A4A             \ QQ21 = Seed s0 for system 0, galaxy 0 (Tibedied), #3-4
 EQUW &0248             \ QQ21 = Seed s1 for system 0, galaxy 0 (Tibedied), #5-6
 EQUW &B753             \ QQ21 = Seed s2 for system 0, galaxy 0 (Tibedied), #7-8

IF Q%
 EQUD &00CA9A3B         \ CASH = Amount of cash (100,000,000 Cr), #9-12
ELSE
 EQUD &E8030000         \ CASH = Amount of cash (100 Cr), #9-12
ENDIF

 EQUB 70                \ QQ14 = Fuel level, #13

 EQUB 0                 \ COK = Competition flags, #14

 EQUB 0                 \ GCNT = Galaxy number, 0-7, #15

 EQUB POW+(128 AND Q%)  \ LASER = Front laser, #16

 EQUB (POW+128) AND Q%  \ LASER+1 = Rear laser, #17

 EQUB 0                 \ LASER+2 = Left laser, #18

 EQUB 0                 \ LASER+3 = Right laser, #19

 EQUW 0                 \ These bytes are unused (they were originally used for
                        \ up/down lasers, but they were dropped), #20-21

 EQUB 22+(15 AND Q%)    \ CRGO = Cargo capacity, #22

 EQUB 0                 \ QQ20+0  = Amount of Food in cargo hold, #23
 EQUB 0                 \ QQ20+1  = Amount of Textiles in cargo hold, #24
 EQUB 0                 \ QQ20+2  = Amount of Radioactives in cargo hold, #25
 EQUB 0                 \ QQ20+3  = Amount of Slaves in cargo hold, #26
 EQUB 0                 \ QQ20+4  = Amount of Liquor/Wines in cargo hold, #27
 EQUB 0                 \ QQ20+5  = Amount of Luxuries in cargo hold, #28
 EQUB 0                 \ QQ20+6  = Amount of Narcotics in cargo hold, #29
 EQUB 0                 \ QQ20+7  = Amount of Computers in cargo hold, #30
 EQUB 0                 \ QQ20+8  = Amount of Machinery in cargo hold, #31
 EQUB 0                 \ QQ20+9  = Amount of Alloys in cargo hold, #32
 EQUB 0                 \ QQ20+10 = Amount of Firearms in cargo hold, #33
 EQUB 0                 \ QQ20+11 = Amount of Furs in cargo hold, #34
 EQUB 0                 \ QQ20+12 = Amount of Minerals in cargo hold, #35
 EQUB 0                 \ QQ20+13 = Amount of Gold in cargo hold, #36
 EQUB 0                 \ QQ20+14 = Amount of Platinum in cargo hold, #37
 EQUB 0                 \ QQ20+15 = Amount of Gem-Stones in cargo hold, #38
 EQUB 0                 \ QQ20+16 = Amount of Alien Items in cargo hold, #39

 EQUB Q%                \ ECM = E.C.M., #40

 EQUB Q%                \ BST = Fuel scoops ("barrel status"), #41

 EQUB Q% AND 127        \ BOMB = Energy bomb, #42

 EQUB Q% AND 1          \ ENGY = Energy/shield level, #43

 EQUB Q%                \ DKCMP = Docking computer, #44

 EQUB Q%                \ GHYP = Galactic hyperdrive, #45

 EQUB Q%                \ ESCP = Escape pod, #46

 EQUD 0                 \ These four bytes are unused, #47-50

 EQUB 3+(Q% AND 1)      \ NOMSL = Number of missiles, #51

 EQUB 0                 \ FIST = Legal status ("fugitive/innocent status"), #52

 EQUB 16                \ AVL+0  = Market availability of Food, #53
 EQUB 15                \ AVL+1  = Market availability of Textiles, #54
 EQUB 17                \ AVL+2  = Market availability of Radioactives, #55
 EQUB 0                 \ AVL+3  = Market availability of Slaves, #56
 EQUB 3                 \ AVL+4  = Market availability of Liquor/Wines, #57
 EQUB 28                \ AVL+5  = Market availability of Luxuries, #58
 EQUB 14                \ AVL+6  = Market availability of Narcotics, #59
 EQUB 0                 \ AVL+7  = Market availability of Computers, #60
 EQUB 0                 \ AVL+8  = Market availability of Machinery, #61
 EQUB 10                \ AVL+9  = Market availability of Alloys, #62
 EQUB 0                 \ AVL+10 = Market availability of Firearms, #63
 EQUB 17                \ AVL+11 = Market availability of Furs, #64
 EQUB 58                \ AVL+12 = Market availability of Minerals, #65
 EQUB 7                 \ AVL+13 = Market availability of Gold, #66
 EQUB 9                 \ AVL+14 = Market availability of Platinum, #67
 EQUB 8                 \ AVL+15 = Market availability of Gem-Stones, #68
 EQUB 0                 \ AVL+16 = Market availability of Alien Items, #69

 EQUB 0                 \ QQ26 = Random byte that changes for each visit to a
                        \ system, for randomising market prices, #70

 EQUW 0                 \ TALLY = Number of kills, #71-72

 EQUB 128               \ SVC = Save count, #73

 EQUB &AA               \ The CHK2 checksum value for the default commander

 EQUB &03               \ The CHK checksum value for the default commander

 SKIP 16

\ ******************************************************************************
\
\       Name: shpcol
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship colours
\
\ ******************************************************************************

.shpcol

 EQUB 0

 EQUB YELLOW            \ Missile
 EQUB CYAN              \ Coriolis space station
 EQUB CYAN              \ Escape pod
 EQUB CYAN              \ Alloy plate
 EQUB CYAN              \ Cargo canister
 EQUB RED               \ Boulder
 EQUB RED               \ Asteroid
 EQUB RED               \ Splinter
 EQUB CYAN              \ Shuttle
 EQUB CYAN              \ Transporter
 EQUB CYAN              \ Cobra Mk III
 EQUB CYAN              \ Python
 EQUB CYAN              \ Boa
 EQUB CYAN              \ Anaconda
 EQUB RED               \ Rock hermit (asteroid)
 EQUB CYAN              \ Viper
 EQUB CYAN              \ Sidewinder
 EQUB CYAN              \ Mamba
 EQUB CYAN              \ Krait
 EQUB CYAN              \ Adder
 EQUB CYAN              \ Gecko
 EQUB CYAN              \ Cobra Mk I
 EQUB CYAN              \ Worm
 EQUB CYAN              \ Cobra Mk III (pirate)
 EQUB CYAN              \ Asp Mk II
 EQUB CYAN              \ Python (pirate)
 EQUB CYAN              \ Fer-de-lance
 EQUB %11001001         \ Moray (colour 3, 2, 0, 1 = cyan/red/black/yellow)
 EQUB WHITE             \ Thargoid
 EQUB WHITE             \ Thargon
 EQUB CYAN              \ Constrictor
 EQUB CYAN              \ The Elite logo
 EQUB CYAN              \ Cougar

\ ******************************************************************************
\
\       Name: scacol
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship colours on the scanner
\
\ ******************************************************************************

.scacol

 EQUB 0

 EQUB YELLOW2           \ Missile
 EQUB GREEN2            \ Coriolis space station
 EQUB BLUE2             \ Escape pod
 EQUB BLUE2             \ Alloy plate
 EQUB BLUE2             \ Cargo canister
 EQUB RED2              \ Boulder
 EQUB RED2              \ Asteroid
 EQUB RED2              \ Splinter
 EQUB CYAN2             \ Shuttle
 EQUB CYAN2             \ Transporter
 EQUB CYAN2             \ Cobra Mk III
 EQUB MAG2              \ Python
 EQUB MAG2              \ Boa
 EQUB MAG2              \ Anaconda
 EQUB RED2              \ Rock hermit (asteroid)
 EQUB CYAN2             \ Viper
 EQUB CYAN2             \ Sidewinder
 EQUB CYAN2             \ Mamba
 EQUB CYAN2             \ Krait
 EQUB CYAN2             \ Adder
 EQUB CYAN2             \ Gecko
 EQUB CYAN2             \ Cobra Mk I
 EQUB BLUE2             \ Worm
 EQUB CYAN2             \ Cobra Mk III (pirate)
 EQUB CYAN2             \ Asp Mk II
 EQUB MAG2              \ Python (pirate)
 EQUB CYAN2             \ Fer-de-lance
 EQUB CYAN2             \ Moray
 EQUB WHITE2            \ Thargoid
 EQUB CYAN2             \ Thargon
 EQUB CYAN2             \ Constrictor
 EQUB 0                 \ The Elite logo
 EQUB CYAN2             \ Cougar

 EQUD 0

\ ******************************************************************************
\
\       Name: UNIV
\       Type: Variable
\   Category: Universe
\    Summary: Table of pointers to the local universe's ship data blocks
\  Deep dive: The local bubble of universe
\
\ ------------------------------------------------------------------------------
\
\ See the deep dive on "Ship data blocks" for details on ship data blocks, and
\ the deep dive on "The local bubble of universe" for details of how Elite
\ stores the local universe in K%, FRIN and UNIV.
\
\ ******************************************************************************

.UNIV

FOR I%, 0, NOSH
  EQUW K% + I% * NI%    \ Address of block no. I%, of size NI%, in workspace K%
NEXT

\ ******************************************************************************
\
\       Name: FLKB
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Flush the keyboard buffer
\
\ ******************************************************************************

.FLKB

 RTS                    \ Return from the subroutine ????

\ ******************************************************************************
\
\       Name: NLIN3
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Print a title and a horizontal line at row 19 to box it in
\
\ ------------------------------------------------------------------------------
\
\ This routine print a text token at the cursor position and draws a horizontal
\ line at pixel row 19. It is used for the Status Mode screen, the Short-range
\ Chart, the Market Price screen and the Equip Ship screen.
\
\ ******************************************************************************

.NLIN3

 JSR TT27               \ Print the text token in A

                        \ Fall through into NLIN4 to draw a horizontal line at
                        \ pixel row 19

\ ******************************************************************************
\
\       Name: NLIN4
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line at pixel row 19 to box in a title
\
\ ------------------------------------------------------------------------------
\
\ This routine is used on the Inventory screen to draw a horizontal line at
\ pixel row 19 to box in the title.
\
\ ******************************************************************************

.NLIN4

 LDA #19                \ Jump to NLIN2 to draw a horizontal line at pixel row
 BNE NLIN2              \ 19, returning from the subroutine with using a tail
                        \ call (this BNE is effectively a JMP as A will never
                        \ be zero)

\ ******************************************************************************
\
\       Name: NLIN
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line at pixel row 23 to box in a title
\
\ ------------------------------------------------------------------------------
\
\ Draw a horizontal line at pixel row 23 and move the text cursor down one
\ line.
\
\ ******************************************************************************

.NLIN

 LDA #23                \ Set A = 23 so NLIN2 below draws a horizontal line at
                        \ pixel row 23

 INC YC                 \ Move the text cursor down one line

                        \ Fall through into NLIN2 to draw the horizontal line
                        \ at row 23

\ ******************************************************************************
\
\       Name: NLIN2
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a screen-wide horizontal line at the pixel row in A
\
\ ------------------------------------------------------------------------------
\
\ This draws a line from (2, A) to (254, A), which is almost screen-wide and
\ fits in nicely between the white borders without clashing with it.
\
\ Arguments:
\
\   A                   The pixel row on which to draw the horizontal line
\
\ ******************************************************************************

.NLIN2

 STA Y1                 \ Set Y1 = A

 LDA #&0F               \ ???
 STA COL

 LDX #2                 \ Set X1 = 2, so (X1, Y1) = (2, A)
 STX X1

 LDX #254               \ Set X2 = 254, so (X2, Y2) = (254, A)
 STX X2

 JSR HLOIN3             \ ???

 LDA #&FF               \ ???
 STA COL
 RTS

\ ******************************************************************************
\
\       Name: HLOIN2
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Remove a line from the sun line heap and draw it on-screen
\
\ ------------------------------------------------------------------------------
\
\ Specifically, this does the following:
\
\   * Set X1 and X2 to the x-coordinates of the ends of the horizontal line with
\     centre YY(1 0) and length A to the left and right
\
\   * Set the Y-th byte of the LSO block to 0 (i.e. remove this line from the
\     sun line heap)
\
\   * Draw a horizontal line from (X1, Y) to (X2, Y)
\
\ Arguments:
\
\   YY(1 0)             The x-coordinate of the centre point of the line
\
\   A                   The half-width of the line, i.e. the contents of the
\                       Y-th byte of the sun line heap
\
\   Y                   The number of the entry in the sun line heap (which is
\                       also the y-coordinate of the line)
\
\ Returns:
\
\   Y                   Y is preserved
\
\ ******************************************************************************

.HLOIN2

 JSR EDGES              \ Call EDGES to calculate X1 and X2 for the horizontal
                        \ line centred on YY(1 0) and with half-width A

 STY Y1                 \ Set Y1 = Y

 LDA #0                 \ Set the Y-th byte of the LSO block to 0
 STA LSO,Y

 JMP HLOIN              \ Call HLOIN to draw a horizontal line from (X1, Y) to
                        \ (X2, Y), returning from the subroutine using a tail
                        \ call

\ ******************************************************************************
\
\       Name: BLINE
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle segment and add it to the ball line heap
\  Deep dive: The ball line heap
\             Drawing circles
\
\ ------------------------------------------------------------------------------
\
\ Draw a single segment of a circle, adding the point to the ball line heap.
\
\ Arguments:
\
\   CNT                 The number of this segment
\
\   STP                 The step size for the circle
\
\   K6(1 0)             The x-coordinate of the new point on the circle, as
\                       a screen coordinate
\
\   (T X)               The y-coordinate of the new point on the circle, as
\                       an offset from the centre of the circle
\
\   FLAG                Set to &FF for the first call, so it sets up the first
\                       point in the heap but waits until the second call before
\                       drawing anything (as we need two points, i.e. two calls,
\                       before we can draw a line)
\
\   K                   The circle's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the circle
\
\   K4(1 0)             Pixel y-coordinate of the centre of the circle
\
\   SWAP                If non-zero, we swap (X1, Y1) and (X2, Y2)
\
\ Returns:
\
\   CNT                 CNT is updated to CNT + STP
\
\   A                   The new value of CNT
\
\   FLAG                Set to 0
\
\ ******************************************************************************

.BLINE

 TXA                    \ Set K6(3 2) = (T X) + K4(1 0)
 ADC K4                 \             = y-coord of centre + y-coord of new point
 STA K6+2               \
 LDA K4+1               \ so K6(3 2) now contains the y-coordinate of the new
 ADC T                  \ point on the circle but as a screen coordinate, to go
 STA K6+3               \ along with the screen y-coordinate in K6(1 0)

 LDA FLAG               \ If FLAG = 0, jump down to BL1
 BEQ BL1

 INC FLAG               \ Flag is &FF so this is the first call to BLINE, so
                        \ increment FLAG to set it to 0, as then the next time
                        \ we call BLINE it can draw the first line, from this
                        \ point to the next

.BL5

                        \ The following inserts a &FF marker into the LSY2 line
                        \ heap to indicate that the next call to BLINE should
                        \ store both the (X1, Y1) and (X2, Y2) points. We do
                        \ this on the very first call to BLINE (when FLAG is
                        \ &FF), and on subsequent calls if the segment does not
                        \ fit on-screen, in which case we don't draw or store
                        \ that segment, and we start a new segment with the next
                        \ call to BLINE that does fit on-screen

 LDY LSP                \ If byte LSP-1 of LSY2 = &FF, jump to BL7 to tidy up
 LDA #&FF               \ and return from the subroutine, as the point that has
 CMP LSY2-1,Y           \ been passed to BLINE is the start of a segment, so all
 BEQ BL7                \ we need to do is save the coordinate in K5, without
                        \ moving the pointer in LSP

 STA LSY2,Y             \ Otherwise we just tried to plot a segment but it
                        \ didn't fit on-screen, so put the &FF marker into the
                        \ heap for this point, so the next call to BLINE starts
                        \ a new segment

 INC LSP                \ Increment LSP to point to the next point in the heap

 BNE BL7                \ Jump to BL7 to tidy up and return from the subroutine
                        \ (this BNE is effectively a JMP, as LSP will never be
                        \ zero)

.BL1

 LDA K5                 \ Set XX15 = K5 = x_lo of previous point
 STA XX15

 LDA K5+1               \ Set XX15+1 = K5+1 = x_hi of previous point
 STA XX15+1

 LDA K5+2               \ Set XX15+2 = K5+2 = y_lo of previous point
 STA XX15+2

 LDA K5+3               \ Set XX15+3 = K5+3 = y_hi of previous point
 STA XX15+3

 LDA K6                 \ Set XX15+4 = x_lo of new point
 STA XX15+4

 LDA K6+1               \ Set XX15+5 = x_hi of new point
 STA XX15+5

 LDA K6+2               \ Set XX12 = y_lo of new point
 STA XX12

 LDA K6+3               \ Set XX12+1 = y_hi of new point
 STA XX12+1

 JSR LL145              \ Call LL145 to see if the new line segment needs to be
                        \ clipped to fit on-screen, returning the clipped line's
                        \ end-points in (X1, Y1) and (X2, Y2)

 BCS BL5                \ If the C flag is set then the line is not visible on
                        \ screen anyway, so jump to BL5, to avoid drawing and
                        \ storing this line

 LDA SWAP               \ If SWAP = 0, then we didn't have to swap the line
 BEQ BL9                \ coordinates around during the clipping process, so
                        \ jump to BL9 to skip the following swap

 LDA X1                 \ Otherwise the coordinates were swapped by the call to
 LDY X2                 \ LL145 above, so we swap (X1, Y1) and (X2, Y2) back
 STA X2                 \ again
 STY X1
 LDA Y1
 LDY Y2
 STA Y2
 STY Y1

.BL9

 LDY LSP                \ Set Y = LSP

 LDA LSY2-1,Y           \ If byte LSP-1 of LSY2 is not &FF, jump down to BL8
 CMP #&FF               \ to skip the following (X1, Y1) code
 BNE BL8

                        \ Byte LSP-1 of LSY2 is &FF, which indicates that we
                        \ need to store (X1, Y1) in the heap

 LDA X1                 \ Store X1 in the LSP-th byte of LSX2
 STA LSX2,Y

 LDA Y1                 \ Store Y1 in the LSP-th byte of LSY2
 STA LSY2,Y

 INY                    \ Increment Y to point to the next byte in LSX2/LSY2

.BL8

 LDA X2                 \ Store X2 in the LSP-th byte of LSX2
 STA LSX2,Y

 LDA Y2                 \ Store Y2 in the LSP-th byte of LSX2
 STA LSY2,Y

 INY                    \ Increment Y to point to the next byte in LSX2/LSY2

 STY LSP                \ Update LSP to point to the same as Y

 JSR LL30               \ Draw a line from (X1, Y1) to (X2, Y2)

 LDA XX13               \ If XX13 is non-zero, jump up to BL5 to add a &FF
 BNE BL5                \ marker to the end of the line heap. XX13 is non-zero
                        \ after the call to the clipping routine LL145 above if
                        \ the end of the line was clipped, meaning the next line
                        \ sent to BLINE can't join onto the end but has to start
                        \ a new segment, and that's what inserting the &FF
                        \ marker does

.BL7

 LDA K6                 \ Copy the data for this step point from K6(3 2 1 0)
 STA K5                 \ into K5(3 2 1 0), for use in the next call to BLINE:
 LDA K6+1               \
 STA K5+1               \   * K5(1 0) = screen x-coordinate of this point
 LDA K6+2               \
 STA K5+2               \   * K5(3 2) = screen y-coordinate of this point
 LDA K6+3               \
 STA K5+3               \ They now become the "previous point" in the next call

 LDA CNT                \ Set CNT = CNT + STP
 CLC
 ADC STP
 STA CNT

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FLIP
\       Type: Subroutine
\   Category: Stardust
\    Summary: Reflect the stardust particles in the screen diagonal
\
\ ------------------------------------------------------------------------------
\
\ Swap the x- and y-coordinates of all the stardust particles and draw the new
\ set of particles. Called by LOOK1 when we switch views.
\
\ This is a quick way of making the stardust field in the new view feel
\ different without having to generate a whole new field. If you look carefully
\ at the stardust field when you switch views, you can just about see that the
\ new field is a reflection of the previous field in the screen diagonal, i.e.
\ in the line from bottom left to top right. This is the line where x = y when
\ the origin is in the middle of the screen, and positive x and y are right and
\ up, which is the coordinate system we use for stardust).
\
\ ******************************************************************************

.FLIP

\LDA MJ                 \ These instructions are commented out in the original
\BNE FLIP-1             \ source. They would have the effect of not swapping the
                        \ stardust if we had mis-jumped into witchspace

 LDA #&FA               \ ???
 STA COL

 LDY NOSTM              \ Set Y to the current number of stardust particles, so
                        \ we can use it as a counter through all the stardust

.FLL1

 LDX SY,Y               \ Copy the Y-th particle's y-coordinate from SY+Y into X

 LDA SX,Y               \ Copy the Y-th particle's x-coordinate from SX+Y into
 STA Y1                 \ both Y1 and the particle's y-coordinate
 STA SY,Y

 TXA                    \ Copy the Y-th particle's original y-coordinate into
 STA X1                 \ both X1 and the particle's x-coordinate, so the x- and
 STA SX,Y               \ y-coordinates are now swapped and (X1, Y1) contains
                        \ the particle's new coordinates

 LDA SZ,Y               \ Fetch the Y-th particle's distance from SZ+Y into ZZ
 STA ZZ

 JSR PIXEL2             \ Draw a stardust particle at (X1,Y1) with distance ZZ

 DEY                    \ Decrement the counter to point to the next particle of
                        \ stardust

 BNE FLL1               \ Loop back to FLL1 until we have moved all the stardust
                        \ particles

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: STARS
\       Type: Subroutine
\   Category: Stardust
\    Summary: The main routine for processing the stardust
\
\ ------------------------------------------------------------------------------
\
\ Called at the very end of the main flight loop.
\
\ ******************************************************************************

.STARS

 LDA #&FA               \ ???
 STA COL

 LDX VIEW               \ Load the current view into X:
                        \
                        \   0 = front
                        \   1 = rear
                        \   2 = left
                        \   3 = right

 BEQ STARS1             \ If this 0, jump to STARS1 to process the stardust for
                        \ the front view

 DEX                    \ If this is view 2 or 3, jump to STARS2 (via ST11) to
 BNE ST11               \ process the stardust for the left or right views

 JMP STARS6             \ Otherwise this is the rear view, so jump to STARS6 to
                        \ process the stardust for the rear view

.ST11

 JMP STARS2             \ Jump to STARS2 for the left or right views, as it's
                        \ too far for the branch instruction above

\ ******************************************************************************
\
\       Name: STARS1
\       Type: Subroutine
\   Category: Stardust
\    Summary: Process the stardust for the front view
\  Deep dive: Stardust in the front view
\
\ ------------------------------------------------------------------------------
\
\ This moves the stardust towards us according to our speed (so the dust rushes
\ past us), and applies our current pitch and roll to each particle of dust, so
\ the stardust moves correctly when we steer our ship.
\
\ When a stardust particle rushes past us and falls off the side of the screen,
\ its memory is recycled as a new particle that's positioned randomly on-screen.
\
\ ******************************************************************************

.STARS1

 LDY NOSTM              \ Set Y to the current number of stardust particles, so
                        \ we can use it as a counter through all the stardust

                        \ In the following, we're going to refer to the 16-bit
                        \ space coordinates of the current particle of stardust
                        \ (i.e. the Y-th particle) like this:
                        \
                        \   x = (x_hi x_lo)
                        \   y = (y_hi y_lo)
                        \   z = (z_hi z_lo)
                        \
                        \ These values are stored in (SX+Y SXL+Y), (SY+Y SYL+Y)
                        \ and (SZ+Y SZL+Y) respectively

.STL1

 JSR DV42               \ Call DV42 to set the following:
                        \
                        \   (P R) = 256 * DELTA / z_hi
                        \         = 256 * speed / z_hi
                        \
                        \ The maximum value returned is P = 2 and R = 128 (see
                        \ DV42 for an explanation)

 LDA R                  \ Set A = R, so now:
                        \
                        \   (P A) = 256 * speed / z_hi

 LSR P                  \ Rotate (P A) right by 2 places, which sets P = 0 (as P
 ROR A                  \ has a maximum value of 2) and leaves:
 LSR P                  \
 ROR A                  \   A = 64 * speed / z_hi

 ORA #1                 \ Make sure A is at least 1, and store it in Q, so we
 STA Q                  \ now have result 1 above:
                        \
                        \   Q = 64 * speed / z_hi

 LDA SZL,Y              \ We now calculate the following:
 SBC DELT4              \
 STA SZL,Y              \  (z_hi z_lo) = (z_hi z_lo) - DELT4(1 0)
                        \
                        \ starting with the low bytes

 LDA SZ,Y               \ And then we do the high bytes
 STA ZZ                 \
 SBC DELT4+1            \ We also set ZZ to the original value of z_hi, which we
 STA SZ,Y               \ use below to remove the existing particle
                        \
                        \ So now we have result 2 above:
                        \
                        \   z = z - DELT4(1 0)
                        \     = z - speed * 64

 JSR MLU1               \ Call MLU1 to set:
                        \
                        \   Y1 = y_hi
                        \
                        \   (A P) = |y_hi| * Q
                        \
                        \ So Y1 contains the original value of y_hi, which we
                        \ use below to remove the existing particle

                        \ We now calculate:
                        \
                        \   (S R) = YY(1 0) = (A P) + y

 STA YY+1               \ First we do the low bytes with:
 LDA P                  \
 ADC SYL,Y              \   YY+1 = A
 STA YY                 \   R = YY = P + y_lo
 STA R                  \
                        \ so we get this:
                        \
                        \   (? R) = YY(1 0) = (A P) + y_lo

 LDA Y1                 \ And then we do the high bytes with:
 ADC YY+1               \
 STA YY+1               \   S = YY+1 = y_hi + YY+1
 STA S                  \
                        \ so we get our result:
                        \
                        \   (S R) = YY(1 0) = (A P) + (y_hi y_lo)
                        \                   = |y_hi| * Q + y
                        \
                        \ which is result 3 above, and (S R) is set to the new
                        \ value of y

 LDA SX,Y               \ Set X1 = A = x_hi
 STA X1                 \
                        \ So X1 contains the original value of x_hi, which we
                        \ use below to remove the existing particle

 JSR MLU2               \ Set (A P) = |x_hi| * Q

                        \ We now calculate:
                        \
                        \   XX(1 0) = (A P) + x

 STA XX+1               \ First we do the low bytes:
 LDA P                  \
 ADC SXL,Y              \   XX(1 0) = (A P) + x_lo
 STA XX

 LDA X1                 \ And then we do the high bytes:
 ADC XX+1               \
 STA XX+1               \   XX(1 0) = XX(1 0) + (x_hi 0)
                        \
                        \ so we get our result:
                        \
                        \   XX(1 0) = (A P) + x
                        \           = |x_hi| * Q + x
                        \
                        \ which is result 4 above, and we also have:
                        \
                        \   A = XX+1 = (|x_hi| * Q + x) / 256
                        \
                        \ i.e. A is the new value of x, divided by 256

 EOR ALP2+1             \ EOR with the flipped sign of the roll angle alpha, so
                        \ A has the opposite sign to the flipped roll angle
                        \ alpha, i.e. it gets the same sign as alpha

 JSR MLS1               \ Call MLS1 to calculate:
                        \
                        \   (A P) = A * ALP1
                        \         = (x / 256) * alpha

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = (x / 256) * alpha + y
                        \         = y + alpha * x / 256

 STA YY+1               \ Set YY(1 0) = (A X) to give:
 STX YY                 \
                        \   YY(1 0) = y + alpha * x / 256
                        \
                        \ which is result 5 above, and we also have:
                        \
                        \   A = YY+1 = y + alpha * x / 256
                        \
                        \ i.e. A is the new value of y, divided by 256

 EOR ALP2               \ EOR A with the correct sign of the roll angle alpha,
                        \ so A has the opposite sign to the roll angle alpha

 JSR MLS2               \ Call MLS2 to calculate:
                        \
                        \   (S R) = XX(1 0)
                        \         = x
                        \
                        \   (A P) = A * ALP1
                        \         = -y / 256 * alpha

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = -y / 256 * alpha + x

 STA XX+1               \ Set XX(1 0) = (A X), which gives us result 6 above:
 STX XX                 \
                        \   x = x - alpha * y / 256

 LDX BET1               \ Fetch the pitch magnitude into X

 LDA YY+1               \ Set A to y_hi and set it to the flipped sign of beta
 EOR BET2+1

 JSR MULTS-2            \ Call MULTS-2 to calculate:
                        \
                        \   (A P) = X * A
                        \         = -beta * y_hi

 STA Q                  \ Store the high byte of the result in Q, so:
                        \
                        \   Q = -beta * y_hi / 256

 JSR MUT2               \ Call MUT2 to calculate:
                        \
                        \   (S R) = XX(1 0) = x
                        \
                        \   (A P) = Q * A
                        \         = (-beta * y_hi / 256) * (-beta * y_hi / 256)
                        \         = (beta * y / 256) ^ 2

 ASL P                  \ Double (A P), store the top byte in A and set the C
 ROL A                  \ flag to bit 7 of the original A, so this does:
 STA T                  \
                        \   (T P) = (A P) << 1
                        \         = 2 * (beta * y / 256) ^ 2

 LDA #0                 \ Set bit 7 in A to the sign bit from the A in the
 ROR A                  \ calculation above and apply it to T, so we now have:
 ORA T                  \
                        \   (A P) = (A P) * 2
                        \         = 2 * (beta * y / 256) ^ 2
                        \
                        \ with the doubling retaining the sign of (A P)

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = 2 * (beta * y / 256) ^ 2 + x

 STA XX+1               \ Store the high byte A in XX+1

 TXA
 STA SXL,Y              \ Store the low byte X in x_lo

                        \ So (XX+1 x_lo) now contains:
                        \
                        \   x = x + 2 * (beta * y / 256) ^ 2
                        \
                        \ which is result 7 above

 LDA YY                 \ Set (S R) = YY(1 0) = y
 STA R
 LDA YY+1
\JSR MAD                \ These instructions are commented out in the original
\STA S                  \ source
\STX R
 STA S

 LDA #0                 \ Set P = 0
 STA P

 LDA BETA               \ Set A = -beta, so:
 EOR #%10000000         \
                        \   (A P) = (-beta 0)
                        \         = -beta * 256

 JSR PIX1               \ Call PIX1 to calculate the following:
                        \
                        \   (YY+1 y_lo) = (A P) + (S R)
                        \               = -beta * 256 + y
                        \
                        \ i.e. y = y - beta * 256, which is result 8 above
                        \
                        \ PIX1 also draws a particle at (X1, Y1) with distance
                        \ ZZ, which will remove the old stardust particle, as we
                        \ set X1, Y1 and ZZ to the original values for this
                        \ particle during the calculations above

                        \ We now have our newly moved stardust particle at
                        \ x-coordinate (XX+1 x_lo) and y-coordinate (YY+1 y_lo)
                        \ and distance z_hi, so we draw it if it's still on
                        \ screen, otherwise we recycle it as a new bit of
                        \ stardust and draw that

 LDA XX+1               \ Set X1 and x_hi to the high byte of XX in XX+1, so
 STA X1                 \ the new x-coordinate is in (x_hi x_lo) and the high
 STA SX,Y               \ byte is in X1

 AND #%01111111         \ If |x_hi| >= 120 then jump to KILL1 to recycle this
 CMP #120               \ particle, as it's gone off the side of the screen,
 BCS KILL1              \ and re-join at STC1 with the new particle

 LDA YY+1               \ Set Y1 and y_hi to the high byte of YY in YY+1, so
 STA SY,Y               \ the new x-coordinate is in (y_hi y_lo) and the high
 STA Y1                 \ byte is in Y1

 AND #%01111111         \ If |y_hi| >= 120 then jump to KILL1 to recycle this
 CMP #120               \ particle, as it's gone off the top or bottom of the
 BCS KILL1              \ screen, and re-join at STC1 with the new particle

 LDA SZ,Y               \ If z_hi < 16 then jump to KILL1 to recycle this
 CMP #16                \ particle, as it's so close that it's effectively gone
 BCC KILL1              \ past us, and re-join at STC1 with the new particle

 STA ZZ                 \ Set ZZ to the z-coordinate in z_hi

.STC1

 JSR PIXEL2             \ Draw a stardust particle at (X1,Y1) with distance ZZ,
                        \ i.e. draw the newly moved particle at (x_hi, y_hi)
                        \ with distance z_hi

 DEY                    \ Decrement the loop counter to point to the next
                        \ stardust particle

 BEQ P%+5               \ If we have just done the last particle, skip the next
                        \ instruction to return from the subroutine

 JMP STL1               \ We have more stardust to process, so jump back up to
                        \ STL1 for the next particle

 RTS                    \ Return from the subroutine

.KILL1

                        \ Our particle of stardust just flew past us, so let's
                        \ recycle that particle, starting it at a random
                        \ position that isn't too close to the centre point

 JSR DORND              \ Set A and X to random numbers

 ORA #4                 \ Make sure A is at least 4 and store it in Y1 and y_hi,
 STA Y1                 \ so the new particle starts at least 4 pixels above or
 STA SY,Y               \ below the centre of the screen

 JSR DORND              \ Set A and X to random numbers

 ORA #8                 \ Make sure A is at least 8 and store it in X1 and x_hi,
 STA X1                 \ so the new particle starts at least 8 pixels either
 STA SX,Y               \ side of the centre of the screen

 JSR DORND              \ Set A and X to random numbers

 ORA #144               \ Make sure A is at least 144 and store it in ZZ and
 STA SZ,Y               \ z_hi so the new particle starts in the far distance
 STA ZZ

 LDA Y1                 \ Set A to the new value of y_hi. This has no effect as
                        \ STC1 starts with a jump to PIXEL2, which starts with a
                        \ LDA instruction

 JMP STC1               \ Jump up to STC1 to draw this new particle

\ ******************************************************************************
\
\       Name: STARS6
\       Type: Subroutine
\   Category: Stardust
\    Summary: Process the stardust for the rear view
\
\ ------------------------------------------------------------------------------
\
\ This routine is very similar to STARS1, which processes stardust for the front
\ view. The main difference is that the direction of travel is reversed, so the
\ signs in the calculations are different, as well as the order of the first
\ batch of calculations.
\
\ When a stardust particle falls away into the far distance, it is removed from
\ the screen and its memory is recycled as a new particle, positioned randomly
\ along one of the four edges of the screen.
\
\ See STARS1 for an explanation of the maths used in this routine. The
\ calculations are as follows:
\
\   1. q = 64 * speed / z_hi
\   2. x = x - |x_hi| * q
\   3. y = y - |y_hi| * q
\   4. z = z + speed * 64
\
\   5. y = y - alpha * x / 256
\   6. x = x + alpha * y / 256
\
\   7. x = x - 2 * (beta * y / 256) ^ 2
\   8. y = y + beta * 256
\
\ ******************************************************************************

.STARS6

 LDY NOSTM              \ Set Y to the current number of stardust particles, so
                        \ we can use it as a counter through all the stardust

.STL6

 JSR DV42               \ Call DV42 to set the following:
                        \
                        \   (P R) = 256 * DELTA / z_hi
                        \         = 256 * speed / z_hi
                        \
                        \ The maximum value returned is P = 2 and R = 128 (see
                        \ DV42 for an explanation)

 LDA R                  \ Set A = R, so now:
                        \
                        \   (P A) = 256 * speed / z_hi

 LSR P                  \ Rotate (P A) right by 2 places, which sets P = 0 (as P
 ROR A                  \ has a maximum value of 2) and leaves:
 LSR P                  \
 ROR A                  \   A = 64 * speed / z_hi

 ORA #1                 \ Make sure A is at least 1, and store it in Q, so we
 STA Q                  \ now have result 1 above:
                        \
                        \   Q = 64 * speed / z_hi

 LDA SX,Y               \ Set X1 = A = x_hi
 STA X1                 \
                        \ So X1 contains the original value of x_hi, which we
                        \ use below to remove the existing particle

 JSR MLU2               \ Set (A P) = |x_hi| * Q

                        \ We now calculate:
                        \
                        \   XX(1 0) = x - (A P)

 STA XX+1               \ First we do the low bytes:
 LDA SXL,Y              \
 SBC P                  \   XX(1 0) = x_lo - (A P)
 STA XX

 LDA X1                 \ And then we do the high bytes:
 SBC XX+1               \
 STA XX+1               \   XX(1 0) = (x_hi 0) - XX(1 0)
                        \
                        \ so we get our result:
                        \
                        \   XX(1 0) = x - (A P)
                        \           = x - |x_hi| * Q
                        \
                        \ which is result 2 above, and we also have:

 JSR MLU1               \ Call MLU1 to set:
                        \
                        \   Y1 = y_hi
                        \
                        \   (A P) = |y_hi| * Q
                        \
                        \ So Y1 contains the original value of y_hi, which we
                        \ use below to remove the existing particle

                        \ We now calculate:
                        \
                        \   (S R) = YY(1 0) = y - (A P)

 STA YY+1               \ First we do the low bytes with:
 LDA SYL,Y              \
 SBC P                  \   YY+1 = A
 STA YY                 \   R = YY = y_lo - P
 STA R                  \
                        \ so we get this:
                        \
                        \   (? R) = YY(1 0) = y_lo - (A P)

 LDA Y1                 \ And then we do the high bytes with:
 SBC YY+1               \
 STA YY+1               \   S = YY+1 = y_hi - YY+1
 STA S                  \
                        \ so we get our result:
                        \
                        \   (S R) = YY(1 0) = (y_hi y_lo) - (A P)
                        \                   = y - |y_hi| * Q
                        \
                        \ which is result 3 above, and (S R) is set to the new
                        \ value of y

 LDA SZL,Y              \ We now calculate the following:
 ADC DELT4              \
 STA SZL,Y              \  (z_hi z_lo) = (z_hi z_lo) + DELT4(1 0)
                        \
                        \ starting with the low bytes

 LDA SZ,Y               \ And then we do the high bytes
 STA ZZ                 \
 ADC DELT4+1            \ We also set ZZ to the original value of z_hi, which we
 STA SZ,Y               \ use below to remove the existing particle
                        \
                        \ So now we have result 4 above:
                        \
                        \   z = z + DELT4(1 0)
                        \     = z + speed * 64

 LDA XX+1               \ EOR x with the correct sign of the roll angle alpha,
 EOR ALP2               \ so A has the opposite sign to the roll angle alpha

 JSR MLS1               \ Call MLS1 to calculate:
                        \
                        \   (A P) = A * ALP1
                        \         = (-x / 256) * alpha

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = (-x / 256) * alpha + y
                        \         = y - alpha * x / 256

 STA YY+1               \ Set YY(1 0) = (A X) to give:
 STX YY                 \
                        \   YY(1 0) = y - alpha * x / 256
                        \
                        \ which is result 5 above, and we also have:
                        \
                        \   A = YY+1 = y - alpha * x / 256
                        \
                        \ i.e. A is the new value of y, divided by 256

 EOR ALP2+1             \ EOR with the flipped sign of the roll angle alpha, so
                        \ A has the opposite sign to the flipped roll angle
                        \ alpha, i.e. it gets the same sign as alpha

 JSR MLS2               \ Call MLS2 to calculate:
                        \
                        \   (S R) = XX(1 0)
                        \         = x
                        \
                        \   (A P) = A * ALP1
                        \         = y / 256 * alpha

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = y / 256 * alpha + x

 STA XX+1               \ Set XX(1 0) = (A X), which gives us result 6 above:
 STX XX                 \
                        \   x = x + alpha * y / 256

 LDA YY+1               \ Set A to y_hi and set it to the flipped sign of beta
 EOR BET2+1

 LDX BET1               \ Fetch the pitch magnitude into X

 JSR MULTS-2            \ Call MULTS-2 to calculate:
                        \
                        \   (A P) = X * A
                        \         = beta * y_hi

 STA Q                  \ Store the high byte of the result in Q, so:
                        \
                        \   Q = beta * y_hi / 256

 LDA XX+1               \ Set S = x_hi
 STA S

 EOR #%10000000         \ Flip the sign of A, so A now contains -x

 JSR MUT1               \ Call MUT1 to calculate:
                        \
                        \   R = XX = x_lo
                        \
                        \   (A P) = Q * A
                        \         = (beta * y_hi / 256) * (-beta * y_hi / 256)
                        \         = (-beta * y / 256) ^ 2

 ASL P                  \ Double (A P), store the top byte in A and set the C
 ROL A                  \ flag to bit 7 of the original A, so this does:
 STA T                  \
                        \   (T P) = (A P) << 1
                        \         = 2 * (-beta * y / 256) ^ 2

 LDA #0                 \ Set bit 7 in A to the sign bit from the A in the
 ROR A                  \ calculation above and apply it to T, so we now have:
 ORA T                  \
                        \   (A P) = -2 * (beta * y / 256) ^ 2
                        \
                        \ with the doubling retaining the sign of (A P)

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = -2 * (beta * y / 256) ^ 2 + x

 STA XX+1               \ Store the high byte A in XX+1

 TXA
 STA SXL,Y              \ Store the low byte X in x_lo

                        \ So (XX+1 x_lo) now contains:
                        \
                        \   x = x - 2 * (beta * y / 256) ^ 2
                        \
                        \ which is result 7 above

 LDA YY                 \ Set (S R) = YY(1 0) = y
 STA R
 LDA YY+1
 STA S

\EOR #128               \ These instructions are commented out in the original
\JSR MAD                \ source
\STA S
\STX R

 LDA #0                 \ Set P = 0
 STA P

 LDA BETA               \ Set A = beta, so (A P) = (beta 0) = beta * 256

 JSR PIX1               \ Call PIX1 to calculate the following:
                        \
                        \   (YY+1 y_lo) = (A P) + (S R)
                        \               = beta * 256 + y
                        \
                        \ i.e. y = y + beta * 256, which is result 8 above
                        \
                        \ PIX1 also draws a particle at (X1, Y1) with distance
                        \ ZZ, which will remove the old stardust particle, as we
                        \ set X1, Y1 and ZZ to the original values for this
                        \ particle during the calculations above

                        \ We now have our newly moved stardust particle at
                        \ x-coordinate (XX+1 x_lo) and y-coordinate (YY+1 y_lo)
                        \ and distance z_hi, so we draw it if it's still on
                        \ screen, otherwise we recycle it as a new bit of
                        \ stardust and draw that

 LDA XX+1               \ Set X1 and x_hi to the high byte of XX in XX+1, so
 STA X1                 \ the new x-coordinate is in (x_hi x_lo) and the high
 STA SX,Y               \ byte is in X1

 LDA YY+1               \ Set Y1 and y_hi to the high byte of YY in YY+1, so
 STA SY,Y               \ the new x-coordinate is in (y_hi y_lo) and the high
 STA Y1                 \ byte is in Y1

 AND #%01111111         \ If |y_hi| >= 110 then jump to KILL6 to recycle this
 CMP #110               \ particle, as it's gone off the top or bottom of the
 BCS KILL6              \ screen, and re-join at STC6 with the new particle

 LDA SZ,Y               \ If z_hi >= 160 then jump to KILL6 to recycle this
 CMP #160               \ particle, as it's so far away that it's too far to
 BCS KILL6              \ see, and re-join at STC1 with the new particle

 STA ZZ                 \ Set ZZ to the z-coordinate in z_hi

.STC6

 JSR PIXEL2             \ Draw a stardust particle at (X1,Y1) with distance ZZ,
                        \ i.e. draw the newly moved particle at (x_hi, y_hi)
                        \ with distance z_hi

 DEY                    \ Decrement the loop counter to point to the next
                        \ stardust particle

 BEQ ST3                \ If we have just done the last particle, skip the next
                        \ instruction to return from the subroutine

 JMP STL6               \ We have more stardust to process, so jump back up to
                        \ STL6 for the next particle

.ST3

 RTS                    \ Return from the subroutine

.KILL6

 JSR DORND              \ Set A and X to random numbers

 AND #%01111111         \ Clear the sign bit of A to get |A|

 ADC #10                \ Make sure A is at least 10 and store it in z_hi and
 STA SZ,Y               \ ZZ, so the new particle starts close to us
 STA ZZ

 LSR A                  \ Divide A by 2 and randomly set the C flag

 BCS ST4                \ Jump to ST4 half the time

 LSR A                  \ Randomly set the C flag again

 LDA #252               \ Set A to either +126 or -126 (252 >> 1) depending on
 ROR A                  \ the C flag, as this is a sign-magnitude number with
                        \ the C flag rotated into its sign bit

 STA X1                 \ Set x_hi and X1 to A, so this particle starts on
 STA SX,Y               \ either the left or right edge of the screen

 JSR DORND              \ Set A and X to random numbers

 STA Y1                 \ Set y_hi and Y1 to random numbers, so the particle
 STA SY,Y               \ starts anywhere along either the left or right edge

 JMP STC6               \ Jump up to STC6 to draw this new particle

.ST4

 JSR DORND              \ Set A and X to random numbers

 STA X1                 \ Set x_hi and X1 to random numbers, so the particle
 STA SX,Y               \ starts anywhere along the x-axis

 LSR A                  \ Randomly set the C flag

 LDA #230               \ Set A to either +115 or -115 (230 >> 1) depending on
 ROR A                  \ the C flag, as this is a sign-magnitude number with
                        \ the C flag rotated into its sign bit

 STA Y1                 \ Set y_hi and Y1 to A, so the particle starts anywhere
 STA SY,Y               \ along either the top or bottom edge of the screen

 BNE STC6               \ Jump up to STC6 to draw this new particle (this BNE is
                        \ effectively a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: MAS1
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Add an orientation vector coordinate to an INWK coordinate
\
\ ------------------------------------------------------------------------------
\
\ Add a doubled nosev vector coordinate, e.g. (nosev_y_hi nosev_y_lo) * 2, to
\ an INWK coordinate, e.g. (x_sign x_hi x_lo), storing the result in the INWK
\ coordinate. The axes used in each side of the addition are specified by the
\ arguments X and Y.
\
\ In the comments below, we document the routine as if we are doing the
\ following, i.e. if X = 0 and Y = 11:
\
\   (x_sign x_hi x_lo) = (x_sign x_hi x_lo) + (nosev_y_hi nosev_y_lo) * 2
\
\ as that way the variable names in the comments contain "x" and "y" to match
\ the registers that specify the vector axis to use.
\
\ Arguments:
\
\   X                   The coordinate to add, as follows:
\
\                         * If X = 0, add (x_sign x_hi x_lo)
\                         * If X = 3, add (y_sign y_hi y_lo)
\                         * If X = 6, add (z_sign z_hi z_lo)
\
\   Y                   The vector to add, as follows:
\
\                         * If Y = 9,  add (nosev_x_hi nosev_x_lo)
\                         * If Y = 11, add (nosev_y_hi nosev_y_lo)
\                         * If Y = 13, add (nosev_z_hi nosev_z_lo)
\
\ Returns:
\
\   A                   The high byte of the result with the sign cleared (e.g.
\                       |x_hi| if X = 0, etc.)
\
\ Other entry points:
\
\   MA9                 Contains an RTS
\
\ ******************************************************************************

.MAS1

 LDA INWK,Y             \ Set K(2 1) = (nosev_y_hi nosev_y_lo) * 2
 ASL A
 STA K+1
 LDA INWK+1,Y
 ROL A
 STA K+2

 LDA #0                 \ Set K+3 bit 7 to the C flag, so the sign bit of the
 ROR A                  \ above result goes into K+3
 STA K+3

 JSR MVT3               \ Add (x_sign x_hi x_lo) to K(3 2 1)

 STA INWK+2,X           \ Store the sign of the result in x_sign

 LDY K+1                \ Store K(2 1) in (x_hi x_lo)
 STY INWK,X
 LDY K+2
 STY INWK+1,X

 AND #%01111111         \ Set A to the sign byte with the sign cleared

.MA9

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MAS2
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate a cap on the maximum distance to the planet or sun
\
\ ------------------------------------------------------------------------------
\
\ Given a value in Y that points to the start of a ship data block as an offset
\ from K%, calculate the following:
\
\   A = A OR x_sign OR y_sign OR z_sign
\
\ and clear the sign bit of the result. The K% workspace contains the ship data
\ blocks, so the offset in Y must be 0 or a multiple of NI% (as each block in
\ K% contains NI% bytes).
\
\ The result effectively contains a maximum cap of the three values (though it
\ might not be one of the three input values - it's just guaranteed to be
\ larger than all of them).
\
\ If Y = 0 and A = 0, then this calculates the maximum cap of the highest byte
\ containing the distance to the planet, as K%+2 = x_sign, K%+5 = y_sign and
\ K%+8 = z_sign (the first slot in the K% workspace represents the planet).
\
\ Arguments:
\
\   Y                   The offset from K% for the start of the ship data block
\                       to use
\
\ Returns:
\
\   A                   A OR K%+2+Y OR K%+5+Y OR K%+8+Y, with bit 7 cleared
\
\ Other entry points:
\
\   m                   Do not include A in the calculation
\
\ ******************************************************************************

.m

 LDA #0                 \ Set A = 0 and fall through into MAS2 to calculate the
                        \ OR of the three bytes at K%+2+Y, K%+5+Y and K%+8+Y

.MAS2

 ORA K%+2,Y             \ Set A = A OR x_sign OR y_sign OR z_sign
 ORA K%+5,Y
 ORA K%+8,Y

 AND #%01111111         \ Clear bit 7 in A

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MAS3
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate A = x_hi^2 + y_hi^2 + z_hi^2 in the K% block
\
\ ------------------------------------------------------------------------------
\
\ Given a value in Y that points to the start of a ship data block as an offset
\ from K%, calculate the following:
\
\   A = x_hi^2 + y_hi^2 + z_hi^2
\
\ returning A = &FF if the calculation overflows a one-byte result. The K%
\ workspace contains the ship data blocks, so the offset in Y must be 0 or a
\ multiple of NI% (as each block in K% contains NI% bytes).
\
\ Arguments:
\
\   Y                   The offset from K% for the start of the ship data block
\                       to use
\
\ Returns
\
\   A                   A = x_hi^2 + y_hi^2 + z_hi^2
\
\                       A = &FF if the calculation overflows a one-byte result
\
\ ******************************************************************************

.MAS3

 LDA K%+1,Y             \ Set (A P) = x_hi * x_hi
 JSR SQUA2

 STA R                  \ Store A (high byte of result) in R

 LDA K%+4,Y             \ Set (A P) = y_hi * y_hi
 JSR SQUA2

 ADC R                  \ Add A (high byte of second result) to R

 BCS MA30               \ If the addition of the two high bytes caused a carry
                        \ (i.e. they overflowed), jump to MA30 to return A = &FF

 STA R                  \ Store A (sum of the two high bytes) in R

 LDA K%+7,Y             \ Set (A P) = z_hi * z_hi
 JSR SQUA2

 ADC R                  \ Add A (high byte of third result) to R, so R now
                        \ contains the sum of x_hi^2 + y_hi^2 + z_hi^2

 BCC P%+4               \ If there is no carry, skip the following instruction
                        \ to return straight from the subroutine

.MA30

 LDA #&FF               \ The calculation has overflowed, so set A = &FF

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: STATUS
\       Type: Subroutine
\   Category: Status
\    Summary: Show the Status Mode screen (red key f8)
\  Deep dive: Combat rank
\
\ ******************************************************************************

.wearedocked

                        \ We call this from STATUS below if we are docked

 LDA #205               \ Print extended token 205 ("DOCKED") and return from
 JSR DETOK              \ the subroutine using a tail call

 JSR TT67_DUPLICATE     \ Print a newline

 JMP st6+3              \ Jump down to st6+3, to print recursive token 125 and
                        \ continue to the rest of the Status Mode screen

.st4

                        \ We call this from st5 below with the high byte of the
                        \ kill tally in A, which is non-zero, and want to return
                        \ with the following in X, depending on our rating:
                        \
                        \   Competent = 6
                        \   Dangerous = 7
                        \   Deadly    = 8
                        \   Elite     = 9
                        \
                        \ The high bytes of the top tier ratings are as follows,
                        \ so this a relatively simple calculation:
                        \
                        \   Competent       = 1 to 2
                        \   Dangerous       = 2 to 9
                        \   Deadly          = 10 to 24
                        \   Elite           = 25 and up

 LDX #9                 \ Set X to 9 for an Elite rating

 CMP #25                \ If A >= 25, jump to st3 to print out our rating, as we
 BCS st3                \ are Elite

 DEX                    \ Decrement X to 8 for a Deadly rating

 CMP #10                \ If A >= 10, jump to st3 to print out our rating, as we
 BCS st3                \ are Deadly

 DEX                    \ Decrement X to 7 for a Dangerous rating

 CMP #2                 \ If A >= 2, jump to st3 to print out our rating, as we
 BCS st3                \ are Dangerous

 DEX                    \ Decrement X to 6 for a Competent rating

 BNE st3                \ Jump to st3 to print out our rating, as we are
                        \ Competent (this BNE is effectively a JMP as A will
                        \ never be zero)

.STATUS

 LDA #8                 \ Clear the top part of the screen, draw a white border,
 JSR TRADEMODE          \ and set up a printable trading screen with a view type
                        \ in QQ11 of 8 (Status Mode screen)

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10)

 LDA #7                 \ Move the text cursor to column 7
 STA XC

 LDA #126               \ Print recursive token 126, which prints the top
 JSR NLIN3              \ four lines of the Status Mode screen:
                        \
                        \         COMMANDER {commander name}
                        \
                        \
                        \   Present System      : {current system name}
                        \   Hyperspace System   : {selected system name}
                        \   Condition           :
                        \
                        \ and draw a horizontal line at pixel row 19 to box
                        \ in the title

 LDA #15                \ Set A to token 129 ("{sentence case}DOCKED")

 LDY QQ12               \ Fetch the docked status from QQ12, and if we are
 BNE wearedocked        \ docked, jump to wearedocked

 LDA #230               \ Otherwise we are in space, so start off by setting A
                        \ to token 70 ("GREEN")

 LDY JUNK               \ Set Y to the number of junk items in our local bubble
                        \ of universe (where junk is asteroids, canisters,
                        \ escape pods and so on)

 LDX FRIN+2,Y           \ The ship slots at FRIN are ordered with the first two
                        \ slots reserved for the planet and sun/space station,
                        \ and then any ships, so if the slot at FRIN+2+Y is not
                        \ empty (i.e is non-zero), then that means the number of
                        \ non-asteroids in the vicinity is at least 1

 BEQ st6                \ So if X = 0, there are no ships in the vicinity, so
                        \ jump to st6 to print "Green" for our ship's condition

 LDY ENERGY             \ Otherwise we have ships in the vicinity, so we load
                        \ our energy levels into Y

 CPY #128               \ Set the C flag if Y >= 128, so C is set if we have
                        \ more than half of our energy banks charged

 ADC #1                 \ Add 1 + C to A, so if C is not set (i.e. we have low
                        \ energy levels) then A is set to token 231 ("RED"),
                        \ and if C is set (i.e. we have healthy energy levels)
                        \ then A is set to token 232 ("YELLOW")

.st6

 JSR plf                \ Print the text token in A (which contains our ship's
                        \ condition) followed by a newline

 LDA #125               \ Print recursive token 125, which prints the next
 JSR spc                \ three lines of the Status Mode screen:
                        \
                        \   Fuel: {fuel level} Light Years
                        \   Cash: {cash} Cr
                        \   Legal Status:
                        \
                        \ followed by a space

 LDA #19                \ Set A to token 133 ("CLEAN")

 LDY FIST               \ Fetch our legal status, and if it is 0, we are clean,
 BEQ st5                \ so jump to st5 to print "Clean"

 CPY #50                \ Set the C flag if Y >= 50, so C is set if we have
                        \ a legal status of 50+ (i.e. we are a fugitive)

 ADC #1                 \ Add 1 + C to A, so if C is not set (i.e. we have a
                        \ legal status between 1 and 49) then A is set to token
                        \ 134 ("OFFENDER"), and if C is set (i.e. we have a
                        \ legal status of 50+) then A is set to token 135
                        \ ("FUGITIVE")

.st5

 JSR plf                \ Print the text token in A (which contains our legal
                        \ status) followed by a newline

 LDA #16                \ Print recursive token 130 ("RATING:")
 JSR spc

 LDA TALLY+1            \ Fetch the high byte of the kill tally, and if it is
 BNE st4                \ not zero, then we have more than 256 kills, so jump
                        \ to st4 to work out whether we are Competent,
                        \ Dangerous, Deadly or Elite

                        \ Otherwise we have fewer than 256 kills, so we are one
                        \ of Harmless, Mostly Harmless, Poor, Average or Above
                        \ Average

 TAX                    \ Set X to 0 (as A is 0)

 LDA TALLY              \ Set A = lower byte of tally / 4
 LSR A
 LSR A

.st5L

                        \ We now loop through bits 2 to 7, shifting each of them
                        \ off the end of A until there are no set bits left, and
                        \ incrementing X for each shift, so at the end of the
                        \ process, X contains the position of the leftmost 1 in
                        \ A. Looking at the rank values in TALLY:
                        \
                        \   Harmless        = %00000000 to %00000011
                        \   Mostly Harmless = %00000100 to %00000111
                        \   Poor            = %00001000 to %00001111
                        \   Average         = %00010000 to %00011111
                        \   Above Average   = %00100000 to %11111111
                        \
                        \ we can see that the values returned by this process
                        \ are:
                        \
                        \   Harmless        = 1
                        \   Mostly Harmless = 2
                        \   Poor            = 3
                        \   Average         = 4
                        \   Above Average   = 5

 INX                    \ Increment X for each shift

 LSR A                  \ Shift A to the right

 BNE st5L               \ Keep looping around until A = 0, which means there are
                        \ no set bits left in A

.st3

 TXA                    \ A now contains our rating as a value of 1 to 9, so
                        \ transfer X to A, so we can print it out

 CLC                    \ Print recursive token 135 + A, which will be in the
 ADC #21                \ range 136 ("HARMLESS") to 144 ("---- E L I T E ----")
 JSR plf                \ followed by a newline

 LDA #18                \ Print recursive token 132, which prints the next bit
 JSR plf2               \ of the Status Mode screen:
                        \
                        \   EQUIPMENT:
                        \
                        \ followed by a newline and an indent of 6 characters

 LDA ESCP               \ ???
 BEQ P%+7

 LDA #112
 JSR plf2

 LDA BST                \ If we don't have fuel scoops fitted, skip the
 BEQ P%+7               \ following two instructions

 LDA #111               \ We do have a fuel scoops fitted, so print recursive
 JSR plf2               \ token 111 ("FUEL SCOOPS"), followed by a newline and
                        \ an indent of 6 characters

 LDA ECM                \ If we don't have an E.C.M. fitted, skip the following
 BEQ P%+7               \ two instructions

 LDA #108               \ We do have an E.C.M. fitted, so print recursive token
 JSR plf2               \ 108 ("E.C.M.SYSTEM"), followed by a newline and an
                        \ indent of 6 characters

 LDA #113               \ We now cover the four pieces of equipment whose flags
 STA XX4                \ are stored in BOMB through BOMB+3, and whose names
                        \ correspond with text tokens 113 through 116:
                        \
                        \   BOMB+0 = BOMB  = token 113 = Energy bomb
                        \   BOMB+1 = ENGY  = token 114 = Energy unit
                        \   BOMB+2 = DKCMP = token 115 = Docking computer
                        \   BOMB+3 = GHYP  = token 116 = Galactic hyperdrive
                        \
                        \ We can print these out using a loop, so we set XX4 to
                        \ 113 as a counter (and we also set A as well, to pass
                        \ through to plf2)

.stqv

 TAY                    \ Fetch byte BOMB+0 through BOMB+4 for values of XX4
 LDX BOMB-113,Y         \ from 113 through 117

 BEQ P%+5               \ If it is zero then we do not own that piece of
                        \ equipment, so skip the next instruction

 JSR plf2               \ Print the recursive token in A from 113 ("ENERGY
                        \ BOMB") through 116 ("GALACTIC HYPERSPACE "), followed
                        \ by a newline and an indent of 6 characters

 INC XX4                \ Increment the counter (and A as well)
 LDA XX4

 CMP #117               \ If A < 117, loop back up to stqv to print the next
 BCC stqv               \ piece of equipment

 LDX #0                 \ Now to print our ship's lasers, so set a counter in X
                        \ to count through the four views (0 = front, 1 = rear,
                        \ 2 = left, 3 = right)

.st

 STX CNT                \ Store the view number in CNT

 LDY LASER,X            \ Fetch the laser power for view X, and if we do not
 BEQ st1                \ have a laser fitted to that view, jump to st1 to move
                        \ on to the next one

 TXA                    \ Print recursive token 96 + X, which will print from 96
 CLC                    \ ("FRONT") through to 99 ("RIGHT"), followed by a space
 ADC #96
 JSR spc

 LDA #103               \ Set A to token 103 ("PULSE LASER")

 LDX CNT                \ Set Y = the laser power for view X
 LDY LASER,X

 CPY #128+POW           \ If the laser power for view X is not #POW+128 (beam
 BNE P%+4               \ laser), skip the next LDA instruction

 LDA #104               \ This sets A = 104 if the laser in view X is a beam
                        \ laser (token 104 is "BEAM LASER")

 CPY #Armlas            \ If the laser power for view X is not #Armlas (military
 BNE P%+4               \ laser), skip the next LDA instruction

 LDA #117               \ This sets A = 117 if the laser in view X is a military
                        \ laser (token 117 is "MILITARY  LASER")

 CPY #Mlas              \ If the laser power for view X is not #Mlas (mining
 BNE P%+4               \ laser), skip the next LDA instruction

 LDA #118               \ This sets A = 118 if the laser in view X is a mining
                        \ laser (token 118 is "MINING  LASER")

 JSR plf2               \ Print the text token in A (which contains our legal
                        \ status) followed by a newline and an indent of 6
                        \ characters

.st1

 LDX CNT                \ Increment the counter in X and CNT to point to the
 INX                    \ next view

 CPX #4                 \ If this isn't the last of the four views, jump back up
 BCC st                 \ to st to print out the next one

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: plf2
\       Type: Subroutine
\   Category: Text
\    Summary: Print text followed by a newline and indent of 6 characters
\
\ ------------------------------------------------------------------------------
\
\ Print a text token followed by a newline, and indent the next line to text
\ column 6.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.plf2

 JSR plf                \ Print the text token in A followed by a newline

 LDA #6                 \ Move the text cursor to column 6
 STA XC

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVT3
\       Type: Subroutine
\   Category: Moving
\    Summary: Calculate K(3 2 1) = (x_sign x_hi x_lo) + K(3 2 1)
\
\ ------------------------------------------------------------------------------
\
\ Add an INWK position coordinate - i.e. x, y or z - to K(3 2 1), like this:
\
\   K(3 2 1) = (x_sign x_hi x_lo) + K(3 2 1)
\
\ The INWK coordinate to add to K(3 2 1) is specified by X.
\
\ Arguments:
\
\   X                   The coordinate to add to K(3 2 1), as follows:
\
\                         * If X = 0, add (x_sign x_hi x_lo)
\
\                         * If X = 3, add (y_sign y_hi y_lo)
\
\                         * If X = 6, add (z_sign z_hi z_lo)
\
\ Returns:
\
\   A                   Contains a copy of the high byte of the result, K+3
\
\   X                   X is preserved
\
\ ******************************************************************************

.MVT3

 LDA K+3                \ Set S = K+3
 STA S

 AND #%10000000         \ Set T = sign bit of K(3 2 1)
 STA T

 EOR INWK+2,X           \ If x_sign has a different sign to K(3 2 1), jump to
 BMI MV13               \ MV13 to process the addition as a subtraction

 LDA K+1                \ Set K(3 2 1) = K(3 2 1) + (x_sign x_hi x_lo)
 CLC                    \ starting with the low bytes
 ADC INWK,X
 STA K+1

 LDA K+2                \ Then the middle bytes
 ADC INWK+1,X
 STA K+2

 LDA K+3                \ And finally the high bytes
 ADC INWK+2,X

 AND #%01111111         \ Setting the sign bit of K+3 to T, the original sign
 ORA T                  \ of K(3 2 1)
 STA K+3

 RTS                    \ Return from the subroutine

.MV13

 LDA S                  \ Set S = |K+3| (i.e. K+3 with the sign bit cleared)
 AND #%01111111
 STA S

 LDA INWK,X             \ Set K(3 2 1) = (x_sign x_hi x_lo) - K(3 2 1)
 SEC                    \ starting with the low bytes
 SBC K+1
 STA K+1

 LDA INWK+1,X           \ Then the middle bytes
 SBC K+2
 STA K+2

 LDA INWK+2,X           \ And finally the high bytes, doing A = |x_sign| - |K+3|
 AND #%01111111         \ and setting the C flag for testing below
 SBC S

 ORA #%10000000         \ Set the sign bit of K+3 to the opposite sign of T,
 EOR T                  \ i.e. the opposite sign to the original K(3 2 1)
 STA K+3

 BCS MV14               \ If the C flag is set, i.e. |x_sign| >= |K+3|, then
                        \ the sign of K(3 2 1). In this case, we want the
                        \ result to have the same sign as the largest argument,
                        \ which is (x_sign x_hi x_lo), which we know has the
                        \ opposite sign to K(3 2 1), and that's what we just set
                        \ the sign of K(3 2 1) to... so we can jump to MV14 to
                        \ return from the subroutine

 LDA #1                 \ We need to swap the sign of the result in K(3 2 1),
 SBC K+1                \ which we do by calculating 0 - K(3 2 1), which we can
 STA K+1                \ do with 1 - C - K(3 2 1), as we know the C flag is
                        \ clear. We start with the low bytes

 LDA #0                 \ Then the middle bytes
 SBC K+2
 STA K+2

 LDA #0                 \ And finally the high bytes
 SBC K+3

 AND #%01111111         \ Set the sign bit of K+3 to the same sign as T,
 ORA T                  \ i.e. the same sign as the original K(3 2 1), as
 STA K+3                \ that's the largest argument

.MV14

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVS5
\       Type: Subroutine
\   Category: Moving
\    Summary: Apply a 3.6 degree pitch or roll to an orientation vector
\  Deep dive: Orientation vectors
\             Pitching and rolling by a fixed angle
\
\ ------------------------------------------------------------------------------
\
\ Pitch or roll a ship by a small, fixed amount (1/16 radians, or 3.6 degrees),
\ in a specified direction, by rotating the orientation vectors. The vectors to
\ rotate are given in X and Y, and the direction of the rotation is given in
\ RAT2. The calculation is as follows:
\
\   * If the direction is positive:
\
\     X = X * (1 - 1/512) + Y / 16
\     Y = Y * (1 - 1/512) - X / 16
\
\   * If the direction is negative:
\
\     X = X * (1 - 1/512) - Y / 16
\     Y = Y * (1 - 1/512) + X / 16
\
\ So if X = 15 (roofv_x), Y = 21 (sidev_x) and RAT2 is positive, it does this:
\
\   roofv_x = roofv_x * (1 - 1/512)  + sidev_x / 16
\   sidev_x = sidev_x * (1 - 1/512)  - roofv_x / 16
\
\ Arguments:
\
\   X                   The first vector to rotate:
\
\                         * If X = 15, rotate roofv_x
\
\                         * If X = 17, rotate roofv_y
\
\                         * If X = 19, rotate roofv_z
\
\                         * If X = 21, rotate sidev_x
\
\                         * If X = 23, rotate sidev_y
\
\                         * If X = 25, rotate sidev_z
\
\   Y                   The second vector to rotate:
\
\                         * If Y = 9,  rotate nosev_x
\
\                         * If Y = 11, rotate nosev_y
\
\                         * If Y = 13, rotate nosev_z
\
\                         * If Y = 21, rotate sidev_x
\
\                         * If Y = 23, rotate sidev_y
\
\                         * If Y = 25, rotate sidev_z
\
\   RAT2                The direction of the pitch or roll to perform, positive
\                       or negative (i.e. the sign of the roll or pitch counter
\                       in bit 7)
\
\ ******************************************************************************

.MVS5

 LDA INWK+1,X           \ Fetch roofv_x_hi, clear the sign bit, divide by 2 and
 AND #%01111111         \ store in T, so:
 LSR A                  \
 STA T                  \ T = |roofv_x_hi| / 2
                        \   = |roofv_x| / 512
                        \
                        \ The above is true because:
                        \
                        \ |roofv_x| = |roofv_x_hi| * 256 + roofv_x_lo
                        \
                        \ so:
                        \
                        \ |roofv_x| / 512 = |roofv_x_hi| * 256 / 512
                        \                    + roofv_x_lo / 512
                        \                  = |roofv_x_hi| / 2

 LDA INWK,X             \ Now we do the following subtraction:
 SEC                    \
 SBC T                  \ (S R) = (roofv_x_hi roofv_x_lo) - |roofv_x| / 512
 STA R                  \       = (1 - 1/512) * roofv_x
                        \
                        \ by doing the low bytes first

 LDA INWK+1,X           \ And then the high bytes (the high byte of the right
 SBC #0                 \ side of the subtraction being 0)
 STA S

 LDA INWK,Y             \ Set P = nosev_x_lo
 STA P

 LDA INWK+1,Y           \ Fetch the sign of nosev_x_hi (bit 7) and store in T
 AND #%10000000
 STA T

 LDA INWK+1,Y           \ Fetch nosev_x_hi into A and clear the sign bit, so
 AND #%01111111         \ A = |nosev_x_hi|

 LSR A                  \ Set (A P) = (A P) / 16
 ROR P                  \           = |nosev_x_hi nosev_x_lo| / 16
 LSR A                  \           = |nosev_x| / 16
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P

 ORA T                  \ Set the sign of A to the sign in T (i.e. the sign of
                        \ the original nosev_x), so now:
                        \
                        \ (A P) = nosev_x / 16

 EOR RAT2               \ Give it the sign as if we multiplied by the direction
                        \ by the pitch or roll direction

 STX Q                  \ Store the value of X so it can be restored after the
                        \ call to ADD

 JSR ADD                \ (A X) = (A P) + (S R)
                        \       = +/-nosev_x / 16 + (1 - 1/512) * roofv_x

 STA K+1                \ Set K(1 0) = (1 - 1/512) * roofv_x +/- nosev_x / 16
 STX K

 LDX Q                  \ Restore the value of X from before the call to ADD

 LDA INWK+1,Y           \ Fetch nosev_x_hi, clear the sign bit, divide by 2 and
 AND #%01111111         \ store in T, so:
 LSR A                  \
 STA T                  \ T = |nosev_x_hi| / 2
                        \   = |nosev_x| / 512

 LDA INWK,Y             \ Now we do the following subtraction:
 SEC                    \
 SBC T                  \ (S R) = (nosev_x_hi nosev_x_lo) - |nosev_x| / 512
 STA R                  \       = (1 - 1/512) * nosev_x
                        \
                        \ by doing the low bytes first

 LDA INWK+1,Y           \ And then the high bytes (the high byte of the right
 SBC #0                 \ side of the subtraction being 0)
 STA S

 LDA INWK,X             \ Set P = roofv_x_lo
 STA P

 LDA INWK+1,X           \ Fetch the sign of roofv_x_hi (bit 7) and store in T
 AND #%10000000
 STA T

 LDA INWK+1,X           \ Fetch roofv_x_hi into A and clear the sign bit, so
 AND #%01111111         \ A = |roofv_x_hi|

 LSR A                  \ Set (A P) = (A P) / 16
 ROR P                  \           = |roofv_x_hi roofv_x_lo| / 16
 LSR A                  \           = |roofv_x| / 16
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P

 ORA T                  \ Set the sign of A to the opposite sign to T (i.e. the
 EOR #%10000000         \ sign of the original -roofv_x), so now:
                        \
                        \ (A P) = -roofv_x / 16

 EOR RAT2               \ Give it the sign as if we multiplied by the direction
                        \ by the pitch or roll direction

 STX Q                  \ Store the value of X so it can be restored after the
                        \ call to ADD

 JSR ADD                \ (A X) = (A P) + (S R)
                        \       = -/+roofv_x / 16 + (1 - 1/512) * nosev_x

 STA INWK+1,Y           \ Set nosev_x = (1-1/512) * nosev_x -/+ roofv_x / 16
 STX INWK,Y

 LDX Q                  \ Restore the value of X from before the call to ADD

 LDA K                  \ Set roofv_x = K(1 0)
 STA INWK,X             \              = (1-1/512) * roofv_x +/- nosev_x / 16
 LDA K+1
 STA INWK+1,X

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TENS
\       Type: Variable
\   Category: Text
\    Summary: A constant used when printing large numbers in BPRNT
\  Deep dive: Printing decimal numbers
\
\ ------------------------------------------------------------------------------
\
\ Contains the four low bytes of the value 100,000,000,000 (100 billion).
\
\ The maximum number of digits that we can print with the BPRNT routine is 11,
\ so the biggest number we can print is 99,999,999,999. This maximum number
\ plus 1 is 100,000,000,000, which in hexadecimal is:
\
\   & 17 48 76 E8 00
\
\ The TENS variable contains the lowest four bytes in this number, with the
\ most significant byte first, i.e. 48 76 E8 00. This value is used in the
\ BPRNT routine when working out which decimal digits to print when printing a
\ number.
\
\ ******************************************************************************

.TENS

 EQUD &00E87648

\ ******************************************************************************
\
\       Name: pr2
\       Type: Subroutine
\   Category: Text
\    Summary: Print an 8-bit number, left-padded to 3 digits, and optional point
\
\ ------------------------------------------------------------------------------
\
\ Print the 8-bit number in X to 3 digits, left-padding with spaces for numbers
\ with fewer than 3 digits (so numbers < 100 are right-aligned). Optionally
\ include a decimal point.
\
\ Arguments:
\
\   X                   The number to print
\
\   C flag              If set, include a decimal point
\
\ Other entry points:
\
\   pr2+2               Print the 8-bit number in X to the number of digits in A
\
\ ******************************************************************************

.pr2

 LDA #3                 \ Set A to the number of digits (3)

 LDY #0                 \ Zero the Y register, so we can fall through into TT11
                        \ to print the 16-bit number (Y X) to 3 digits, which
                        \ effectively prints X to 3 digits as the high byte is
                        \ zero

\ ******************************************************************************
\
\       Name: TT11
\       Type: Subroutine
\   Category: Text
\    Summary: Print a 16-bit number, left-padded to n digits, and optional point
\
\ ------------------------------------------------------------------------------
\
\ Print the 16-bit number in (Y X) to a specific number of digits, left-padding
\ with spaces for numbers with fewer digits (so lower numbers will be right-
\ aligned). Optionally include a decimal point.
\
\ Arguments:
\
\   X                   The low byte of the number to print
\
\   Y                   The high byte of the number to print
\
\   A                   The number of digits
\
\   C flag              If set, include a decimal point
\
\ ******************************************************************************

.TT11

 STA U                  \ We are going to use the BPRNT routine (below) to
                        \ print this number, so we store the number of digits
                        \ in U, as that's what BPRNT takes as an argument

 LDA #0                 \ BPRNT takes a 32-bit number in K to K+3, with the
 STA K                  \ most significant byte first (big-endian), so we set
 STA K+1                \ the two most significant bytes to zero (K and K+1)
 STY K+2                \ and store (Y X) in the least two significant bytes
 STX K+3                \ (K+2 and K+3), so we are going to print the 32-bit
                        \ number (0 0 Y X)

                        \ Finally we fall through into BPRNT to print out the
                        \ number in K to K+3, which now contains (Y X), to 3
                        \ digits (as U = 3), using the same C flag as when pr2
                        \ was called to control the decimal point

\ ******************************************************************************
\
\       Name: BPRNT
\       Type: Subroutine
\   Category: Text
\    Summary: Print a 32-bit number, left-padded to a specific number of digits,
\             with an optional decimal point
\  Deep dive: Printing decimal numbers
\
\ ------------------------------------------------------------------------------
\
\ Print the 32-bit number stored in K(0 1 2 3) to a specific number of digits,
\ left-padding with spaces for numbers with fewer digits (so lower numbers are
\ right-aligned). Optionally include a decimal point.
\
\ See the deep dive on "Printing decimal numbers" for details of the algorithm
\ used in this routine.
\
\ Arguments:
\
\   K(0 1 2 3)          The number to print, stored with the most significant
\                       byte in K and the least significant in K+3 (i.e. as a
\                       big-endian number, which is the opposite way to how the
\                       6502 assembler stores addresses, for example)
\
\   U                   The maximum number of digits to print, including the
\                       decimal point (spaces will be used on the left to pad
\                       out the result to this width, so the number is right-
\                       aligned to this width). U must be 11 or less
\
\   C flag              If set, include a decimal point followed by one
\                       fractional digit (i.e. show the number to 1 decimal
\                       place). In this case, the number in K(0 1 2 3) contains
\                       10 * the number we end up printing, so to print 123.4,
\                       we would pass 1234 in K(0 1 2 3) and would set the C
\                       flag to include the decimal point
\
\ ******************************************************************************

.BPRNT

 LDX #11                \ Set T to the maximum number of digits allowed (11
 STX T                  \ characters, which is the number of digits in 10
                        \ billion). We will use this as a flag when printing
                        \ characters in TT37 below

 PHP                    \ Make a copy of the status register (in particular
                        \ the C flag) so we can retrieve it later

 BCC TT30               \ If the C flag is clear, we do not want to print a
                        \ decimal point, so skip the next two instructions

 DEC T                  \ As we are going to show a decimal point, decrement
 DEC U                  \ both the number of characters and the number of
                        \ digits (as one of them is now a decimal point)

.TT30

 LDA #11                \ Set A to 11, the maximum number of digits allowed

 SEC                    \ Set the C flag so we can do subtraction without the
                        \ C flag affecting the result

 STA XX17               \ Store the maximum number of digits allowed (11) in
                        \ XX17

 SBC U                  \ Set U = 11 - U + 1, so U now contains the maximum
 STA U                  \ number of digits minus the number of digits we want
 INC U                  \ to display, plus 1 (so this is the number of digits
                        \ we should skip before starting to print the number
                        \ itself, and the plus 1 is there to ensure we print at
                        \ least one digit)

 LDY #0                 \ In the main loop below, we use Y to count the number
                        \ of times we subtract 10 billion to get the leftmost
                        \ digit, so set this to zero

 STY S                  \ In the main loop below, we use location S as an
                        \ 8-bit overflow for the 32-bit calculations, so
                        \ we need to set this to 0 before joining the loop

 JMP TT36               \ Jump to TT36 to start the process of printing this
                        \ number's digits

.TT35

                        \ This subroutine multiplies K(S 0 1 2 3) by 10 and
                        \ stores the result back in K(S 0 1 2 3), using the fact
                        \ that K * 10 = (K * 2) + (K * 2 * 2 * 2)

 ASL K+3                \ Set K(S 0 1 2 3) = K(S 0 1 2 3) * 2 by rotating left
 ROL K+2
 ROL K+1
 ROL K
 ROL S

 LDX #3                 \ Now we want to make a copy of the newly doubled K in
                        \ XX15, so we can use it for the first (K * 2) in the
                        \ equation above, so set up a counter in X for copying
                        \ four bytes, starting with the last byte in memory
                        \ (i.e. the least significant)

.tt35

 LDA K,X                \ Copy the X-th byte of K(0 1 2 3) to the X-th byte of
 STA XX15,X             \ XX15(0 1 2 3), so that XX15 will contain a copy of
                        \ K(0 1 2 3) once we've copied all four bytes

 DEX                    \ Decrement the loop counter

 BPL tt35               \ Loop back to copy the next byte until we have copied
                        \ all four

 LDA S                  \ Store the value of location S, our overflow byte, in
 STA XX15+4             \ XX15+4, so now XX15(4 0 1 2 3) contains a copy of
                        \ K(S 0 1 2 3), which is the value of (K * 2) that we
                        \ want to use in our calculation

 ASL K+3                \ Now to calculate the (K * 2 * 2 * 2) part. We still
 ROL K+2                \ have (K * 2) in K(S 0 1 2 3), so we just need to shift
 ROL K+1                \ it twice. This is the first one, so we do this:
 ROL K                  \
 ROL S                  \   K(S 0 1 2 3) = K(S 0 1 2 3) * 2 = K * 4

 ASL K+3                \ And then we do it again, so that means:
 ROL K+2                \
 ROL K+1                \   K(S 0 1 2 3) = K(S 0 1 2 3) * 2 = K * 8
 ROL K
 ROL S

 CLC                    \ Clear the C flag so we can do addition without the
                        \ C flag affecting the result

 LDX #3                 \ By now we've got (K * 2) in XX15(4 0 1 2 3) and
                        \ (K * 8) in K(S 0 1 2 3), so the final step is to add
                        \ these two 32-bit numbers together to get K * 10.
                        \ So we set a counter in X for four bytes, starting
                        \ with the last byte in memory (i.e. the least
                        \ significant)

.tt36

 LDA K,X                \ Fetch the X-th byte of K into A

 ADC XX15,X             \ Add the X-th byte of XX15 to A, with carry

 STA K,X                \ Store the result in the X-th byte of K

 DEX                    \ Decrement the loop counter

 BPL tt36               \ Loop back to add the next byte, moving from the least
                        \ significant byte to the most significant, until we
                        \ have added all four

 LDA XX15+4             \ Finally, fetch the overflow byte from XX15(4 0 1 2 3)

 ADC S                  \ And add it to the overflow byte from K(S 0 1 2 3),
                        \ with carry

 STA S                  \ And store the result in the overflow byte from
                        \ K(S 0 1 2 3), so now we have our desired result, i.e.
                        \
                        \   K(S 0 1 2 3) = K(S 0 1 2 3) * 10

 LDY #0                 \ In the main loop below, we use Y to count the number
                        \ of times we subtract 10 billion to get the leftmost
                        \ digit, so set this to zero so we can rejoin the main
                        \ loop for another subtraction process

.TT36

                        \ This is the main loop of our digit-printing routine.
                        \ In the following loop, we are going to count the
                        \ number of times that we can subtract 10 million and
                        \ store that count in Y, which we have already set to 0

 LDX #3                 \ Our first calculation concerns 32-bit numbers, so
                        \ set up a counter for a four-byte loop

 SEC                    \ Set the C flag so we can do subtraction without the
                        \ C flag affecting the result

.tt37

                        \ We now loop through each byte in turn to do this:
                        \
                        \   XX15(4 0 1 2 3) = K(S 0 1 2 3) - 100,000,000,000

 LDA K,X                \ Subtract the X-th byte of TENS (i.e. 10 billion) from
 SBC TENS,X             \ the X-th byte of K

 STA XX15,X             \ Store the result in the X-th byte of XX15

 DEX                    \ Decrement the loop counter

 BPL tt37               \ Loop back to subtract the next byte, moving from the
                        \ least significant byte to the most significant, until
                        \ we have subtracted all four

 LDA S                  \ Subtract the fifth byte of 10 billion (i.e. &17) from
 SBC #&17               \ the fifth (overflow) byte of K, which is S

 STA XX15+4             \ Store the result in the overflow byte of XX15

 BCC TT37               \ If subtracting 10 billion took us below zero, jump to
                        \ TT37 to print out this digit, which is now in Y

 LDX #3                 \ We now want to copy XX15(4 0 1 2 3) back into
                        \ K(S 0 1 2 3), so we can loop back up to do the next
                        \ subtraction, so set up a counter for a four-byte loop

.tt38

 LDA XX15,X             \ Copy the X-th byte of XX15(0 1 2 3) to the X-th byte
 STA K,X                \ of K(0 1 2 3), so that K(0 1 2 3) will contain a copy
                        \ of XX15(0 1 2 3) once we've copied all four bytes

 DEX                    \ Decrement the loop counter

 BPL tt38               \ Loop back to copy the next byte, until we have copied
                        \ all four

 LDA XX15+4             \ Store the value of location XX15+4, our overflow
 STA S                  \ byte in S, so now K(S 0 1 2 3) contains a copy of
                        \ XX15(4 0 1 2 3)

 INY                    \ We have now managed to subtract 10 billion from our
                        \ number, so increment Y, which is where we are keeping
                        \ a count of the number of subtractions so far

 JMP TT36               \ Jump back to TT36 to subtract the next 10 billion

.TT37

 TYA                    \ If we get here then Y contains the digit that we want
                        \ to print (as Y has now counted the total number of
                        \ subtractions of 10 billion), so transfer Y into A

 BNE TT32               \ If the digit is non-zero, jump to TT32 to print it

 LDA T                  \ Otherwise the digit is zero. If we are already
                        \ printing the number then we will want to print a 0,
                        \ but if we haven't started printing the number yet,
                        \ then we probably don't, as we don't want to print
                        \ leading zeroes unless this is the only digit before
                        \ the decimal point
                        \
                        \ To help with this, we are going to use T as a flag
                        \ that tells us whether we have already started
                        \ printing digits:
                        \
                        \   * If T <> 0 we haven't printed anything yet
                        \
                        \   * If T = 0 then we have started printing digits
                        \
                        \ We initially set T above to the maximum number of
                        \ characters allowed, less 1 if we are printing a
                        \ decimal point, so the first time we enter the digit
                        \ printing routine at TT37, it is definitely non-zero

 BEQ TT32               \ If T = 0, jump straight to the print routine at TT32,
                        \ as we have already started printing the number, so we
                        \ definitely want to print this digit too

 DEC U                  \ We initially set U to the number of digits we want to
 BPL TT34               \ skip before starting to print the number. If we get
                        \ here then we haven't printed any digits yet, so
                        \ decrement U to see if we have reached the point where
                        \ we should start printing the number, and if not, jump
                        \ to TT34 to set up things for the next digit

 LDA #' '               \ We haven't started printing any digits yet, but we
 BNE tt34               \ have reached the point where we should start printing
                        \ our number, so call TT26 (via tt34) to print a space
                        \ so that the number is left-padded with spaces (this
                        \ BNE is effectively a JMP as A will never be zero)

.TT32

 LDY #0                 \ We are printing an actual digit, so first set T to 0,
 STY T                  \ to denote that we have now started printing digits as
                        \ opposed to spaces

 CLC                    \ The digit value is in A, so add ASCII "0" to get the
 ADC #'0'               \ ASCII character number to print

.tt34

 JSR TT26               \ Call TT26 to print the character in A and fall through
                        \ into TT34 to get things ready for the next digit

.TT34

 DEC T                  \ Decrement T but keep T >= 0 (by incrementing it
 BPL P%+4               \ again if the above decrement made T negative)
 INC T

 DEC XX17               \ Decrement the total number of characters left to
                        \ print, which we stored in XX17

 BMI rT10               \ If the result is negative, we have printed all the
                        \ characters, so jump down to rT10 to return from the
                        \ subroutine

 BNE P%+10              \ If the result is positive (> 0) then we still have
                        \ characters left to print, so loop back to TT35 (via
                        \ the JMP TT35 instruction below) to print the next
                        \ digit

 PLP                    \ If we get here then we have printed the exact number
                        \ of digits that we wanted to, so restore the C flag
                        \ that we stored at the start of the routine

 BCC P%+7               \ If the C flag is clear, we don't want a decimal point,
                        \ so loop back to TT35 (via the JMP TT35 instruction
                        \ below) to print the next digit

 LDA #'.'               \ Otherwise the C flag is set, so print the decimal
 JSR TT26               \ point

 JMP TT35               \ Loop back to TT35 to print the next digit

.rT10

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DTW1
\       Type: Variable
\   Category: Text
\    Summary: A mask for applying the lower case part of Sentence Case to
\             extended text tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is used to change characters to lower case as part of applying
\ Sentence Case to extended text tokens. It has two values:
\
\   * %00100000 = apply lower case to the second letter of a word onwards
\
\   * %00000000 = do not change case to lower case
\
\ The default value is %00100000 (apply lower case).
\
\ The flag is set to %00100000 (apply lower case) by jump token 2, {sentence
\ case}, which calls routine MT2 to change the value of DTW1.
\
\ The flag is set to %00000000 (do not change case to lower case) by jump token
\ 1, {all caps}, which calls routine MT1 to change the value of DTW1.
\
\ The letter to print is OR'd with DTW1 in DETOK2, which lower-cases the letter
\ by setting bit 5 (if DTW1 is %00100000). However, this OR is only done if bit
\ 7 of DTW2 is clear, i.e. we are printing a word, so this doesn't affect the
\ first letter of the word, which remains capitalised.
\
\ ******************************************************************************

.DTW1

 EQUB %00100000

\ ******************************************************************************
\
\       Name: DTW2
\       Type: Variable
\   Category: Text
\    Summary: A flag that indicates whether we are currently printing a word
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is used to indicate whether we are currently printing a word. It
\ has two values:
\
\   * 0 = we are currently printing a word
\
\   * Non-zero = we are not currently printing a word
\
\ The default value is %11111111 (we are not currently printing a word).
\
\ The flag is set to %00000000 (we are currently printing a word) whenever a
\ non-terminator character is passed to DASC for printing.
\
\ The flag is set to %11111111 (we are not currently printing a word) whenever a
\ terminator character (full stop, colon, carriage return, line feed, space) is
\ passed to DASC for printing. It is also set to %11111111 by jump token 8,
\ {tab 6}, which calls routine MT8 to change the value of DTW2, and to %10000000
\ by TTX66 when we clear the screen.
\
\ ******************************************************************************

.DTW2

 EQUB %11111111

\ ******************************************************************************
\
\       Name: DTW3
\       Type: Variable
\   Category: Text
\    Summary: A flag for switching between standard and extended text tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is used to indicate whether standard or extended text tokens
\ should be printed by calls to DETOK. It allows us to mix standard tokens in
\ with extended tokens. It has two values:
\
\   * %00000000 = print extended tokens (i.e. those in TKN1 and RUTOK)
\
\   * %11111111 = print standard tokens (i.e. those in QQ18)
\
\ The default value is %00000000 (extended tokens).
\
\ Standard tokens are set by jump token {6}, which calls routine MT6 to change
\ the value of DTW3 to %11111111.
\
\ Extended tokens are set by jump token {5}, which calls routine MT5 to change
\ the value of DTW3 to %00000000.
\
\ ******************************************************************************

.DTW3

 EQUB %00000000

\ ******************************************************************************
\
\       Name: DTW4
\       Type: Variable
\   Category: Text
\    Summary: Flags that govern how justified extended text tokens are printed
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is used to control how justified text tokens are printed as part
\ of the extended text token system. There are two bits that affect justified
\ text:
\
\   * Bit 7: 1 = justify text
\            0 = do not justify text
\
\   * Bit 6: 1 = buffer the entire token before printing, including carriage
\                returns (used for in-flight messages only)
\            0 = print the contents of the buffer whenever a carriage return
\                appears in the token
\
\ The default value is %00000000 (do not justify text, print buffer on carriage
\ return).
\
\ The flag is set to %10000000 (justify text, print buffer on carriage return)
\ by jump token 14, {justify}, which calls routine MT14 to change the value of
\ DTW4.
\
\ The flag is set to %11000000 (justify text, buffer entire token) by routine
\ MESS, which printe in-flight messages.
\
\ The flag is set to %00000000 (do not justify text, print buffer on carriage
\ return) by jump token 15, {left align}, which calls routine MT1 to change the
\ value of DTW4.
\
\ ******************************************************************************

.DTW4

 EQUB 0

\ ******************************************************************************
\
\       Name: DTW5
\       Type: Variable
\   Category: Text
\    Summary: The size of the justified text buffer at BUF
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ When justified text is enabled by jump token 14, {justify}, during printing of
\ extended text tokens, text is fed into a buffer at BUF instead of being
\ printed straight away, so it can be padded out with spaces to justify the
\ text. DTW5 contains the size of the buffer, so BUF + DTW5 points to the first
\ free byte after the end of the buffer.
\
\ ******************************************************************************

.DTW5

 EQUB 0

\ ******************************************************************************
\
\       Name: DTW6
\       Type: Variable
\   Category: Text
\    Summary: A flag to denote whether printing in lower case is enabled for
\             extended text tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is used to indicate whether lower case is currently enabled. It
\ has two values:
\
\   * %10000000 = lower case is enabled
\
\   * %00000000 = lower case is not enabled
\
\ The default value is %00000000 (lower case is not enabled).
\
\ The flag is set to %10000000 (lower case is enabled) by jump token 13 {lower
\ case}, which calls routine MT10 to change the value of DTW6.
\
\ The flag is set to %00000000 (lower case is not enabled) by jump token 1, {all
\ caps}, and jump token 1, {sentence case}, which call routines MT1 and MT2 to
\ change the value of DTW6.
\
\ ******************************************************************************

.DTW6

 EQUB %00000000

\ ******************************************************************************
\
\       Name: DTW8
\       Type: Variable
\   Category: Text
\    Summary: A mask for capitalising the next letter in an extended text token
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is only used by one specific extended token, the {single cap}
\ jump token, which capitalises the next letter only. It has two values:
\
\   * %11011111 = capitalise the next letter
\
\   * %11111111 = do not change case
\
\ The default value is %11111111 (do not change case).
\
\ The flag is set to %11011111 (capitalise the next letter) by jump token 19,
\ {single cap}, which calls routine MT19 to change the value of DTW.
\
\ The flag is set to %11111111 (do not change case) at the start of DASC, after
\ the letter has been capitalised in DETOK2, so the effect is to capitalise one
\ letter only.
\
\ The letter to print is AND'd with DTW8 in DETOK2, which capitalises the letter
\ by clearing bit 5 (if DTW8 is %11011111). However, this AND is only done if at
\ least one of the following is true:
\
\   * Bit 7 of DTW2 is set (we are not currently printing a word)
\
\   * Bit 7 of DTW6 is set (lower case has been enabled by jump token 13, {lower
\     case}
\
\ In other words, we only capitalise the next letter if it's the first letter in
\ a word, or we are printing in lower case.
\
\ ******************************************************************************

.DTW8

 EQUB %11111111

\ ******************************************************************************
\
\       Name: FEED
\       Type: Subroutine
\   Category: Text
\    Summary: Print a newline
\
\ ******************************************************************************

.FEED

 LDA #12                \ Set A = 12, so when we skip MT16 and fall through into
                        \ TT26, we print character 12, which is a newline

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &41, or BIT &41A9, which does nothing apart
                        \ from affect the flags

                        \ Fall through into TT26 (skipping MT16) to print the
                        \ newline character

\ ******************************************************************************
\
\       Name: MT16
\       Type: Subroutine
\   Category: Text
\    Summary: Print the character in variable DTW7
\  Deep dive: Extended text tokens
\
\ ******************************************************************************

.MT16

 LDA #'A'               \ Set A to the contents of DTW7, as DTW7 points to the
                        \ second byte of this instruction, so updating DTW7 will
                        \ modify this instruction (the default value of DTW7 is
                        \ an "A")

DTW7 = MT16 + 1         \ Point DTW7 to the second byte of the instruction above
                        \ so that modifying DTW7 changes the value loaded into A

                        \ Fall through into TT26 to print the character in A

\ ******************************************************************************
\
\       Name: TT26
\       Type: Subroutine
\   Category: Text
\    Summary: Print a character at the text cursor, with support for verified
\             text in extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The character to print
\
\ Returns:
\
\   X                   X is preserved
\
\   C flag              The C flag is cleared
\
\ Other entry points:
\
\   DASC                DASC does exactly the same as TT26 and prints a
\                       character at the text cursor, with support for verified
\                       text in extended tokens
\
\   rT9                 Contains an RTS
\
\ ******************************************************************************

.DASC

.TT26

 STX SC                 \ Store X in SC, so we can retrieve it below

 LDX #%11111111         \ Set DTW8 = %11111111, to disable the effect of {19} if
 STX DTW8               \ it was set (as {19} capitalises one character only)

 CMP #'.'               \ If the character in A is a word terminator:
 BEQ DA8                \
 CMP #':'               \   * Full stop
 BEQ DA8                \   * Colon
 CMP #10                \   * Line feed
 BEQ DA8                \   * Carriage return
 CMP #12                \   * Space
 BEQ DA8                \
 CMP #' '               \ then skip the following instruction
 BEQ DA8

 INX                    \ Increment X to 0, so DTW2 gets set to %00000000 below

.DA8

 STX DTW2               \ Store X in DTW2, so DTW2 is now:
                        \
                        \   * %00000000 if this character is a word terminator
                        \
                        \   * %11111111 if it isn't
                        \
                        \ so DTW2 indicates whether or not we are currently
                        \ printing a word

 LDX SC                 \ Retrieve the original value of X from SC

 BIT DTW4               \ If bit 7 of DTW4 is set then we are currently printing
 BMI P%+5               \ justified text, so skip the next instruction

 JMP CHPR               \ Bit 7 of DTW4 is clear, so jump down to CHPR to print
                        \ this character, as we are not printing justified text

                        \ If we get here then we are printing justified text, so
                        \ we need to buffer the text until we reach the end of
                        \ the paragraph, so we can then pad it out with spaces

 BIT DTW4               \ If bit 6 of DTW4 is set, then this is an in-flight
 BVS P%+6               \ message and we should buffer the carriage return
                        \ character {12}, so skip the following two instructions

 CMP #12                \ If the character in A is a carriage return, then we
 BEQ DA1                \ have reached the end of the paragraph, so jump down to
                        \ DA1 to print out the contents of the buffer,
                        \ justifying it as we go

                        \ If we get here then we need to buffer this character
                        \ in the line buffer at BUF

 LDX DTW5               \ DTW5 contains the current size of the buffer, so this
 STA BUF,X              \ stores the character in A at BUF + DTW5, the next free
                        \ space in the buffer

 LDX SC                 \ Retrieve the original value of X from SC so we can
                        \ preserve it through this subroutine call

 INC DTW5               \ Increment the size of the BUF buffer that is stored in
                        \ DTW5

 CLC                    \ Clear the C flag

 RTS                    \ Return from the subroutine

.DA1

                        \ If we get here then we are justifying text and we have
                        \ reached the end of the paragraph, so we need to print
                        \ out the contents of the buffer, justifying it as we go

 TXA                    \ Store X and Y on the stack
 PHA
 TYA
 PHA

.DA5

 LDX DTW5               \ Set X = DTW5, which contains the size of the buffer

 BEQ DA6+3              \ If X = 0 then the buffer is empty, so jump down to
                        \ DA6+3 to print a newline

 CPX #(LL+1)            \ If X < LL+1, i.e. X <= LL, then the buffer contains
 BCC DA6                \ fewer than LL characters, which is less then a line
                        \ length, so jump down to DA6 to print the contents of
                        \ BUF followed by a newline, as we don't justify the
                        \ last line of the paragraph

                        \ Otherwise X > LL, so the buffer does not fit into one
                        \ line, and we therefore need to justify the text, which
                        \ we do one line at a time

 LSR SC+1               \ Shift SC+1 to the right, which clears bit 7 of SC+1,
                        \ so we pass through the following comparison on the
                        \ first iteration of the loop and set SC+1 to %01000000

.DA11

 LDA SC+1               \ If bit 7 of SC+1 is set, skip the following two
 BMI P%+6               \ instructions

 LDA #%01000000         \ Set SC+1 = %01000000
 STA SC+1

 LDY #(LL-1)            \ Set Y = line length, so we can loop backwards from the
                        \ end of the first line in the buffer using Y as the
                        \ loop counter

.DAL1

 LDA BUF+LL             \ If the LL-th byte in BUF is a space, jump down to DA2
 CMP #' '               \ to print out the first line from the buffer, as it
 BEQ DA2                \ fits the line width exactly (i.e. it's justified)

                        \ We now want to find the last space character in the
                        \ first line in the buffer, so we loop through the line
                        \ using Y as a counter

.DAL2

 DEY                    \ Decrement the loop counter in Y

 BMI DA11               \ If Y <= 0, loop back to DA11, as we have now looped
 BEQ DA11               \ through the whole line

 LDA BUF,Y              \ If the Y-th byte in BUF is not a space, loop back up
 CMP #' '               \ to DAL2 to check the next character
 BNE DAL2

                        \ Y now points to a space character in the line buffer

 ASL SC+1               \ Shift SC+1 to the left

 BMI DAL2               \ If bit 7 of SC+1 is set, jump to DAL2 to find the next
                        \ space character

                        \ We now want to insert a space into the line buffer at
                        \ position Y, which we do by shifting every character
                        \ after position Y along by 1, and then inserting the
                        \ space

 STY SC                 \ Store Y in SC, so we want to insert the space at
                        \ position SC

 LDY DTW5               \ Fetch the buffer size from DTW5 into Y, to act as a
                        \ loop counter for moving the line buffer along by 1

.DAL6

 LDA BUF,Y              \ Copy the Y-th character from BUF into the Y+1-th
 STA BUF+1,Y            \ position

 DEY                    \ Decrement the loop counter in Y

 CPY SC                 \ Loop back to shift the next character along, until we
 BCS DAL6               \ have moved the SC-th character (i.e. Y < SC)

 INC DTW5               \ Increment the buffer size in DTW5

\LDA #' '               \ This instruction is commented out in the original
                        \ source, as it has no effect because A already contains
                        \ ASCII " ". This is because the last character that is
                        \ tested in the above loop is at position SC, which we
                        \ know contains a space, so we know A contains a space
                        \ character when the loop finishes

                        \ We've now shifted the line to the right by 1 from
                        \ position SC onwards, so SC and SC+1 both contain
                        \ spaces, and Y is now SC-1 as we did a DEY just before
                        \ the end of the loop - in other words, we have inserted
                        \ a space at position SC, and Y points to the character
                        \ before the newly inserted space

                        \ We now want to move the pointer Y left to find the
                        \ next space in the line buffer, before looping back to
                        \ check whether we are done, and if not, insert another
                        \ space

.DAL3

 CMP BUF,Y              \ If the character at position Y is not a space, jump to
 BNE DAL1               \ DAL1 to see whether we have now justified the line

 DEY                    \ Decrement the loop counter in Y

 BPL DAL3               \ Loop back to check the next character to the left,
                        \ until we have found a space

 BMI DA11               \ Jump back to DA11 (this BMI is effectively a JMP as
                        \ we already passed through a BPL to get here)

.DA2

                        \ This subroutine prints out a full line of characters
                        \ from the start of the line buffer in BUF, followed by
                        \ a newline. It then removes that line from the buffer,
                        \ shuffling the rest of the buffer contents down

 LDX #LL                \ Call DAS1 to print out the first LL characters from
 JSR DAS1               \ the line buffer in BUF

 LDA #12                \ Print a newline
 JSR CHPR

 LDA DTW5               \ Subtract #LL from the end-of-buffer pointer in DTW5
\CLC                    \
 SBC #LL                \ The CLC instruction is commented out in the original
 STA DTW5               \ source. It isn't needed as CHPR clears the C flag

 TAX                    \ Copy the new value of DTW5 into X

 BEQ DA6+3              \ If DTW5 = 0 then jump down to DA6+3 to print a newline
                        \ as the buffer is now empty

                        \ If we get here then we have printed our line but there
                        \ is more in the buffer, so we now want to remove the
                        \ line we just printed from the start of BUF

 LDY #0                 \ Set Y = 0 to count through the characters in BUF

 INX                    \ Increment X, so it now contains the number of
                        \ characters in the buffer (as DTW5 is a zero-based
                        \ pointer and is therefore equal to the number of
                        \ characters minus 1)

.DAL4

 LDA BUF+LL+1,Y         \ Copy the Y-th character from BUF+LL to BUF
 STA BUF,Y

 INY                    \ Increment the character pointer

 DEX                    \ Decrement the character count

 BNE DAL4               \ Loop back to copy the next character until we have
                        \ shuffled down the whole buffer

 BEQ DA5                \ Jump back to DA5 (this BEQ is effectively a JMP as we
                        \ have already passed through the BNE above)

.DAS1

                        \ This subroutine prints out X characters from BUF,
                        \ returning with X = 0

 LDY #0                 \ Set Y = 0 to point to the first character in BUF

.DAL5

 LDA BUF,Y              \ Print the Y-th character in BUF using CHPR, which also
 JSR CHPR               \ clears the C flag for when we return from the
                        \ subroutine below

 INY                    \ Increment Y to point to the next character

 DEX                    \ Decrement the loop counter

 BNE DAL5               \ Loop back for the next character until we have printed
                        \ X characters from BUF

.rT9

 RTS                    \ Return from the subroutine

.DA6

 JSR DAS1               \ Call DAS1 to print X characters from BUF, returning
                        \ with X = 0

 STX DTW5               \ Set the buffer size in DTW5 to 0, as the buffer is now
                        \ empty

 PLA                    \ Restore Y and X from the stack
 TAY
 PLA
 TAX

 LDA #12                \ Set A = 12, so when we skip BELL and fall through into
                        \ CHPR, we print character 12, which is a newline

.DA7

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &07, or BIT &07A9, which does nothing apart
                        \ from affect the flags

                        \ Fall through into CHPR (skipping BELL) to print the
                        \ character and return with the C flag cleared

\ ******************************************************************************
\
\       Name: BELL
\       Type: Subroutine
\   Category: Sound
\    Summary: Make a standard system beep
\
\ ------------------------------------------------------------------------------
\
\ This is the standard system beep as made by the VDU 7 statement in BBC BASIC.
\
\ ******************************************************************************

.BELL

 LDA #7                 \ Control code 7 makes a beep, so load this into A

 JMP CHPR               \ Call the CHPR print routine to actually make the sound

\ ******************************************************************************
\
\       Name: ESCAPE
\       Type: Subroutine
\   Category: Flight
\    Summary: Launch our escape pod
\
\ ------------------------------------------------------------------------------
\
\ This routine displays our doomed Cobra Mk III disappearing off into the ether
\ before arranging our replacement ship. Called when we press ESCAPE during
\ flight and have an escape pod fitted.
\
\ ******************************************************************************

.ESCAPE

 JSR RES2               \ Reset a number of flight variables and workspaces

 LDX #CYL               \ Set the current ship type to a Cobra Mk III, so we
 STX TYPE               \ can show our ship disappear into the distance when we
                        \ eject in our pod

 JSR FRS1               \ Call FRS1 to launch the Cobra Mk III straight ahead,
                        \ like a missile launch, but with our ship instead

 BCS ES1                \ If the Cobra was successfully added to the local
                        \ bubble, jump to ES1 to skip the following instructions

 LDX #CYL2              \ The Cobra wasn't added to the local bubble for some
 JSR FRS1               \ reason, so try launching a pirate Cobra Mk III instead

.ES1

 LDA #8                 \ Set the Cobra's byte #27 (speed) to 8
 STA INWK+27

 LDA #194               \ Set the Cobra's byte #30 (pitch counter) to 194, so it
 STA INWK+30            \ pitches as we pull away

 LSR A                  \ Set the Cobra's byte #32 (AI flag) to %01100001, so it
 STA INWK+32            \ has no AI, and we can use this value as a counter to
                        \ do the following loop 97 times

.ESL1

 JSR MVEIT              \ Call MVEIT to move the Cobra in space

 LDA QQ11               \ ???
 ORA VIEW
 BNE P%+5

 JSR LL9                \ Call LL9 to draw the Cobra on-screen

 DEC INWK+32            \ Decrement the counter in byte #32

 BNE ESL1               \ Loop back to keep moving the Cobra until the AI flag
                        \ is 0, which gives it time to drift away from our pod

 JSR SCAN               \ Call SCAN to remove the Cobra from the scanner (by
                        \ redrawing it)

 LDA #0                 \ Set A = 0 so we can use it to zero the contents of
                        \ the cargo hold

 LDX #16                \ We lose all our cargo when using our escape pod, so
                        \ up a counter in X so we can zero the 17 cargo slots
                        \ in QQ20

.ESL2

 STA QQ20,X             \ Set the X-th byte of QQ20 to zero, so we no longer
                        \ have any of item type X in the cargo hold

 DEX                    \ Decrement the counter

 BPL ESL2               \ Loop back to ESL2 until we have emptied the entire
                        \ cargo hold

 STA FIST               \ Launching an escape pod also clears our criminal
                        \ record, so set our legal status in FIST to 0 ("clean")

 STA ESCP               \ The escape pod is a one-use item, so set ESCP to 0 so
                        \ we no longer have one fitted

 LDA #70                \ Our replacement ship is delivered with a full tank of
 STA QQ14               \ fuel, so set the current fuel level in QQ14 to 70, or
                        \ 7.0 light years

 JMP GOIN               \ Go to the docking bay (i.e. show the ship hanger
                        \ screen) and return from the subroutine with a tail
                        \ call

\ ******************************************************************************
\
\       Name: HME2
\       Type: Subroutine
\   Category: Charts
\    Summary: Search the galaxy for a system
\
\ ******************************************************************************

.HME2

 LDA #&FF               \ ???
 STA COL

 LDA #14                \ Print extended token 14 ("{clear bottom of screen}
 JSR DETOK              \ PLANET NAME?{fetch line input from keyboard}"). The
                        \ last token calls MT26, which puts the entered search
                        \ term in INWK+5 and the term length in Y

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will erase the crosshairs currently there

 JSR TT81               \ Set the seeds in QQ15 (the selected system) to those
                        \ of system 0 in the current galaxy (i.e. copy the seeds
                        \ from QQ21 to QQ15)

 LDA #0                 \ We now loop through the galaxy's systems in order,
 STA XX20               \ until we find a match, so set XX20 to act as a system
                        \ counter, starting with system 0

.HME3

 JSR MT14               \ Switch to justified text when printing extended
                        \ tokens, so the call to cpl prints into the justified
                        \ text buffer at BUF instead of the screen, and DTW5
                        \ gets set to the length of the system name

 JSR cpl                \ Print the selected system name into the justified text
                        \ buffer

 LDX DTW5               \ Fetch DTW5 into X, so X is now equal to the length of
                        \ the selected system name

 LDA INWK+5,X           \ Fetch the X-th character from the entered search term

 CMP #13                \ If the X-th character is not a carriage return, then
 BNE HME6               \ the selected system name and the entered search term
                        \ are different lengths, so jump to HME6 to move on to
                        \ the next system

.HME4

 DEX                    \ Decrement X so it points to the last letter of the
                        \ selected system name (and, when we loop back here, it
                        \ points to the next letter to the left)

 LDA INWK+5,X           \ Set A to the X-th character of the entered search term

 ORA #%00100000         \ Set bit 5 of the character to make it lower case

 CMP BUF,X              \ If the character in A matches the X-th character of
 BEQ HME4               \ the selected system name in BUF, loop back to HME4 to
                        \ check the next letter to the left

 TXA                    \ The last comparison didn't match, so copy the letter
 BMI HME5               \ number into A, and if it's negative, that means we
                        \ managed to go past the first letters of each term
                        \ before we failed to get a match, so the terms are the
                        \ same, so jump to HME5 to process a successful search

.HME6

                        \ If we get here then the selected system name and the
                        \ entered search term did not match

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 INC XX20               \ Incrememt the system counter in XX20

 BNE HME3               \ If we haven't yet checked all 256 systems in the
                        \ current galaxy, loop back to HME3 to check the next
                        \ system

                        \ If we get here then the entered search term did not
                        \ match any systems in the current galaxy

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10), so we can put the crosshairs back where
                        \ they were before the search

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10)

 JSR BEEP_LONG_LOW      \ ???

 LDA #215               \ Print extended token 215 ("{left align} UNKNOWN
 JMP DETOK              \ PLANET"), which will print on-screem as the left align
                        \ code disables justified text, and return from the
                        \ subroutine using a tail call

.HME5

                        \ If we get here then we have found a match for the
                        \ entered search

 LDA QQ15+3             \ The x-coordinate of the system described by the seeds
 STA QQ9                \ in QQ15 is in QQ15+3 (s1_hi), so we copy this to QQ9
                        \ as the x-coordinate of the search result

 LDA QQ15+1             \ The y-coordinate of the system described by the seeds
 STA QQ10               \ in QQ15 is in QQ15+1 (s0_hi), so we copy this to QQ10
                        \ as the y-coordinate of the search result

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10)

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10)

 JSR MT15               \ Switch to left-aligned text when printing extended
                        \ tokens so future tokens will print to the screen (as
                        \ this disables justified text)

 JMP T95                \ Jump to T95 to print the distance to the selected
                        \ system and return from the subroutine using a tail
                        \ call

\ ******************************************************************************
\
\       Name: HATB
\       Type: Variable
\   Category: Ship hanger
\    Summary: Ship hanger group table
\
\ ------------------------------------------------------------------------------
\
\ This table contains groups of ships to show in the ship hanger. A group of
\ ships is shown half the time (the other half shows a solo ship), and each of
\ the four groups is equally likely.
\
\ The bytes for each ship in the group contain the following information:
\
\   Byte #0             Non-zero = Ship type to draw
\                       0        = don't draw anything
\
\   Byte #1             Bits 0-7 = Ship's x_hi
\                       Bit 0    = Ship's z_hi (1 if clear, or 2 if set)
\
\   Byte #2             Bits 0-7 = Ship's z_lo
\                       Bit 0    = Ship's x_sign
\
\ Ths ship's y-coordinate is calculated in the has1 routine from the size of
\ its targetable area. Ships of type 0 are not shown.
\
\ ******************************************************************************

.HATB

                        \ Hanger group for X = 0
                        \
                        \ Cobra Mk III (left)

 EQUB 11                \ Ship type = 11 = Cobra Mk III
 EQUB %01000100         \ x_hi = %01000100 = 68, z_hi   = 1     -> x = -68
 EQUB %00111011         \ z_lo = %00111011 = 59, x_sign = 1        z = +315

 EQUB 0                 \ No second ship
 EQUB %10000010         \ x_hi = %10000010 = 130, z_hi   = 1    -> x = +130
 EQUB %10110000         \ z_lo = %10110000 = 176, x_sign = 0       z = +432

 EQUB 0                 \ No third ship
 EQUB 0
 EQUB 0

                        \ Hanger group for X = 9
                        \
                        \ Three cargo canisters (left, far right and forward,
                        \ right)

 EQUB OIL               \ Ship type = OIL = Cargo canister
 EQUB %01010000         \ x_hi = %01010000 = 80, z_hi   = 1     -> x = -80
 EQUB %00010001         \ z_lo = %00010001 = 17, x_sign = 1        z = +273

 EQUB OIL               \ Ship type = OIL = Cargo canister
 EQUB %11010001         \ x_hi = %11010001 = 209, z_hi = 2      -> x = +209
 EQUB %00101000         \ z_lo = %00101000 =  40, x_sign = 0       z = +552

 EQUB OIL               \ Ship type = OIL = Cargo canister
 EQUB %01000000         \ x_hi = %01000000 = 64, z_hi   = 1     -> x = +64
 EQUB %00000110         \ z_lo = %00000110 = 6,  x_sign = 0        z = +262

                        \ Hanger group for X = 18
                        \
                        \ Viper (right) and Krait (left)

 EQUB COPS              \ Ship type = COPS = Viper
 EQUB %01100000         \ x_hi = %01100000 =  96, z_hi   = 1    -> x = +96
 EQUB %10010000         \ z_lo = %10010000 = 144, x_sign = 0       z = +400

 EQUB KRA               \ Ship type = KRA = Krait
 EQUB %00010000         \ x_hi = %00010000 =  16, z_hi   = 1    -> x = -16
 EQUB %11010001         \ z_lo = %11010001 = 209, x_sign = 1       z = +465

 EQUB 0                 \ No third ship
 EQUB 0
 EQUB 0

                        \ Hanger group for X = 27
                        \
                        \ Adder (right and forward) and Viper (left)

 EQUB 20                \ Ship type = 20 = Adder
 EQUB %01010001         \ x_hi = %01010001 =  81, z_hi  = 2     -> x = +81
 EQUB %11111000         \ z_lo = %11111000 = 248, x_sign = 0       z = +760

 EQUB 16                \ Ship type = 16 = Viper
 EQUB %01100000         \ x_hi = %01100000 = 96,  z_hi   = 1    -> x = -96
 EQUB %01110101         \ z_lo = %01110101 = 117, x_sign = 1       z = +373

 EQUB 0                 \ No third ship
 EQUB 0
 EQUB 0

\ ******************************************************************************
\
\       Name: HALL
\       Type: Subroutine
\   Category: Ship hanger
\
\ ------------------------------------------------------------------------------
\
\ Half the time this will draw one of the four pre-defined ship hanger groups in
\ HATB, and half the time this will draw a solitary Sidewinder, Mamba, Krait or
\ Adder on a random position. In all cases, the ships will be randomly spun
\ around on the ground so they can face in any dirction, and larger ships are
\ drawn higher up off the ground than smaller ships.
\
\ The ships are drawn by the HAS1 routine, which uses the normal ship-drawing
\ routine in LL9, and then the hanger background is drawn by sending an OSWORD
\ 248 command to the I/O processor.
\
\ ******************************************************************************

.HALL

 LDA #0                 \ Switch to the mode 1 palette for the space view,
 JSR SETVDU19           \ which is yellow (colour 1), red (colour 2) and cyan
                        \ (colour 3)

 LDA #0                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 0 (space
                        \ view)

 JSR DORND              \ Set A and X to random numbers

 BPL HA7                \ Jump to HA7 if A is positive (50% chance)

 AND #3                 \ Reduce A to a random number in the range 0-3

 STA T                  \ Set X = A * 8 + A
 ASL A                  \       = 9 * A
 ASL A                  \
 ASL A                  \ so X is a random number, either 0, 9, 18 or 27
 ADC T
 TAX

                        \ The following double loop calls the HAS1 routine three
                        \ times to display three ships on screen. For each call,
                        \ the values passed to HAS1 in XX15+2 to XX15 are taken
                        \ from the HATB table, depending on the value in X, as
                        \ follows:
                        \
                        \   * If X = 0,  pass bytes #0 to #2 of HATB to HAS1
                        \                then bytes #3 to #5
                        \                then bytes #6 to #8
                        \
                        \   * If X = 9,  pass bytes  #9 to #11 of HATB to HAS1
                        \                then bytes #12 to #14
                        \                then bytes #15 to #17
                        \
                        \   * If X = 18, pass bytes #18 to #20 of HATB to HAS1
                        \                then bytes #21 to #23
                        \                then bytes #24 to #26
                        \
                        \   * If X = 27, pass bytes #27 to #29 of HATB to HAS1
                        \                then bytes #30 to #32
                        \                then bytes #33 to #35
                        \
                        \ Note that the values are passed in reverse, so for the
                        \ first call, for example, where we pass bytes #0 to #2
                        \ of HATB to HAS1, we call HAS1 with:
                        \
                        \   XX15   = HATB+2
                        \   XX15+1 = HATB+1
                        \   XX15+2 = HATB

 LDY #3                 \ Set CNT2 = 3 to act as an outer loop counter going
 STY CNT2               \ from 3 to 1, so the HAL8 loop is run 3 times

.HAL8

 LDY #2                 \ Set Y = 2 to act as an inner loop counter going from
                        \ 2 to 0

.HAL9

 LDA HATB,X             \ Copy the X-th byte of HATB to the Y-th byte of XX15,
 STA XX15,Y             \ as described above

 INX                    \ Increment X to point to the next byte in HATB

 DEY                    \ Decrement Y to point to the previous byte in XX15

 BPL HAL9               \ Loop back to copy the next byte until we have copied
                        \ three of them (i.e. Y was 3 before the DEY)

 TXA                    \ Store X on the stack so we can retrieve it after the
 PHA                    \ call to HAS1 (as it contains the index of the next
                        \ byte in HATB

 JSR HAS1               \ Call HAS1 to draw this ship in the hanger

 PLA                    \ Restore the value of X, so X points to the next byte
 TAX                    \ in HATB after the three bytes we copied into XX15

 DEC CNT2               \ Decrement the outer loop counter in CNT2

 BNE HAL8               \ Loop back to HAL8 to do it 3 times, once for each ship
                        \ in the HATB table

 LDY #128               \ Set Y = 128 to send as byte #2 of the parameter block
                        \ to the OSWORD 248 command below, to tell the I/O
                        \ processor that there are multiple ships in the hanger

 BNE HA9                \ Jump to HA9 to display the ship hanger (this BNE is
                        \ effectively a JMP as Y is never zero)

.HA7

                        \ If we get here, A is a positive random number in the
                        \ range 0-127

 LSR A                  \ Set XX15+1 = A / 2 (random number 0-63)
 STA XX15+1

 JSR DORND              \ Set XX15 = random number 0-255
 STA XX15

 JSR DORND              \ Set XX15+2 = #SH3 + random number 0-3
 AND #3                 \
 ADC #SH3               \ which is the ship type of a Sidewinder, Mamba, Krait
 STA XX15+2             \ or Adder

 JSR HAS1               \ Call HAS1 to draw this ship in the hanger, with the
                        \ the following properties:
                        \
                        \   * Random x-coordinate from -63 to +63
                        \
                        \   * Randomly chosen Sidewinder, Mamba, Krait or Adder
                        \
                        \   * Random z-coordinate from +256 to +639

 LDY #0                 \ Set Y = 0 to use in the following instruction, to tell
                        \ the hanger-drawing routine that there is just one ship
                        \ in the hanger, so it knows not to draw between the
                        \ ships

.HA9

 STY HCNT               \ Store Y in HCNT to specify whether there are multiple
                        \ ships in the hanger

 JMP HANGER             \ Call HANGER to draw the hanger background and return
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: HAS1
\       Type: Subroutine
\   Category: Ship hanger
\    Summary: Draw a ship in the ship hanger
\
\ ------------------------------------------------------------------------------
\
\ The ship's position within the hanger is determined by the arguments and the
\ size of the ship's targetable area, as follows:
\
\   * The x-coordinate is (x_sign x_hi 0) from the arguments, so the ship can be
\     left of centre or right of centre
\
\   * The y-coordinate is negative and is lower down the screen for smaller
\     ships, so smaller ships are drawn closer to the ground (because they are)
\
\   * The z-coordinate is positive, with both z_hi (which is 1 or 2) and z_lo
\     coming from the arguments
\
\ Arguments:
\
\   XX15                Bits 0-7 = Ship's z_lo
\                       Bit 0    = Ship's x_sign
\
\   XX15+1              Bits 0-7 = Ship's x_hi
\                       Bit 0    = Ship's z_hi (1 if clear, or 2 if set)
\
\   XX15+2              Non-zero = Ship type to draw
\                       0        = Don't draw anything
\
\ ******************************************************************************

.HAS1

 JSR ZINF               \ Call ZINF to reset the INWK ship workspace and reset
                        \ the orientation vectors, with nosev pointing out of
                        \ the screen, so this puts the ship flat on the
                        \ horizontal deck (the y = 0 plane) with its nose
                        \ pointing towards us

 LDA XX15               \ Set z_lo = XX15
 STA INWK+6

 LSR A                  \ Set the sign bit of x_sign to bit 0 of A
 ROR INWK+2

 LDA XX15+1             \ Set x_hi = XX15+1
 STA INWK

 LSR A                  \ Set z_hi = 1 + bit 0 of XX15+1
 LDA #1
 ADC #0
 STA INWK+7

 LDA #%10000000         \ Set bit 7 of y_sign, so y is negative
 STA INWK+5

 STA RAT2               \ Set RAT2 = %10000000, so the yaw calls in HAL5 below
                        \ are negative

 LDA #&B                \ Set the ship line heap pointer in INWK(35 34) to point
 STA INWK+34            \ to &0B00

 JSR DORND              \ We now perform a random number of small angle (3.6
 STA XSAV               \ degree) rotations to spin the ship on the deck while
                        \ keeping it flat on the deck (a bit like spinning a
                        \ bottle), so we set XSAV to a random number between 0
                        \ and 255 for the number of small yaw rotations to
                        \ perform, so the ship could be pointing in any
                        \ direction by the time we're done

.HAL5

 LDX #21                \ Rotate (sidev_x, nosev_x) by a small angle (yaw)
 LDY #9
 JSR MVS5

 LDX #23                \ Rotate (sidev_y, nosev_y) by a small angle (yaw)
 LDY #11
 JSR MVS5

 LDX #25                \ Rotate (sidev_z, nosev_z) by a small angle (yaw)
 LDY #13
 JSR MVS5

 DEC XSAV               \ Decrement the yaw counter in XSAV

 BNE HAL5               \ Loop back to yaw a little more until we have yawed
                        \ by the number of times in XSAV

 LDY XX15+2             \ Set Y = XX15+2, the ship type of the ship we need to
                        \ draw

 BEQ HA1                \ If Y = 0, return from the subroutine (as HA1 contains
                        \ an RTS)

 TYA                    \ Set X = 2 * Y
 ASL A
 TAX

 LDA XX21-2,X           \ Set XX0(1 0) to the X-th address in the ship blueprint
 STA XX0                \ address lookup table at XX21, so XX0(1 0) now points
 LDA XX21-1,X           \ to the blueprint for the ship we need to draw
 STA XX0+1

 BEQ HA1                \ If the high byte of the blueprint address is 0, then
                        \ this is not a valid blueprint address, so return from
                        \ the subroutine (as HA1 contains an RTS)

 LDY #1                 \ Set Q = ship byte #1
 LDA (XX0),Y
 STA Q

 INY                    \ Set R = ship byte #2
 LDA (XX0),Y            \
 STA R                  \ so (R Q) contains the ship's targetable area, which is
                        \ a square number

 JSR LL5                \ Set Q = SQRT(R Q)

 LDA #100               \ Set y_lo = (100 - Q) / 2
 SBC Q                  \
 LSR A                  \ so the bigger the ship's targetable area, the smaller
 STA INWK+3             \ the magnitude of the y-coordinate, so because we set
                        \ y_sign to be negative above, this means smaller ships
                        \ are drawn lower down, i.e. closer to the ground, while
                        \ larger ships are drawn higher up, as you would expect

 JSR TIDY               \ Call TIDY to tidy up the orientation vectors, to
                        \ prevent the ship from getting elongated and out of
                        \ shape due to the imprecise nature of trigonometry
                        \ in assembly language

 JMP LL9                \ Jump to LL9 to display the ship and return from the
                        \ subroutine using a tail call

.HA1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TACTICS (Part 1 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Process missiles, both enemy missiles and our own
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section implements missile tactics and is entered at TA18 from the main
\ entry point below, if the current ship is a missile. Specifically:
\
\   * If E.C.M. is active, destroy the missile
\
\   * If the missile is hostile towards us, then check how close it is. If it
\     hasn't reached us, jump to part 3 so it can streak towards us, otherwise
\     we've been hit, so process a large amount of damage to our ship
\
\   * Otherwise see how close the missile is to its target. If it has not yet
\     reached its target, give the target a chance to activate its E.C.M. if it
\     has one, otherwise jump to TA19 with K3 set to the vector from the target
\     to the missile
\
\   * If it has reached its target and the target is the space station, destroy
\     the missile, potentially damaging us if we are nearby
\
\   * If it has reached its target and the target is a ship, destroy the missile
\     and the ship, potentially damaging us if we are nearby
\
\ ******************************************************************************

.TAX35

 LDA INWK
 ORA INWK+3
 ORA INWK+6
 BNE P%+7

 LDA #&50
 JSR OOPS

 LDX #&04
 BNE TA87

.TA34

                        \ If we get here, the missile is hostile

 LDA #0                 \ Set A to x_hi OR y_hi OR z_hi
 JSR MAS4

 BEQ P%+5               \ If A = 0 then the missile is very close to our ship,
                        \ so skip the following instruction

 JMP TN4                \ ???

 JSR TA87+3             \ The missile has hit our ship, so call TA87+3 to set
                        \ bit 7 of the missile's byte #31, which marks the
                        \ missile as being killed

 JSR EXNO3              \ Make the sound of the missile exploding

 LDA #250               \ Call OOPS to damage the ship by 250, which is a pretty
 JMP OOPS               \ big hit, and return from the subroutine using a tail
                        \ call

.TA18

                        \ This is the entry point for missile tactics and is
                        \ called from the main TACTICS routine below

 LDA ECMA               \ If an E.C.M. is currently active (either our's or an
 BNE TAX35              \ opponent's), jump to TAX35 to ???

 LDA INWK+32            \ Fetch the AI flag from byte #32 and if bit 6 is set
 ASL A                  \ (i.e. missile is hostile), jump up to TA34 to check
 BMI TA34               \ whether the missile has hit us

 LSR A                  \ Otherwise shift A right again. We know bits 6 and 7
                        \ are now clear, so this leaves bits 0-5. Bits 1-5
                        \ contain the target's slot number, and bit 0 is cleared
                        \ in FRMIS when a missile is launched, so A contains
                        \ the slot number shifted left by 1 (i.e. doubled) so we
                        \ can use it as an index for the two-byte address table
                        \ at UNIV

 TAX                    \ Copy the address of the target ship's data block from
 LDA UNIV,X             \ UNIV(X+1 X) to (A V)
 STA V
 LDA UNIV+1,X

 JSR VCSUB              \ Calculate vector K3 as follows:
                        \
                        \ K3(2 1 0) = (x_sign x_hi x_lo) - x-coordinate of
                        \ target ship
                        \
                        \ K3(5 4 3) = (y_sign y_hi z_lo) - y-coordinate of
                        \ target ship
                        \
                        \ K3(8 7 6) = (z_sign z_hi z_lo) - z-coordinate of
                        \ target ship

                        \ So K3 now contains the vector from the target ship to
                        \ the missile

 LDA K3+2               \ Set A = OR of all the sign and high bytes of the
 ORA K3+5               \ above, clearing bit 7 (i.e. ignore the signs)
 ORA K3+8
 AND #%01111111
 ORA K3+1
 ORA K3+4
 ORA K3+7

 BNE TA64               \ If the result is non-zero, then the missile is some
                        \ distance from the target, so jump down to TA64 see if
                        \ the target activates its E.C.M.

 LDA INWK+32            \ Fetch the AI flag from byte #32 and if only bits 7 and
 CMP #%10000010         \ 1 are set (AI is enabled and the target is slot 1, the
 BEQ TAX35               \ space station), jump to TAX35 to ???

 LDY #31                \ Fetch byte #31 (the exploding flag) of the target ship
 LDA (V),Y              \ into A

 BIT M32+1              \ M32 contains an LDY #32 instruction, so M32+1 contains
                        \ 32, so this instruction tests A with %00100000, which
                        \ checks bit 5 of A (the "already exploding?" bit)

 BNE TA35               \ If the target ship is already exploding, jump to TA35
                        \ to destroy this missile

 ORA #%10000000         \ Otherwise set bit 7 of the target's byte #31 to mark
 STA (V),Y              \ the ship as having been killed, so it explodes

.TA35

 LDA INWK               \ Set A = x_lo OR y_lo OR z_lo of the missile
 ORA INWK+3
 ORA INWK+6

 BNE P%+7               \ If A is non-zero then the missile is not near our
                        \ ship, so skip the next two instructions to avoid
                        \ damaging our ship

 LDA #80                \ Otherwise the missile just got destroyed near us, so
 JSR OOPS               \ call OOPS to damage the ship by 80, which is nowhere
                        \ near as bad as the 250 damage from a missile slamming
                        \ straight into us, but it's still pretty nasty

 LDA INWK+32            \ ???
 AND #%01111111
 LSR A
 TAX

.TA87

 JSR EXNO2              \ Call EXNO2 to process the fact that we have killed a
                        \ missile (so increase the kill tally, make an explosion
                        \ sound and so on)

 ASL INWK+31            \ Set bit 7 of the missile's byte #31 flag to mark it as
 SEC                    \ having been killed, so it explodes
 ROR INWK+31

.TA1

 RTS                    \ Return from the subroutine

.TA64

                        \ If we get here then the missile has not reached the
                        \ target

 JSR DORND              \ Set A and X to random numbers

 CMP #16                \ If A >= 16 (94% chance), jump down to TA19S with the
 BCS TA19S              \ vector from the target to the missile in K3

.M32

 LDY #32                \ Fetch byte #32 for the target and shift bit 0 (E.C.M.)
 LDA (V),Y              \ into the C flag
 LSR A

 BCS P%+5               \ If the C flag is set then the target has E.C.M.
                        \ fitted, so skip the next instruction

.TA19S

 JMP TA19               \ The target does not have E.C.M. fitted, so jump down
                        \ to TA19 with the vector from the target to the missile
                        \ in K3

 JMP ECBLB2             \ The target has E.C.M., so jump to ECBLB2 to set it
                        \ off, returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TACTICS (Part 2 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Escape pod, station, lone Thargon, safe-zone pirate
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section contains the main entry point at TACTICS, which is called from
\ part 2 of MVEIT for ships that have the AI flag set (i.e. bit 7 of byte #32).
\ This part does the following:
\
\   * If this is a missile, jump up to the missile code in part 1
\
\   * If this is the space station and it is hostile, consider spawning a cop
\     (6.2% chance, up to a maximum of seven) and we're done
\
\   * If this is the space station and it is not hostile, consider spawning
\     (0.8% chance if there are no Transporters around) a Transporter or Shuttle
\     (equal odds of each type) and we're done
\
\   * If this is a rock hermit, consider spawning (22% chance) a highly
\     aggressive and hostile Sidewinder, Mamba, Krait, Adder or Gecko (equal
\     odds of each type) and we're done
\
\   * Recharge the ship's energy banks by 1
\
\ Arguments:
\
\   X                   The ship type
\
\ ******************************************************************************

.TACTICS

 LDA #3                 \ Set RAT = 3, which is the magnitude we set the pitch
 STA RAT                \ or roll counter to in part 7 when turning a ship
                        \ towards a vector (a higher value giving a longer
                        \ turn). This value is not changed in the TACTICS
                        \ routine, but it is set to different values by the
                        \ DOCKIT routine

 LDA #4                 \ Set RAT2 = 4, which is the threshold below which we
 STA RAT2               \ don't apply pitch and roll to the ship (so a lower
                        \ value means we apply pitch and roll more often, and a
                        \ value of 0 means we always apply them). The value is
                        \ compared with double the high byte of sidev . XX15,
                        \ where XX15 is the vector from the ship to the enemy
                        \ or planet. This value is set to different values by
                        \ both the TACTICS and DOCKIT routines

 LDA #22                \ Set CNT2 = 22, which is the maximum angle beyond which
 STA CNT2               \ a ship will slow down to start turning towards its
                        \ prey (a lower value means a ship will start to slow
                        \ down even if its angle with the enemy ship is large,
                        \ which gives a tighter turn). This value is not changed
                        \ in the TACTICS routine, but it is set to different
                        \ values by the DOCKIT routine

 CPX #MSL               \ If this is a missile, jump up to TA18 to implement
 BEQ TA18               \ missile tactics

 CPX #SST               \ If this is not the space station, jump down to TA13
 BNE TA13

 LDA NEWB               \ This is the space station, so check whether bit 2 of
 AND #%00000100         \ the ship's NEWB flags is set, and if it is (i.e. the
 BNE TN5                \ station is hostile), jump to TN5 to spawn some cops

 LDA MANY+SHU+1         \ The station is not hostile, so check how many
 BNE TA1                \ Transporters there are in the vicinity, and if we
                        \ already have one, return from the subroutine (as TA1
                        \ contains an RTS)

                        \ If we get here then the station is not hostile, so we
                        \ can consider spawning a Transporter or Shuttle

 JSR DORND              \ Set A and X to random numbers

 CMP #253               \ If A < 253 (99.2% chance), return from the subroutine
 BCC TA1                \ (as TA1 contains an RTS)

 AND #1                 \ Set A = a random number that's either 0 or 1

 ADC #SHU-1             \ The C flag is set (as we didn't take the BCC above),
 TAX                    \ so this sets X to a value of either #SHU or #SHU + 1,
                        \ which is the ship type for a Shuttle or a Transporter

 BNE TN6                \ Jump to TN6 to spawn this ship type and return from
                        \ the subroutine using a tail call (this BNE is
                        \ effectively a JMP as A is never zero)

.TN5

                        \ We only call the tactics routine for the space station
                        \ when it is hostile, so if we get here then this is the
                        \ station, and we already know it's hostile, so we need
                        \ to spawn some cops

 JSR DORND              \ Set A and X to random numbers

 CMP #240               \ If A < 240 (93.8% chance), return from the subroutine
 BCC TA1                \ (as TA1 contains an RTS)

 LDA MANY+COPS          \ Check how many cops there are in the vicinity already,
 CMP #6                 \ and if there are 6 or more, return from the subroutine
 BCS TA22               \ (as TA22 contains an RTS)

 LDX #COPS              \ Set X to the ship type for a cop

.TN6

 LDA #%11110001         \ Set the AI flag to give the ship E.C.M., enable AI and
                        \ make it very aggressive (56 out of 63)

 JMP SFS1               \ Jump to SFS1 to spawn the ship, returning from the
                        \ subroutine using a tail call

.TA13

 CPX #HER               \ If this is not a rock hermit, jump down to TA17
 BNE TA17

 JSR DORND              \ Set A and X to random numbers

 CMP #200               \ If A < 200 (78% chance), return from the subroutine
 BCC TA22               \ (as TA22 contains an RTS)

 LDX #0                 \ Set byte #32 to %00000000 to disable AI, aggression
 STX INWK+32            \ and E.C.M.

 LDX #%00100100         \ ???

 STX NEWB               \ Set the ship's NEWB flags to %00000000 so the ship we
                        \ spawn below will inherit the default values from E%

 AND #3                 \ Set A = a random number that's in the range 0-3

 ADC #SH3               \ The C flag is set (as we didn't take the BCC above),
 TAX                    \ so this sets X to a random value between #SH3 + 1 and
                        \ #SH3 + 4, so that's a Sidewinder, Mamba, Krait, Adder
                        \ or Gecko

 JSR TN6                \ Call TN6 to spawn this ship with E.C.M., AI and a high
                        \ aggression (56 out of 63)

 LDA #0                 \ Set byte #32 to %00000000 to disable AI, aggression
 STA INWK+32            \ and E.C.M. (for the rock hermit)

 RTS                    \ Return from the subroutine

.TA17

 LDY #14                \ If the ship's energy is greater or equal to the
 LDA INWK+35            \ maximum value from the ship's blueprint pointed to by
 CMP (XX0),Y            \ XX0, then skip the next instruction
 BCS TA21

 INC INWK+35            \ The ship's energy is not at maximum, so recharge the
                        \ energy banks by 1

\ ******************************************************************************
\
\       Name: TACTICS (Part 3 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Calculate dot product to determine ship's aim
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section sets up some vectors and calculates dot products. Specifically:
\
\   * If this is a lone Thargon without a mothership, set it adrift aimlessly
\     and we're done
\
\   * If this is a trader, 80% of the time we're done, 20% of the time the
\     trader performs the same checks as the bounty hunter
\
\   * If this is a bounty hunter (or one of the 20% of traders) and we have been
\     really bad (i.e. a fugitive or serious offender), the ship becomes hostile
\     (if it isn't already)
\
\   * If the ship is not hostile, then either perform docking manouevres (if
\     it's docking) or fly towards the planet (if it isn't docking) and we're
\     done
\
\   * If the ship is hostile, and a pirate, and we are within the space station
\     safe zone, stop the pirate from attacking by removing all its aggression
\
\   * Calculate the dot product of the ship's nose vector (i.e. the direction it
\     is pointing) with the vector between us and the ship. This value will help
\     us work out later on whether the enemy ship is pointing towards us, and
\     therefore whether it can hit us with its lasers.
\
\ Other entry points:
\
\   GOPL                Make the ship head towards the planet
\
\ ******************************************************************************

.TA21

 CPX #TGL               \ If this is not a Thargon, jump down to TA14
 BNE TA14

 LDA MANY+THG           \ If there is at least one Thargoid in the vicinity,
 BNE TA14               \ jump down to TA14

 LSR INWK+32            \ This is a Thargon but there is no Thargoid mothership,
 ASL INWK+32            \ so clear bit 0 of the AI flag to disable its E.C.M.

 LSR INWK+27            \ And halve the Thargon's speed

.TA22

 RTS                    \ Return from the subroutine

.TA14

 JSR DORND              \ Set A and X to random numbers

 LDA NEWB               \ Extract bit 0 of the ship's NEWB flags into the C flag
 LSR A                  \ and jump to TN1 if it is clear (i.e. if this is not a
 BCC TN1                \ trader)

 CPX #50                \ This is a trader, so if X >= 50 (80% chance), return
 BCS TA22               \ from the subroutine (as TA22 contains an RTS)

.TN1

 LSR A                  \ Extract bit 1 of the ship's NEWB flags into the C flag
 BCC TN2                \ and jump to TN2 if it is clear (i.e. if this is not a
                        \ bounty hunter)

 LDX FIST               \ This is a bounty hunter, so check whether our FIST
 CPX #40                \ rating is < 40 (where 50 is a fugitive), and jump to
 BCC TN2                \ TN2 if we are not 100% evil

 LDA NEWB               \ We are a fugitive or a bad offender, and this ship is
 ORA #%00000100         \ a bounty hunter, so set bit 2 of the ship's NEWB flags
 STA NEWB               \ to make it hostile

 LSR A                  \ Shift A right twice so the next test in TN2 will check
 LSR A                  \ bit 2

.TN2

 LSR A                  \ Extract bit 2 of the ship's NEWB flags into the C flag
 BCS TN3                \ and jump to TN3 if it is set (i.e. if this ship is
                        \ hostile)

 LSR A                  \ The ship is not hostile, so extract bit 4 of the
 LSR A                  \ ship's NEWB flags into the C flag, and jump to GOPL if
 BCC GOPL               \ it is clear (i.e. if this ship is not docking)

 JMP DOCKIT             \ The ship is not hostile and is docking, so jump to
                        \ DOCKIT to apply the docking algorithm to this ship

.GOPL

 JSR SPS1               \ The ship is not hostile and it is not docking, so call
                        \ SPS1 to calculate the vector to the planet and store
                        \ it in XX15

 JMP TA151              \ Jump to TA151 to make the ship head towards the planet

.TN3

 LSR A                  \ Extract bit 2 of the ship's NEWB flags into the C flag
 BCC TN4                \ and jump to TN4 if it is clear (i.e. if this ship is
                        \ not a pirate)

 LDA SSPR               \ If we are not inside the space station safe zone, jump
 BEQ TN4                \ to TN4

                        \ If we get here then this is a pirate and we are inside
                        \ the space station safe zone

 LDA INWK+32            \ Set bits 0 and 7 of the AI flag in byte #32 (has AI
 AND #%10000001         \ enabled and has an E.C.M.)
 STA INWK+32

.TN4

 LDX #8                 \ We now want to copy the ship's x, y and z coordinates
                        \ from INWK to K3, so set up a counter for 9 bytes

.TAL1

 LDA INWK,X             \ Copy the X-th byte from INWK to the X-th byte of K3
 STA K3,X

 DEX                    \ Decrement the counter

 BPL TAL1               \ Loop back until we have copied all 9 bytes

.TA19

                        \ If this is a missile that's heading for its target
                        \ (not us, one of the other ships), then the missile
                        \ routine at TA18 above jumps here after setting K3 to
                        \ the vector from the target to the missile

 JSR TAS2               \ Normalise the vector in K3 and store the normalised
                        \ version in XX15, so XX15 contains the normalised
                        \ vector from our ship to the ship we are applying AI
                        \ tactics to (or the normalised vector from the target
                        \ to the missile - in both cases it's the vector from
                        \ the potential victim to the attacker)

 LDY #10                \ Set (A X) = nosev . XX15
 JSR TAS3

 STA CNT                \ Store the high byte of the dot product in CNT. The
                        \ bigger the value, the more aligned the two ships are,
                        \ with a maximum magnitude of 36 (96 * 96 >> 8). If CNT
                        \ is positive, the ships are facing in a similar
                        \ direction, if it's negative they are facing in
                        \ opposite directions

\ ******************************************************************************
\
\       Name: TACTICS (Part 4 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Check energy levels, maybe launch escape pod if low
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section works out what kind of condition the ship is in. Specifically:
\
\   * If this is an Anaconda, consider spawning (22% chance) a Worm (61% of the
\     time) or a Sidewinder (39% of the time)
\
\   * Rarely (2.5% chance) roll the ship by a noticeable amount
\
\   * If the ship has at least half its energy banks full, jump to part 6 to
\     consider firing the lasers
\
\   * If the ship is not into the last 1/8th of its energy, jump to part 5 to
\     consider firing a missile
\
\   * If the ship is into the last 1/8th of its energy, and this ship type has
\     an escape pod fitted, then rarely (10% chance) the ship launches an escape
\     pod and is left drifting in space
\
\ ******************************************************************************

 LDA TYPE               \ If this is not a missile, skip the following
 CMP #MSL               \ instruction
 BNE P%+5

 JMP TA20               \ This is a missile, so jump down to TA20 to get
                        \ straight into some aggressive manoeuvring

 CMP #ANA               \ If this is not an Anaconda, jump down to TN7 to skip
 BNE TN7                \ the following

 JSR DORND              \ Set A and X to random numbers

 CMP #200               \ If A < 200 (78% chance), jump down to TN7 to skip the
 BCC TN7                \ following

 JSR DORND              \ Set A and X to random numbers

 LDX #WRM               \ Set X to the ship type for a Worm

 CMP #100               \ If A >= 100 (61% chance), skip the following
 BCS P%+4               \ instruction

 LDX #SH3               \ Set X to the ship type for a Sidewinder

 JMP TN6                \ Jump to TN6 to spawn the Worm or Sidewinder and return
                        \ from the subroutine using a tail call

.TN7

 JSR DORND              \ Set A and X to random numbers

 CMP #250               \ If A < 250 (97.5% chance), jump down to TA7 to skip
 BCC TA7                \ the following

 JSR DORND              \ Set A and X to random numbers

 ORA #104               \ Bump A up to at least 104 and store in the roll
 STA INWK+29            \ counter, to gives the ship a noticeable roll

.TA7

 LDY #14                \ Set A = the ship's maximum energy / 2
 LDA (XX0),Y
 LSR A

 CMP INWK+35            \ If the ship's current energy in byte #35 > A, i.e. the
 BCC TA3                \ ship has at least half of its energy banks charged,
                        \ jump down to TA3

 LSR A                  \ If the ship's current energy in byte #35 > A / 4, i.e.
 LSR A                  \ the ship is not into the last 1/8th of its energy,
 CMP INWK+35            \ jump down to ta3 to consider firing a missile
 BCC ta3

 JSR DORND              \ Set A and X to random numbers

 CMP #230               \ If A < 230 (90% chance), jump down to ta3 to consider
 BCC ta3                \ firing a missile

 LDX TYPE               \ Fetch the ship blueprint's default NEWB flags from the
 LDA E%-1,X             \ table at E%, and if bit 7 is clear (i.e. this ship
 BPL ta3                \ does not have an escape pod), jump to ta3 to skip the
                        \ spawning of an escape pod

                        \ By this point, the ship has run out of both energy and
                        \ luck, so it's time to bail

 LDA NEWB               \ ???
 AND #&F0
 STA NEWB
 LDY #&24
 STA (INF),Y

 LDA #0                 \ Set the AI flag to 0 to disable AI, hostility and
 STA INWK+32            \ E.C.M., so the ship's a sitting duck

 JMP SESCP              \ Jump to SESCP to spawn an escape pod from the ship,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TACTICS (Part 5 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Consider whether to launch a missile at us
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section considers whether to launch a missile. Specifically:
\
\   * If the ship doesn't have any missiles, skip to the next part
\
\   * If an E.C.M. is firing, skip to the next part
\
\   * Randomly decide whether to fire a missile (or, in the case of Thargoids,
\     release a Thargon), and if we do, we're done
\
\ ******************************************************************************

.ta3

                        \ If we get here then the ship has less than half energy
                        \ so there may not be enough juice for lasers, but let's
                        \ see if we can fire a missile

 LDA INWK+31            \ Set A = bits 0-2 of byte #31, the number of missiles
 AND #%00000111         \ the ship has left

 BEQ TA3                \ If it doesn't have any missiles, jump to TA3

 STA T                  \ Store the number of missiles in T

 JSR DORND              \ Set A and X to random numbers

 AND #31                \ Restrict A to a random number in the range 0-31

 CMP T                  \ If A >= T, which is quite likely, though less likely
 BCS TA3                \ with higher numbers of missiles, jump to TA3

 LDA ECMA               \ If an E.C.M. is currently active (either our's or an
 BNE TA3                \ opponent's), jump to TA3

 DEC INWK+31            \ We're done with the checks, so it's time to fire off a
                        \ missile, so reduce the missile count in byte #31 by 1

 LDA TYPE               \ If this is not a Thargoid, jump down to TA16 to launch
 CMP #THG               \ a missile
 BNE TA16

 LDX #TGL               \ This is a Thargoid, so instead of launching a missile,
 LDA INWK+32            \ the mothership launches a Thargon, so call SFS1 to
 JMP SFS1               \ spawn a Thargon from the parent ship, and return from
                        \ the subroutine using a tail call

.TA16

 JMP SFRMIS             \ Jump to SFRMIS to spawn a missile as a child of the
                        \ current ship, make a noise and print a message warning
                        \ of incoming missiles, and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: TACTICS (Part 6 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Consider firing a laser at us, if aim is true
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section looks at potentially firing the ship's laser at us. Specifically:
\
\   * If the ship is not pointing at us, skip to the next part
\
\   * If the ship is pointing at us but not accurately, fire its laser at us and
\     skip to the next part
\
\   * If we are in the ship's crosshairs, register some damage to our ship, slow
\     down the attacking ship, make the noise of us being hit by laser fire, and
\     we're done
\
\ ******************************************************************************

.TA3

                        \ If we get here then the ship either has plenty of
                        \ energy, or levels are low but it couldn't manage to
                        \ launch a missile, so maybe we can fire the laser?

 LDA #0                 \ Set A to x_hi OR y_hi OR z_hi
 JSR MAS4

 AND #%11100000         \ If any of the hi bytes have any of bits 5-7 set, then
 BNE TA4                \ jump to TA4 to skip the laser checks, as the ship is
                        \ too far away from us to hit us with a laser

 LDX CNT                \ Set X = the dot product set above in CNT. If this is
                        \ positive, this ship and our ship are facing in similar
                        \ directions, but if it's negative then we are facing
                        \ each other, so for us to be in the enemy ship's line
                        \ of fire, X needs to be negative. The value in X can
                        \ have a maximum magnitude of 36, which would mean we
                        \ were facing each other square on, so in the following
                        \ code we check X like this:
                        \
                        \   X = 0 to -31, we are not in the enemy ship's line
                        \       of fire, so they can't shoot at us
                        \
                        \   X = -32 to -34, we are in the enemy ship's line
                        \       of fire, so they can shoot at us, but they can't
                        \       hit us as we're not dead in their crosshairs
                        \
                        \   X = -35 to -36, we are bang in the middle of the
                        \       enemy ship's crosshairs, so they can not only
                        \       shoot us, they can hit us

 CPX #160               \ If X < 160, i.e. X > -32, then we are not in the enemy
 BCC TA4                \ ship's line of fire, so jump to TA4 to skip the laser
                        \ checks

 LDY #19                \ Fetch the enemy ship's byte #19 from their ship's
 LDA (XX0),Y            \ blueprint into A

 AND #%11111000         \ Extract bits 3-7, which contain the enemy's laser
                        \ power

 BEQ TA4                \ If the enemy has no laser power, jump to TA4 to skip
                        \ the laser checks

 LDA INWK+31            \ Set bit 6 in byte #31 to denote that the ship is
 ORA #%01000000         \ firing its laser at us
 STA INWK+31

 CPX #163               \ If X < 163, i.e. X > -35, then we are not in the enemy
 BCC TA4                \ ship's crosshairs, so jump to TA4 to skip the laser

 LDA (XX0),Y            \ Fetch the enemy ship's byte #19 from their ship's
                        \ blueprint into A

 LSR A                  \ Halve the enemy ship's byte #19 (which contains both
                        \ the laser power and number of missiles) to get the
                        \ amount of damage we should take

 JSR OOPS               \ Call OOPS to take some damage, which could do anything
                        \ from reducing the shields and energy, all the way to
                        \ losing cargo or dying (if the latter, we don't come
                        \ back from this subroutine)

 DEC INWK+28            \ Halve the attacking ship's acceleration in byte #28

 LDA ECMA               \ If an E.C.M. is currently active (either our's or an
 BNE TA9-1              \ opponent's), return from the subroutine without making
                        \ the laser-strike sound (as TA9-1 contains an RTS)

 JSR BEING_HIT_NOISE    \ ???

\ ******************************************************************************
\
\       Name: TACTICS (Part 7 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Set pitch, roll, and acceleration
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section looks at manoeuvring the ship. Specifically:
\
\   * Work out which direction the ship should be moving, depending on the type
\     of ship, where it is, which direction it is pointing, and how aggressive
\     it is
\
\   * Set the pitch and roll counters to head in that direction
\
\   * Speed up or slow down, depending on where the ship is in relation to us
\
\ Other entry points:
\
\   TA151               Make the ship head towards the planet
\
\ ******************************************************************************

.TA4

 LDA INWK+7             \ If z_hi >= 3 then the ship is quite far away, so jump
 CMP #3                 \ down to TA5
 BCS TA5

 LDA INWK+1             \ Otherwise set A = x_hi OR y_hi and extract bits 1-7
 ORA INWK+4
 AND #%11111110

 BEQ TA15               \ If A = 0 then the ship is pretty close to us, so jump
                        \ to TA15 so it heads away from us

.TA5

                        \ If we get here then the ship is quite far away

 JSR DORND              \ Set A and X to random numbers

 ORA #%10000000         \ Set bit 7 of A

 CMP INWK+32            \ If A >= byte #32 (the ship's AI flag) then jump down
 BCS TA15               \ to TA15 so it heads away from us

                        \ We get here if A < byte #32, and the chances of this
                        \ being true are greater with high values of byte #32.
                        \ In other words, higher byte #32 values increase the
                        \ chances of a ship changing direction to head towards
                        \ us - or, to put it another way, ships with higher
                        \ byte #32 values are spoiling for a fight. Thargoids
                        \ have byte #32 set to 255, which explains an awful lot

.TA20

                        \ If this is a missile we will have jumped straight
                        \ here, but we also get here if the ship is either far
                        \ away and aggressive, or not too close

 JSR TAS6               \ Call TAS6 to negate the vector in XX15 so it points in
                        \ the opposite direction

 LDA CNT                \ Change the sign of the dot product in CNT, so now it's
 EOR #%10000000         \ positive if the ships are facing each other, and
                        \ negative if they are facing the same way

.TA152

 STA CNT                \ Update CNT with the new value in A

.TA15

                        \ If we get here, then one of the following is true:
                        \
                        \   * This is a trader and XX15 is pointing towards the
                        \     planet
                        \
                        \   * The ship is pretty close to us, or it's just not
                        \     very aggressive (though there is a random factor
                        \     at play here too). XX15 is still pointing from our
                        \     ship towards the enemy ship
                        \
                        \   * The ship is aggressive (though again, there's an
                        \     element of randomness here). XX15 is pointing from
                        \     the enemy ship towards our ship
                        \
                        \   * This is a missile heading for a target. XX15 is
                        \     pointing from the missile towards the target
                        \
                        \ We now want to move the ship in the direction of XX15,
                        \ which will make aggressive ships head towards us, and
                        \ ships that are too close turn away. Peaceful traders,
                        \ meanwhile, head off towards the planet in search of a
                        \ space station, and missiles home in on their targets

 LDY #16                \ Set (A X) = roofv . XX15
 JSR TAS3               \
                        \ This will be positive if XX15 is pointing in the same
                        \ direction as an arrow out of the top of the ship, in
                        \ other words if the ship should pull up to head in the
                        \ direction of XX15

 TAX                    \ Copy A into X so we can retrieve it below

 EOR #%10000000         \ Give the ship's pitch counter the opposite sign to the
 AND #%10000000         \ dot product result, with a value of 0
 STA INWK+30

 TXA                    \ Retrieve the original value of A from X

 ASL A                  \ Shift A left to double it and drop the sign bit

 CMP RAT2               \ If A < RAT2, skip to TA11 (so if RAT2 = 0, we always
 BCC TA11               \ set the pitch counter to RAT)

 LDA RAT                \ Set the magnitude of the ship's pitch counter to RAT
 ORA INWK+30            \ (we already set the sign above)
 STA INWK+30

.TA11

 LDA INWK+29            \ Fetch the roll counter from byte #29 into A

 ASL A                  \ Shift A left to double it and drop the sign bit

 CMP #32                \ If A >= 32 then jump to TA12, as the ship is already
 BCS TA12               \ in the process of rolling ???

 LDY #22                \ Set (A X) = sidev . XX15
 JSR TAS3               \
                        \ This will be positive if XX15 is pointing in the same
                        \ direction as an arrow out of the right side of the
                        \ ship, in other words if the ship should roll right to
                        \ head in the direction of XX15

 TAX                    \ Copy A into X so we can retrieve it below

 EOR INWK+30            \ Give the ship's roll counter a positive sign if the
 AND #%10000000         \ pitch counter and dot product have different signs,
 EOR #%10000000         \ negative if they have the same sign, with a value of 0
 STA INWK+29

 TXA                    \ Retrieve the original value of A from X

 ASL A                  \ Shift A left to double it and drop the sign bit

 CMP RAT2               \ If A < RAT2, skip to TA12 (so if RAT2 = 0, we always
 BCC TA12               \ set the roll counter to RAT)

 LDA RAT                \ Set the magnitude of the ship's roll counter to RAT
 ORA INWK+29            \ (we already set the sign above)
 STA INWK+29

.TA12

.TA6

 LDA CNT                \ Fetch the dot product, and if it's negative jump to
 BMI TA9                \ TA9, as the ships are facing away from each other and
                        \ the ship might want to slow down to take another shot

 CMP CNT2               \ The dot product is positive, so the ships are facing
 BCC TA9                \ each other. If A < CNT2 then the ships are not heading
                        \ directly towards each other, so jump to TA9 to slow
                        \ down

.PH10E

 LDA #3                 \ Otherwise set the acceleration in byte #28 to 3
 STA INWK+28

 RTS                    \ Return from the subroutine

.TA9

 AND #%01111111         \ Clear the sign bit of the dot product in A

 CMP #18                \ If A < 18 then the ship is way off the XX15 vector, so
 BCC TA10               \ return from the subroutine (TA10 contains an RTS)
                        \ without slowing down, as it still has quite a bit of
                        \ turning to do to get on course

 LDA #&FF               \ Otherwise set A = -1

 LDX TYPE               \ If this is not a missile then skip the ASL instruction
 CPX #MSL
 BNE P%+3

 ASL A                  \ This is a missile, so set A = -2, as missiles are more
                        \ nimble and can brake more quickly

 STA INWK+28            \ Set the ship's acceleration to A

.TA10

 RTS                    \ Return from the subroutine

.TA151

                        \ This is called from part 3 with the vector to the
                        \ planet in XX15, when we want the ship to turn towards
                        \ the planet. It does the same dot product calculation
                        \ as part 3, but it can also change the value of RAT2
                        \ so that roll and pitch is always applied

 LDY #10                \ Set (A X) = nosev . XX15
 JSR TAS3               \
                        \ The bigger the value of the dot product, the more
                        \ aligned the two vectors are, with a maximum magnitude
                        \ in A of 36 (96 * 96 >> 8). If A is positive, the
                        \ vectors are facing in a similar direction, if it's
                        \ negative they are facing in opposite directions

 CMP #&98               \ If A is positive or A <= -24, jump to ttt
 BCC ttt

 LDX #0                 \ A > -24, which means the vectors are facing in
 STX RAT2               \ opposite directions but are quite aligned, so set
                        \ RAT2 = 0 instead of the default value of 4, so we
                        \ always apply roll and pitch when we turn the ship
                        \ towards the planet

.ttt

 JMP TA152              \ Jump to TA152 to store A in CNT and move the ship in
                        \ the direction of XX15

\ ******************************************************************************
\
\       Name: DOCKIT
\       Type: Subroutine
\   Category: Flight
\    Summary: Apply docking manoeuvres to the ship in INWK
\  Deep dive: The docking computer
\
\ ******************************************************************************

.DOCKIT

 LDA #6                 \ Set RAT2 = 6, which is the threshold below which we
 STA RAT2               \ don't apply pitch and roll to the ship (so a lower
                        \ value means we apply pitch and roll more often, and a
                        \ value of 0 means we always apply them). The value is
                        \ compared with double the high byte of sidev . XX15,
                        \ where XX15 is the vector from the ship to the station

 LSR A                  \ Set RAT = 2, which is the magnitude we set the pitch
 STA RAT                \ or roll counter to in part 7 when turning a ship
                        \ towards a vector (a higher value giving a longer
                        \ turn)

 LDA #29                \ Set CNT2 = 29, which is the maximum angle beyond which
 STA CNT2               \ a ship will slow down to start turning towards its
                        \ prey (a lower value means a ship will start to slow
                        \ down even if its angle with the enemy ship is large,
                        \ which gives a tighter turn)

 LDA SSPR               \ If we are inside the space station safe zone, skip the
 BNE P%+5               \ next instruction

.GOPLS

 JMP GOPL               \ Jump to GOPL to make the ship head towards the planet

 JSR VCSU1              \ If we get here then we are in the space station safe
                        \ zone, so call VCSU1 to calculate the following, where
                        \ the station is at coordinates (station_x, station_y,
                        \ station_z):
                        \
                        \   K3(2 1 0) = (x_sign x_hi x_lo) - station_x
                        \
                        \   K3(5 4 3) = (y_sign y_hi z_lo) - station_y
                        \
                        \   K3(8 7 6) = (z_sign z_hi z_lo) - station_z
                        \
                        \ so K3 contains the vector from the station to the ship

 LDA K3+2               \ If any of the top bytes of the K3 results above are
 ORA K3+5               \ non-zero (after removing the sign bits), jump to GOPL
 ORA K3+8               \ via GOPLS to make the ship head towards the planet, as
 AND #%01111111         \ this will aim the ship in the general direction of the
 BNE GOPLS              \ station (it's too far away for anything more accurate)

 JSR TA2                \ Call TA2 to calculate the length of the vector in K3
                        \ (ignoring the low coordinates), returning it in Q

 LDA Q                  \ Store the value of Q in K, so K now contains the
 STA K                  \ distance between station and the ship

 JSR TAS2               \ Call TAS2 to normalise the vector in K3, returning the
                        \ normalised version in XX15, so XX15 contains the unit
                        \ vector pointing from the station to the ship

 LDY #10                \ Call TAS4 to calculate:
 JSR TAS4               \
                        \   (A X) = nosev . XX15
                        \
                        \ where nosev is the nose vector of the space station,
                        \ so this is the dot product of the station to ship
                        \ vector with the station's nosev (which points straight
                        \ out into space, out of the docking slot), and because
                        \ both vectors are unit vectors, the following is also
                        \ true:
                        \
                        \   (A X) = cos(t)
                        \
                        \ where t is the angle between the two vectors
                        \
                        \ If the dot product is positive, that means the vector
                        \ from the station to the ship and the nosev sticking
                        \ out of the docking slot are facing in a broadly
                        \ similar direction (so the ship is essentially heading
                        \ for the slot, which is facing towards the ship), and
                        \ if it's negative they are facing in broadly opposite
                        \ directions (so the station slot is on the opposite
                        \ side of the station as the ship approaches)

 BMI PH1                \ If the dot product is negative, i.e. the station slot
                        \ is on the opposite side, jump to PH1 to fly towards
                        \ the ideal docking position, some way in front of the
                        \ slot

 CMP #35                \ If the dot product < 35, jump to PH1 to fly towards
 BCC PH1                \ the ideal docking position, some way in front of the
                        \ slot, as there is a large angle between the vector
                        \ from the station to the ship and the station's nosev,
                        \ so the angle of approach is not very optimal
                        \
                        \ Specifically, as the unit vector length is 96 in our
                        \ vector system,
                        \
                        \   (A X) = cos(t) < 35 / 96
                        \
                        \ so:
                        \
                        \   t > arccos(35 / 96) = 68.6 degrees
                        \
                        \ so the ship is coming in from the side of the station
                        \ at an angle between 68.6 and 90 degrees off the
                        \ optimal entry angle

                        \ If we get here, the slot is on the same side as the
                        \ ship and the angle of approach is less than 68.6
                        \ degrees, so we're heading in pretty much the correct
                        \ direction for a good approach to the docking slot

 LDY #10                \ Call TAS3 to calculate:
 JSR TAS3               \
                        \   (A X) = nosev . XX15
                        \
                        \ where nosev is the nose vector of the ship, so this is
                        \ the dot product of the station to ship vector with the
                        \ ship's nosev, and is a measure of how close to the
                        \ station the ship is pointing, with negative meaning it
                        \ is pointing at the station, and positive meaning it is
                        \ pointing away from the station

 CMP #&A2               \ If the dot product is in the range 0 to -34, jump to
 BCS PH3                \ PH3 to refine our approach, as we are pointing towards
                        \ the station

                        \ If we get here, then we are not pointing straight at
                        \ the station, so check how close we are

 LDA K                  \ Fetch the distance to the station into A

\BEQ PH10               \ This instruction is commented out in the original
                        \ source

 CMP #157               \ If A < 157, jump to PH2 to turn away from the station,
 BCC PH2                \ as we are too close

 LDA TYPE               \ Fetch the ship type into A

 BMI PH3                \ If bit 7 is set, then that means the ship type was set
                        \ to -96 in the DOKEY routine when we switched on our
                        \ docking compter, so this is us auto-docking our Cobra,
                        \ so jump to PH3 to refine our approach. Otherwise this
                        \ is an NPC trying to dock, so turn away from the
                        \ station

.PH2

                        \ If we get here then we turn away from the station and
                        \ slow right down, effectively aborting this approach
                        \ attempt

 JSR TAS6               \ Call TAS6 to negate the vector in XX15 so it points in
                        \ the opposite direction, away from from the station and
                        \ towards the ship

 JSR TA151              \ Call TA151 to make the ship head in the direction of
                        \ XX15, which makes the ship turn away from the station

.PH22

                        \ If we get here then we slam on the brakes and slow
                        \ right down

 LDX #0                 \ Set the acceleration in byte #28 to 0
 STX INWK+28

 INX                    \ Set the speed in byte #28 to 1
 STX INWK+27

 RTS                    \ Return from the subroutine

.PH1

                        \ If we get here then the slot is on the opposite side
                        \ of the station to the ship, or it's on the same side
                        \ and the approach angle is not optimal, so we just fly
                        \ towards the station, aiming for the ideal docking
                        \ position some distance in front of the slot

 JSR VCSU1              \ Call VCSU1 to set K3 to the vector from the station to
                        \ the ship

 JSR DCS1               \ Call DCS1 twice to calculate the vector from the ideal
 JSR DCS1               \ docking position to the ship, where the ideal docking
                        \ position is straight out of the docking slot at a
                        \ distance of 8 unit vectors from the centre of the
                        \ station

 JSR TAS2               \ Call TAS2 to normalise the vector in K3, returning the
                        \ normalised version in XX15

 JSR TAS6               \ Call TAS6 to negate the vector in XX15 so it points in
                        \ the opposite direction

 JMP TA151              \ Call TA151 to make the ship head in the direction of
                        \ XX15, which makes the ship turn towards the ideal
                        \ docking position, and return from the subroutine using
                        \ a tail call

.TN11

                        \ If we get here, we accelerate and apply a full
                        \ clockwise roll (which matches the space station's
                        \ roll)

 INC INWK+28            \ Increment the acceleration in byte #28

 LDA #%01111111         \ Set the roll counter to a positive roll with no
 STA INWK+29            \ damping, to match the space station's roll

 BNE TN13               \ Jump down to TN13 (this BNE is effectively a JMP as
                        \ A will never be zero)

.PH3

                        \ If we get here, we refine our approach using pitch and
                        \ roll to aim for the station

 LDX #0                 \ Set RAT2 = 0
 STX RAT2

 STX INWK+30            \ Set the pitch counter to 0 to stop any pitching

 LDA TYPE               \ If this is not our ship's docking computer, but is an
 BPL PH32               \ NPC ship trying to dock, jump to PH32

                        \ In the following, ship_x and ship_y are the x and
                        \ y-coordinates of XX15, the vector from the station to
                        \ the ship

 EOR XX15               \ A is negative, so this sets the sign of A to the same
 EOR XX15+1             \ as -XX15 * XX15+1, or -ship_x * ship_y

 ASL A                  \ Shift the sign bit into the C flag, so the C flag has
                        \ the following sign:
                        \
                        \   * Positive if ship_x and ship_y have different signs
                        \   * Negative if ship_x and ship_y have the same sign

 LDA #2                 \ Set A = +2 or -2, giving it the sign in the C flag,
 ROR A                  \ and store it in byte #29, the roll counter, so that
 STA INWK+29            \ the ship rolls towards the station

 LDA XX15               \ If |ship_x * 2| >= 12, i.e. |ship_x| >= 6, then jump
 ASL A                  \ to PH22 to slow right down and return from the
 CMP #12                \ subroutine, as the station is not in our sights
 BCS PH22

 LDA XX15+1             \ Set A = +2 or -2, giving it the same sign as ship_y,
 ASL A                  \ and store it in byte #30, the pitch counter, so that
 LDA #2                 \ the ship pitches towards the station
 ROR A
 STA INWK+30

 LDA XX15+1             \ If |ship_y * 2| >= 12, i.e. |ship_y| >= 6, then jump
 ASL A                  \ to PH22 to slow right down and return from the
 CMP #12                \ subroutine, as the station is not in our sights
 BCS PH22

.PH32

                        \ If we get here, we try to match the station roll

 STX INWK+29            \ Set the roll counter to 0 to stop any pitching

 LDA INWK+22            \ Set XX15 = sidev_x_hi
 STA XX15

 LDA INWK+24            \ Set XX15+1 = sidev_y_hi
 STA XX15+1

 LDA INWK+26            \ Set XX15+2 = sidev_z_hi
 STA XX15+2             \
                        \ so XX15 contains the sidev vector of the ship

 LDY #16                \ Call TAS4 to calculate:
 JSR TAS4               \
                        \   (A X) = roofv . XX15
                        \
                        \ where roofv is the roof vector of the space station.
                        \ To dock with the slot horizontal, we want roofv to be
                        \ pointing off to the side, i.e. parallel to the ship's
                        \ sidev vector, which means we want the dot product to
                        \ be large (it can be positive or negative, as roofv can
                        \ point left or right - it just needs to be parallel to
                        \ the ship's sidev)

 ASL A                  \ If |A * 2| >= 66, i.e. |A| >= 33, then the ship is
 CMP #66                \ lined up with the slot, so jump to TN11 to accelerate
 BCS TN11               \ and roll clockwise (a positive roll) before jumping
                        \ down to TN13 to check if we're docked yet

 JSR PH22               \ Call PH22 to slow right down, as we haven't yet
                        \ matched the station's roll

.TN13

                        \ If we get here, we check to see if we have docked

 LDA K3+10              \ If K3+10 is non-zero, skip to TNRTS, to return from
 BNE TNRTS              \ the subroutine
                        \
                        \ I have to say I have no idea what K3+10 contains, as
                        \ it isn't mentioned anywhere in the whole codebase
                        \ apart from here, but it does share a location with
                        \ XX2+10, so it will sometimes be non-zero (specifically
                        \ when face #10 in the ship we're drawing is visible,
                        \ which probably happens quite a lot). This would seem
                        \ to affect whether an NPC ship can dock, as that's the
                        \ code that gets skipped if K3+10 is non-zero, but as
                        \ to what this means... that's not yet clear

 ASL NEWB               \ Set bit 7 of the ship's NEWB flags to indicate that
 SEC                    \ the ship has now docked, which only has meaning if
 ROR NEWB               \ this is an NPC trying to dock

.TNRTS

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: VCSU1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate vector K3(8 0) = [x y z] - coordinates of the sun or
\             space station
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   K3(2 1 0) = (x_sign x_hi x_lo) - x-coordinate of the sun or space station
\
\   K3(5 4 3) = (y_sign y_hi z_lo) - y-coordinate of the sun or space station
\
\   K3(8 7 6) = (z_sign z_hi z_lo) - z-coordinate of the sun or space station
\
\ where the first coordinate is from the ship data block in INWK, and the second
\ coordinate is from the sun or space station's ship data block which they
\ share.
\
\ ******************************************************************************

.VCSU1

 LDA #LO(K%+NI%)        \ Set the low byte of V(1 0) to point to the coordinates
 STA V                  \ of the sun or space station

 LDA #HI(K%+NI%)        \ Set A to the high byte of the address of the
                        \ coordinates of the sun or space station

                        \ Fall through into VCSUB to calculate:
                        \
                        \   K3(2 1 0) = (x_sign x_hi x_lo) - x-coordinate of sun
                        \               or space station
                        \
                        \   K3(2 1 0) = (x_sign x_hi x_lo) - x-coordinate of sun
                        \               or space station
                        \
                        \   K3(8 7 6) = (z_sign z_hi z_lo) - z-coordinate of sun
                        \               or space station

\ ******************************************************************************
\
\       Name: VCSUB
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate vector K3(8 0) = [x y z] - coordinates in (A V)
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   K3(2 1 0) = (x_sign x_hi x_lo) - x-coordinate in (A V)
\
\   K3(5 4 3) = (y_sign y_hi z_lo) - y-coordinate in (A V)
\
\   K3(8 7 6) = (z_sign z_hi z_lo) - z-coordinate in (A V)
\
\ where the first coordinate is from the ship data block in INWK, and the second
\ coordinate is from the ship data block pointed to by (A V).
\
\ ******************************************************************************

.VCSUB

 STA V+1                \ Set the low byte of V(1 0) to A, so now V(1 0) = (A V)

 LDY #2                 \ K3(2 1 0) = (x_sign x_hi x_lo) - x-coordinate in data
 JSR TAS1               \ block at V(1 0)

 LDY #5                 \ K3(5 4 3) = (y_sign y_hi z_lo) - y-coordinate of data
 JSR TAS1               \ block at V(1 0)

 LDY #8                 \ Fall through into TAS1 to calculate the final result:
                        \
                        \ K3(8 7 6) = (z_sign z_hi z_lo) - z-coordinate of data
                        \ block at V(1 0)

\ ******************************************************************************
\
\       Name: TAS1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate K3 = (x_sign x_hi x_lo) - V(1 0)
\
\ ------------------------------------------------------------------------------
\
\ Calculate one of the following, depending on the value in Y:
\
\   K3(2 1 0) = (x_sign x_hi x_lo) - x-coordinate in V(1 0)
\
\   K3(5 4 3) = (y_sign y_hi z_lo) - y-coordinate in V(1 0)
\
\   K3(8 7 6) = (z_sign z_hi z_lo) - z-coordinate in V(1 0)
\
\ where the first coordinate is from the ship data block in INWK, and the second
\ coordinate is from the ship data block pointed to by V(1 0).
\
\ Arguments:
\
\   V(1 0)              The address of the ship data block to subtract
\
\   Y                   The coordinate in the V(1 0) block to subtract:
\
\                         * If Y = 2, subtract the x-coordinate and store the
\                           result in K3(2 1 0)
\
\                         * If Y = 5, subtract the y-coordinate and store the
\                           result in K3(5 4 3)
\
\                         * If Y = 8, subtract the z-coordinate and store the
\                           result in K3(8 7 6)
\
\ ******************************************************************************

.TAS1

 LDA (V),Y              \ Copy the sign byte of the V(1 0) coordinate into K+3,
 EOR #%10000000         \ flipping it in the process
 STA K+3

 DEY                    \ Copy the high byte of the V(1 0) coordinate into K+2
 LDA (V),Y
 STA K+2

 DEY                    \ Copy the high byte of the V(1 0) coordinate into K+1,
 LDA (V),Y              \ so now:
 STA K+1                \
                        \   K(3 2 1) = - coordinate in V(1 0)

 STY U                  \ Copy the index (now 0, 3 or 6) into U and X
 LDX U

 JSR MVT3               \ Call MVT3 to add the same coordinates, but this time
                        \ from INWK, so this would look like this for the
                        \ x-axis:
                        \
                        \   K(3 2 1) = (x_sign x_hi x_lo) + K(3 2 1)
                        \            = (x_sign x_hi x_lo) - coordinate in V(1 0)

 LDY U                  \ Restore the index into Y, though this instruction has
                        \ no effect, as Y is not used again, either here or
                        \ following calls to this routine

 STA K3+2,X             \ Store K(3 2 1) in K3+X(2 1 0), starting with the sign
                        \ byte

 LDA K+2                \ And then doing the high byte
 STA K3+1,X

 LDA K+1                \ And finally the low byte
 STA K3,X

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TAS4
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the dot product of XX15 and one of the space station's
\             orientation vectors
\
\ ------------------------------------------------------------------------------
\
\ Calculate the dot product of the vector in XX15 and one of the space station's
\ orientation vectors, as determined by the value of Y. If vect is the space
\ station orientation vector, we calculate this:
\
\   (A X) = vect . XX15
\         = vect_x * XX15 + vect_y * XX15+1 + vect_z * XX15+2
\
\ Technically speaking, this routine can also calculate the dot product between
\ XX15 and the sun's orientation vectors, as the sun and space station share the
\ same ship data slot (the second ship data block at K%). However, the sun
\ doesn't have orientation vectors, so this only gets called when that slot is
\ being used for the space station.
\
\ Arguments:
\
\   Y                   The space station's orientation vector:
\
\                         * If Y = 10, calculate nosev . XX15
\
\                         * If Y = 16, calculate roofv . XX15
\
\                         * If Y = 22, calculate sidev . XX15
\
\ Returns:
\
\   (A X)               The result of the dot product
\
\ ******************************************************************************

.TAS4

 LDX K%+NI%,Y           \ Set Q = the Y-th byte of K%+NI%, i.e. vect_x from the
 STX Q                  \ second ship data block at K%

 LDA XX15               \ Set A = XX15

 JSR MULT12             \ Set (S R) = Q * A
                        \           = vect_x * XX15

 LDX K%+NI%+2,Y         \ Set Q = the Y+2-th byte of K%+NI%, i.e. vect_y
 STX Q

 LDA XX15+1             \ Set A = XX15+1

 JSR MAD                \ Set (A X) = Q * A + (S R)
                        \           = vect_y * XX15+1 + vect_x * XX15

 STA S                  \ Set (S R) = (A X)
 STX R

 LDX K%+NI%+4,Y         \ Set Q = the Y+2-th byte of K%+NI%, i.e. vect_z
 STX Q

 LDA XX15+2             \ Set A = XX15+2

 JMP MAD                \ Set:
                        \
                        \   (A X) = Q * A + (S R)
                        \           = vect_z * XX15+2 + vect_y * XX15+1 +
                        \             vect_x * XX15
                        \
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TAS6
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Negate the vector in XX15 so it points in the opposite direction
\
\ ******************************************************************************

.TAS6

 LDA XX15               \ Reverse the sign of the x-coordinate of the vector in
 EOR #%10000000         \ XX15
 STA XX15

 LDA XX15+1             \ Then reverse the sign of the y-coordinate
 EOR #%10000000
 STA XX15+1

 LDA XX15+2             \ And then the z-coordinate, so now the XX15 vector is
 EOR #%10000000         \ pointing in the opposite direction
 STA XX15+2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DCS1
\       Type: Subroutine
\   Category: Flight
\    Summary: Calculate the vector from the ideal docking position to the ship
\
\ ------------------------------------------------------------------------------
\
\ This routine is called by the docking computer routine in DOCKIT. It works out
\ the vector between the ship and the ideal docking position, which is straight
\ in front of the docking slot, but some distance away.
\
\ Specifically, it calculates the following:
\
\   * K3(2 1 0) = K3(2 1 0) - nosev_x_hi * 4
\
\   * K3(5 4 3) = K3(5 4 3) - nosev_y_hi * 4
\
\   * K3(8 7 6) = K3(8 7 6) - nosev_x_hi * 4
\
\ where K3 is the vector from the station to the ship, and nosev is the nose
\ vector for the space station.
\
\ The nose vector points from the centre of the station through the slot, so
\ -nosev * 4 is the vector from a point in front of the docking slot, but some
\ way from the station, back to the centre of the station. Adding this to the
\ vector from the station to the ship gives the vector from the point in front
\ of the station to the ship.
\
\ In practice, this routine is called twice, so the ideal docking position is
\ actually at a distance of 8 unit vectors from the centre of the station.
\
\ Back in DOCKIT, we flip this vector round to get the vector from the ship to
\ the point in front of the station slot.
\
\ Arguments:
\
\   K3                  The vector from the station to the ship
\
\ Returns:
\
\   K3                  The vector from the ship to the ideal docking position
\                       (4 unit vectors from the centre of the station for each
\                       call to DCS1, so two calls will return the vector to a
\                       point that's 8 unit vectors from the centre of the
\                       station)
\
\ ******************************************************************************

.DCS1

 JSR P%+3               \ Run the following routine twice, so the subtractions
                        \ are all * 4

 LDA K%+NI%+10          \ Set A to the space station's byte #10, nosev_x_hi

 LDX #0                 \ Set K3(2 1 0) = K3(2 1 0) - A * 2
 JSR TAS7               \               = K3(2 1 0) - nosev_x_hi * 2

 LDA K%+NI%+12          \ Set A to the space station's byte #12, nosev_y_hi

 LDX #3                 \ Set K3(5 4 3) = K3(5 4 3) - A * 2
 JSR TAS7               \               = K3(5 4 3) - nosev_y_hi * 2

 LDA K%+NI%+14          \ Set A to the space station's byte #14, nosev_z_hi

 LDX #6                 \ Set K3(8 7 6) = K3(8 7 6) - A * 2
                        \               = K3(8 7 6) - nosev_x_hi * 2

.TAS7

                        \ This routine subtracts A * 2 from one of the K3
                        \ coordinates, as determined by the value of X:
                        \
                        \   * X = 0, set K3(2 1 0) = K3(2 1 0) - A * 2
                        \
                        \   * X = 3, set K3(5 4 3) = K3(5 4 3) - A * 2
                        \
                        \   * X = 6, set K3(8 7 6) = K3(8 7 6) - A * 2
                        \
                        \ Let's document it for X = 0, i.e. K3(2 1 0)

 ASL A                  \ Shift A left one place and move the sign bit into the
                        \ C flag, so A = |A * 2|

 STA R                  \ Set R = |A * 2|

 LDA #0                 \ Rotate the sign bit of A from the C flag into the sign
 ROR A                  \ bit of A, so A is now just the sign bit from the
                        \ original value of A. This also clears the C flag

 EOR #%10000000         \ Flip the sign bit of A, so it has the sign of -A

 EOR K3+2,X             \ Give A the correct sign of K3(2 1 0) * -A

 BMI TS71               \ If the sign of K3(2 1 0) * -A is negative, jump to
                        \ TS71, as K3(2 1 0) and A have the same sign

                        \ If we get here then K3(2 1 0) and A have different
                        \ signs, so we can add them to do the subtraction

 LDA R                  \ Set K3(2 1 0) = K3(2 1 0) + R
 ADC K3,X               \               = K3(2 1 0) + |A * 2|
 STA K3,X               \
                        \ starting with the low bytes

 BCC TS72               \ If the above addition didn't overflow, we have the
                        \ result we want, so jump to TS72 to return from the
                        \ subroutine

 INC K3+1,X             \ The above addition overflowed, so increment the high
                        \ byte of K3(2 1 0)

.TS72

 RTS                    \ Return from the subroutine

.TS71

                        \ If we get here, then K3(2 1 0) and A have the same
                        \ sign

 LDA K3,X               \ Set K3(2 1 0) = K3(2 1 0) - R
 SEC                    \               = K3(2 1 0) - |A * 2|
 SBC R                  \
 STA K3,X               \ starting with the low bytes

 LDA K3+1,X             \ And then the high bytes
 SBC #0
 STA K3+1,X

 BCS TS72               \ If the subtraction didn't underflow, we have the
                        \ result we want, so jump to TS72 to return from the
                        \ subroutine

 LDA K3,X               \ Negate the result in K3(2 1 0) by flipping all the
 EOR #%11111111         \ bits and adding 1, i.e. using two's complement to
 ADC #1                 \ give it the opposite sign, starting with the low
 STA K3,X               \ bytes

 LDA K3+1,X             \ Then doing the high bytes
 EOR #%11111111
 ADC #0
 STA K3+1,X

 LDA K3+2,X             \ And finally, flipping the sign bit
 EOR #%10000000
 STA K3+2,X

 JMP TS72               \ Jump to TS72 to return from the subroutine

\ ******************************************************************************
\
\       Name: HITCH
\       Type: Subroutine
\   Category: Tactics
\    Summary: Work out if the ship in INWK is in our crosshairs
\  Deep dive: In the crosshairs
\
\ ------------------------------------------------------------------------------
\
\ This is called by the main flight loop to see if we have laser or missile lock
\ on an enemy ship.
\
\ Returns:
\
\   C flag              Set if the ship is in our crosshairs, clear if it isn't
\
\ Other entry points:
\
\   HI1                 Contains an RTS
\
\ ******************************************************************************

.HITCH

 CLC                    \ Clear the C flag so we can return with it cleared if
                        \ our checks fail

 LDA INWK+8             \ Set A = z_sign

 BNE HI1                \ If A is non-zero then the ship is behind us and can't
                        \ be in our crosshairs, so return from the subroutine
                        \ with the C flag clear (as HI1 contains an RTS)

 LDA TYPE               \ If the ship type has bit 7 set then it is the planet
 BMI HI1                \ or sun, which we can't target or hit with lasers, so
                        \ return from the subroutine with the C flag clear (as
                        \ HI1 contains an RTS)

 LDA INWK+31            \ Fetch bit 5 of byte #31 (the exploding flag) and OR
 AND #%00100000         \ with x_hi and y_hi
 ORA INWK+1
 ORA INWK+4

 BNE HI1                \ If this value is non-zero then either the ship is
                        \ exploding (so we can't target it), or the ship is too
                        \ far away from our line of fire to be targeted, so
                        \ return from the subroutine with the C flag clear (as
                        \ HI1 contains an RTS)

 LDA INWK               \ Set A = x_lo

 JSR SQUA2              \ Set (A P) = A * A = x_lo^2

 STA S                  \ Set (S R) = (A P) = x_lo^2
 LDA P
 STA R

 LDA INWK+3             \ Set A = y_lo

 JSR SQUA2              \ Set (A P) = A * A = y_lo^2

 TAX                    \ Store the high byte in X

 LDA P                  \ Add the two low bytes, so:
 ADC R                  \
 STA R                  \   R = P + R

 TXA                    \ Restore the high byte into A and add S to give the
 ADC S                  \ following:
                        \
                        \   (A R) = (S R) + (A P) = x_lo^2 + y_lo^2

 BCS TN10               \ If the addition just overflowed then there is no way
                        \ our crosshairs are within the ship's targetable area,
                        \ so return from the subroutine with the C flag clear
                        \ (as TN10 contains a CLC then an RTS)

 STA S                  \ Set (S R) = (A P) = x_lo^2 + y_lo^2

 LDY #2                 \ Fetch the ship's blueprint and set A to the high byte
 LDA (XX0),Y            \ of the targetable area of the ship

 CMP S                  \ We now compare the high bytes of the targetable area
                        \ and the calculation in (S R):
                        \
                        \   * If A >= S then then the C flag will be set
                        \
                        \   * If A < S then the C flag will be C clear

 BNE HI1                \ If A <> S we have just set the C flag correctly, so
                        \ return from the subroutine (as HI1 contains an RTS)

 DEY                    \ The high bytes were identical, so now we fetch the
 LDA (XX0),Y            \ low byte of the targetable area into A

 CMP R                  \ We now compare the low bytes of the targetable area
                        \ and the calculation in (S R):
                        \
                        \   * If A >= R then the C flag will be set
                        \
                        \   * If A < R then the C flag will be C clear

.HI1

 RTS                    \ Return from the subroutine

.TN10

 CLC                    \ Clear the C flag to indicate the ship is not in our
                        \ crosshairs

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FRS1
\       Type: Subroutine
\   Category: Tactics
\    Summary: Launch a ship straight ahead of us, below the laser sights
\
\ ------------------------------------------------------------------------------
\
\ This is used in two places:
\
\   * When we launch a missile, in which case the missile is the ship that is
\     launched ahead of us
\
\   * When we launch our escape pod, in which case it's our abandoned Cobra Mk
\     III that is launched ahead of us
\
\   * The fq1 entry point is used to launch a bunch of cargo canisters ahead of
\     us as part of the death screen
\
\ Arguments:
\
\   X                   The type of ship to launch ahead of us
\
\ Returns:
\
\   C flag              Set if the ship was successfully launched, clear if it
\                       wasn't (as there wasn't enough free memory)
\
\ Other entry points:
\
\   fq1                 Used to add a cargo canister to the universe
\
\ ******************************************************************************

.FRS1

 JSR ZINF               \ Call ZINF to reset the INWK ship workspace

 LDA #28                \ Set y_lo = 28
 STA INWK+3

 LSR A                  \ Set z_lo = 14, so the launched ship starts out
 STA INWK+6             \ ahead of us

 LDA #%10000000         \ Set y_sign to be negative, so the launched ship is
 STA INWK+5             \ launched just below our line of sight

 LDA MSTG               \ Set A to the missile lock target, shifted left so the
 ASL A                  \ slot number is in bits 1-4

 ORA #%10000000         \ Set bit 7 and store the result in byte #32, the AI
 STA INWK+32            \ flag launched ship for the launched ship. For missiles
                        \ this enables AI (bit 7), makes it friendly towards us
                        \ (bit 6), sets the target to the value of MSTG (bits
                        \ 1-4), and sets its lock status as launched (bit 0).
                        \ It doesn't matter what it does for our abandoned
                        \ Cobra, as the AI flag gets overwritten once we return
                        \ from the subroutine back to the ESCAPE routine that
                        \ called FRS1 in the first place

.fq1

 LDA #&60               \ Set byte #14 (nosev_z_hi) to 1 (&60), so the launched
 STA INWK+14            \ ship is pointing away from us

 ORA #128               \ Set byte #22 (sidev_x_hi) to -1 (&D0), so the launched
 STA INWK+22            \ ship has the same orientation as spawned ships, just
                        \ pointing away from us (if we set sidev to +1 instead,
                        \ this ship would be a mirror image of all the other
                        \ ships, which are spawned with -1 in nosev and +1 in
                        \ sidev)

 LDA DELTA              \ Set byte #27 (speed) to 2 * DELTA, so the launched
 ROL A                  \ ship flies off at twice our speed
 STA INWK+27

 TXA                    \ Add a new ship of type X to our local bubble of
 JMP NWSHP              \ universe and return from the subroutine using a tail
                        \ call

\ ******************************************************************************
\
\       Name: FRMIS
\       Type: Subroutine
\   Category: Tactics
\    Summary: Fire a missile from our ship
\
\ ------------------------------------------------------------------------------
\
\ We fired a missile, so send it streaking away from us to unleash mayhem and
\ destruction on our sworn enemies.
\
\ ******************************************************************************

.FRMIS

 LDX #MSL               \ Call FRS1 to launch a missile straight ahead of us
 JSR FRS1

 BCC FR1                \ If FRS1 returns with the C flag clear, then there
                        \ isn't room in the universe for our missile, so jump
                        \ down to FR1 to display a "missile jammed" message

 LDX MSTG               \ Fetch the slot number of the missile's target

 JSR GINF               \ Get the address of the data block for the target ship
                        \ and store it in INF

 LDA FRIN,X             \ Fetch the ship type of the missile's target into A

 JSR ANGRY              \ Call ANGRY to make the target ship hostile

 LDY #0                 \ We have just launched a missile, so we need to remove
 JSR ABORT              \ missile lock and hide the leftmost indicator on the
                        \ dashboard by setting it to black (Y = 0)

 DEC NOMSL              \ Reduce the number of missiles we have by 1

 LDY #8                 \ Call the NOISE routine with Y = 8 to make the sound
 JSR NOISE              \ of a missile launch ???

\ ******************************************************************************
\
\       Name: ANGRY
\       Type: Subroutine
\   Category: Tactics
\    Summary: Make a ship hostile
\
\ ------------------------------------------------------------------------------
\
\ All this routine does is set the ship's hostile flag, start it turning and
\ give it a kick of acceleration - later calls to TACTICS will make the ship
\ start to attack us.
\
\ Arguments:
\
\   A                   The type of ship we're going to irritate
\
\   INF                 The address of the data block for the ship we're going
\                       to infuriate
\
\ ******************************************************************************

.ANGRY

 CMP #SST               \ If this is the space station, jump to AN2 to make the
 BEQ AN2                \ space station hostile

 LDY #36                \ Fetch the ship's NEWB flags from byte #36
 LDA (INF),Y

 AND #%00100000         \ If bit 5 of the ship's NEWB flags is clear, skip the
 BEQ P%+5               \ following instruction, otherwise bit 5 is set, meaning
                        \ this ship is an innocent bystander, and attacking it
                        \ will annoy the space station

 JSR AN2                \ Call AN2 to make the space station hostile

 LDY #32                \ Fetch the ship's byte #32 (AI flag)
 LDA (INF),Y

 BEQ HI1                \ If the AI flag is zero then this ship has no AI and
                        \ it can't get hostile, so return from the subroutine
                        \ (as HI1 contains an RTS)

 ORA #%10000000         \ Otherwise set bit 7 (AI enabled) to ensure AI is
 STA (INF),Y            \ definitely enabled

 LDY #28                \ Set the ship's byte #28 (acceleration) to 2, so it
 LDA #2                 \ speeds up
 STA (INF),Y

 ASL A                  \ Set the ship's byte #30 (pitch counter) to 4, so it
 LDY #30                \ starts pitching
 STA (INF),Y

 LDA TYPE               \ If the ship's type is < #CYL (i.e. a missile, Coriolis
 CMP #CYL               \ space station, escape pod, plate, cargo canister,
 BCC AN3                \ boulder, asteroid, splinter, Shuttle or Transporter),
                        \ then jump to AN3 to skip the following

 LDY #36                \ Set bit 2 of the ship's NEWB flags in byte #36 to
 LDA (INF),Y            \ make this ship hostile
 ORA #%00000100
 STA (INF),Y

.AN3

 RTS                    \ Return from the subroutine

.AN2

 LDA K%+NI%+36          \ Set bit 2 of the NEWB flags in byte #36 of the second
 ORA #%00000100         \ ship in the ship data workspace at K%, which is
 STA K%+NI%+36          \ reserved for the sun or the space station (in this
                        \ case it's the latter), to make it hostile

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FR1
\       Type: Subroutine
\   Category: Tactics
\    Summary: Display the "missile jammed" message
\
\ ------------------------------------------------------------------------------
\
\ This is shown if there isn't room in the local bubble of universe for a new
\ missile.
\
\ Other entry points:
\
\   FR1-2               Clear the C flag and return from the subroutine
\
\ ******************************************************************************

.FR1

 LDA #201               \ Print recursive token 41 ("MISSILE JAMMED") as an
 JMP MESS               \ in-flight message and return from the subroutine using
                        \ a tail call

\ ******************************************************************************
\
\       Name: SESCP
\       Type: Subroutine
\   Category: Flight
\    Summary: Spawn an escape pod from the current (parent) ship
\
\ ------------------------------------------------------------------------------
\
\ This is called when an enemy ship has run out of both energy and luck, so it's
\ time to bail.
\
\ Other entry points:
\
\   SFS1-2              Add a missile to the local bubble that has AI enabled,
\                       is hostile, but has no E.C.M.
\
\ ******************************************************************************

.SESCP

 LDX #ESC               \ Set X to the ship type for an escape pod

 LDA #%11111110         \ Set A to an AI flag that has AI enabled, is hostile,
                        \ but has no E.C.M.

                        \ Fall through into SFS1 to spawn the escape pod

\ ******************************************************************************
\
\       Name: SFS1
\       Type: Subroutine
\   Category: Universe
\    Summary: Spawn a child ship from the current (parent) ship
\
\ ------------------------------------------------------------------------------
\
\ If the parent is a space station then the child ship is spawned coming out of
\ the slot, and if the child is a cargo canister, it is sent tumbling through
\ space. Otherwise the child ship is spawned with the same ship data as the
\ parent, just with damping disabled and the ship type and AI flag that are
\ passed in A and X.
\
\ Arguments:
\
\   A                   AI flag for the new ship (see the documentation on ship
\                       data byte #32 for details)
\
\   X                   The ship type of the child to spawn
\
\   INF                 Address of the parent's ship data block
\
\   TYPE                The type of the parent ship
\
\ Returns:
\
\   C flag              Set if ship successfully added, clear if it failed
\
\   INF                 INF is preserved
\
\   XX0                 XX0 is preserved
\
\   INWK                The whole INWK workspace is preserved
\
\   X                   X is preserved
\
\ ******************************************************************************

.SFS1

 STA T1                 \ Store the child ship's AI flag in T1

                        \ Before spawning our child ship, we need to save the
                        \ INF and XX00 variables and the whole INWK workspace,
                        \ so we can restore them later when returning from the
                        \ subroutine

 TXA                    \ Store X, the ship type to spawn, on the stack so we
 PHA                    \ can preserve it through the routine

 LDA XX0                \ Store XX0(1 0) on the stack, so we can restore it
 PHA                    \ later when returning from the subroutine
 LDA XX0+1
 PHA

 LDA INF                \ Store INF(1 0) on the stack, so we can restore it
 PHA                    \ later when returning from the subroutine
 LDA INF+1
 PHA

 LDY #NI%-1             \ Now we want to store the current INWK data block in
                        \ temporary memory so we can restore it when we are
                        \ done, and we also want to copy the parent's ship data
                        \ into INWK, which we can do at the same time, so set up
                        \ a counter in Y for NI% bytes

.FRL2

 LDA INWK,Y             \ Copy the Y-th byte of INWK to the Y-th byte of
 STA XX3,Y              \ temporary memory in XX3, so we can restore it later
                        \ when returning from the subroutine

 LDA (INF),Y            \ Copy the Y-th byte of the parent ship's data block to
 STA INWK,Y             \ the Y-th byte of INWK

 DEY                    \ Decrement the loop counter

 BPL FRL2               \ Loop back to copy the next byte until we have done
                        \ them all

                        \ INWK now contains the ship data for the parent ship,
                        \ so now we need to tweak the data before creating the
                        \ new child ship (in this way, the child inherits things
                        \ like location from the parent)

 LDA TYPE               \ Fetch the ship type of the parent into A

 CMP #SST               \ If the parent is not a space station, jump to rx to
 BNE rx                 \ skip the following

                        \ The parent is a space station, so the child needs to
                        \ launch out of the space station's slot. The space
                        \ station's nosev vector points out of the station's
                        \ slot, so we want to move the ship along this vector.
                        \ We do this by taking the unit vector in nosev and
                        \ doubling it, so we spawn our ship 2 units along the
                        \ vector from the space station's centre

 TXA                    \ Store the child's ship type in X on the stack
 PHA

 LDA #32                \ Set the child's byte #27 (speed) to 32
 STA INWK+27

 LDX #0                 \ Add 2 * nosev_x_hi to (x_lo, x_hi, x_sign) to get the
 LDA INWK+10            \ child's x-coordinate
 JSR SFS2

 LDX #3                 \ Add 2 * nosev_y_hi to (y_lo, y_hi, y_sign) to get the
 LDA INWK+12            \ child's y-coordinate
 JSR SFS2

 LDX #6                 \ Add 2 * nosev_z_hi to (z_lo, z_hi, z_sign) to get the
 LDA INWK+14            \ child's z-coordinate
 JSR SFS2

 PLA                    \ Restore the child's ship type from the stack into X
 TAX

.rx

 LDA T1                 \ Restore the child ship's AI flag from T1 and store it
 STA INWK+32            \ in the child's byte #32 (AI)

 LSR INWK+29            \ Clear bit 0 of the child's byte #29 (roll counter) so
 ASL INWK+29            \ that its roll dampens (so if we are spawning from a
                        \ space station, for example, the spawned ship won't
                        \ keep rolling forever)

 TXA                    \ Copy the child's ship type from X into A

 CMP #SPL+1             \ If the type of the child we are spawning is less than
 BCS NOIL               \ #PLT or greater than #SPL - i.e. not an alloy plate,
 CMP #PLT               \ cargo canister, boulder, asteroid or splinter - then
 BCC NOIL               \ jump to NOIL to skip us setting up some pitch and roll
                        \ for it

 PHA                    \ Store the child's ship type on the stack so we can
                        \ retrieve it below

 JSR DORND              \ Set A and X to random numbers

 ASL A                  \ Set the child's byte #30 (pitch counter) to a random
 STA INWK+30            \ value, and at the same time set the C flag randomly

 TXA                    \ Set the child's byte #27 (speed) to a random value
 AND #%00001111         \ between 0 and 15
 STA INWK+27

 LDA #&FF               \ Set the child's byte #29 (roll counter) to a full
 ROR A                  \ roll, so the canister tumbles through space, with
 STA INWK+29            \ damping randomly enabled or disabled, depending on the
                        \ C flag from above

 PLA                    \ Retrieve the child's ship type from the stack

.NOIL

 JSR NWSHP              \ Add a new ship of type A to the local bubble

                        \ We have now created our child ship, so we need to
                        \ restore all the variables we saved at the start of
                        \ the routine, so they are preserved when we return
                        \ from the subroutine

 PLA                    \ Restore INF(1 0) from the stack
 STA INF+1
 PLA
 STA INF

 LDX #NI%-1             \ Now to restore the INWK workspace that we saved into
                        \ XX3 above, so set a counter in X for NI% bytes

.FRL3

 LDA XX3,X              \ Copy the Y-th byte of XX3 to the Y-th byte of INWK
 STA INWK,X

 DEX                    \ Decrement the loop counter

 BPL FRL3               \ Loop back to copy the next byte until we have done
                        \ them all

 PLA                    \ Restore XX0(1 0) from the stack
 STA XX0+1
 PLA
 STA XX0

 PLA                    \ Retrieve the ship type to spawn from the stack into X
 TAX                    \ so it is preserved through calls to this routine

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SFS2
\       Type: Subroutine
\   Category: Moving
\    Summary: Move a ship in space along one of the coordinate axes
\
\ ------------------------------------------------------------------------------
\
\ Move a ship's coordinates by a certain amount in the direction of one of the
\ axes, where X determines the axis. Mathematically speaking, this routine
\ translates the ship along a single axis by a signed delta.
\
\ Arguments:
\
\   A                   The amount of movement, i.e. the signed delta
\
\   X                   Determines which coordinate axis of INWK to move:
\
\                         * X = 0 moves the ship along the x-axis
\
\                         * X = 3 moves the ship along the y-axis
\
\                         * X = 6 moves the ship along the z-axis
\
\ ******************************************************************************

.SFS2

 ASL A                  \ Set R = |A * 2|, with the C flag set to bit 7 of A
 STA R

 LDA #0                 \ Set bit 7 of A to the C flag, i.e. the sign bit from
 ROR A                  \ the original argument in A

 JMP MVT1               \ Add the delta R with sign A to (x_lo, x_hi, x_sign)
                        \ (or y or z, depending on the value in X) and return
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: LL164
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Make the hyperspace sound and draw the hyperspace tunnel
\
\ ------------------------------------------------------------------------------
\
\ See the IRQ1 routine for details on the multi-coloured effect that's used.
\
\ ******************************************************************************

.LL164

 LDY #&0A               \ ???
 JSR NOISE

 LDY #&0B
 JSR NOISE

 LDA #4                 \ Set the step size for the hyperspace rings to 4, so
                        \ there are more sections in the rings and they are
                        \ quite round (compared to the step size of 8 used in
                        \ the much more polygonal launch rings)

 STA HFX                \ ???

 JSR HFS2               \ Call HFS2 to draw the hyperspace tunnel rings

 STZ HFX                \ Set HFX back to 0, so we switch back to the normal
                        \ split-screen mode

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LAUN
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Make the launch sound and draw the launch tunnel
\
\ ------------------------------------------------------------------------------
\
\ This is shown when launching from or docking with the space station.
\
\ ******************************************************************************

.LAUN

 LDY #8                 \ Call the NOISE routine with Y = 8 to make the sound
 JSR NOISE              \ of the ship launching from the station

 LDA #8                 \ Set the step size for the launch tunnel rings to 8, so
                        \ there are fewer sections in the rings and they are
                        \ quite polygonal (compared to the step size of 4 used
                        \ in the much rounder hyperspace rings)

                        \ Fall through into HFS2 to draw the launch tunnel rings

\ ******************************************************************************
\
\       Name: HFS2
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw the launch or hyperspace tunnel
\
\ ------------------------------------------------------------------------------
\
\ The animation gets drawn like this. First, we draw a circle of radius 8 at the
\ centre, and then double the radius, draw another circle, double the radius
\ again and draw a circle, and we keep doing this until the radius is bigger
\ than 160 (which goes beyond the edge of the screen, which is 256 pixels wide,
\ equivalent to a radius of 128). We then repeat this whole process for an
\ initial circle of radius 9, then radius 10, all the way up to radius 15.
\
\ This has the effect of making the tunnel appear to be racing towards us as we
\ hurtle out into hyperspace or through the space station's docking tunnel.
\
\ The hyperspace effect is done in a full mode 2 screen, which makes the rings
\ all coloured and zig-zaggy, while the launch screen is in the normal
\ four-colour mode 1 screen.
\
\ Arguments:
\
\   A                   The step size of the straight lines making up the rings
\                       (4 for launch, 8 for hyperspace)
\
\ Other entry points:
\
\   HFS1                Don't clear the screen, and draw 8 concentric rings
\                       with the step size in STP
\
\ ******************************************************************************

.HFS2

 STA STP                \ Store the step size in A

 LDA QQ11               \ ???
 PHA

 LDA #0
 JSR TT66

 PLA
 STA QQ11

.HFS1

 LDX #X                 \ Set K3 = #X (the x-coordinate of the centre of the
 STX K3                 \ screen)

 LDX #Y                 \ Set K4 = #Y (the y-coordinate of the centre of the
 STX K4                 \ screen)

 LDX #0                 \ Set X = 0

 STX XX4                \ Set XX4 = 0, which we will use as a counter for
                        \ drawing 8 concentric rings

 STX K3+1               \ Set the high bytes of K3(1 0) and K4(1 0) to 0
 STX K4+1

.HFL5

 JSR HFL1               \ Call HFL1 below to draw a set of rings, with each one
                        \ twice the radius of the previous one, until they won't
                        \ fit on-screen

 INC XX4                \ Increment the counter and fetch it into X
 LDX XX4

 CPX #8                 \ If we haven't drawn 8 sets of rings yet, loop back to
 BNE HFL5               \ HFL5 to draw the next ring

 RTS                    \ Return from the subroutine

.HFL1

 LDA XX4                \ Set K to the ring number in XX4 (0-7) + 8, so K has
 AND #7                 \ a value of 8 to 15, which we will use as the starting
 CLC                    \ radius for our next set of rings
 ADC #8
 STA K

.HFL2

 LDA #1                 \ Set LSP = 1 to reset the ball line heap
 STA LSP

 JSR CIRCLE2            \ Call CIRCLE2 to draw a circle with the centre at
                        \ (K3(1 0), K4(1 0)) and radius K

 ASL K                  \ Double the radius in K

 BCS HF8                \ If the radius had a 1 in bit 7 before the above shift,
                        \ then doubling K will means the circle will no longer
                        \ fit on the screen (which is width 256), so jump to
                        \ HF8 to stop drawing circles

 LDA K                  \ If the radius in K <= 160, loop back to HFL2 to draw
 CMP #160               \ another one
 BCC HFL2

.HF8

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: STARS2
\       Type: Subroutine
\   Category: Stardust
\    Summary: Process the stardust for the left or right view
\  Deep dive: Stardust in the side views
\
\ ------------------------------------------------------------------------------
\
\ This moves the stardust sideways according to our speed and which side we are
\ looking out of, and applies our current pitch and roll to each particle of
\ dust, so the stardust moves correctly when we steer our ship.
\
\ Arguments:
\
\   X                   The view to process:
\
\                         * X = 1 for left view
\
\                         * X = 2 for right view
\
\ ******************************************************************************

.STARS2

 LDA #0                 \ Set A to 0 so we can use it to capture a sign bit

 CPX #2                 \ If X >= 2 then the C flag is set

 ROR A                  \ Roll the C flag into the sign bit of A and store in
 STA RAT                \ RAT, so:
                        \
                        \   * Left view, C is clear so RAT = 0 (positive)
                        \
                        \   * Right view, C is set so RAT = 128 (negative)
                        \
                        \ RAT represents the end of the x-axis where we want new
                        \ stardust particles to come from: positive for the left
                        \ view where new particles come in from the right,
                        \ negative for the right view where new particles come
                        \ in from the left

 EOR #%10000000         \ Set RAT2 to the opposite sign, so:
 STA RAT2               \
                        \   * Left view, RAT2 = 128 (negative)
                        \
                        \   * Right view, RAT2 = 0 (positive)
                        \
                        \ RAT2 represents the direction in which stardust
                        \ particles should move along the x-axis: negative for
                        \ the left view where particles go from right to left,
                        \ positive for the right view where particles go from
                        \ left to right

 JSR ST2                \ Call ST2 to flip the signs of the following if this is
                        \ the right view: ALPHA, ALP2, ALP2+1, BET2 and BET2+1

 LDY NOSTM              \ Set Y to the current number of stardust particles, so
                        \ we can use it as a counter through all the stardust

.STL2

 LDA SZ,Y               \ Set A = ZZ = z_hi

 STA ZZ                 \ We also set ZZ to the original value of z_hi, which we
                        \ use below to remove the existing particle

 LSR A                  \ Set A = z_hi / 8
 LSR A
 LSR A

 JSR DV41               \ Call DV41 to set the following:
                        \
                        \   (P R) = 256 * DELTA / A
                        \         = 256 * speed / (z_hi / 8)
                        \         = 8 * 256 * speed / z_hi
                        \
                        \ This represents the distance we should move this
                        \ particle along the x-axis, let's call it delta_x

 LDA P                  \ ???
 STA L009B

 EOR RAT2               \ Set S = P but with the sign from RAT2, so we now have
 STA S                  \ the distance delta_x with the correct sign in (S R):
                        \
                        \   (S R) = delta_x
                        \         = 8 * 256 * speed / z_hi
                        \
                        \ So (S R) is the delta, signed to match the direction
                        \ the stardust should move in, which is result 1 above

 LDA SXL,Y              \ Set (A P) = (x_hi x_lo)
 STA P                  \           = x
 LDA SX,Y

 STA X1                 \ Set X1 = A, so X1 contains the original value of x_hi,
                        \ which we use below to remove the existing particle

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = x + delta_x

 STA S                  \ Set (S R) = (A X)
 STX R                  \           = x + delta_x

 LDA SY,Y               \ Set A = y_hi

 STA Y1                 \ Set Y1 = A, so Y1 contains the original value of y_hi,
                        \ which we use below to remove the existing particle

 EOR BET2               \ Give A the correct sign of A * beta, i.e. y_hi * beta

 LDX BET1               \ Fetch |beta| from BET1, the pitch angle

 JSR MULTS-2            \ Call MULTS-2 to calculate:
                        \
                        \   (A P) = X * A
                        \         = beta * y_hi

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = beta * y + x + delta_x

 STX XX                 \ Set XX(1 0) = (A X), which gives us results 2 and 3
 STA XX+1               \ above, done at the same time:
                        \
                        \   x = x + delta_x + beta * y

 LDX SYL,Y              \ Set (S R) = (y_hi y_lo)
 STX R                  \           = y
 LDX Y1
 STX S

 LDX BET1               \ Fetch |beta| from BET1, the pitch angle

 EOR BET2+1             \ Give A the opposite sign to x * beta

 JSR MULTS-2            \ Call MULTS-2 to calculate:
                        \
                        \   (A P) = X * A
                        \         = -beta * x

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = -beta * x + y

 STX YY                 \ Set YY(1 0) = (A X), which gives us result 4 above:
 STA YY+1               \
                        \   y = y - beta * x

 LDX ALP1               \ Set X = |alpha| from ALP2, the roll angle

 EOR ALP2               \ Give A the correct sign of A * alpha, i.e. y_hi *
                        \ alpha

 JSR MULTS-2            \ Call MULTS-2 to calculate:
                        \
                        \   (A P) = X * A
                        \         = alpha * y

 STA Q                  \ Set Q = high byte of alpha * y

 LDA XX                 \ Set (S R) = XX(1 0)
 STA R                  \           = x
 LDA XX+1               \
 STA S                  \ and set A = y_hi at the same time

 EOR #%10000000         \ Flip the sign of A = -x_hi

 JSR MAD                \ Call MAD to calculate:
                        \
                        \   (A X) = Q * A + (S R)
                        \         = alpha * y * -x + x

 STA XX+1               \ Store the high byte A in XX+1

 TXA
 STA SXL,Y              \ Store the low byte X in x_lo

                        \ So (XX+1 x_lo) now contains result 5 above:
                        \
                        \   x = x - alpha * x * y

 LDA YY                 \ Set (S R) = YY(1 0)
 STA R                  \           = y
 LDA YY+1               \
 STA S                  \ and set A = y_hi at the same time

 JSR MAD                \ Call MAD to calculate:
                        \
                        \   (A X) = Q * A + (S R)
                        \         = alpha * y * y_hi + y

 STA S                  \ Set (S R) = (A X)
 STX R                  \           = y + alpha * y * y

 LDA #0                 \ Set P = 0
 STA P

 LDA ALPHA              \ Set A = alpha, so:
                        \
                        \   (A P) = (alpha 0)
                        \         = alpha / 256

 JSR PIX1               \ Call PIX1 to calculate the following:
                        \
                        \   (YY+1 y_lo) = (A P) + (S R)
                        \               = alpha * 256 + y + alpha * y * y
                        \
                        \ i.e. y = y + alpha / 256 + alpha * y^2, which is
                        \ result 6 above
                        \
                        \ PIX1 also draws a particle at (X1, Y1) with distance
                        \ ZZ, which will remove the old stardust particle, as we
                        \ set X1, Y1 and ZZ to the original values for this
                        \ particle during the calculations above

                        \ We now have our newly moved stardust particle at
                        \ x-coordinate (XX+1 x_lo) and y-coordinate (YY+1 y_lo)
                        \ and distance z_hi, so we draw it if it's still on
                        \ screen, otherwise we recycle it as a new bit of
                        \ stardust and draw that

 LDA XX+1               \ Set X1 and x_hi to the high byte of XX in XX+1, so
 STA SX,Y               \ the new x-coordinate is in (x_hi x_lo) and the high
 STA X1                 \ byte is in X1

 AND #%01111111         \ If |x_hi| >= ??? then jump to KILL2 to recycle this
 EOR #%01111111         \ particle, as it's gone off the side of the screen,
 CMP L009B              \ and re-join at STC2 with the new particle ???
 BCC KILL2
 BEQ KILL2

 LDA YY+1               \ Set Y1 and y_hi to the high byte of YY in YY+1, so
 STA SY,Y               \ the new x-coordinate is in (y_hi y_lo) and the high
 STA Y1                 \ byte is in Y1

 AND #%01111111         \ If |y_hi| >= 116 then jump to ST5 to recycle this
 CMP #116               \ particle, as it's gone off the top or bottom of the
 BCS ST5                \ screen, and re-join at STC2 with the new particle

.STC2

 JSR PIXEL2             \ Draw a stardust particle at (X1,Y1) with distance ZZ,
                        \ i.e. draw the newly moved particle at (x_hi, y_hi)
                        \ with distance z_hi

 DEY                    \ Decrement the loop counter to point to the next
                        \ stardust particle

 BEQ ST2                \ If we have just done the last particle, skip the next
                        \ instruction to return from the subroutine

 JMP STL2               \ We have more stardust to process, so jump back up to
                        \ STL2 for the next particle

                        \ Fall through into ST2 to restore the signs of the
                        \ following if this is the right view: ALPHA, ALP2,
                        \ ALP2+1, BET2 and BET2+1

.ST2

 LDA ALPHA              \ If this is the right view, flip the sign of ALPHA
 EOR RAT
 STA ALPHA

 LDA ALP2               \ If this is the right view, flip the sign of ALP2
 EOR RAT
 STA ALP2

 EOR #%10000000         \ If this is the right view, flip the sign of ALP2+1
 STA ALP2+1

 LDA BET2               \ If this is the right view, flip the sign of BET2
 EOR RAT
 STA BET2

 EOR #%10000000         \ If this is the right view, flip the sign of BET2+1
 STA BET2+1

 RTS                    \ Return from the subroutine

.KILL2

 JSR DORND              \ Set A and X to random numbers

 STA Y1                 \ Set y_hi and Y1 to random numbers, so the particle
 STA SY,Y               \ starts anywhere along the y-axis

 LDA #115               \ Make sure A is at least 115 and has the sign in RAT
 ORA RAT

 STA X1                 \ Set x_hi and X1 to A, so this particle starts on the
 STA SX,Y               \ correct edge of the screen for new particles

 BNE STF1               \ Jump down to STF1 to set the z-coordinate (this BNE is
                        \ effectively a JMP as A will never be zero)

.ST5

 JSR DORND              \ Set A and X to random numbers

 STA X1                 \ Set x_hi and X1 to random numbers, so the particle
 STA SX,Y               \ starts anywhere along the x-axis

 LDA #110               \ Make sure A is at least 110 and has the sign in AL2+1,
 ORA ALP2+1             \ the flipped sign of the roll angle alpha

 STA Y1                 \ Set y_hi and Y1 to A, so the particle starts at the
 STA SY,Y               \ top or bottom edge, depending on the current roll
                        \ angle alpha

.STF1

 JSR DORND              \ Set A and X to random numbers

 ORA #8                 \ Make sure A is at least 8 and store it in z_hi and
 STA ZZ                 \ ZZ, so the new particle starts at any distance from
 STA SZ,Y               \ us, but not too close

 BNE STC2               \ Jump up to STC2 to draw this new particle (this BNE is
                        \ effectively a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: MU5
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Set K(3 2 1 0) = (A A A A) and clear the C flGag
\
\ ------------------------------------------------------------------------------
\
\ In practice this is only called via a BEQ following an AND instruction, in
\ which case A = 0, so this routine effectively does this:
\
\   K(3 2 1 0) = 0
\
\ ******************************************************************************

.MU5

 STA K                  \ Set K(3 2 1 0) to (A A A A)
 STA K+1
 STA K+2
 STA K+3

 CLC                    \ Clear the C flag

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MULT3
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate K(3 2 1 0) = (A P+1 P) * Q
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following multiplication between a signed 24-bit number and a
\ signed 8-bit number, returning the result as a signed 32-bit number:
\
\   K(3 2 1 0) = (A P+1 P) * Q
\
\ The algorithm is the same shift-and-add algorithm as in routine MULT1, but
\ extended to cope with more bits.
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.MULT3

 STA R                  \ Store the high byte of (A P+1 P) in R

 AND #%01111111         \ Set K+2 to |A|, the high byte of K(2 1 0)
 STA K+2

 LDA Q                  \ Set A to bits 0-6 of Q, so A = |Q|
 AND #%01111111

 BEQ MU5                \ If |Q| = 0, jump to MU5 to set K(3 2 1 0) to 0,
                        \ returning from the subroutine using a tail call

 SEC                    \ Set T = |Q| - 1
 SBC #1
 STA T

                        \ We now use the same shift-and-add algorithm as MULT1
                        \ to calculate the following:
                        \
                        \ K(2 1 0) = K(2 1 0) * |Q|
                        \
                        \ so we start with the first shift right, in which we
                        \ take (K+2 P+1 P) and shift it right, storing the
                        \ result in K(2 1 0), ready for the multiplication loop
                        \ (so the multiplication loop actually calculates
                        \ (|A| P+1 P) * |Q|, as the following sets K(2 1 0) to
                        \ (|A| P+1 P) shifted right)

 LDA P+1                \ Set A = P+1

 LSR K+2                \ Shift the high byte in K+2 to the right

 ROR A                  \ Shift the middle byte in A to the right and store in
 STA K+1                \ K+1 (so K+1 contains P+1 shifted right)

 LDA P                  \ Shift the middle byte in P to the right and store in
 ROR A                  \ K, so K(2 1 0) now contains (|A| P+1 P) shifted right
 STA K

                        \ We now use the same shift-and-add algorithm as MULT1
                        \ to calculate the following:
                        \
                        \ K(2 1 0) = K(2 1 0) * |Q|

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDX #24                \ Set up a counter in X to count the 24 bits in K(2 1 0)

.MUL2

 BCC P%+4               \ If C (i.e. the next bit from K) is set, do the
 ADC T                  \ addition for this bit of K:
                        \
                        \   A = A + T + C
                        \     = A + |Q| - 1 + 1
                        \     = A + |Q|

 ROR A                  \ Shift A right by one place to catch the next digit
 ROR K+2                \ next digit of our result in the left end of K(2 1 0),
 ROR K+1                \ while also shifting K(2 1 0) right to fetch the next
 ROR K                  \ bit for the calculation into the C flag
                        \
                        \ On the last iteration of this loop, the bit falling
                        \ off the end of K will be bit 0 of the original A, as
                        \ we did one shift before the loop and we are doing 24
                        \ iterations. We set A to 0 before looping, so this
                        \ means the loop exits with the C flag clear

 DEX                    \ Decrement the loop counter

 BNE MUL2               \ Loop back for the next bit until K(2 1 0) has been
                        \ rotated all the way

                        \ The result (|A| P+1 P) * |Q| is now in (A K+2 K+1 K),
                        \ but it is positive and doesn't have the correct sign
                        \ of the final result yet

 STA T                  \ Save the high byte of the result into T

 LDA R                  \ Fetch the sign byte from the original (A P+1 P)
                        \ argument that we stored in R

 EOR Q                  \ EOR with Q so the sign bit is the same as that of
                        \ (A P+1 P) * Q

 AND #%10000000         \ Extract the sign bit

 ORA T                  \ Apply this to the high byte of the result in T, so
                        \ that A now has the correct sign for the result, and
                        \ (A K+2 K+1 K) therefore contains the correctly signed
                        \ result

 STA K+3                \ Store A in K+3, so K(3 2 1 0) now contains the result

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MLS2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (S R) = XX(1 0) and (A P) = A * ALP1
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   (S R) = XX(1 0)
\
\   (A P) = A * ALP1
\
\ where ALP1 is the magnitude of the current roll angle alpha, in the range
\ 0-31.
\
\ ******************************************************************************

.MLS2

 LDX XX                 \ Set (S R) = XX(1 0), starting with the low bytes
 STX R

 LDX XX+1               \ And then doing the high bytes
 STX S

                        \ Fall through into MLS1 to calculate (A P) = A * ALP1

\ ******************************************************************************
\
\       Name: MLS1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = ALP1 * A
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   (A P) = ALP1 * A
\
\ where ALP1 is the magnitude of the current roll angle alpha, in the range
\ 0-31.
\
\ This routine uses an unrolled version of MU11. MU11 calculates P * X, so we
\ use the same algorithm but with P set to ALP1 and X set to A. The unrolled
\ version here can skip the bit tests for bits 5-7 of P as we know P < 32, so
\ only 5 shifts with bit tests are needed (for bits 0-4), while the other 3
\ shifts can be done without a test (for bits 5-7).
\
\ Other entry points:
\
\   MULTS-2             Calculate (A P) = X * A
\
\ ******************************************************************************

.MLS1

 LDX ALP1               \ Set P to the roll angle alpha magnitude in ALP1
 STX P                  \ (0-31), so now we calculate P * A

.MULTS

 TAX                    \ Set X = A, so now we can calculate P * X instead of
                        \ P * A to get our result, and we can use the algorithm
                        \ from MU11 to do that, just unrolled (as MU11 returns
                        \ P * X)

 AND #%10000000         \ Set T to the sign bit of A
 STA T

 TXA                    \ Set A = |A|
 AND #127

 BEQ MU6                \ If A = 0, jump to MU6 to set P(1 0) = 0 and return
                        \ from the subroutine using a tail call

 TAX                    \ Set T1 = X - 1
 DEX                    \
 STX T1                 \ We subtract 1 as the C flag will be set when we want
                        \ to do an addition in the loop below

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LSR P                  \ Set P = P >> 1
                        \ and C flag = bit 0 of P

                        \ We are now going to work our way through the bits of
                        \ P, and do a shift-add for any bits that are set,
                        \ keeping the running total in A, but instead of using a
                        \ loop like MU11, we just unroll it, starting with bit 0

 BCC P%+4               \ If C (i.e. the next bit from P) is set, do the
 ADC T1                 \ addition for this bit of P:
                        \
                        \   A = A + T1 + C
                        \     = A + X - 1 + 1
                        \     = A + X

 ROR A                  \ Shift A right to catch the next digit of our result,
                        \ which the next ROR sticks into the left end of P while
                        \ also extracting the next bit of P

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation into the C flag

 BCC P%+4               \ Repeat the shift-and-add loop for bit 1
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat the shift-and-add loop for bit 2
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat the shift-and-add loop for bit 3
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat the shift-and-add loop for bit 4
 ADC T1
 ROR A
 ROR P

 LSR A                  \ Just do the "shift" part for bit 5
 ROR P

 LSR A                  \ Just do the "shift" part for bit 6
 ROR P

 LSR A                  \ Just do the "shift" part for bit 7
 ROR P

 ORA T                  \ Give A the sign bit of the original argument A that
                        \ we put into T above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MU6
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Set P(1 0) = (A A)
\
\ ------------------------------------------------------------------------------
\
\ In practice this is only called via a BEQ following an AND instruction, in
\ which case A = 0, so this routine effectively does this:
\
\   P(1 0) = 0
\
\ ******************************************************************************

.MU6

 STA P+1                \ Set P(1 0) = (A A)
 STA P

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SQUA
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Clear bit 7 of A and calculate (A P) = A * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of unsigned 8-bit numbers, after first
\ clearing bit 7 of A:
\
\   (A P) = A * A
\
\ ******************************************************************************

.SQUA

 AND #%01111111         \ Clear bit 7 of A and fall through into SQUA2 to set
                        \ (A P) = A * A

\ ******************************************************************************
\
\       Name: SQUA2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = A * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of unsigned 8-bit numbers:
\
\   (A P) = A * A
\
\ ******************************************************************************

.SQUA2

 STA P                  \ Copy A into P and X
 TAX

 BNE MU11               \ If X = 0 fall through into MU1 to return a 0,
                        \ otherwise jump to MU11 to return P * X

\ ******************************************************************************
\
\       Name: MU1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Copy X into P and A, and clear the C flag
\
\ ------------------------------------------------------------------------------
\
\ Used to return a 0 result quickly from MULTU below.
\
\ ******************************************************************************

.MU1

 CLC                    \ Clear the C flag

 STX P                  \ Copy X into P and A
 TXA

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MLU1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate Y1 = y_hi and (A P) = |y_hi| * Q for Y-th stardust
\
\ ------------------------------------------------------------------------------
\
\ Do the following assignment, and multiply the Y-th stardust particle's
\ y-coordinate with an unsigned number Q:
\
\   Y1 = y_hi
\
\   (A P) = |y_hi| * Q
\
\ ******************************************************************************

.MLU1

 LDA SY,Y               \ Set Y1 the Y-th byte of SY
 STA Y1

                        \ Fall through into MLU2 to calculate:
                        \
                        \   (A P) = |A| * Q

\ ******************************************************************************
\
\       Name: MLU2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = |A| * Q
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of a sign-magnitude 8-bit number P with an
\ unsigned number Q:
\
\   (A P) = |A| * Q
\
\ ******************************************************************************

.MLU2

 AND #%01111111         \ Clear the sign bit in P, so P = |A|
 STA P

                        \ Fall through into MULTU to calculate:
                        \
                        \   (A P) = P * Q
                        \         = |A| * Q

\ ******************************************************************************
\
\       Name: MULTU
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = P * Q
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of unsigned 8-bit numbers:
\
\   (A P) = P * Q
\
\ ******************************************************************************

.MULTU

 LDX Q                  \ Set X = Q

 BEQ MU1                \ If X = Q = 0, jump to MU1 to copy X into P and A,
                        \ clear the C flag and return from the subroutine using
                        \ a tail call

                        \ Otherwise fall through into MU11 to set (A P) = P * X

\ ******************************************************************************
\
\       Name: MU11
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = P * X
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two unsigned 8-bit numbers:
\
\   (A P) = P * X
\
\ This uses the same shift-and-add approach as MULT1, but it's simpler as we
\ are dealing with unsigned numbers in P and X. See the deep dive on
\ "Shift-and-add multiplication" for a discussion of how this algorithm works.
\
\ ******************************************************************************

.MU11

 DEX                    \ Set T = X - 1
 STX T                  \
                        \ We subtract 1 as the C flag will be set when we want
                        \ to do an addition in the loop below

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 TAX                    \ Copy A into X. There is a comment in the original
                        \ source here that says "just in case", which refers to
                        \ the MU11 routine in the cassette and disc versions,
                        \ which set X to 0 (as they use X as a loop counter).
                        \ The version here doesn't use a loop, but this
                        \ instruction makes sure the unrolled version returns
                        \ the same results as the loop versions, just in case
                        \ something out there relies on MU11 returning X = 0

 LSR P                  \ Set P = P >> 1
                        \ and C flag = bit 0 of P

                        \ We now repeat the following four instruction block
                        \ eight times, one for each bit in P. In the cassette
                        \ and disc versions of Elite the following is done with
                        \ a loop, but it is marginally faster to unroll the loop
                        \ and have eight copies of the code, though it does take
                        \ up a bit more memory (though that isn't a concern when
                        \ you have a 6502 Second Processor)

 BCC P%+4               \ If C (i.e. bit 0 of P) is set, do the
 ADC T                  \ addition for this bit of P:
                        \
                        \   A = A + T + C
                        \     = A + X - 1 + 1
                        \     = A + X

 ROR A                  \ Shift A right to catch the next digit of our result,
                        \ which the next ROR sticks into the left end of P while
                        \ also extracting the next bit of P

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation into the C flag

 BCC P%+4               \ Repeat for the second time
 ADC T
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the third time
 ADC T
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the fourth time
 ADC T
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the fifth time
 ADC T
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the sixth time
 ADC T
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the seventh time
 ADC T
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the eighth time
 ADC T
 ROR A
 ROR P

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FMLTU2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate A = K * sin(A)
\  Deep dive: The sine, cosine and arctan tables
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   A = K * sin(A)
\
\ Because this routine uses the sine lookup table SNE, we can also call this
\ routine to calculate cosine multiplication. To calculate the following:
\
\   A = K * cos(B)
\
\ call this routine with B + 16 in the accumulator, as sin(B + 16) = cos(B).
\
\ ******************************************************************************

.FMLTU2

 AND #%00011111         \ Restrict A to bits 0-5 (so it's in the range 0-31)

 TAX                    \ Set Q = sin(A) * 256
 LDA SNE,X
 STA Q

 LDA K                  \ Set A to the radius in K

                        \ Fall through into FMLTU to do the following:
                        \
                        \   (A ?) = A * Q
                        \         = K * sin(A) * 256
                        \ which is equivalent to:
                        \
                        \   A = K * sin(A)

\ ******************************************************************************
\
\       Name: FMLTU
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate A = A * Q / 256
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two unsigned 8-bit numbers, returning only
\ the high byte of the result:
\
\   (A ?) = A * Q
\
\ or, to put it another way:
\
\   A = A * Q / 256
\
\ ******************************************************************************

.FMLTU

 STX P                  \ Store X in P so we can preserve it through the call to
                        \ FMULTU

 STA widget             \ Store A in widget, so now widget = argument A

 TAX                    \ Transfer A into X, so now X = argument A

 BEQ MU3                \ If A = 0, jump to MU3 to return a result of 0, as
                        \ 0 * Q / 256 is always 0

                        \ We now want to calculate La + Lq, first adding the low
                        \ bytes (from the logL table), and then the high bytes
                        \ (from the log table)

 LDA logL,X             \ Set A = low byte of La
                        \       = low byte of La (as we set X to A above)

 LDX Q                  \ Set X = Q

 BEQ MU3again           \ If X = 0, jump to MU3again to return a result of 0, as
                        \ A * 0 / 256 is always 0

 CLC                    \ Set A = A + low byte of Lq
 ADC logL,X             \       = low byte of La + low byte of Lq

 LDA log,X              \ Set A = high byte of Lq

 LDX widget             \ Set A = A + C + high byte of La
 ADC log,X              \       = high byte of Lq + high byte of La + C
                        \
                        \ so we now have:
                        \
                        \   A = high byte of (La + Lq)

 BCC MU3again           \ If the addition fitted into one byte and didn't carry,
                        \ then La + Lq < 256, so we jump to MU3again to return a
                        \ result of 0

 TAX                    \ Otherwise La + Lq >= 256, so we return the A-th entry
 LDA antilog,X          \ from the antilog table

 LDX P                  \ Restore X from P so it is preserved

 RTS                    \ Return from the subroutine

.MU3again

 LDA #0                 \ Set A = 0 ???

.MU3

                        \ If we get here then A (our result) is already 0

 LDX P                  \ Restore X from P so it is preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MLTU2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P+1 P) = (A ~P) * Q
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of an unsigned 16-bit number and an unsigned
\ 8-bit number:
\
\   (A P+1 P) = (A ~P) * Q
\
\ where ~P means P EOR %11111111 (i.e. P with all its bits flipped). In other
\ words, if you wanted to calculate &1234 * &56, you would:
\
\   * Set A to &12
\   * Set P to &34 EOR %11111111 = &CB
\   * Set Q to &56
\
\ before calling MLTU2.
\
\ This routine is like a mash-up of MU11 and FMLTU. It uses part of FMLTU's
\ inverted argument trick to work out whether or not to do an addition, and like
\ MU11 it sets up a counter in X to extract bits from (P+1 P). But this time we
\ extract 16 bits from (P+1 P), so the result is a 24-bit number. The core of
\ the algorithm is still the shift-and-add approach explained in MULT1, just
\ with more bits.
\
\ Returns:
\
\   Q                   Q is preserved
\
\ Other entry points:
\
\   MLTU2-2             Set Q to X, so this calculates (A P+1 P) = (A ~P) * X
\
\ ******************************************************************************

 STX Q                  \ Store X in Q

.MLTU2

 EOR #%11111111         \ Flip the bits in A and rotate right, storing the
 LSR A                  \ result in P+1, so we now calculate (P+1 P) * Q
 STA P+1

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDX #16                \ Set up a counter in X to count the 16 bits in (P+1 P)

 ROR P                  \ Set P = P >> 1 with bit 7 = bit 0 of A
                        \ and C flag = bit 0 of P

.MUL7

 BCS MU21               \ If C (i.e. the next bit from P) is set, do not do the
                        \ addition for this bit of P, and instead skip to MU21
                        \ to just do the shifts

 ADC Q                  \ Do the addition for this bit of P:
                        \
                        \   A = A + Q + C
                        \     = A + Q

 ROR A                  \ Rotate (A P+1 P) to the right, so we capture the next
 ROR P+1                \ digit of the result in P+1, and extract the next digit
 ROR P                  \ of (P+1 P) in the C flag

 DEX                    \ Decrement the loop counter

 BNE MUL7               \ Loop back for the next bit until P has been rotated
                        \ all the way

 RTS                    \ Return from the subroutine

.MU21

 LSR A                  \ Shift (A P+1 P) to the right, so we capture the next
 ROR P+1                \ digit of the result in P+1, and extract the next digit
 ROR P                  \ of (P+1 P) in the C flag

 DEX                    \ Decrement the loop counter

 BNE MUL7               \ Loop back for the next bit until P has been rotated
                        \ all the way

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MUT3
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Unused routine that does the same as MUT2
\
\ ------------------------------------------------------------------------------
\
\ This routine is never actually called, but it is identical to MUT2, as the
\ extra instructions have no effect.
\
\ ******************************************************************************

.MUT3

 LDX ALP1               \ Set P = ALP1, though this gets overwritten by the
 STX P                  \ following, so this has no effect

                        \ Fall through into MUT2 to do the following:
                        \
                        \   (S R) = XX(1 0)
                        \   (A P) = Q * A

\ ******************************************************************************
\
\       Name: MUT2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (S R) = XX(1 0) and (A P) = Q * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following assignment, and multiplication of two signed 8-bit numbers:
\
\   (S R) = XX(1 0)
\   (A P) = Q * A
\
\ ******************************************************************************

.MUT2

 LDX XX+1               \ Set S = XX+1
 STX S

                        \ Fall through into MUT1 to do the following:
                        \
                        \   R = XX
                        \   (A P) = Q * A

\ ******************************************************************************
\
\       Name: MUT1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate R = XX and (A P) = Q * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following assignment, and multiplication of two signed 8-bit numbers:
\
\   R = XX
\   (A P) = Q * A
\
\ ******************************************************************************

.MUT1

 LDX XX                 \ Set R = XX
 STX R

                        \ Fall through into MULT1 to do the following:
                        \
                        \   (A P) = Q * A

\ ******************************************************************************
\
\       Name: MULT1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = Q * A
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two 8-bit sign-magnitude numbers:
\
\   (A P) = Q * A
\
\ ******************************************************************************

.MULT1

 TAX                    \ Store A in X

 AND #%01111111         \ Set P = |A| >> 1
 LSR A                  \ and C flag = bit 0 of A
 STA P

 TXA                    \ Restore argument A

 EOR Q                  \ Set bit 7 of A and T if Q and A have different signs,
 AND #%10000000         \ clear bit 7 if they have the same signs, 0 all other
 STA T                  \ bits, i.e. T contains the sign bit of Q * A

 LDA Q                  \ Set A = |Q|
 AND #%01111111

 BEQ mu10               \ If |Q| = 0 jump to mu10 (with A set to 0)

 TAX                    \ Set T1 = |Q| - 1
 DEX                    \
 STX T1                 \ We subtract 1 as the C flag will be set when we want
                        \ to do an addition in the loop below

                        \ We are now going to work our way through the bits of
                        \ P, and do a shift-add for any bits that are set,
                        \ keeping the running total in A. We already set up
                        \ the first shift at the start of this routine, as
                        \ P = |A| >> 1 and C = bit 0 of A, so we now need to set
                        \ up a loop to sift through the other 7 bits in P

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 TAX                    \ Copy A into X. There is a comment in the original
                        \ source here that says "just in case", which refers to
                        \ the MULT1 routine in the cassette and disc versions,
                        \ which set X to 0 (as they use X as a loop counter).
                        \ The version here doesn't use a loop, but this
                        \ instruction makes sure the unrolled version returns
                        \ the same results as the loop versions, just in case
                        \ something out there relies on MULT1 returning X = 0

\MUL4                   \ These instructions are commented out in the original
\BCC P%+4               \ source. They contain the original loop version of the
\ADC T1                 \ code that's used in the disc and cassette versions
\ROR A
\ROR P
\DEX
\BNE MUL4
\LSR A
\ROR P
\ORA T
\RTS
\.mu10
\STA P
\RTS

                        \ We now repeat the following four instruction block
                        \ seven times, one for each remaining bit in P. In the
                        \ cassette and disc versions of Elite the following is
                        \ done with a loop, but it is marginally faster to
                        \ unroll the loop and have seven copies of the code,
                        \ though it does take up a bit more memory (though that
                        \ isn't a concern when you have a 6502 Second Processor)

 BCC P%+4               \ If C (i.e. the next bit from P) is set, do the
 ADC T1                 \ addition for this bit of P:
                        \
                        \   A = A + T1 + C
                        \     = A + |Q| - 1 + 1
                        \     = A + |Q|

 ROR A                  \ As mentioned above, this ROR shifts A right and
                        \ catches bit 0 in C - giving another digit for our
                        \ result - and the next ROR sticks that bit into the
                        \ left end of P while also extracting the next bit of P
                        \ for the next addition

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation

 BCC P%+4               \ Repeat for the second time
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the third time
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the fourth time
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the fifth time
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the sixth time
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat for the seventh time
 ADC T1
 ROR A
 ROR P

 LSR A                  \ Rotate (A P) once more to get the final result, as
 ROR P                  \ we only pushed 7 bits through the above process

 ORA T                  \ Set the sign bit of the result that we stored in T

 RTS                    \ Return from the subroutine

.mu10

 STA P                  \ If we get here, the result is 0 and A = 0, so set
                        \ P = 0 so (A P) = 0

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MULT12
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (S R) = Q * A
\
\ ------------------------------------------------------------------------------
\
\ Calculate:
\
\   (S R) = Q * A
\
\ ******************************************************************************

.MULT12

 JSR MULT1              \ Set (A P) = Q * A

 STA S                  \ Set (S R) = (A P)
 LDA P
 STA R

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TAS3
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the dot product of XX15 and an orientation vector
\
\ ------------------------------------------------------------------------------
\
\ Calculate the dot product of the vector in XX15 and one of the orientation
\ vectors, as determined by the value of Y. If vect is the orientation vector,
\ we calculate this:
\
\   (A X) = vect . XX15
\         = vect_x * XX15 + vect_y * XX15+1 + vect_z * XX15+2
\
\ Arguments:
\
\   Y                   The orientation vector:
\
\                         * If Y = 10, calculate nosev . XX15
\
\                         * If Y = 16, calculate roofv . XX15
\
\                         * If Y = 22, calculate sidev . XX15
\
\ Returns:
\
\   (A X)               The result of the dot product
\
\ ******************************************************************************

.TAS3

 LDX INWK,Y             \ Set Q = the Y-th byte of INWK, i.e. vect_x
 STX Q

 LDA XX15               \ Set A = XX15

 JSR MULT12             \ Set (S R) = Q * A
                        \           = vect_x * XX15

 LDX INWK+2,Y           \ Set Q = the Y+2-th byte of INWK, i.e. vect_y
 STX Q

 LDA XX15+1             \ Set A = XX15+1

 JSR MAD                \ Set (A X) = Q * A + (S R)
                        \           = vect_y * XX15+1 + vect_x * XX15

 STA S                  \ Set (S R) = (A X)
 STX R

 LDX INWK+4,Y           \ Set Q = the Y+2-th byte of INWK, i.e. vect_z
 STX Q

 LDA XX15+2             \ Set A = XX15+2

                        \ Fall through into MAD to set:
                        \
                        \   (A X) = Q * A + (S R)
                        \           = vect_z * XX15+2 + vect_y * XX15+1 +
                        \             vect_x * XX15

\ ******************************************************************************
\
\       Name: MAD
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A X) = Q * A + (S R)
\
\ ------------------------------------------------------------------------------
\
\ Calculate
\
\   (A X) = Q * A + (S R)
\
\ ******************************************************************************

.MAD

 JSR MULT1              \ Call MULT1 to set (A P) = Q * A

                        \ Fall through into ADD to do:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = Q * A + (S R)

\ ******************************************************************************
\
\       Name: ADD
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A X) = (A P) + (S R)
\  Deep dive: Adding sign-magnitude numbers
\
\ ------------------------------------------------------------------------------
\
\ Add two 16-bit sign-magnitude numbers together, calculating:
\
\   (A X) = (A P) + (S R)
\
\ ******************************************************************************

.ADD

 STA T1                 \ Store argument A in T1

 AND #%10000000         \ Extract the sign (bit 7) of A and store it in T
 STA T

 EOR S                  \ EOR bit 7 of A with S. If they have different bit 7s
 BMI MU8                \ (i.e. they have different signs) then bit 7 in the
                        \ EOR result will be 1, which means the EOR result is
                        \ negative. So the AND, EOR and BMI together mean "jump
                        \ to MU8 if A and S have different signs"

                        \ If we reach here, then A and S have the same sign, so
                        \ we can add them and set the sign to get the result

 LDA R                  \ Add the least significant bytes together into X:
 CLC                    \
 ADC P                  \   X = P + R
 TAX

 LDA S                  \ Add the most significant bytes together into A. We
 ADC T1                 \ stored the original argument A in T1 earlier, so we
                        \ can do this with:
                        \
                        \   A = A  + S + C
                        \     = T1 + S + C

 ORA T                  \ If argument A was negative (and therefore S was also
                        \ negative) then make sure result A is negative by
                        \ OR-ing the result with the sign bit from argument A
                        \ (which we stored in T)

 RTS                    \ Return from the subroutine

.MU8

                        \ If we reach here, then A and S have different signs,
                        \ so we can subtract their absolute values and set the
                        \ sign to get the result

 LDA S                  \ Clear the sign (bit 7) in S and store the result in
 AND #%01111111         \ U, so U now contains |S|
 STA U

 LDA P                  \ Subtract the least significant bytes into X:
 SEC                    \
 SBC R                  \   X = P - R
 TAX

 LDA T1                 \ Restore the A of the argument (A P) from T1 and
 AND #%01111111         \ clear the sign (bit 7), so A now contains |A|

 SBC U                  \ Set A = |A| - |S|

                        \ At this point we have |A P| - |S R| in (A X), so we
                        \ need to check whether the subtraction above was the
                        \ the right way round (i.e. that we subtracted the
                        \ smaller absolute value from the larger absolute
                        \ value)

 BCS MU9                \ If |A| >= |S|, our subtraction was the right way
                        \ round, so jump to MU9 to set the sign

                        \ If we get here, then |A| < |S|, so our subtraction
                        \ above was the wrong way round (we actually subtracted
                        \ the larger absolute value from the smaller absolute
                        \ value). So let's subtract the result we have in (A X)
                        \ from zero, so that the subtraction is the right way
                        \ round

 STA U                  \ Store A in U

 TXA                    \ Set X = 0 - X using two's complement (to negate a
 EOR #&FF               \ number in two's complement, you can invert the bits
 ADC #1                 \ and add one - and we know the C flag is clear as we
 TAX                    \ didn't take the BCS branch above, so the ADC will do
                        \ the correct addition)

 LDA #0                 \ Set A = 0 - A, which we can do this time using a
 SBC U                  \ a subtraction with the C flag clear

 ORA #%10000000         \ We now set the sign bit of A, so that the EOR on the
                        \ next line will give the result the opposite sign to
                        \ argument A (as T contains the sign bit of argument
                        \ A). This is the same as giving the result the same
                        \ sign as argument S (as A and S have different signs),
                        \ which is what we want, as S has the larger absolute
                        \ value

.MU9

 EOR T                  \ If we get here from the BCS above, then |A| >= |S|,
                        \ so we want to give the result the same sign as
                        \ argument A, so if argument A was negative, we flip
                        \ the sign of the result with an EOR (to make it
                        \ negative)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TIS1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A ?) = (-X * A + (S R)) / 96
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following expression between sign-magnitude numbers, ignoring
\ the low byte of the result:
\
\   (A ?) = (-X * A + (S R)) / 96
\
\ This uses the same shift-and-subtract algorithm as TIS2, just with the
\ quotient A hard-coded to 96.
\
\ Returns:
\
\   Q                   Gets set to the value of argument X
\
\ ******************************************************************************

.TIS1

 STX Q                  \ Set Q = X

 EOR #%10000000         \ Flip the sign bit in A

 JSR MAD                \ Set (A X) = Q * A + (S R)
                        \           = X * -A + (S R)

.DVID96

 TAX                    \ Set T to the sign bit of the result
 AND #%10000000
 STA T

 TXA                    \ Set A to the high byte of the result with the sign bit
 AND #%01111111         \ cleared, so (A ?) = |X * A + (S R)|

                        \ The following is identical to TIS2, except Q is
                        \ hard-coded to 96, so this does A = A / 96

 LDX #254               \ Set T1 to have bits 1-7 set, so we can rotate through
 STX T1                 \ 7 loop iterations, getting a 1 each time, and then
                        \ getting a 0 on the 8th iteration... and we can also
                        \ use T1 to catch our result bits into bit 0 each time

.DVL3

 ASL A                  \ Shift A to the left

 CMP #96                \ If A < 96 skip the following subtraction
 BCC DV4

 SBC #96                \ Set A = A - 96
                        \
                        \ Going into this subtraction we know the C flag is
                        \ set as we passed through the BCC above, and we also
                        \ know that A >= 96, so the C flag will still be set
                        \ once we are done

.DV4

 ROL T1                 \ Rotate the counter in T1 to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS DVL3               \ If we still have set bits in T1, loop back to DVL3 to
                        \ do the next iteration of 7

 LDA T1                 \ Fetch the result from T1 into A

 ORA T                  \ Give A the sign of the result that we stored above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DV42
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (P R) = 256 * DELTA / z_hi
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following division and remainder:
\
\   P = DELTA / (the Y-th stardust particle's z_hi coordinate)
\
\   R = remainder as a fraction of A, where 1.0 = 255
\
\ Another way of saying the above is this:
\
\   (P R) = 256 * DELTA / z_hi
\
\ DELTA is a value between 1 and 40, and the minimum z_hi is 16 (dust particles
\ are removed at lower values than this), so this means P is between 0 and 2
\ (as 40 / 16 = 2.5, so the maximum result is P = 2 and R = 128.
\
\ This uses the same shift-and-subtract algorithm as TIS2, but this time we
\ keep the remainder.
\
\ Arguments:
\
\   Y                   The number of the stardust particle to process
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.DV42

 LDA SZ,Y               \ Fetch the Y-th dust particle's z_hi coordinate into A

\ ******************************************************************************
\
\       Name: DV41
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (P R) = 256 * DELTA / A
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following division and remainder:
\
\   P = DELTA / A
\
\   R = remainder as a fraction of A, where 1.0 = 255
\
\ Another way of saying the above is this:
\
\   (P R) = 256 * DELTA / A
\
\ This uses the same shift-and-subtract algorithm as TIS2, but this time we
\ keep the remainder.
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.DV41

 STA Q                  \ Store A in Q

 LDA DELTA              \ Fetch the speed from DELTA into A

\ ******************************************************************************
\
\       Name: DVID4
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (P R) = 256 * A / Q
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following division and remainder:
\
\   P = A / Q
\
\   R = remainder as a fraction of Q, where 1.0 = 255
\
\ Another way of saying the above is this:
\
\   (P R) = 256 * A / Q
\
\ This uses the same shift-and-subtract algorithm as TIS2, but this time we
\ keep the remainder and the loop is unrolled.
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.DVID4

 ASL A                  \ Shift A left and store in P (we will build the result
 STA P                  \ in P)

 LDA #0                 \ Set A = 0 for us to build a remainder

                        \ We now repeat the following five instruction block
                        \ eight times, one for each bit in P. In the cassette
                        \ and disc versions of Elite the following is done with
                        \ a loop, but it is marginally faster to unroll the loop
                        \ and have eight copies of the code, though it does take
                        \ up a bit more memory (though that isn't a concern when
                        \ you have a 6502 Second Processor)

 ROL A                  \ Shift A to the left

 CMP Q                  \ If A < Q skip the following subtraction
 BCC P%+4

 SBC Q                  \ A >= Q, so set A = A - Q

 ROL P                  \ Shift P to the left, pulling the C flag into bit 0

 ROL A                  \ Repeat for the second time
 CMP Q
 BCC P%+4
 SBC Q
 ROL P

 ROL A                  \ Repeat for the third time
 CMP Q
 BCC P%+4
 SBC Q
 ROL P

 ROL A                  \ Repeat for the fourth time
 CMP Q
 BCC P%+4
 SBC Q
 ROL P

 ROL A                  \ Repeat for the fifth time
 CMP Q
 BCC P%+4
 SBC Q
 ROL P

 ROL A                  \ Repeat for the sixth time
 CMP Q
 BCC P%+4
 SBC Q
 ROL P

 ROL A                  \ Repeat for the seventh time
 CMP Q
 BCC P%+4
 SBC Q
 ROL P

 ROL A                  \ Repeat for the eighth time
 CMP Q
 BCC P%+4
 SBC Q
 ROL P

 LDX #0                 \ Set X = 0 so this unrolled version of DVID4 also
                        \ returns X = 0

{
 STA widget
 TAX
 BEQ LLfix

 LDA logL,X
 LDX Q
 SEC
 SBC logL,X
 LDX widget
 LDA log,X
 LDX Q
 SBC log,X
 BCS LL2

 TAX
 LDA antilog,X

.LLfix

 STA R
 RTS

.LL2

 LDA #&FF
 STA R
 RTS
}

\ ******************************************************************************
\
\       Name: DVID3B2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate K(3 2 1 0) = (A P+1 P) / (z_sign z_hi z_lo)
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   K(3 2 1 0) = (A P+1 P) / (z_sign z_hi z_lo)
\
\ The actual division here is done as an 8-bit calculation using LL31, but this
\ routine shifts both the numerator (the top part of the division) and the
\ denominator (the bottom part of the division) around to get the multi-byte
\ result we want.
\
\ Specifically, it shifts both of them to the left as far as possible, keeping a
\ tally of how many shifts get done in each one - and specifically, the
\ difference in the number of shifts between the top and bottom (as shifting
\ both of them once in the same direction won't change the result). It then
\ divides the two highest bytes with the simple 8-bit routine in LL31, and
\ shifts the result by the difference in the number of shifts, which acts as a
\ scale factor to get the correct result.
\
\ Returns:
\
\   K(3 2 1 0)          The result of the division
\
\   X                   X is preserved
\
\ ******************************************************************************

.DVID3B2

 STA P+2                \ Set P+2 = A

 LDA INWK+6             \ Set Q = z_lo, making sure Q is at least 1
 ORA #1
 STA Q

 LDA INWK+7             \ Set R = z_hi
 STA R

 LDA INWK+8             \ Set S = z_sign
 STA S

.DVID3B

                        \ Given the above assignments, we now want to calculate
                        \ the following to get the result we want:
                        \
                        \   K(3 2 1 0) = P(2 1 0) / (S R Q)

 LDA P                  \ Make sure P(2 1 0) is at least 1
 ORA #1
 STA P

 LDA P+2                \ Set T to the sign of P+2 * S (i.e. the sign of the
 EOR S                  \ result) and store it in T
 AND #%10000000
 STA T

 LDY #0                 \ Set Y = 0 to store the scale factor

 LDA P+2                \ Clear the sign bit of P+2, so the division can be done
 AND #%01111111         \ with positive numbers and we'll set the correct sign
                        \ below, once all the maths is done
                        \
                        \ This also leaves A = P+2, which we use below

.DVL9

                        \ We now shift (A P+1 P) left until A >= 64, counting
                        \ the number of shifts in Y. This makes the top part of
                        \ the division as large as possible, thus retaining as
                        \ much accuracy as we can.  When we come to return the
                        \ final result, we shift the result by the number of
                        \ places in Y, and in the correct direction

 CMP #64                \ If A >= 64, jump down to DV14
 BCS DV14

 ASL P                  \ Shift (A P+1 P) to the left
 ROL P+1
 ROL A

 INY                    \ Increment the scale factor in Y

 BNE DVL9               \ Loop up to DVL9 (this BNE is effectively a JMP, as Y
                        \ will never be zero)

.DV14

                        \ If we get here, A >= 64 and contains the highest byte
                        \ of the numerator, scaled up by the number of left
                        \ shifts in Y

 STA P+2                \ Store A in P+2, so we now have the scaled value of
                        \ the numerator in P(2 1 0)

 LDA S                  \ Set A = |S|
 AND #%01111111

.DVL6

                        \ We now shift (S R Q) left until bit 7 of S is set,
                        \ reducing Y by the number of shifts. This makes the
                        \ bottom part of the division as large as possible, thus
                        \ retaining as much accuracy as we can. When we come to
                        \ return the final result, we shift the result by the
                        \ total number of places in Y, and in the correct
                        \ direction, to give us the correct result
                        \
                        \ We set A to |S| above, so the following actually
                        \ shifts (A R Q)

 DEY                    \ Decrement the scale factor in Y

 ASL Q                  \ Shift (A R Q) to the left
 ROL R
 ROL A

 BPL DVL6               \ Loop up to DVL6 to do another shift, until bit 7 of A
                        \ is set and we can't shift left any further

.DV9

                        \ We have now shifted both the numerator and denominator
                        \ left as far as they will go, keeping a tally of the
                        \ overall scale factor of the various shifts in Y. We
                        \ can now divide just the two highest bytes to get our
                        \ result

 STA Q                  \ Set Q = A, the highest byte of the denominator

 LDA #254               \ Set R to have bits 1-7 set, so we can pass this to
 STA R                  \ LL31 to act as the bit counter in the division

 LDA P+2                \ Set A to the highest byte of the numerator

{
.LL31

 ASL A
 BCS LL29

 CMP Q
 BCC P%+4

 SBC Q

 ROL R

 BCS LL31

 JMP RTS

.LL29

 SBC Q
 SEC
 ROL R
 BCS LL31

 LDA R

.RTS
}

 LDA #0                 \ Set K(3 2 1) = 0 to hold the result (we populate K
 STA K+1                \ next)
 STA K+2
 STA K+3

 TYA                    \ If Y is positive, jump to DV12
 BPL DV12

                        \ If we get here then Y is negative, so we need to shift
                        \ the result R to the left by Y places, and then set the
                        \ correct sign for the result

 LDA R                  \ Set A = R

.DVL8

 ASL A                  \ Shift (K+3 K+2 K+1 A) left
 ROL K+1
 ROL K+2
 ROL K+3

 INY                    \ Increment the scale factor in Y

 BNE DVL8               \ Loop back to DVL8 until we have shifted left by Y
                        \ places

 STA K                  \ Store A in K so the result is now in K(3 2 1 0)

 LDA K+3                \ Set K+3 to the sign in T, which we set above to the
 ORA T                  \ correct sign for the result
 STA K+3

 RTS                    \ Return from the subroutine

.DV13

                        \ If we get here then Y is zero, so we don't need to
                        \ shift the result R, we just need to set the correct
                        \ sign for the result

 LDA R                  \ Store R in K so the result is now in K(3 2 1 0)
 STA K

 LDA T                  \ Set K+3 to the sign in T, which we set above to the
 STA K+3                \ correct sign for the result

 RTS                    \ Return from the subroutine

.DV12

 BEQ DV13               \ We jumped here having set A to the scale factor in Y,
                        \ so this jumps up to DV13 if Y = 0

                        \ If we get here then Y is positive and non-zero, so we
                        \ need to shift the result R to the right by Y places
                        \ and then set the correct sign for the result. We also
                        \ know that K(3 2 1) will stay 0, as we are shifting the
                        \ lowest byte to the right, so no set bits will make
                        \ their way into the top three bytes

 LDA R                  \ Set A = R

.DVL10

 LSR A                  \ Shift A right

 DEY                    \ Decrement the scale factor in Y

 BNE DVL10              \ Loop back to DVL10 until we have shifted right by Y
                        \ places

 STA K                  \ Store the shifted A in K so the result is now in
                        \ K(3 2 1 0)

 LDA T                  \ Set K+3 to the sign in T, which we set above to the
 STA K+3                \ correct sign for the result

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: cntr
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Apply damping to the pitch or roll dashboard indicator
\
\ ------------------------------------------------------------------------------
\
\ Apply damping to the value in X, where X ranges from 1 to 255 with 128 as the
\ centre point (so X represents a position on a centre-based dashboard slider,
\ such as pitch or roll). If the value is in the left-hand side of the slider
\ (1-127) then it bumps the value up by 1 so it moves towards the centre, and
\ if it's in the right-hand side, it reduces it by 1, also moving it towards the
\ centre.
\
\ ******************************************************************************

.cntr

 LDA auto               \ If the docking computer is currently activated, jump
 BNE cnt2               \ to cnt2 to skip the following as we always want to
                        \ enable damping for the docking computer

 LDA DAMP               \ If DAMP is non-zero, then keyboard damping is not
 BNE RE1                \ enabled, so jump to RE1 to return from the subroutine

.cnt2

 TXA                    \ If X < 128, then it's in the left-hand side of the
 BPL BUMP               \ dashboard slider, so jump to BUMP to bump it up by 1,
                        \ to move it closer to the centre

 DEX                    \ Otherwise X >= 128, so it's in the right-hand side
 BMI ARCRTS             \ of the dashboard slider, so decrement X by 1, and if
                        \ it's still >= 128, jump to ARCRTS to return from the
                        \ subroutine, otherwise fall through to BUMP to undo
                        \ the bump and then return

.BUMP

 INX                    \ Bump X up by 1, and if it hasn't overshot the end of
 BNE RE1                \ the dashboard slider, jump to RE1 to return from the
                        \ subroutine, otherwise fall through to REDU to drop
                        \ it down by 1 again

.REDU

 DEX                    \ Reduce X by 1, and if we have reached 0 jump up to
 BEQ BUMP               \ BUMP to add 1, because we need the value to be in the
                        \ range 1 to 255

.RE1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: BUMP2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Bump up the value of the pitch or roll dashboard indicator
\
\ ------------------------------------------------------------------------------
\
\ Increase ("bump up") X by A, where X is either the current rate of pitch or
\ the current rate of roll.
\
\ The rate of pitch or roll ranges from 1 to 255 with 128 as the centre point.
\ This is the amount by which the pitch or roll is currently changing, so 1
\ means it is decreasing at the maximum rate, 128 means it is not changing,
\ and 255 means it is increasing at the maximum rate. These values correspond
\ to the line on the DC or RL indicators on the dashboard, with 1 meaning full
\ left, 128 meaning the middle, and 255 meaning full right.
\
\ If bumping up X would push it past 255, then X is set to 255.
\
\ If keyboard auto-recentre is configured and the result is less than 128, we
\ bump X up to the mid-point, 128. This is the equivalent of having a roll or
\ pitch in the left half of the indicator, when increasing the roll or pitch
\ should jump us straight to the mid-point.
\
\ Other entry points:
\
\   RE2+2               Restore A from T and return from the subroutine
\
\ ******************************************************************************

.BUMP2

 STA T                  \ Store argument A in T so we can restore it later

 TXA                    \ Copy argument X into A

 CLC                    \ Clear the C flag so we can do addition without the
                        \ C flag affecting the result

 ADC T                  \ Set X = A = argument X + argument A
 TAX

 BCC RE2                \ If the C flag is clear, then we didn't overflow, so
                        \ jump to RE2 to auto-recentre and return the result

 LDX #255               \ We have an overflow, so set X to the maximum possible
                        \ value of 255

.RE2

 BPL djd1               \ If X has bit 7 clear (i.e. the result < 128), then
                        \ jump to djd1 in routine REDU2 to do an auto-recentre,
                        \ if configured, because the result is on the left side
                        \ of the centre point of 128

                        \ Jumps to RE2+2 end up here

 LDA T                  \ Restore the original argument A from T into A

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: REDU2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Reduce the value of the pitch or roll dashboard indicator
\
\ ------------------------------------------------------------------------------
\
\ Reduce X by A, where X is either the current rate of pitch or the current
\ rate of roll.
\
\ The rate of pitch or roll ranges from 1 to 255 with 128 as the centre point.
\ This is the amount by which the pitch or roll is currently changing, so 1
\ means it is decreasing at the maximum rate, 128 means it is not changing,
\ and 255 means it is increasing at the maximum rate. These values correspond
\ to the line on the DC or RL indicators on the dashboard, with 1 meaning full
\ left, 128 meaning the middle, and 255 meaning full right.
\
\ If reducing X would bring it below 1, then X is set to 1.
\
\ If keyboard auto-recentre is configured and the result is greater than 128, we
\ reduce X down to the mid-point, 128. This is the equivalent of having a roll
\ or pitch in the right half of the indicator, when decreasing the roll or pitch
\ should jump us straight to the mid-point.
\
\ Other entry points:
\
\
\ ******************************************************************************

.REDU2

 STA T                  \ Store argument A in T so we can restore it later

 TXA                    \ Copy argument X into A

 SEC                    \ Set the C flag so we can do subtraction without the
                        \ C flag affecting the result

 SBC T                  \ Set X = A = argument X - argument A
 TAX

 BCS RE3                \ If the C flag is set, then we didn't underflow, so
                        \ jump to RE3 to auto-recentre and return the result

 LDX #1                 \ We have an underflow, so set X to the minimum possible
                        \ value, 1

.RE3

 BPL RE2+2              \ If X has bit 7 clear (i.e. the result < 128), then
                        \ jump to RE2+2 above to return the result as is,
                        \ because the result is on the left side of the centre
                        \ point of 128, so we don't need to auto-centre

.djd1

                        \ If we get here, then we need to apply auto-recentre,
                        \ if it is configured

 LDA DJD                \ If keyboard auto-recentre is disabled, then
 BNE RE2+2              \ jump to RE2+2 to restore A and return

 LDX #128               \ If keyboard auto-recentre is enabled, set X to 128
 BMI RE2+2              \ (the middle of our range) and jump to RE2+2 to
                        \ restore A and return

\ ******************************************************************************
\
\       Name: ARCTAN
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate A = arctan(P / Q)
\  Deep dive: The sine, cosine and arctan tables
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   A = arctan(P / Q)
\
\ In other words, this finds the angle in the right-angled triangle where the
\ opposite side to angle A is length P and the adjacent side to angle A has
\ length Q, so:
\
\   tan(A) = P / Q
\
\ Other entry points:
\
\   ARCRTS              Contains an RTS
\
\ ******************************************************************************

.ARCTAN

 LDA P                  \ Set T1 = P EOR Q, which will have the sign of P * Q
 EOR Q
 STA T1

 LDA Q                  \ If Q = 0, jump to AR2 to return a right angle
 BEQ AR2

 ASL A                  \ Set Q = |Q| * 2 (this is a quick way of clearing the
 STA Q                  \ sign bit, and we don't need to shift right again as we
                        \ only ever use this value in the division with |P| * 2,
                        \ which we set next)

 LDA P                  \ Set A = |P| * 2
 ASL A

 CMP Q                  \ If A >= Q, i.e. |P| > |Q|, jump to AR1 to swap P
 BCS AR1                \ and Q around, so we can still use the lookup table

 JSR ARS1               \ Call ARS1 to set the following from the lookup table:
                        \
                        \   A = arctan(A / Q)
                        \     = arctan(|P / Q|)

 SEC                    \ Set the C flag so the SBC instruction in AR3 will be
                        \ correct, should we jump there

.AR4

 LDX T1                 \ If T1 is negative, i.e. P and Q have different signs,
 BMI AR3                \ jump down to AR3 to return arctan(-|P / Q|)

 RTS                    \ Otherwise P and Q have the same sign, so our result is
                        \ correct and we can return from the subroutine

.AR1

                        \ We want to calculate arctan(t) where |t| > 1, so we
                        \ can use the calculation described in the documentation
                        \ for the ACT table, i.e. 64 - arctan(1 / t)

 LDX Q                  \ Swap the values in Q and P, using the fact that we
 STA Q                  \ called AR1 with A = P
 STX P                  \
 TXA                    \ This also sets A = P (which now contains the original
                        \ argument |Q|)

 JSR ARS1               \ Call ARS1 to set the following from the lookup table:
                        \
                        \   A = arctan(A / Q)
                        \     = arctan(|Q / P|)
                        \     = arctan(1 / |P / Q|)

 STA T                  \ Set T = 64 - T
 LDA #64
 SBC T

 BCS AR4                \ Jump to AR4 to continue the calculation (this BCS is
                        \ effectively a JMP as the subtraction will never
                        \ underflow, as ARS1 returns values in the range 0-31)

.AR2

                        \ If we get here then Q = 0, so tan(A) = infinity and
                        \ A is a right angle, or 0.25 of a circle. We allocate
                        \ 255 to a full circle, so we should return 63 for a
                        \ right angle

 LDA #63                \ Set A to 63, to represent a right angle

 RTS                    \ Return from the subroutine

.AR3

                        \ A contains arctan(|P / Q|) but P and Q have different
                        \ signs, so we need to return arctan(-|P / Q|), using
                        \ the calculation described in the documentation for the
                        \ ACT table, i.e. 128 - A

 STA T                  \ Set A = 128 - A
 LDA #128               \
\SEC                    \ The SEC instruction is commented out in the original
 SBC T                  \ source, and isn't required as we did a SEC before
                        \ calling AR3

 RTS                    \ Return from the subroutine

.ARS1

                        \ This routine fetches arctan(A / Q) from the ACT table

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q

 LDA R                  \ Set X = R / 8
 LSR A                  \       = 32 * A / Q
 LSR A                  \
 LSR A                  \ so X has the value t * 32 where t = A / Q, which is
 TAX                    \ what we need to look up values in the ACT table

 LDA ACT,X              \ Fetch ACT+X from the ACT table into A, so now:
                        \
                        \   A = value in ACT + X
                        \     = value in ACT + (32 * A / Q)
                        \     = arctan(A / Q)

.ARCRTS

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LASLI
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw the laser lines for when we fire our lasers
\
\ ------------------------------------------------------------------------------
\
\ Draw the laser lines, aiming them to slightly different place each time so
\ they appear to flicker and dance. Also heat up the laser temperature and drain
\ some energy.
\
\ Other entry points:
\
\   LASLI2              Just draw the current laser lines without moving the
\                       centre point, draining energy or heating up. This has
\                       the effect of removing the lines from the screen
\
\   LASLI-1             Contains an RTS
\
\ ******************************************************************************

.LASLI

 JSR DORND              \ Set A and X to random numbers

 AND #7                 \ Restrict A to a random value in the range 0 to 7

 ADC #Y-4               \ Set LASY to four pixels above the centre of the
 STA LASY               \ screen (#Y), plus our random number, so the laser
                        \ dances above and below the centre point

 JSR DORND              \ Set A and X to random numbers

 AND #7                 \ Restrict A to a random value in the range 0 to 7

 ADC #X-4               \ Set LASX to four pixels left of the centre of the
 STA LASX               \ screen (#X), plus our random number, so the laser
                        \ dances to the left and right of the centre point

 LDA GNTMP              \ Add 8 to the laser temperature in GNTMP
 ADC #8
 STA GNTMP

 JSR DENGY              \ Call DENGY to deplete our energy banks by 1

.LASLI2

 LDA QQ11               \ If this is not a space view (i.e. QQ11 is non-zero)
 BNE ARCRTS             \ then jump to MA9 to return from the main flight loop
                        \ (as ARCRTS is an RTS)

 LDA #RED               \ Switch to colour 2, which is red in the space view
 STA COL

 LDA #32                \ Set A = 32 and Y = 224 for the first set of laser
 LDY #224               \ lines (the wider pair of lines)

 DEC LASY               \ Decrement the y-coordinate of the centre point to move
 DEC LASY               \ it up the screen by two pixels for the top set of
                        \ lines, so the wider set of lines aim slightly higher
                        \ than the narrower set

 JSR las                \ Call las below to draw the first set of laser lines

 INC LASY               \ Increment the y-coordinate of the centre point to put
 INC LASY               \ it back to the original position

 LDA #48                \ Fall through into las with A = 48 and Y = 208 to draw
 LDY #208               \ a second set of lines (the narrower pair)

                        \ The following routine draws two laser lines, one from
                        \ the centre point down to point A on the bottom row,
                        \ and the other from the centre point down to point Y
                        \ on the bottom row. We therefore get lines from the
                        \ centre point to points 32, 48, 208 and 224 along the
                        \ bottom row, giving us the triangular laser effect
                        \ we're after

.las

 STA X2                 \ Set X2 = A

 LDA LASX               \ Set (X1, Y1) to the random centre point we set above
 STA X1
 LDA LASY
 STA Y1

 LDA #2*Y-1             \ Set Y2 = 2 * #Y - 1. The constant #Y is 96, the
 STA Y2                 \ y-coordinate of the mid-point of the space view, so
                        \ this sets Y2 to 191, the y-coordinate of the bottom
                        \ pixel row of the space view

 JSR LL30               \ Draw a line from (X1, Y1) to (X2, Y2), so that's from
                        \ the centre point to (A, 191)

 LDA LASX               \ Set (X1, Y1) to the random centre point we set above
 STA X1
 LDA LASY
 STA Y1

 STY X2                 \ Set X2 = Y

 LDA #2*Y-1             \ Set Y2 = 2 * #Y - 1, the y-coordinate of the bottom
 STA Y2                 \ pixel row of the space view (as before)

 JMP LL30               \ Draw a line from (X1, Y1) to (X2, Y2), so that's from
                        \ the centre point to (Y, 191), and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PDESC
\       Type: Subroutine
\   Category: Text
\    Summary: Print the system's extended description or a mission 1 directive
\  Deep dive: Extended system descriptions
\             Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This prints a specific system's extended description. This is called the "pink
\ volcanoes string" in a comment in the original source, and the "goat soup"
\ recipe by Ian Bell on his website (where he also refers to the species string
\ as the "pink felines" string).
\
\ For some special systems, when you are docked at them, the procedurally
\ generated extended description is overridden and a text token from the RUTOK
\ table is shown instead. If mission 1 is in progress, then a number of systems
\ along the route of that mission's story will show custom mission-related
\ directives in place of that system's normal "goat soup" phrase.
\
\ Arguments:
\
\   ZZ                  The system number (0-255)
\
\ ******************************************************************************

.PDESC

 LDA QQ8                \ If either byte in QQ18(1 0) is non-zero, meaning that
 ORA QQ8+1              \ the distance from the current system to the selected
 BNE PD1                \ is non-zero, jump to PD1 to show the standard "goat
                        \ soup" description

 LDA QQ12               \ If QQ12 does not have bit 7 set, which means we are
 BPL PD1                \ not docked, jump to PD1 to show the standard "goat
                        \ soup" description

                        \ If we get here, then the current system is the same as
                        \ the selected system and we are docked, so now to check
                        \ whether there is a special override token for this
                        \ system

 LDY #NRU%              \ Set Y as a loop counter as we work our way through the
                        \ system numbers in RUPLA, starting at NRU% (which is
                        \ the number of entries in RUPLA, 26) and working our
                        \ way down to 1

.PDL1

 LDA RUPLA-1,Y          \ Fetch the Y-th byte from RUPLA-1 into A (we use
                        \ RUPLA-1 because Y is looping from 26 to 1

 CMP ZZ                 \ If A doesn't match the system whose description we
 BNE PD2                \ are printing (in ZZ), junp to PD2 to keep looping
                        \ through the system numbers in RUPLA

                        \ If we get here we have found a match for this system
                        \ number in RUPLA

 LDA RUGAL-1,Y          \ Fetch the Y-th byte from RUGAL-1 into A

 AND #%01111111         \ Extract bits 0-6 of A

 CMP GCNT               \ If the result does not equal the current galaxy
 BNE PD2                \ number, jump to PD2 to keep looping through the system
                        \ numbers in RUPLA

 LDA RUGAL-1,Y          \ Fetch the Y-th byte from RUGAL-1 into A, once again

 BMI PD3                \ If bit 7 is set, jump to PD3 to print the extended
                        \ token in A from the second table in RUTOK

 LDA TP                 \ Fetch bit 0 of TP into the C flag, and skip to PD1 if
 LSR A                  \ it is clear (i.e. if mission 1 is not in progress) to
 BCC PD1                \ print the "goat soup" extended description

                        \ If we get here then mission 1 is in progress, so we
                        \ print out the corresponding token from RUTOK

 JSR MT14               \ Call MT14 to switch to justified text

 LDA #1                 \ Set A = 1 so that extended token 1 (an empty string)
                        \ gets printed below instead of token 176, followed by
                        \ the Y-th token in RUTOK

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &B0, or BIT &B0A9, which does nothing apart
                        \ from affect the flags

.PD3

 LDA #176               \ Print extended token 176 ("{lower case}{justify}
 JSR DETOK2             \ {single cap}")

 TYA                    \ Print the extended token in Y from the second table
 JSR DETOK3             \ in RUTOK

 LDA #177               \ Set A = 177 so when we jump to PD4 in the next
                        \ instruction, we print token 177 (".{cr}{left align}")

 BNE PD4                \ Jump to PD4 to print the extended token in A and
                        \ return from the subroutine using a tail call

.PD2

 DEY                    \ Decrement the byte counter in Y

 BNE PDL1               \ Loop back to check the next byte in RUPLA until we
                        \ either find a match for the system in ZZ, or we fall
                        \ through into the "goat soup" extended description
                        \ routine

.PD1

                        \ We now print the "goat soup" extended description

 LDX #3                 \ We now want to seed the random number generator with
                        \ the s1 and s2 16-bit seeds from the current system, so
                        \ we get the same extended description for each system
                        \ every time we call PDESC, so set a counter in X for
                        \ copying 4 bytes

{
.PDL1                   \ This label is a duplicate of the label above (which is
                        \ why we need to surround it with braces, as BeebAsm
                        \ doesn't allow us to redefine labels, unlike BBC BASIC)

 LDA QQ15+2,X           \ Copy QQ15+2 to QQ15+5 (s1 and s2) to RAND to RAND+3
 STA RAND,X

 DEX                    \ Decrement the loop counter

 BPL PDL1               \ Loop back to PDL1 until we have copied all

 LDA #5                 \ Set A = 5, so we print extended token 5 in the next
                        \ instruction ("{lower case}{justify}{single cap}[86-90]
                        \ IS [140-144].{cr}{left align}"
}

.PD4

 JMP DETOK              \ Print the extended token given in A, and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: BRIEF2
\       Type: Subroutine
\   Category: Missions
\    Summary: Start mission 2
\
\ ******************************************************************************

.BRIEF2

 LDA TP                 \ Set bit 2 of TP to indicate mission 2 is in progress
 ORA #%00000100         \ but plans have not yet been picked up
 STA TP

 LDA #11                \ Set A = 11 so the call to BRP prints extended token 11
                        \ (the initial contact at the start of mission 2, asking
                        \ us to head for Ceerdi for a mission briefing)

                        \ Fall through into BRP to print the extended token in A
                        \ and show the Status Mode screen

\ ******************************************************************************
\
\       Name: BRP
\       Type: Subroutine
\   Category: Missions
\    Summary: Print an extended token and show the Status Mode screen
\
\ ******************************************************************************

.BRP

 LDX #&FF               \ ???
 STX COL

 JSR DETOK              \ Print the extended token in A

 JMP BAY                \ Jump to BAY to go to the docking bay (i.e. show the
                        \ Status Mode screen) and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: BRIEF3
\       Type: Subroutine
\   Category: Missions
\    Summary: Receive the briefing and plans for mission 2
\
\ ******************************************************************************

.BRIEF3

 LDA TP                 \ Set bits 1 and 3 of TP to indicate that mission 1 is
 AND #%11110000         \ complete, and mission 2 is in progress and the plans
 ORA #%00001010         \ have been picked up
 STA TP

 LDA #222               \ Set A = 222 so the call to BRP prints extended token
                        \ 222 (the briefing for mission 2 where we pick up the
                        \ plans we need to take to Birera)

 BNE BRP                \ Jump to BRP to print the extended token in A and show
                        \ the Status Mode screen), returning from the subroutine
                        \ using a tail call (this BNE is effectively a JMP as A
                        \ is never zero)

\ ******************************************************************************
\
\       Name: DEBRIEF2
\       Type: Subroutine
\   Category: Missions
\    Summary: Finish mission 2
\
\ ******************************************************************************

.DEBRIEF2

 LDA TP                 \ Set bit 2 of TP to indicate mission 2 is complete (so
 ORA #%00000100         \ both bits 2 and 3 are now set)
 STA TP

 LDA #2                 \ Set ENGY to 2 so our energy banks recharge at twice
 STA ENGY               \ the speed, as our mission reward is a special navy
                        \ energy unit

 INC TALLY+1            \ Award 256 kill points for completing the mission

 LDA #223               \ Set A = 223 so the call to BRP prints extended token
                        \ 223 (the thank you message at the end of mission 2)

 BNE BRP                \ Jump to BRP to print the extended token in A and show
                        \ the Status Mode screen), returning from the subroutine
                        \ using a tail call (this BNE is effectively a JMP as A
                        \ is never zero)

\ ******************************************************************************
\
\       Name: DEBRIEF
\       Type: Subroutine
\   Category: Missions
\    Summary: Finish mission 1
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   BRPS                Print the extended token in A, show the Status Mode
\                       screen and return from the subroutine
\
\ ******************************************************************************

.DEBRIEF

 LSR TP                 \ Clear bit 0 of TP to indicate that mission 1 is no
 ASL TP                 \ longer in progress, as we have completed it

 LDX #LO(50000)         \ Increase our cash reserves by the generous mission
 LDY #HI(50000)         \ reward of 5,000 CR
 JSR MCASH

 LDA #15                \ Set A = 15 so the call to BRP prints extended token 15
                        \ (the thank you message at the end of mission 1)

.BRPS

 BNE BRP                \ Jump to BRP to print the extended token in A and show
                        \ the Status Mode screen, returning from the subroutine
                        \ using a tail call (this BNE is effectively a JMP as A
                        \ is never zero)

\ ******************************************************************************
\
\       Name: BRIEF
\       Type: Subroutine
\   Category: Missions
\    Summary: Start mission 1 and show the mission briefing
\
\ ------------------------------------------------------------------------------
\
\ This routine does the following:
\
\   * Clear the screen
\   * Display "INCOMING MESSAGE" in the middle of the screen
\   * Wait for 2 seconds
\   * Clear the screen
\   * Show the Constrictor rolling and pitching in the middle of the screen
\   * Do this for 64 loop iterations
\   * Move the ship away from us and up until it's near the top of the screen
\   * Show the mission 1 briefing in extended token 10
\
\ The mission briefing ends with a "{display ship, wait for key press}" token,
\ which calls the PAUSE routine. This continues to display the rotating ship,
\ waiting until a key is pressed, and then removes the ship from the screen.
\
\ ******************************************************************************

.BRIEF

 LSR TP                 \ Set bit 0 of TP to indicate that mission 1 is now in
 SEC                    \ progress
 ROL TP

 JSR BRIS               \ Call BRIS to clear the screen, display "INCOMING
                        \ MESSAGE" and wait for 2 seconds

 JSR ZINF               \ Call ZINF to reset the INWK ship workspace

 LDA #CON               \ Set the ship type in TYPE to the Constrictor
 STA TYPE

 JSR NWSHP              \ Add a new Constrictor to the local bubble (in this
                        \ case, the briefing screen)

 LDA #1                 \ Move the text cursor to column 1
 JSR DOXC

 STA INWK+7             \ Set z_hi = 1, the distance at which we show the
                        \ rotating ship

 LDA #&0D               \ ???

 JSR TT66               \ Clear the top part of the screen, draw a white border,
                        \ and set the current view type in QQ11 to 1

 LDA #64                \ Set the main loop counter to 64, so the ship rotates
                        \ for 64 iterations through MVEIT
 STA MCNT

.BRL1

 LDX #%01111111         \ Set the ship's roll counter to a positive roll that
 STX INWK+29            \ doesn't dampen

 STX INWK+30            \ Set the ship's pitch counter to a positive pitch that
                        \ doesn't dampen

 JSR LL9                \ Draw the ship on screen

 JSR MVEIT              \ Call MVEIT to rotate the ship in space

 DEC MCNT               \ Decrease the counter in MCNT

 BNE BRL1               \ Loop back to keep moving the ship until we have done
                        \ all 64 iterations

.BRL2

 LSR INWK               \ Halve x_lo so the Constrictor moves towards the centre

 INC INWK+6             \ Increment z_lo so the Constrictor moves away from us

 BEQ BR2                \ If z_lo = 0 (i.e. it just went past 255), jump to BR2
                        \ to show the briefing

 INC INWK+6             \ Increment z_lo so the Constrictor moves a bit further
                        \ away from us

 BEQ BR2                \ If z_lo = 0 (i.e. it just went past 255), jump out of
                        \ the loop to BR2 to stop moving the ship up the screen
                        \ and show the briefing

 LDX INWK+3             \ Set X = y_lo + 1
 INX

 CPX #120               \ If X < 120 then skip the next instruction
 BCC P%+4

 LDX #120               \ X is bigger than 120, so set X = 120 so that X has a
                        \ maximum value of 120 ???

 STX INWK+3             \ Set y_lo = X
                        \          = y_lo + 1
                        \
                        \ so the ship moves up the screen (as space coordinates
                        \ have the y-axis going up)

 JSR LL9                \ Draw the ship on screen

 JSR MVEIT              \ Call MVEIT to move and rotate the ship in space

 DEC MCNT               \ ???

 JMP BRL2               \ Loop back to keep moving the ship up the screen and
                        \ away from us

.BR2

 INC INWK+7             \ Increment z_hi, to keep the ship at the same distance
                        \ as we just incremented z_lo past 255

 JSR PAS1               \ ???

 LDA #10                \ Set A = 10 so the call to BRP prints extended token 10
                        \ (the briefing for mission 1 where we find out all
                        \ about the stolen Constrictor)

 BNE BRPS               \ Jump to BRP via BRPS to print the extended token in A
                        \ and show the Status Mode screen), returning from the
                        \ subroutine using a tail call (this BNE is effectively
                        \ a JMP as A is never zero)

\ ******************************************************************************
\
\       Name: BRIS
\       Type: Subroutine
\   Category: Missions
\    Summary: Clear the screen, display "INCOMING MESSAGE" and wait for 2
\             seconds
\
\ ******************************************************************************

.BRIS

 LDA #216               \ Print extended token 216 ("{clear screen}{tab 6}{move
 JSR DETOK              \ to row 10, white, lower case}{white}{all caps}INCOMING
                        \ MESSAGE"

 LDY #100               \ Delay for 100 vertical syncs (100/50 = 2 seconds) and
 JMP DELAY              \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PAUSE
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Display a rotating ship, waiting until a key is pressed, then
\             remove the ship from the screen
\
\ ******************************************************************************

.PAUSE

 JSR PAS1               \ Call PAS1 to display the rotating ship at space
                        \ coordinates (0, 112, 256) and scan the keyboard,
                        \ returning the internal key number in X (or 0 for no
                        \ key press)

 BNE PAUSE              \ If a key was already being held down when we entered
                        \ this routine, keep looping back up to PAUSE, until
                        \ the key is released

.PAL1

 JSR PAS1               \ Call PAS1 to display the rotating ship at space
                        \ coordinates (0, 112, 256) and scan the keyboard,
                        \ returning the internal key number in X (or 0 for no
                        \ key press)

 BEQ PAL1               \ Keep looping up to PAL1 until a key is pressed

 LDA #0                 \ Set the ship's AI flag to 0 (no AI) so it doesn't get
 STA INWK+31            \ any ideas of its pwn

 LDA #1                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 1

 JSR LL9                \ Draw the ship on screen to remove it

                        \ Fall through into MT23 to move to row 10, switch to
                        \ white text, and switch to lower case when printing
                        \ extended tokens

\ ******************************************************************************
\
\       Name: MT23
\       Type: Subroutine
\   Category: Text
\    Summary: Move to row 10, switch to white text, and switch to lower case
\             when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ******************************************************************************

.MT23

 LDA #10                \ Set A = 10, so when we fall through into MT29, the
                        \ text cursor gets moved to row 10

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &06, or BIT &06A9, which does nothing apart
                        \ from affect the flags

                        \ Fall through into MT29 to move to the row in A, switch
                        \ to white text, and switch to lower case

\ ******************************************************************************
\
\       Name: MT29
\       Type: Subroutine
\   Category: Text
\    Summary: Move to row 6, switch to white text, and switch to lower case when
\             printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * YC = 6 (move to row 6)
\
\ Then it calls WHITETEXT to switch to white text, before jumping to MT13 to
\ switch to lower case when printing extended tokens.
\
\ ******************************************************************************

.MT29

 LDA #6                 \ Move the text cursor to row 6
 STA YC

 LDA #&FF               \ ???
 STA COL

 JMP MT13               \ Jump to MT13 to set bit 7 of DTW6 and bit 5 of DTW1,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PAS1
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Display a rotating ship at space coordinates (0, 120, 256) and
\             scan the keyboard
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   If a key is being pressed, X contains the internal key
\                       number, otherwise it contains 0
\
\   A                   Contains the same as X
\
\ ******************************************************************************

.PAS1

 LDA #120               \ Set y_lo = 120 ???
 STA INWK+3

 LDA #0                 \ Set x_lo = 0
 STA INWK

 STA INWK+6             \ Set z_lo = 0

 LDA #2                 \ Set z_hi = 1, so (z_hi z_lo) = 256
 STA INWK+7

 JSR LL9                \ Draw the ship on screen

 JSR MVEIT              \ Call MVEIT to move and rotate the ship in space

 JMP RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press),
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PAUSE2
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Wait until a key is pressed, ignoring any existing key press
\
\ ******************************************************************************

.PAUSE2

 JSR RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press)

 BNE PAUSE2             \ If a key was already being held down when we entered
                        \ this routine, keep looping back up to PAUSE2, until
                        \ the key is released

 JSR RDKEY              \ Any pre-existing key press is now gone, so we can
                        \ start scanning the keyboard again, returning the
                        \ internal key number in X (or 0 for no key press)

 BEQ PAUSE2             \ Keep looping up to PAUSE2 until a key is pressed

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GINF
\       Type: Subroutine
\   Category: Universe
\    Summary: Fetch the address of a ship's data block into INF
\
\ ------------------------------------------------------------------------------
\
\ Get the address of the data block for ship slot X and store it in INF. This
\ address is fetched from the UNIV table, which stores the addresses of the 13
\ ship data blocks in workspace K%.
\
\ Arguments:
\
\   X                   The ship slot number for which we want the data block
\                       address
\
\ ******************************************************************************

.GINF

 TXA                    \ Set Y = X * 2
 ASL A
 TAY

 LDA UNIV,Y             \ Get the high byte of the address of the X-th ship
 STA INF                \ from UNIV and store it in INF

 LDA UNIV+1,Y           \ Get the low byte of the address of the X-th ship
 STA INF+1              \ from UNIV and store it in INF

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ping
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the selected system to the current system
\
\ ******************************************************************************

.ping

 LDX #1                 \ We want to copy the X- and Y-coordinates of the
                        \ current system in (QQ0, QQ1) to the selected system's
                        \ coordinates in (QQ9, QQ10), so set up a counter to
                        \ copy two bytes

.pl1

 LDA QQ0,X              \ Load byte X from the current system in QQ0/QQ1

 STA QQ9,X              \ Store byte X in the selected system in QQ9/QQ10

 DEX                    \ Decrement the loop counter

 BPL pl1                \ Loop back for the next byte to copy

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MTIN
\       Type: Variable
\   Category: Text
\    Summary: Lookup table for random tokens in the extended token table (0-37)
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The ERND token type, which is part of the extended token system, takes an
\ argument between 0 and 37, and returns a randomly chosen token in the range
\ specified in this table. This is used to generate the extended description of
\ each system.
\
\ For example, the entry at position 13 in this table (counting from 0) is 66,
\ so ERND 14 will expand into a random token in the range 66-70, i.e. one of
\ "JUICE", "BRANDY", "WATER", "BREW" and "GARGLE BLASTERS".
\
\ ******************************************************************************

.MTIN

 EQUB 16                \ Token  0: a random extended token between 16 and 20
 EQUB 21                \ Token  1: a random extended token between 21 and 25
 EQUB 26                \ Token  2: a random extended token between 26 and 30
 EQUB 31                \ Token  3: a random extended token between 31 and 35
 EQUB 155               \ Token  4: a random extended token between 155 and 159
 EQUB 160               \ Token  5: a random extended token between 160 and 164
 EQUB 46                \ Token  6: a random extended token between 46 and 50
 EQUB 165               \ Token  7: a random extended token between 165 and 169
 EQUB 36                \ Token  8: a random extended token between 36 and 40
 EQUB 41                \ Token  9: a random extended token between 41 and 45
 EQUB 61                \ Token 10: a random extended token between 61 and 65
 EQUB 51                \ Token 11: a random extended token between 51 and 55
 EQUB 56                \ Token 12: a random extended token between 56 and 60
 EQUB 170               \ Token 13: a random extended token between 170 and 174
 EQUB 66                \ Token 14: a random extended token between 66 and 70
 EQUB 71                \ Token 15: a random extended token between 71 and 75
 EQUB 76                \ Token 16: a random extended token between 76 and 80
 EQUB 81                \ Token 17: a random extended token between 81 and 85
 EQUB 86                \ Token 18: a random extended token between 86 and 90
 EQUB 140               \ Token 19: a random extended token between 140 and 144
 EQUB 96                \ Token 20: a random extended token between 96 and 100
 EQUB 101               \ Token 21: a random extended token between 101 and 105
 EQUB 135               \ Token 22: a random extended token between 135 and 139
 EQUB 130               \ Token 23: a random extended token between 130 and 134
 EQUB 91                \ Token 24: a random extended token between 91 and 95
 EQUB 106               \ Token 25: a random extended token between 106 and 110
 EQUB 180               \ Token 26: a random extended token between 180 and 184
 EQUB 185               \ Token 27: a random extended token between 185 and 189
 EQUB 190               \ Token 28: a random extended token between 190 and 194
 EQUB 225               \ Token 29: a random extended token between 225 and 229
 EQUB 230               \ Token 30: a random extended token between 230 and 234
 EQUB 235               \ Token 31: a random extended token between 235 and 239
 EQUB 240               \ Token 32: a random extended token between 240 and 244
 EQUB 245               \ Token 33: a random extended token between 245 and 249
 EQUB 250               \ Token 34: a random extended token between 250 and 254
 EQUB 115               \ Token 35: a random extended token between 115 and 119
 EQUB 120               \ Token 36: a random extended token between 120 and 124
 EQUB 125               \ Token 37: a random extended token between 125 and 129

.L4A42

 LSR A

.L4A43

 RTS

.L4A44

 RTS

.L4A45

 STA XX15
 STA X2
 LDA #&18
 STA Y1
 LDA #&98
 STA Y2
 JMP LL30

\ ******************************************************************************
\
\       Name: tnpr1
\       Type: Subroutine
\   Category: Market
\    Summary: Work out if we have space for one tonne of cargo
\
\ ------------------------------------------------------------------------------
\
\ Given a market item, work out whether there is room in the cargo hold for one
\ tonne of this item.
\
\ For standard tonne canisters, the limit is given by the type of cargo hold we
\ have, with a standard cargo hold having a capacity of 20t and an extended
\ cargo bay being 35t.
\
\ For items measured in kg (gold, platinum), g (gem-stones) and alien items,
\ the individual limit on each of these is 200 units.
\
\ Arguments:
\
\   A                   The type of market item (see QQ23 for a list of market
\                       item numbers)
\
\ Returns:
\
\   A                   A = 1
\
\   C flag              Returns the result:
\
\                         * Set if there is no room for this item
\
\                         * Clear if there is room for this item
\
\ ******************************************************************************

.tnpr1

 STA QQ29               \ Store the type of market item in QQ29

 LDA #1                 \ Set the number of units of this market item to 1

                        \ Fall through into tnpr to work out whether there is
                        \ room in the cargo hold for A tonnes of the item of
                        \ type QQ29

\ ******************************************************************************
\
\       Name: tnpr
\       Type: Subroutine
\   Category: Market
\    Summary: Work out if we have space for a specific amount of cargo
\
\ ------------------------------------------------------------------------------
\
\ Given a market item and an amount, work out whether there is room in the
\ cargo hold for this item.
\
\ For standard tonne canisters, the limit is given by the type of cargo hold we
\ have, with a standard cargo hold having a capacity of 20t and an extended
\ cargo bay being 35t.
\
\ For items measured in kg (gold, platinum), g (gem-stones) and alien items,
\ the individual limit on each of these is 200 units.
\
\ Arguments:
\
\   A                   The number of units of this market item
\
\   QQ29                The type of market item (see QQ23 for a list of market
\                       item numbers)
\
\ Returns:
\
\   A                   A is preserved
\
\   C flag              Returns the result:
\
\                         * Set if there is no room for this item
\
\                         * Clear if there is room for this item
\
\ ******************************************************************************

.tnpr

 PHA                    \ Store A on the stack

 LDX #12                \ If QQ29 > 12 then jump to kg below, as this cargo
 CPX QQ29               \ type is gold, platinum, gem-stones or alien items,
 BCC kg                 \ and they have different cargo limits to the standard
                        \ tonne canisters

.Tml

                        \ Here we count the tonne canisters we have in the hold
                        \ and add to A to see if we have enough room for A more
                        \ tonnes of cargo, using X as the loop counter, starting
                        \ with X = 12

 ADC QQ20,X             \ Set A = A + the number of tonnes we have in the hold
                        \ of market item number X. Note that the first time we
                        \ go round this loop, the C flag is set (as we didn't
                        \ branch with the BCC above, so the effect of this loop
                        \ is to count the number of tonne canisters in the hold,
                        \ and add 1

 DEX                    \ Decrement the loop counter

 BPL Tml                \ Loop back to add in the next market item in the hold,
                        \ until we have added up all market items from 12
                        \ (minerals) down to 0 (food)

 ADC L1265              \ ???

 CMP CRGO               \ If A < CRGO then the C flag will be clear (we have
                        \ room in the hold)
                        \
                        \ If A >= CRGO then the C flag will be set (we do not
                        \ have room in the hold)
                        \
                        \ This works because A contains the number of canisters
                        \ plus 1, while CRGO contains our cargo capacity plus 2,
                        \ so if we actually have "a" canisters and a capacity
                        \ of "c", then:
                        \
                        \ A < CRGO means: a+1 <  c+2
                        \                 a   <  c+1
                        \                 a   <= c
                        \
                        \ So this is why the value in CRGO is 2 higher than the
                        \ actual cargo bay size, i.e. it's 22 for the standard
                        \ 20-tonne bay, and 37 for the large 35-tonne bay

 PLA                    \ Restore A from the stack

 RTS                    \ Return from the subroutine

.kg

                        \ Here we count the number of items of this type that
                        \ we already have in the hold, and add to A to see if
                        \ we have enough room for A more units

 LDY QQ29               \ Set Y to the item number we want to add

 ADC QQ20,Y             \ Set A = A + the number of units of this item that we
                        \ already have in the hold

 CMP #200               \ Is the result greater than 200 (the limit on
                        \ individual stocks of gold, platinum, gem-stones and
                        \ alien items)?
                        \
                        \ If so, this sets the C flag (no room)
                        \
                        \ Otherwise it is clear (we have room)

 PLA                    \ Restore A from the stack

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DOXC
\       Type: Subroutine
\   Category: Text
\    Summary: Move the text cursor to a specific column
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text column
\
\ ******************************************************************************

.DOXC

 STA XC                 \ Store the new text column in XC

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DOYC
\       Type: Subroutine
\   Category: Text
\    Summary: Move the text cursor to a specific row
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text row
\
\ ******************************************************************************

.DOYC

 STA YC                 \ Store the new text row in YC

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: INCYC
\       Type: Subroutine
\   Category: Text
\    Summary: Move the text cursor to the next row
\
\ ******************************************************************************

.INCYC

 INC YC                 \ Move the text cursor to the next row

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TRADEMODE
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear the screen and set up a trading screen
\
\ ------------------------------------------------------------------------------
\
\ Clear the top part of the screen, draw a white border, set the palette for
\ trading screens, and set the current view type in QQ11 to A.
\
\ Arguments:
\
\   A                   The type of the new current view (see QQ11 for a list of
\                       view types)
\
\ Other entry points:
\
\   TRADE               Set the palette for trading screens and switch the
\                       current colour to white
\
\ ******************************************************************************

.TRADEMODE

 JSR TT66               \ Clear the top part of the screen, draw a white border,
                        \ and set the current view type in QQ11 to A

 JSR FLKB               \ Call FLKB to flush the keyboard buffer

.TRADE

 LDA #48                \ Switch to the mode 1 palette for trading screens,
 JSR SETVDU19           \ which is yellow (colour 1), magenta (colour 2) and
                        \ white (colour 3)

 LDA #CYAN              \ Switch to colour 3, which is white in the trade view
 STA COL

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT20
\       Type: Subroutine
\   Category: Universe
\    Summary: Twist the selected system's seeds four times
\  Deep dive: Twisting the system seeds
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Twist the three 16-bit seeds in QQ15 (selected system) four times, to
\ generate the next system.
\
\ ******************************************************************************

.TT20

 JSR P%+3               \ This line calls the line below as a subroutine, which
                        \ does two twists before returning here, and then we
                        \ fall through to the line below for another two
                        \ twists, so the net effect of these two consecutive
                        \ JSR calls is four twists, not counting the ones
                        \ inside your head as you try to follow this process

 JSR P%+3               \ This line calls TT54 as a subroutine to do a twist,
                        \ and then falls through into TT54 to do another twist
                        \ before returning from the subroutine

\ ******************************************************************************
\
\       Name: TT54
\       Type: Subroutine
\   Category: Universe
\    Summary: Twist the selected system's seeds
\  Deep dive: Twisting the system seeds
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ This routine twists the three 16-bit seeds in QQ15 once.
\
\ ******************************************************************************

.TT54

 LDA QQ15               \ X = tmp_lo = s0_lo + s1_lo
 CLC
 ADC QQ15+2
 TAX

 LDA QQ15+1             \ Y = tmp_hi = s1_hi + s1_hi + C
 ADC QQ15+3
 TAY

 LDA QQ15+2             \ s0_lo = s1_lo
 STA QQ15

 LDA QQ15+3             \ s0_hi = s1_hi
 STA QQ15+1

 LDA QQ15+5             \ s1_hi = s2_hi
 STA QQ15+3

 LDA QQ15+4             \ s1_lo = s2_lo
 STA QQ15+2

 CLC                    \ s2_lo = X + s1_lo
 TXA
 ADC QQ15+2
 STA QQ15+4

 TYA                    \ s2_hi = Y + s1_hi + C
 ADC QQ15+3
 STA QQ15+5

 RTS                    \ The twist is complete so return from the subroutine

\ ******************************************************************************
\
\       Name: TT146
\       Type: Subroutine
\   Category: Text
\    Summary: Print the distance to the selected system in light years
\
\ ------------------------------------------------------------------------------
\
\ If it is non-zero, print the distance to the selected system in light years.
\ If it is zero, just move the text cursor down a line.
\
\ Specifically, if the distance in QQ8 is non-zero, print token 31 ("DISTANCE"),
\ then a colon, then the distance to one decimal place, then token 35 ("LIGHT
\ YEARS"). If the distance is zero, move the cursor down one line.
\
\ ******************************************************************************

.TT146

 LDA QQ8                \ Take the two bytes of the 16-bit value in QQ8 and
 ORA QQ8+1              \ OR them together to check whether there are any
 BNE TT63               \ non-zero bits, and if so, jump to TT63 to print the
                        \ distance

 INC YC                 \ The distance is zero, so we just move the text cursor
 RTS                    \ in YC down by one line and return from the subroutine

.TT63

 LDA #191               \ Print recursive token 31 ("DISTANCE") followed by
 JSR TT68               \ a colon

 LDX QQ8                \ Load (Y X) from QQ8, which contains the 16-bit
 LDY QQ8+1              \ distance we want to show

 SEC                    \ Set the C flag so that the call to pr5 will include a
                        \ decimal point, and display the value as (Y X) / 10

 JSR pr5                \ Print (Y X) to 5 digits, including a decimal point

 LDA #195               \ Set A to the recursive token 35 (" LIGHT YEARS") and
                        \ fall through into TT60 to print the token followed
                        \ by a paragraph break

\ ******************************************************************************
\
\       Name: TT60
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token and a paragraph break
\
\ ------------------------------------------------------------------------------
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token). Then print a paragraph break (a blank line between
\ paragraphs) by moving the cursor down a line, setting Sentence Case, and then
\ printing a newline.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.TT60

 JSR TT27               \ Print the text token in A and fall through into TTX69
                        \ to print the paragraph break

\ ******************************************************************************
\
\       Name: TTX69
\       Type: Subroutine
\   Category: Text
\    Summary: Print a paragraph break
\
\ ------------------------------------------------------------------------------
\
\ Print a paragraph break (a blank line between paragraphs) by moving the cursor
\ down a line, setting Sentence Case, and then printing a newline.
\
\ ******************************************************************************

.TTX69

 INC YC                 \ Move the text cursor down a line

                        \ Fall through into TT69 to set Sentence Case and print
                        \ a newline

\ ******************************************************************************
\
\       Name: TT69
\       Type: Subroutine
\   Category: Text
\    Summary: Set Sentence Case and print a newline
\
\ ******************************************************************************

.TT69

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case
 STA QQ17

                        \ Fall through into TT67 to print a newline

\ ******************************************************************************
\
\       Name: TT67
\       Type: Subroutine
\   Category: Text
\    Summary: Print a newline
\
\ ******************************************************************************

.TT67

 LDA #12                \ Load a newline character into A

 JMP TT27               \ Print the text token in A and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT70
\       Type: Subroutine
\   Category: Text
\    Summary: Display "MAINLY " and jump to TT72
\
\ ------------------------------------------------------------------------------
\
\ This subroutine is called by TT25 when displaying a system's economy.
\
\ ******************************************************************************

.TT70

 LDA #173               \ Print recursive token 13 ("MAINLY ")
 JSR TT27

 JMP TT72               \ Jump to TT72 to continue printing system data as part
                        \ of routine TT25

\ ******************************************************************************
\
\       Name: spc
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token followed by a space
\
\ ------------------------------------------------------------------------------
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token) followed by a space.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.spc

 JSR TT27               \ Print the text token in A

 JMP TT162              \ Print a space and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: TT25
\       Type: Subroutine
\   Category: Universe
\    Summary: Show the Data on System screen (red key f6)
\  Deep dive: Generating system data
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   TT72                Used by TT70 to re-enter the routine after displaying
\                       "MAINLY" for the economy type
\
\ ******************************************************************************

.TT25

 LDA #1                 \ Clear the top part of the screen, draw a white border,
 JSR TRADEMODE          \ and set up a printable trading screen with a view type
                        \ in QQ11 of 1

 LDA #9                 \ Move the text cursor to column 9
 STA XC

 LDA #163               \ Print recursive token 3 ("DATA ON {selected system
 JSR NLIN3              \ name}" and draw a horizontal line at pixel row 19
                        \ to box in the title

 JSR TTX69              \ Print a paragraph break and set Sentence Case

 JSR TT146              \ If the distance to this system is non-zero, print
                        \ "DISTANCE", then the distance, "LIGHT YEARS" and a
                        \ paragraph break, otherwise just move the cursor down
                        \ a line

 LDA #194               \ Print recursive token 34 ("ECONOMY") followed by
 JSR TT68               \ a colon

 LDA QQ3                \ The system economy is determined by the value in QQ3,
                        \ so fetch it into A. First we work out the system's
                        \ prosperity as follows:
                        \
                        \   QQ3 = 0 or 5 = %000 or %101 = Rich
                        \   QQ3 = 1 or 6 = %001 or %110 = Average
                        \   QQ3 = 2 or 7 = %010 or %111 = Poor
                        \   QQ3 = 3 or 4 = %011 or %100 = Mainly

 CLC                    \ If (QQ3 + 1) >> 1 = %10, i.e. if QQ3 = %011 or %100
 ADC #1                 \ (3 or 4), then call TT70, which prints "MAINLY " and
 LSR A                  \ jumps down to TT72 to print the type of economy
 CMP #%00000010
 BEQ TT70

 LDA QQ3                \ The LSR A above shifted bit 0 of QQ3 into the C flag,
 BCC TT71               \ so this jumps to TT71 if bit 0 of QQ3 is 0, in other
                        \ words if QQ3 = %000, %001 or %010 (0, 1 or 2)

 SBC #5                 \ Here QQ3 = %101, %110 or %111 (5, 6 or 7), so subtract
 CLC                    \ 5 to bring it down to 0, 1 or 2 (the C flag is already
                        \ set so the SBC will be correct)

.TT71

 ADC #170               \ A is now 0, 1 or 2, so print recursive token 10 + A.
 JSR TT27               \ This means that:
                        \
                        \   QQ3 = 0 or 5 prints token 10 ("RICH ")
                        \   QQ3 = 1 or 6 prints token 11 ("AVERAGE ")
                        \   QQ3 = 2 or 7 prints token 12 ("POOR ")

.TT72

 LDA QQ3                \ Now to work out the type of economy, which is
 LSR A                  \ determined by bit 2 of QQ3, as follows:
 LSR A                  \
                        \   QQ3 bit 2 = 0 = Industrial
                        \   QQ3 bit 2 = 1 = Agricultural
                        \
                        \ So we fetch QQ3 into A and set A = bit 2 of QQ3 using
                        \ two right shifts (which will work as QQ3 is only a
                        \ 3-bit number)

 CLC                    \ Print recursive token 8 + A, followed by a paragraph
 ADC #168               \ break and Sentence Case, so:
 JSR TT60               \
                        \   QQ3 bit 2 = 0 prints token 8 ("INDUSTRIAL")
                        \   QQ3 bit 2 = 1 prints token 9 ("AGRICULTURAL")

 LDA #162               \ Print recursive token 2 ("GOVERNMENT") followed by
 JSR TT68               \ a colon

 LDA QQ4                \ The system economy is determined by the value in QQ4,
                        \ so fetch it into A

 CLC                    \ Print recursive token 17 + A, followed by a paragraph
 ADC #177               \ break and Sentence Case, so:
 JSR TT60               \
                        \   QQ4 = 0 prints token 17 ("ANARCHY")
                        \   QQ4 = 1 prints token 18 ("FEUDAL")
                        \   QQ4 = 2 prints token 19 ("MULTI-GOVERNMENT")
                        \   QQ4 = 3 prints token 20 ("DICTATORSHIP")
                        \   QQ4 = 4 prints token 21 ("COMMUNIST")
                        \   QQ4 = 5 prints token 22 ("CONFEDERACY")
                        \   QQ4 = 6 prints token 23 ("DEMOCRACY")
                        \   QQ4 = 7 prints token 24 ("CORPORATE STATE")

 LDA #196               \ Print recursive token 36 ("TECH.LEVEL") followed by a
 JSR TT68               \ colon

 LDX QQ5                \ Fetch the tech level from QQ5 and increment it, as it
 INX                    \ is stored in the range 0-14 but the displayed range
                        \ should be 1-15

 CLC                    \ Call pr2 to print the technology level as a 3-digit
 JSR pr2                \ number without a decimal point (by clearing the C
                        \ flag)

 JSR TTX69              \ Print a paragraph break and set Sentence Case

 LDA #192               \ Print recursive token 32 ("POPULATION") followed by a
 JSR TT68               \ colon

 SEC                    \ Call pr2 to print the population as a 3-digit number
 LDX QQ6                \ with a decimal point (by setting the C flag), so the
 JSR pr2                \ number printed will be population / 10

 LDA #198               \ Print recursive token 38 (" BILLION"), followed by a
 JSR TT60               \ paragraph break and Sentence Case

 LDA #'('               \ Print an opening bracket
 JSR TT27

 LDA QQ15+4             \ Now to calculate the species, so first check bit 7 of
 BMI TT75               \ s2_lo, and if it is set, jump to TT75 as this is an
                        \ alien species

 LDA #188               \ Bit 7 of s2_lo is clear, so print recursive token 28
 JSR TT27               \ ("HUMAN COLONIAL")

 JMP TT76               \ Jump to TT76 to print "S)" and a paragraph break, so
                        \ the whole species string is "(HUMAN COLONIALS)"

.TT75

 LDA QQ15+5             \ This is an alien species, and we start with the first
 LSR A                  \ adjective, so fetch bits 2-7 of s2_hi into A and push
 LSR A                  \ onto the stack so we can use this later
 PHA

 AND #%00000111         \ Set A = bits 0-2 of A (so that's bits 2-4 of s2_hi)

 CMP #3                 \ If A >= 3, jump to TT205 to skip the first adjective,
 BCS TT205

 ADC #227               \ Otherwise A = 0, 1 or 2, so print recursive token
 JSR spc                \ 67 + A, followed by a space, so:
                        \
                        \   A = 0 prints token 67 ("LARGE") and a space
                        \   A = 1 prints token 67 ("FIERCE") and a space
                        \   A = 2 prints token 67 ("SMALL") and a space

.TT205

 PLA                    \ Now for the second adjective, so restore A to bits
 LSR A                  \ 2-7 of s2_hi, and throw away bits 2-4 to leave
 LSR A                  \ A = bits 5-7 of s2_hi
 LSR A

 CMP #6                 \ If A >= 6, jump to TT206 to skip the second adjective
 BCS TT206

 ADC #230               \ Otherwise A = 0 to 5, so print recursive token
 JSR spc                \ 70 + A, followed by a space, so:
                        \
                        \   A = 0 prints token 70 ("GREEN") and a space
                        \   A = 1 prints token 71 ("RED") and a space
                        \   A = 2 prints token 72 ("YELLOW") and a space
                        \   A = 3 prints token 73 ("BLUE") and a space
                        \   A = 4 prints token 74 ("BLACK") and a space
                        \   A = 5 prints token 75 ("HARMLESS") and a space

.TT206

 LDA QQ15+3             \ Now for the third adjective, so EOR the high bytes of
 EOR QQ15+1             \ s0 and s1 and extract bits 0-2 of the result:
 AND #%00000111         \
 STA QQ19               \   A = (s0_hi EOR s1_hi) AND %111
                        \
                        \ storing the result in QQ19 so we can use it later

 CMP #6                 \ If A >= 6, jump to TT207 to skip the third adjective
 BCS TT207

 ADC #236               \ Otherwise A = 0 to 5, so print recursive token
 JSR spc                \ 76 + A, followed by a space, so:
                        \
                        \   A = 0 prints token 76 ("SLIMY") and a space
                        \   A = 1 prints token 77 ("BUG-EYED") and a space
                        \   A = 2 prints token 78 ("HORNED") and a space
                        \   A = 3 prints token 79 ("BONY") and a space
                        \   A = 4 prints token 80 ("FAT") and a space
                        \   A = 5 prints token 81 ("FURRY") and a space

.TT207

 LDA QQ15+5             \ Now for the actual species, so take bits 0-1 of
 AND #%00000011         \ s2_hi, add this to the value of A that we used for
 CLC                    \ the third adjective, and take bits 0-2 of the result
 ADC QQ19
 AND #%00000111

 ADC #242               \ A = 0 to 7, so print recursive token 82 + A, so:
 JSR TT27               \
                        \   A = 0 prints token 76 ("RODENT")
                        \   A = 1 prints token 76 ("FROG")
                        \   A = 2 prints token 76 ("LIZARD")
                        \   A = 3 prints token 76 ("LOBSTER")
                        \   A = 4 prints token 76 ("BIRD")
                        \   A = 5 prints token 76 ("HUMANOID")
                        \   A = 6 prints token 76 ("FELINE")
                        \   A = 7 prints token 76 ("INSECT")

.TT76

 LDA #'S'               \ Print an "S" to pluralise the species
 JSR TT27

 LDA #')'               \ And finally, print a closing bracket, followed by a
 JSR TT60               \ paragraph break and Sentence Case, to end the species
                        \ section

 LDA #193               \ Print recursive token 33 ("GROSS PRODUCTIVITY"),
 JSR TT68               \ followed by colon

 LDX QQ7                \ Fetch the 16-bit productivity value from QQ7 into
 LDY QQ7+1              \ (Y X)

 JSR pr6                \ Print (Y X) to 5 digits with no decimal point

 JSR TT162              \ Print a space

 STZ QQ17               \ Set QQ17 = 0 to switch to ALL CAPS

 LDA #'M'               \ Print "M"
 JSR TT27

 LDA #226               \ Print recursive token 66 (" CR"), followed by a
 JSR TT60               \ paragraph break and Sentence Case

 LDA #250               \ Print recursive token 90 ("AVERAGE RADIUS"), followed
 JSR TT68               \ by a colon

                        \ The average radius is calculated like this:
                        \
                        \   ((s2_hi AND %1111) + 11) * 256 + s1_hi
                        \
                        \ or, in terms of memory locations:
                        \
                        \   ((QQ15+5 AND %1111) + 11) * 256 + QQ15+3
                        \
                        \ Because the multiplication is by 256, this is the
                        \ same as saying a 16-bit number, with high byte:
                        \
                        \   (QQ15+5 AND %1111) + 11
                        \
                        \ and low byte:
                        \
                        \   QQ15+3
                        \
                        \ so we can set this up in (Y X) and call the pr5
                        \ routine to print it out

 LDA QQ15+5             \ Set A = QQ15+5
 LDX QQ15+3             \ Set X = QQ15+3

 AND #%00001111         \ Set Y = (A AND %1111) + 11
 CLC
 ADC #11
 TAY

 JSR pr5                \ Print (Y X) to 5 digits, not including a decimal
                        \ point, as the C flag will be clear (as the maximum
                        \ radius will always fit into 16 bits)

 JSR TT162              \ Print a space

 LDA #'k'               \ Print "km"
 JSR TT26
 LDA #'m'
 JSR TT26

 JSR TTX69              \ Print a paragraph break and set Sentence Case

                        \ By this point, ZZ contains the current system number
                        \ which PDESC requires. It gets put there in the TT102
                        \ routine, which calls TT111 to populate ZZ before
                        \ calling TT25 (this routine)

 JMP PDESC              \ Jump to PDESC to print the system's extended
                        \ description, returning from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: TT24
\       Type: Subroutine
\   Category: Universe
\    Summary: Calculate system data from the system seeds
\  Deep dive: Generating system data
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Calculate system data from the seeds in QQ15 and store them in the relevant
\ locations. Specifically, this routine calculates the following from the three
\ 16-bit seeds in QQ15 (using only s0_hi, s1_hi and s1_lo):
\
\   QQ3 = economy (0-7)
\   QQ4 = government (0-7)
\   QQ5 = technology level (0-14)
\   QQ6 = population * 10 (1-71)
\   QQ7 = productivity (96-62480)
\
\ The ranges of the various values are shown in brackets. Note that the radius
\ and type of inhabitant are calculated on-the-fly in the TT25 routine when
\ the system data gets displayed, so they aren't calculated here.
\
\ ******************************************************************************

.TT24

 LDA QQ15+1             \ Fetch s0_hi and extract bits 0-2 to determine the
 AND #%00000111         \ system's economy, and store in QQ3
 STA QQ3

 LDA QQ15+2             \ Fetch s1_lo and extract bits 3-5 to determine the
 LSR A                  \ system's government, and store in QQ4
 LSR A
 LSR A
 AND #%00000111
 STA QQ4

 LSR A                  \ If government isn't anarchy or feudal, skip to TT77,
 BNE TT77               \ as we need to fix the economy of anarchy and feudal
                        \ systems so they can't be rich

 LDA QQ3                \ Set bit 1 of the economy in QQ3 to fix the economy
 ORA #%00000010         \ for anarchy and feudal governments
 STA QQ3

.TT77

 LDA QQ3                \ Now to work out the tech level, which we do like this:
 EOR #%00000111         \
 CLC                    \   flipped_economy + (s1_hi AND %11) + (government / 2)
 STA QQ5                \
                        \ or, in terms of memory locations:
                        \
                        \   QQ5 = (QQ3 EOR %111) + (QQ15+3 AND %11) + (QQ4 / 2)
                        \
                        \ We start by setting QQ5 = QQ3 EOR %111

 LDA QQ15+3             \ We then take the first 2 bits of s1_hi (QQ15+3) and
 AND #%00000011         \ add it into QQ5
 ADC QQ5
 STA QQ5

 LDA QQ4                \ And finally we add QQ4 / 2 and store the result in
 LSR A                  \ QQ5, using LSR then ADC to divide by 2, which rounds
 ADC QQ5                \ up the result for odd-numbered government types
 STA QQ5

 ASL A                  \ Now to work out the population, like so:
 ASL A                  \
 ADC QQ3                \   (tech level * 4) + economy + government + 1
 ADC QQ4                \
 ADC #1                 \ or, in terms of memory locations:
 STA QQ6                \
                        \   QQ6 = (QQ5 * 4) + QQ3 + QQ4 + 1

 LDA QQ3                \ Finally, we work out productivity, like this:
 EOR #%00000111         \
 ADC #3                 \  (flipped_economy + 3) * (government + 4)
 STA P                  \                        * population
 LDA QQ4                \                        * 8
 ADC #4                 \
 STA Q                  \ or, in terms of memory locations:
 JSR MULTU              \
                        \   QQ7 = (QQ3 EOR %111 + 3) * (QQ4 + 4) * QQ6 * 8
                        \
                        \ We do the first step by setting P to the first
                        \ expression in brackets and Q to the second, and
                        \ calling MULTU, so now (A P) = P * Q. The highest this
                        \ can be is 10 * 11 (as the maximum values of economy
                        \ and government are 7), so the high byte of the result
                        \ will always be 0, so we actually have:
                        \
                        \   P = P * Q
                        \     = (flipped_economy + 3) * (government + 4)

 LDA QQ6                \ We now take the result in P and multiply by the
 STA Q                  \ population to get the productivity, by setting Q to
 JSR MULTU              \ the population from QQ6 and calling MULTU again, so
                        \ now we have:
                        \
                        \   (A P) = P * population

 ASL P                  \ Next we multiply the result by 8, as a 16-bit number,
 ROL A                  \ so we shift both bytes to the left three times, using
 ASL P                  \ the C flag to carry bits from bit 7 of the low byte
 ROL A                  \ into bit 0 of the high byte
 ASL P
 ROL A

 STA QQ7+1              \ Finally, we store the productivity in two bytes, with
 LDA P                  \ the low byte in QQ7 and the high byte in QQ7+1
 STA QQ7

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT22
\       Type: Subroutine
\   Category: Charts
\    Summary: Show the Long-range Chart (red key f4)
\
\ ******************************************************************************

.TT22

 LDA #64                \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 32 (Long-
                        \ range Chart)

 LDA #16                \ Switch to the mode 1 palette for the trade view, which
 JSR SETVDU19           \ is yellow (colour 1), magenta (colour 2) and white
                        \ (colour 3)

 LDA #CYAN              \ Switch to colour 3, which is white in the chart view
 STA COL

 LDA #7                 \ Move the text cursor to column 7
 STA XC

 JSR TT81               \ Set the seeds in QQ15 to those of system 0 in the
                        \ current galaxy (i.e. copy the seeds from QQ21 to QQ15)

 LDA #199               \ Print recursive token 39 ("GALACTIC CHART{galaxy
 JSR TT27               \ number right-aligned to width 3}")

 JSR NLIN               \ Draw a horizontal line at pixel row 23 to box in the
                        \ title and act as the top frame of the chart, and move
                        \ the text cursor down one line

 LDA #153               \ Draw a screen-wide horizontal line at pixel row 152
 JSR NLIN2-2            \ for the bottom edge of the chart, so the chart itself
                        \ is 128 pixels high, starting on row 24 and ending on
                        \ row 151 ???

 JSR TT14               \ Call TT14 to draw a circle with crosshairs at the
                        \ current system's galactic coordinates

 LDX #0                 \ We're now going to plot each of the galaxy's systems,
                        \ so set up a counter in X for each system, starting at
                        \ 0 and looping through to 255

.TT83

 STX XSAV               \ Store the counter in XSAV

 LDX QQ15+3             \ Fetch the s1_hi seed into X, which gives us the
                        \ galactic x-coordinate of this system

 LDY QQ15+4             \ Fetch the s2_lo seed and clear all the bits apart
 TYA                    \ from bits 4 and 6, storing the result in ZZ to give a
 ORA #%01010000         \ random number out of 0, &10, &40 or &50 (but which
 STA ZZ                 \ will always be the same for this system). We use this
                        \ value to determine the size of the point for this
                        \ system on the chart by passing it as the distance
                        \ argument to the PIXEL routine below

 LDA #&0F               \ ???
 STA COL

 LDA QQ15+1             \ Fetch the s0_hi seed into A, which gives us the
                        \ galactic y-coordinate of this system

 JSR L4A42              \ ???

 CLC                    \ Add 24 to the halved y-coordinate ???
 ADC #24                \ (as the top of the chart is on pixel row 24, just
                        \ below the line we drew on row 23 above)

 JSR PIXEL              \ Call PIXEL to draw a point at (X, A), with the size of
                        \ the point dependent on the distance specified in ZZ
                        \ (so a high value of ZZ will produce a 1-pixel point,
                        \ a medium value will produce a 2-pixel dash, and a
                        \ small value will produce a 4-pixel square)

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 LDX XSAV               \ Restore the loop counter from XSAV

 INX                    \ Increment the counter

 BNE TT83               \ If X > 0 then we haven't done all 256 systems yet, so
                        \ loop back up to TT83

 LDA QQ9                \ ???
 JSR L4A44

 STA QQ19
 LDA QQ10
 JSR L4A42

 STA QQ19+1

 LDA #4                 \ Set QQ19+2 to size 4 for the crosshairs size
 STA QQ19+2

 LDA #&AF               \ ???
 STA COL

                        \ Fall through into TT15 to draw crosshairs of size 4 at
                        \ the selected system's coordinates

\ ******************************************************************************
\
\       Name: TT15
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a set of crosshairs
\
\ ------------------------------------------------------------------------------
\
\ For all views except the Short-range Chart, the centre is drawn 24 pixels to
\ the right of the y-coordinate given.
\
\ Arguments:
\
\   QQ19                The pixel x-coordinate of the centre of the crosshairs
\
\   QQ19+1              The pixel y-coordinate of the centre of the crosshairs
\
\   QQ19+2              The size of the crosshairs
\
\ ******************************************************************************

.TT15

 LDA #24                \ Set A to 24, which we will use as the minimum
                        \ screen indent for the crosshairs (i.e. the minimum
                        \ distance from the top-left corner of the screen)

 LDX QQ11               \ If the current view is not the Short-range Chart,
 BPL TT178              \ which is the only view with bit 7 set, then jump to
                        \ TT178 to skip the following instruction

 LDA #0                 \ This is the Short-range Chart, so set A to 0, so the
                        \ crosshairs can go right up against the screen edges

.TT178

 STA QQ19+5             \ Set QQ19+5 to A, which now contains the correct indent
                        \ for this view

 LDA QQ19               \ Set A = crosshairs x-coordinate - crosshairs size
 SEC                    \ to get the x-coordinate of the left edge of the
 SBC QQ19+2             \ crosshairs

 BIT QQ11               \ ???
 BMI TT84

 BCC L4CC7

 CMP #&02
 BCS TT84

.L4CC7

 LDA #&02

.TT84

                        \ In the following, the authors have used XX15 for
                        \ temporary storage. XX15 shares location with X1, Y1,
                        \ X2 and Y2, so in the following, you can consider
                        \ the variables like this:
                        \
                        \   XX15   is the same as X1
                        \   XX15+1 is the same as Y1
                        \   XX15+2 is the same as X2
                        \   XX15+3 is the same as Y2
                        \
                        \ Presumably this routine was written at a different
                        \ time to the line-drawing routine, before the two
                        \ workspaces were merged to save space

 STA XX15               \ Set XX15 (X1) = A (the x-coordinate of the left edge
                        \ of the crosshairs)

 LDA QQ19               \ Set A = crosshairs x-coordinate + crosshairs size
 CLC                    \ to get the x-coordinate of the right edge of the
 ADC QQ19+2             \ crosshairs

 BCS L4CD6              \ ???

 CMP #&FE
 BCC TT85

.L4CD6

 LDA #&FE

.TT85

 STA XX15+2             \ Set XX15+2 (X2) = A (the x-coordinate of the right
                        \ edge of the crosshairs)

 LDA QQ19+1             \ Set XX15+1 (Y1) = crosshairs y-coordinate + indent
 CLC                    \ to get the y-coordinate of the centre of the
 ADC QQ19+5             \ crosshairs
 STA XX15+1

 JSR HLOIN3             \ ???

 LDA QQ19+1             \ Set A = crosshairs y-coordinate - crosshairs size
 SEC                    \ to get the y-coordinate of the top edge of the
 SBC QQ19+2             \ crosshairs

 BCS TT86               \ If the above subtraction didn't underflow, then A is
                        \ correct, so skip the next instruction

 LDA #0                 \ The subtraction underflowed, so set A to 0 so the
                        \ crosshairs don't spill out of the top of the screen

.TT86

 CLC                    \ Set XX15+1 (Y1) = A + indent to get the y-coordinate
 ADC QQ19+5             \ of the top edge of the indented crosshairs
 STA XX15+1

 LDA QQ19+1             \ Set A = crosshairs y-coordinate + crosshairs size
 CLC                    \ + indent to get the y-coordinate of the bottom edge
 ADC QQ19+2             \ of the indented crosshairs
 ADC QQ19+5

 CMP #152               \ If A < 152 then skip the following, as the crosshairs
 BCC TT87               \ won't spill out of the bottom of the screen

 LDX QQ11               \ A >= 152, so we need to check whether this will fit in
                        \ this view, so fetch the view number

 BMI TT87               \ If this is the Short-range Chart then the y-coordinate
                        \ is fine, so skip to TT87

 LDA #152               \ Otherwise this is the Long-range Chart, so we need to
                        \ clip the crosshairs at a maximum y-coordinate of 152
                        \ ???

.TT87

 STA XX15+3             \ Set XX15+3 (Y2) = A (the y-coordinate of the bottom
                        \ edge of the crosshairs)

 LDA QQ19               \ Set XX15 (X1) = the x-coordinate of the centre of the
 STA XX15               \ crosshairs

 STA XX15+2             \ Set XX15+2 (X2) = the x-coordinate of the centre of
                        \ the crosshairs

 JMP LL30               \ Draw a vertical line (X1, Y1) to (X2, Y2), which will
                        \ draw from the top edge of the crosshairs to the bottom
                        \ edge, through the centre of the crosshairs, returning
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT14
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle with crosshairs on a chart
\
\ ------------------------------------------------------------------------------
\
\ Draw a circle with crosshairs at the current system's galactic coordinates.
\
\ ******************************************************************************

.TT126

 LDA #104               \ Set QQ19 = 104, for the x-coordinate of the centre of
 STA QQ19               \ the fixed circle on the Short-range Chart

 LDA #90                \ Set QQ19+1 = 90, for the y-coordinate of the centre of
 STA QQ19+1             \ the fixed circle on the Short-range Chart

 LDA #16                \ Set QQ19+2 = 16, the size of the crosshairs on the
 STA QQ19+2             \ Short-range Chart

 LDA #&AF               \ ???
 STA COL

 JSR TT15               \ Draw the set of crosshairs defined in QQ19, at the
                        \ exact coordinates as this is the Short-range Chart

 LDA QQ14               \ ???
 JSR L4A43
 STA K

 JMP TT128              \ Jump to TT128 to draw a circle with the centre at the
                        \ same coordinates as the crosshairs, (QQ19, QQ19+1),
                        \ and radius K that reflects the current fuel levels,
                        \ returning from the subroutine using a tail call

.TT14

 LDA QQ11               \ If the current view is the Short-range Chart, which
 BMI TT126              \ is the only view with bit 7 set, then jump up to TT126
                        \ to draw the crosshairs and circle for that view

                        \ Otherwise this is the Long-range Chart, so we draw the
                        \ crosshairs and circle for that view instead

 LDA QQ14               \ ???
 LSR A
 JSR L4A42

 STA K
 LDA QQ0
 JSR L4A44

 STA QQ19
 LDA QQ1
 JSR L4A42

 STA QQ19+1

 LDA #7                 \ Set QQ19+2 = 7, the size of the crosshairs on the
 STA QQ19+2             \ Long-range Chart

 LDA #&FF               \ ???
 STA COL

 JSR TT15               \ Draw the set of crosshairs defined in QQ19, which will
                        \ be drawn 24 pixels to the right of QQ19+1

 LDA QQ19+1             \ Add 24 to the y-coordinate of the crosshairs in QQ19+1
 CLC                    \ so that the centre of the circle matches the centre
 ADC #24                \ of the crosshairs
 STA QQ19+1

                        \ Fall through into TT128 to draw a circle with the
                        \ centre at the same coordinates as the crosshairs,
                        \ (QQ19, QQ19+1),  and radius K that reflects the
                        \ current fuel levels

\ ******************************************************************************
\
\       Name: TT128
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle on a chart
\  Deep dive: Drawing circles
\
\ ------------------------------------------------------------------------------
\
\ Draw a circle with the centre at (QQ19, QQ19+1) and radius K.
\
\ Arguments:
\
\   QQ19                The x-coordinate of the centre of the circle
\
\   QQ19+1              The y-coordinate of the centre of the circle
\
\   K                   The radius of the circle
\
\ ******************************************************************************

.TT128

 LDA QQ19               \ Set K3 = the x-coordinate of the centre
 STA K3

 LDA QQ19+1             \ Set K4 = the y-coordinate of the centre
 STA K4

 STZ K4+1               \ Set the high bytes of K3(1 0) and K4(1 0) to 0
 STZ K3+1

 LDX #1                 \ Set LSP = 1 to reset the ball line heap
 STX LSP

 INX                    \ Set STP = 2, the step size for the circle
 STX STP

 LDA #RED               \ Switch to colour 2, which is red in the chart view
 STA COL

 JMP CIRCLE2            \ Jump to CIRCLE2 to draw a circle with the centre at
                        \ (K3(1 0), K4(1 0)) and radius K, returning from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT219
\       Type: Subroutine
\   Category: Market
\    Summary: Show the Buy Cargo screen (red key f1)
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   BAY2                Jump into the main loop at FRCE, setting the key
\                       "pressed" to red key f9 (so we show the Inventory
\                       screen)
\
\ ******************************************************************************

.TT219

 LDA #2                 \ Clear the top part of the screen, draw a white border,
 JSR TRADEMODE          \ and set up a printable trading screen with a view type
                        \ in QQ11 of 2 (Buy Cargo screen)

 JSR TT163              \ Print the column headers for the prices table

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case, with the
 STA QQ17               \ next letter in capitals

 LDA #0                 \ We're going to loop through all the available market
 STA QQ29               \ items, so we set up a counter in QQ29 to denote the
                        \ current item and start it at 0

.TT220

 JSR TT151              \ Call TT151 to print the item name, market price and
                        \ availability of the current item, and set QQ24 to the
                        \ item's price / 4, QQ25 to the quantity available and
                        \ QQ19+1 to byte #1 from the market prices table for
                        \ this item

 LDA QQ25               \ If there are some of the current item available, jump
 BNE TT224              \ to TT224 below to see if we want to buy any

 JMP TT222              \ Otherwise there are none available, so jump down to
                        \ TT222 to skip this item

.TQ4

 LDY #176               \ Set Y to the recursive token 16 ("QUANTITY")

.Tc

 JSR TT162              \ Print a space

 TYA                    \ Print the recursive token in Y followed by a question
 JSR prq                \ mark

.TTX224

 JSR dn2                \ Call dn2 to make a short, high beep and delay for 1
                        \ second

.TT224

 JSR CLYNS              \ Clear the bottom three text rows of the upper screen,
                        \ and move the text cursor to column 1 on row 21, i.e.
                        \ the start of the top row of the three bottom rows

 LDA #204               \ Print recursive token 44 ("QUANTITY OF ")
 JSR TT27

 LDA QQ29               \ Print recursive token 48 + QQ29, which will be in the
 CLC                    \ range 48 ("FOOD") to 64 ("ALIEN ITEMS"), so this
 ADC #208               \ prints the current item's name
 JSR TT27

 LDA #'/'               \ Print "/"
 JSR TT27

 JSR TT152              \ Print the unit ("t", "kg" or "g") for the current item
                        \ (as the call to TT151 above set QQ19+1 with the
                        \ appropriate value)

 LDA #'?'               \ Print "?"
 JSR TT27

 JSR TT67               \ Print a newline

 LDX #0                 \ These instructions have no effect, as they are
 STX R                  \ repeated at the start of gnum, which we call next.
 LDX #12                \ Perhaps they were left behind when code was moved from
 STX T1                 \ here into gnum, and weren't deleted?

 JSR gnum               \ Call gnum to get a number from the keyboard, which
                        \ will be the quantity of this item we want to purchase,
                        \ returning the number entered in A and R

 BCS TQ4                \ If gnum set the C flag, the number entered is greater
                        \ then the quantity available, so jump up to TQ4 to
                        \ display a "Quantity?" error, beep, clear the number
                        \ and try again

 STA P                  \ Otherwise we have a valid purchase quantity entered,
                        \ so store the amount we want to purchase in P

 JSR tnpr               \ Call tnpr to work out whether there is room in the
                        \ cargo hold for this item

 LDY #&CE
 LDA R
 BEQ L4DD8

 BCS Tc

.L4DD8

 LDA QQ24               \ There is room in the cargo hold, so now to check
 STA Q                  \ whether we have enough cash, so fetch the item's
                        \ price / 4, which was returned in QQ24 by the call
                        \ to TT151 above and store it in Q

 JSR GCASH              \ Call GCASH to calculate
                        \
                        \   (Y X) = P * Q * 4
                        \
                        \ which will be the total price of this transaction
                        \ (as P contains the purchase quantity and Q contains
                        \ the item's price / 4)

 JSR LCASH              \ Subtract (Y X) cash from the cash pot in CASH

 LDY #197               \ If the C flag is clear, we didn't have enough cash,
 BCC Tc                 \ so set Y to the recursive token 37 ("CASH") and jump
                        \ up to Tc to print a "Cash?" error, beep, clear the
                        \ number and try again

 LDY QQ29               \ Fetch the current market item number from QQ29 into Y

 LDA R                  \ Set A to the number of items we just purchased (this
                        \ was set by gnum above)

 PHA                    \ Store the quantity just purchased on the stack

 CLC                    \ Add the number purchased to the Y-th byte of QQ20,
 ADC QQ20,Y             \ which contains the number of items of this type in
 STA QQ20,Y             \ our hold (so this transfers the bought items into our
                        \ cargo hold)

 LDA AVL,Y              \ Subtract the number of items from the Y-th byte of
 SEC                    \ AVL, which contains the number of items of this type
 SBC R                  \ that are available on the market
 STA AVL,Y

 PLA                    \ Restore the quantity just purchased

 BEQ TT222              \ If we didn't buy anything, jump to TT222 to skip the
                        \ following instruction

 JSR dn                 \ Call dn to print the amount of cash left in the cash
                        \ pot, then make a short, high beep to confirm the
                        \ purchase, and delay for 1 second

.TT222

 LDA QQ29               \ Move the text cursor to row QQ29 + 5 (where QQ29 is
 CLC                    \ the item number, starting from 0)
 ADC #5
 JSR DOYC

 LDA #0                 \ Move the text cursor to column 0
 JSR DOXC

 INC QQ29               \ Increment QQ29 to point to the next item

 LDA QQ29               \ If QQ29 >= 17 then jump to BAY2 as we have done the
 CMP #17                \ last item
 BCS BAY2

 JMP TT220              \ Otherwise loop back to TT220 to print the next market
                        \ item

.BAY2

 LDA #f9                \ Jump into the main loop at FRCE, setting the key
 JMP FRCE               \ "pressed" to red key f9 (so we show the Inventory
                        \ screen)

\ ******************************************************************************
\
\       Name: gnum
\       Type: Subroutine
\   Category: Market
\    Summary: Get a number from the keyboard
\
\ ------------------------------------------------------------------------------
\
\ Get a number from the keyboard, up to the maximum number in QQ25, for the
\ buying and selling of cargo and equipment.
\
\ Pressing "Y" will return the maximum number (i.e. buy/sell all items), while
\ pressing "N" will abort the sale and return a 0.
\
\ Pressing a key with an ASCII code less than ASCII "0" will return a 0 in A (so
\ that includes pressing Space or Return), while pressing a key with an ASCII
\ code greater than ASCII "9" will jump to the Inventory screen (so that
\ includes all letters and most punctuation).
\
\ Arguments:
\
\   QQ25                The maximum number allowed
\
\ Returns:
\
\   A                   The number entered
\
\   R                   Also contains the number entered
\
\   C flag              Set if the number is too large (> QQ25), clear otherwise
\
\ ******************************************************************************

.gnum

 LDA #MAGENTA           \ Switch to colour 2, which is magenta in the trade view
 STA COL

 LDX #0                 \ We will build the number entered in R, so initialise
 STX R                  \ it with 0

 LDX #12                \ We will check for up to 12 key presses, so set a
 STX T1                 \ counter in T1

.TT223

 JSR TT217              \ Scan the keyboard until a key is pressed, and return
                        \ the key's ASCII code in A (and X)

 LDX R                  \ If R is non-zero then skip to NWDAV2, as we are
 BNE NWDAV2             \ already building a number

 CMP #'Y'               \ If "Y" was pressed, jump to NWDAV1 to return the
 BEQ NWDAV1             \ maximum number allowed (i.e. buy/sell the whole stock)

 CMP #'N'               \ If "N" was pressed, jump to NWDAV3 to return from the
 BEQ NWDAV3             \ subroutine with a result of 0 (i.e. abort transaction)

.NWDAV2

 STA Q                  \ Store the key pressed in Q

 SEC                    \ Subtract ASCII '0' from the key pressed, to leave the
 SBC #'0'               \ numeric value of the key in A (if it was a number key)

 BCC OUT                \ If A < 0, jump to OUT to return from the subroutine
                        \ with a result of 0, as the key pressed was not a
                        \ number or letter and is less than ASCII "0"

 CMP #10                \ If A >= 10, jump to BAY2 to display the Inventory
 BCS BAY2               \ screen, as the key pressed was a letter or other
                        \ non-digit and is greater than ASCII "9"

 STA S                  \ Store the numeric value of the key pressed in S

 LDA R                  \ Fetch the result so far into A

 CMP #26                \ If A >= 26, where A is the number entered so far, then
 BCS OUTX               \ adding a further digit will make it bigger than 256,
                        \ so jump to OUTX to ???

 ASL A                  \ Set A = (A * 2) + (A * 8) = A * 10
 STA T
 ASL A
 ASL A
 ADC T

 ADC S                  \ ???
 BCS OUTX
 STA R

 CMP QQ25               \ If the result in R = the maximum allowed in QQ25, jump
 BEQ TT226              \ to TT226 to print the key press and keep looping (the
                        \ BEQ is needed because the BCS below would jump to OUT
                        \ if R >= QQ25, which we don't want)

 BCS OUTX               \ If the result in R > QQ25, jump to OUTX to ???

.TT226

 LDA Q                  \ Print the character in Q (i.e. the key that was
 JSR TT26               \ pressed, as we stored the ASCII value in Q earlier)

 DEC T1                 \ Decrement the loop counter

 BNE TT223              \ Loop back to TT223 until we have checked for 12 digits

.OUT

 LDA #CYAN              \ Switch to colour 3, which is white in the trade view
 STA COL

 LDA R                  \ Set A to the result we have been building in R

 RTS                    \ Return from the subroutine

.NWDAV1

                        \ If we get here then "Y" was pressed, so we return the
                        \ maximum number allowed, which is in QQ25

 JSR TT26               \ Print the character for the key that was pressed

 LDA QQ25               \ Set R = QQ25, so we return the maximum value allowed
 STA R

 JMP OUT                \ Jump to OUT to return from the subroutine

.NWDAV3

                        \ If we get here then "N" was pressed, so we return 0

 JSR TT26               \ Print the character for the key that was pressed

 STZ R                  \ Set R = 0, so we return 0

 JMP OUT                \ Jump to OUT to return from the subroutine

\ ******************************************************************************
\
\       Name: NWDAV4
\       Type: Subroutine
\   Category: Market
\    Summary: Print an "ITEM?" error, make a beep and rejoin the TT210 routine
\
\ ******************************************************************************

.NWDAV4

 JSR TT67               \ Print a newline

 LDA #176               \ Print recursive token 127 ("ITEM") followed by a
 JSR prq                \ question mark

 JSR dn2                \ Call dn2 to make a short, high beep and delay for 1
                        \ second

 LDY QQ29               \ Fetch the item number we are selling from QQ29

 JMP NWDAVxx            \ Jump back into the TT210 routine that called NWDAV4

.OUTX

 LDA Q
 JSR DASC

 SEC
 JMP OUT

\ ******************************************************************************
\
\       Name: TT208
\       Type: Subroutine
\   Category: Market
\    Summary: Show the Sell Cargo screen (red key f2)
\
\ ******************************************************************************

.TT208

 LDA #4                 \ Clear the top part of the screen, draw a white border,
 JSR TRADEMODE          \ and set up a printable trading screen with a view type
                        \ in QQ11 of 4 (Sell Cargo screen)

 LDA #10                \ Move the text cursor to column 10
 STA XC

 LDA #205               \ Print recursive token 45 ("SELL")
 JSR TT27

 LDA #206               \ Print recursive token 46 (" CARGO{sentence case}")
 JSR NLIN3              \ draw a horizontal line at pixel row 19 to box in the
                        \ title

 JSR TT67               \ Print a newline

                        \ Fall through into TT210 to show the Inventory screen
                        \ with the option to sell

\ ******************************************************************************
\
\       Name: TT210
\       Type: Subroutine
\   Category: Inventory
\    Summary: Show a list of current cargo in our hold, optionally to sell
\
\ ------------------------------------------------------------------------------
\
\ Show a list of current cargo in our hold, either with the ability to sell (the
\ Sell Cargo screen) or without (the Inventory screen), depending on the current
\ view.
\
\ Arguments:
\
\   QQ11                The current view:
\
\                           * 4 = Sell Cargo
\
\                           * 8 = Inventory
\
\ Other entry points:
\
\   NWDAVxx             Used to rejoin this routine from the call to NWDAV4
\
\ ******************************************************************************

.TT210

 LDY #0                 \ We're going to loop through all the available market
                        \ items and check whether we have any in the hold (and,
                        \ if we are in the Sell Cargo screen, whether we want
                        \ to sell any items), so we set up a counter in Y to
                        \ denote the current item and start it at 0

.TT211

 STY QQ29               \ Store the current item number in QQ29

.NWDAVxx

 LDX QQ20,Y             \ Fetch into X the amount of the current item that we
 BEQ TT212              \ have in our cargo hold, which is stored in QQ20+Y,
                        \ and if there are no items of this type in the hold,
                        \ jump down to TT212 to skip to the next item

 TYA                    \ Set Y = Y * 4, so this will act as an index into the
 ASL A                  \ market prices table at QQ23 for this item (as there
 ASL A                  \ are four bytes per item in the table)
 TAY

 LDA QQ23+1,Y           \ Fetch byte #1 from the market prices table for the
 STA QQ19+1             \ current item and store it in QQ19+1, for use by the
                        \ call to TT152 below

 TXA                    \ Store the amount of item in the hold (in X) on the
 PHA                    \ stack

 JSR TT69               \ Call TT69 to set Sentence Case and print a newline

 CLC                    \ Print recursive token 48 + QQ29, which will be in the
 LDA QQ29               \ range 48 ("FOOD") to 64 ("ALIEN ITEMS"), so this
 ADC #208               \ prints the current item's name
 JSR TT27

 LDA #14                \ Move the text cursor to column 14, for the item's
 JSR DOXC               \ quantity

 PLA                    \ Restore the amount of item in the hold into X
 TAX

 STA QQ25               \ Store the amount of this item in the hold in QQ25

 CLC                    \ Print the 8-bit number in X to 3 digits, without a
 JSR pr2                \ decimal point

 JSR TT152              \ Print the unit ("t", "kg" or "g") for the market item
                        \ whose byte #1 from the market prices table is in
                        \ QQ19+1 (which we set up above)

 LDA QQ11               \ If the current view type in QQ11 is not 4 (Sell Cargo
 CMP #4                 \ screen), jump to TT212 to skip the option to sell
 BNE TT212              \ items

\JSRTT162               \ This instruction is commented out in the original
                        \ source

 LDA #205               \ Print recursive token 45 ("SELL")
 JSR TT27

 LDA #206               \ Print extended token 206 ("{all caps}(Y/N)?")
 JSR DETOK

 JSR gnum               \ Call gnum to get a number from the keyboard, which
                        \ will be the number of the item we want to sell,
                        \ returning the number entered in A and R, and setting
                        \ the C flag if the number is bigger than the available
                        \ amount of this item in QQ25

 BEQ TT212              \ If no number was entered, jump to TT212 to move on to
                        \ the next item

 BCS NWDAV4             \ If the number entered was too big, jump to NWDAV4 to
                        \ print an "ITEM?" error, make a beep and rejoin the
                        \ routine at NWDAVxx above

 LDA QQ29               \ We are selling this item, so fetch the item number
                        \ from QQ29

 LDX #255               \ Set QQ17 = 255 to disable printing
 STX QQ17

 JSR TT151              \ Call TT151 to set QQ24 to the item's price / 4 (the
                        \ routine doesn't print the item details, as we just
                        \ disabled printing)

 LDY QQ29               \ Subtract R (the number of items we just asked to buy)
 LDA QQ20,Y             \ from the available amount of this item in QQ20, as we
 SEC                    \ just bought them
 SBC R
 STA QQ20,Y

 LDA R                  \ Set P to the amount of this item we just bought
 STA P

 LDA QQ24               \ Set Q to the item's price / 4
 STA Q

 JSR GCASH              \ Call GCASH to calculate
                        \
                        \   (Y X) = P * Q * 4
                        \
                        \ which will be the total price we make from this sale
                        \ (as P contains the quantity we're selling and Q
                        \ contains the item's price / 4)

 JSR MCASH              \ Add (Y X) cash to the cash pot in CASH

 LDA #0                 \ We've made the sale, so set the amount

 STA QQ17               \ Set QQ17 = 0, which enables printing again

.TT212

 LDY QQ29               \ Fetch the item number from QQ29 into Y, and increment
 INY                    \ Y to point to the next item

 CPY #17                \ Loop back to TT211 to print the next item in the hold
 BCC TT211              \ until Y = 17 (at which point we have done the last
                        \ item)

 LDA QQ11               \ If the current view type in QQ11 is not 4 (Sell Cargo
 CMP #4                 \ screen), skip the next two instructions and just
 BNE P%+8               \ return from the subroutine

 JSR dn2                \ This is the Sell Cargo screen, so call dn2 to make a
                        \ short, high beep and delay for 1 second

 JMP BAY2               \ And then jump to BAY2 to display the Inventory
                        \ screen, as we have finished selling cargo

 JSR TT69               \ ???

 LDA L1264
 ORA L1265
 BNE L4F4A

.L4F49

 RTS

.L4F4A

 CLC
 LDA #&00
 LDX L1264
 LDY L1265
 JSR TT11

 JSR DORND

 AND #&03
 CLC
 ADC #&6F
 JSR DETOK

 LDA #&C6
 JSR DETOK

 LDA L1265
 BNE L4F71

 LDX L1264
 DEX
 BEQ L4F49

.L4F71

 LDA #&73
 JMP DASC

\ ******************************************************************************
\
\       Name: TT213
\       Type: Subroutine
\   Category: Inventory
\    Summary: Show the Inventory screen (red key f9)
\
\ ******************************************************************************

.TT213

 LDA #8                 \ Clear the top part of the screen, draw a white border,
 JSR TRADEMODE          \ and set up a printable trading screen with a view type
                        \ in QQ11 of 4 (Inventory screen)

 LDA #11                \ Move the text cursor to column 11 to print the screen
 STA XC                 \ title

 LDA #164               \ Print recursive token 4 ("INVENTORY{crlf}") followed
 JSR TT60               \ by a paragraph break and Sentence Case

 JSR NLIN4              \ Draw a horizontal line at pixel row 19 to box in the
                        \ title. The authors could have used a call to NLIN3
                        \ instead and saved the above call to TT60, but you
                        \ just can't optimise everything

 JSR fwl                \ Call fwl to print the fuel and cash levels on two
                        \ separate lines

 LDA CRGO               \ If our ship's cargo capacity is < 26 (i.e. we do not
 CMP #26                \ have a cargo bay extension), skip the following two
 BCC P%+7               \ instructions

 LDA #107               \ We do have a cargo bay extension, so print recursive
 JSR TT27               \ token 107 ("LARGE CARGO{sentence case} BAY")

 JMP TT210              \ Jump to TT210 to print the contents of our cargo bay
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT214
\       Type: Subroutine
\   Category: Inventory
\    Summary: Ask a question with a "Y/N?" prompt and return the response
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token to print before the "Y/N?" prompt
\
\ Returns:
\
\   C flag              Set if the response was "yes", clear otherwise
\
\ ******************************************************************************

.TT214

.TT221

 JSR TT27               \ Print the text token in A

 LDA #206               \ Print extended token 206 ("{all caps}(Y/N)?")
 JSR DETOK

 JSR TT217              \ Scan the keyboard until a key is pressed, and return
                        \ the key's ASCII code in A and X

 ORA #%00100000         \ Set bit 5 in the value of the key pressed, which
                        \ converts it to lower case

 CMP #'y'               \ If "y" was pressed, jump to TT218
 BEQ TT218

 LDA #'n'               \ Otherwise jump to TT26 to print "n" and return from
 JMP TT26               \ the subroutine using a tail call (so all other
                        \ responses apart from "y" indicate a no)

.TT218

 JSR TT26               \ Print the character in A, i.e. print "y"

 SEC                    \ Set the C flag to indicate a "yes" response

 RTS

\ ******************************************************************************
\
\       Name: TT16
\       Type: Subroutine
\   Category: Charts
\    Summary: Move the crosshairs on a chart
\
\ ------------------------------------------------------------------------------
\
\ Move the chart crosshairs by the amount in X and Y.
\
\ Arguments:
\
\   X                   The amount to move the crosshairs in the x-axis
\
\   Y                   The amount to move the crosshairs in the y-axis
\
\ ******************************************************************************

.TT16

 TXA                    \ Push the change in X onto the stack (let's call this
 PHA                    \ the x-delta)

 DEY                    \ Negate the change in Y and push it onto the stack
 TYA                    \ (let's call this the y-delta)
 EOR #255
 PHA

 JSR WSCAN              \ Call WSCAN to wait for the vertical sync, so the whole
                        \ screen gets drawn and we can move the crosshairs with
                        \ no screen flicker

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will erase the crosshairs currently there

 PLA                    \ Store the y-delta in QQ19+3 and fetch the current
 STA QQ19+3             \ y-coordinate of the crosshairs from QQ10 into A, ready
 LDA QQ10               \ for the call to TT123

 JSR TT123              \ Call TT123 to move the selected system's galactic
                        \ y-coordinate by the y-delta, putting the new value in
                        \ QQ19+4

 LDA QQ19+4             \ Store the updated y-coordinate in QQ10 (the current
 STA QQ10               \ y-coordinate of the crosshairs)

 STA QQ19+1             \ This instruction has no effect, as QQ19+1 is
                        \ overwritten below, both in TT103 and TT105

 PLA                    \ Store the x-delta in QQ19+3 and fetch the current
 STA QQ19+3             \ x-coordinate of the crosshairs from QQ10 into A, ready
 LDA QQ9                \ for the call to TT123

 JSR TT123              \ Call TT123 to move the selected system's galactic
                        \ x-coordinate by the x-delta, putting the new value in
                        \ QQ19+4

 LDA QQ19+4             \ Store the updated x-coordinate in QQ9 (the current
 STA QQ9                \ x-coordinate of the crosshairs)

 STA QQ19               \ This instruction has no effect, as QQ19 is overwritten
                        \ below, both in TT103 and TT105

                        \ Now we've updated the coordinates of the crosshairs,
                        \ fall through into TT103 to redraw them at their new
                        \ location

\ ******************************************************************************
\
\       Name: TT103
\       Type: Subroutine
\   Category: Charts
\    Summary: Draw a small set of crosshairs on a chart
\
\ ------------------------------------------------------------------------------
\
\ Draw a small set of crosshairs on a galactic chart at the coordinates in
\ (QQ9, QQ10).
\
\ ******************************************************************************

.TT103

 LDA #&AF               \ ???
 STA COL

 LDA QQ11               \ Fetch the current view type into A

 BMI TT105              \ If this is the Short-range Chart screen, jump to TT105

 LDA QQ9                \ ???
 JSR L4A44

 STA QQ19
 LDA QQ10
 JSR L4A42
 STA QQ19+1

 LDA #4                 \ Set QQ19+2 to 4 denote crosshairs of size 4
 STA QQ19+2

 JMP TT15               \ Jump to TT15 to draw crosshairs of size 4 at the
                        \ crosshairs coordinates, returning from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: TT123
\       Type: Subroutine
\   Category: Charts
\    Summary: Move galactic coordinates by a signed delta
\
\ ------------------------------------------------------------------------------
\
\ Move an 8-bit galactic coordinate by a certain distance in either direction
\ (i.e. a signed 8-bit delta), but only if it doesn't cause the coordinate to
\ overflow. The coordinate is in a single axis, so it's either an x-coordinate
\ or a y-coordinate.
\
\ Arguments:
\
\   A                   The galactic coordinate to update
\
\   QQ19+3              The delta (can be positive or negative)
\
\ Returns:
\
\   QQ19+4              The updated coordinate after moving by the delta (this
\                       will be the same as A if moving by the delta overflows)
\
\ Other entry points:
\
\   TT180               Contains an RTS
\
\ ******************************************************************************

.TT123

 STA QQ19+4             \ Store the original coordinate in temporary storage at
                        \ QQ19+4

 CLC                    \ Set A = A + QQ19+3, so A now contains the original
 ADC QQ19+3             \ coordinate, moved by the delta

 LDX QQ19+3             \ If the delta is negative, jump to TT124
 BMI TT124

 BCC TT125              \ If the C flag is clear, then the above addition didn't
                        \ overflow, so jump to TT125 to return the updated value

 RTS                    \ Otherwise the C flag is set and the above addition
                        \ overflowed, so do not update the return value

.TT124

 BCC TT180              \ If the C flag is clear, then because the delta is
                        \ negative, this indicates the addition (which is
                        \ effectively a subtraction) underflowed, so jump to
                        \ TT180 to return from the subroutine without updating
                        \ the return value

.TT125

 STA QQ19+4             \ Store the updated coordinate in QQ19+4

.TT180

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT105
\       Type: Subroutine
\   Category: Charts
\    Summary: Draw crosshairs on the Short-range Chart, with clipping
\
\ ------------------------------------------------------------------------------
\
\ Check whether the crosshairs are close enough to the current system to appear
\ on the Short-range Chart, and if so, draw them.
\
\ ******************************************************************************

.TT105

 LDA QQ9                \ Set A = QQ9 - QQ0, the horizontal distance between the
 SEC                    \ crosshairs (QQ9) and the current system (QQ0)
 SBC QQ0

 BCS L5017              \ ???

 EOR #&FF
 ADC #&01

.L5017

 CMP #&1D
 BCS TT180

 LDA QQ9
 SEC
 SBC QQ0
 BPL TT179

 CMP #&E9
 BCC TT180

.TT179

 ASL A                  \ ???
 ASL A
 CLC
 ADC #&68
 JSR L4A43
 STA QQ19

 LDA QQ10               \ Set A = QQ10 - QQ1, the vertical distance between the
 SEC                    \ crosshairs (QQ10) and the current system (QQ1)
 SBC QQ1

 BCS L503D              \ ???

 EOR #&FF
 ADC #&01

.L503D

 CMP #&23
 BCS TT180

 LDA QQ10
 SEC
 SBC QQ1

 ASL A                  \ ???
 CLC
 ADC #&5A
 JSR L4A43
 STA QQ19+1

 LDA #8                 \ Set QQ19+2 to 8 denote crosshairs of size 8
 STA QQ19+2

 LDA #&AF               \ ???
 STA COL

 JMP TT15               \ Jump to TT15 to draw crosshairs of size 8 at the
                        \ crosshairs coordinates, returning from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: TT23
\       Type: Subroutine
\   Category: Charts
\    Summary: Show the Short-range Chart (red key f5)
\
\ ******************************************************************************

.TT23

 LDA #128               \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 128 (Short-
                        \ range Chart)

 LDA #16                \ Switch to the mode 1 palette for the trade view, which
 JSR SETVDU19           \ is yellow (colour 1), magenta (colour 2) and white
                        \ (colour 3)

 LDA #CYAN              \ Switch to colour 3, which is white in the chart view
 STA COL

 LDA #7                 \ Move the text cursor to column 7
 STA XC

 LDA #190               \ Print recursive token 30 ("SHORT RANGE CHART") and
 JSR NLIN3              \ draw a horizontal line at pixel row 19 to box in the
                        \ title

 JSR TT14               \ Call TT14 to draw a circle with crosshairs at the
                        \ current system's galactic coordinates

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ i.e. at the selected system

 JSR TT81               \ Set the seeds in QQ15 to those of system 0 in the
                        \ current galaxy (i.e. copy the seeds from QQ21 to QQ15)

 LDA #CYAN              \ Switch to colour 3, which is white in the chart view
 STA COL

 LDA #0                 \ Set A = 0, which we'll use below to zero out the INWK
                        \ workspace

 STA XX20               \ We're about to start working our way through each of
                        \ the galaxy's systems, so set up a counter in XX20 for
                        \ each system, starting at 0 and looping through to 255

 LDX #24                \ First, though, we need to zero out the 25 bytes at
                        \ INWK so we can use them to work out which systems have
                        \ room for a label, so set a counter in X for 25 bytes

.EE3

 STA INWK,X             \ Set the X-th byte of INWK to zero

 DEX                    \ Decrement the counter

 BPL EE3                \ Loop back to EE3 for the next byte until we've zeroed
                        \ all 25 bytes

                        \ We now loop through every single system in the galaxy
                        \ and check the distance from the current system whose
                        \ coordinates are in (QQ0, QQ1). We get the galactic
                        \ coordinates of each system from the system's seeds,
                        \ like this:
                        \
                        \   x = s1_hi (which is stored in QQ15+3)
                        \   y = s0_hi (which is stored in QQ15+1)
                        \
                        \ so the following loops through each system in the
                        \ galaxy in turn and calculates the distance between
                        \ (QQ0, QQ1) and (s1_hi, s0_hi) to find the closest one

.TT182

 LDA QQ15+3             \ Set A = s1_hi - QQ0, the horizontal distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ0, QQ1)
 SBC QQ0

 BCS TT184              \ If a borrow didn't occur, i.e. s1_hi >= QQ0, then the
                        \ result is positive, so jump to TT184 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s1_hi - QQ0|)

.TT184

 CMP #29                \ If the horizontal distance in A is >= 29, then this
 BCS L50FB              \ system is too far away from the current system to
                        \ appear in the Short-range Chart, so jump to L50FB to
                        \ move on to the next system ???

 LDA QQ15+1             \ Set A = s0_hi - QQ1, the vertical distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ0, QQ1)
 SBC QQ1

 BCS TT186              \ If a borrow didn't occur, i.e. s0_hi >= QQ1, then the
                        \ result is positive, so jump to TT186 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s0_hi - QQ1|)

.TT186

 CMP #&28
 BCS L50FB

                        \ This system should be shown on the Short-range Chart,
                        \ so now we need to work out where the label should go,
                        \ and set up the various variables we need to draw the
                        \ system's filled circle on the chart

 LDA QQ15+3             \ Set A = s1_hi - QQ0, the horizontal distance between
 SEC                    \ this system and the current system, where |A| < 20.
 SBC QQ0                \ Let's call this the x-delta, as it's the horizontal
                        \ difference between the current system at the centre of
                        \ the chart, and this system (and this time we keep the
                        \ sign of A, so it can be negative if it's to the left
                        \ of the chart's centre, or positive if it's to the
                        \ right)

 ASL A                  \ Set XX12 = 104 + x-delta * 4
 ASL A                  \
 ADC #104               \ 104 is the x-coordinate of the centre of the chart,
 JSR L4A43              \ so this sets XX12 to the centre 104 +/- 76, the pixel
 STA XX12               \ x-coordinate of this system ???

 LSR A                  \ Move the text cursor to column x-delta / 2 + 1
 LSR A                  \ which will be in the range 1-10
 LSR A
 INC A
 STA XC

 LDA QQ15+1             \ Set A = s0_hi - QQ1, the vertical distance between
 SEC                    \ this system and the current system, where |A| < 38.
 SBC QQ1                \ Let's call this the y-delta, as it's the vertical
                        \ difference between the current system at the centre of
                        \ the chart, and this system (and this time we keep the
                        \ sign of A, so it can be negative if it's above the
                        \ chart's centre, or positive if it's below)

 ASL A                  \ Set K4 = 90 + y-delta * 2
 ADC #90                \
 JSR L4A43              \ 90 is the y-coordinate of the centre of the chart,
 STA K4                 \ so this sets K4 to the centre 90 +/- 74, the pixel
                        \ y-coordinate of this system ???

 LSR A                  \ Set Y = K4 / 8, so Y contains the number of the text
 LSR A                  \ row that contains this system
 LSR A
 TAY

                        \ Now to see if there is room for this system's label.
                        \ Ideally we would print the system name on the same
                        \ text row as the system, but we only want to print one
                        \ label per row, to prevent overlap, so now we check
                        \ this system's row, and if that's already occupied,
                        \ the row above, and if that's already occupied, the
                        \ row below... and if that's already occupied, we give
                        \ up and don't print a label for this system

 LDX INWK,Y             \ If the value in INWK+Y is 0 (i.e. the text row
 BEQ EE4                \ containing this system does not already have another
                        \ system's label on it), jump to EE4 to store this
                        \ system's label on this row

 INY                    \ If the value in INWK+Y+1 is 0 (i.e. the text row below
 LDX INWK,Y             \ the one containing this system does not already have
 BEQ EE4                \ another system's label on it), jump to EE4 to store
                        \ this system's label on this row

 DEY                    \ If the value in INWK+Y-1 is 0 (i.e. the text row above
 DEY                    \ the one containing this system does not already have
 LDX INWK,Y             \ another system's label on it), fall through into to
 BNE ee1                \ EE4 to store this system's label on this row,
                        \ otherwise jump to ee1 to skip printing a label for
                        \ this system (as there simply isn't room)

.EE4

 STY YC                 \ Now to print the label, so move the text cursor to row
                        \ Y (which contains the row where we can print this
                        \ system's label)

 CPY #3                 \ If Y < 3, then the label would clash with the chart
 BCC TT187              \ title, so jump to TT187 to skip printing the label

 CPY #&15
 BCS TT187

 TYA
 PHA
 LDA QQ15+3
 JSR L5193

 PLA
 TAY
 LDA QQ8+1
 BNE TT187

 LDA QQ8
 CMP #&46

.L50FB

 BCS TT187

 LDA #&FF               \ Store &FF in INWK+Y, to denote that this row is now
 STA INWK,Y             \ occupied so we don't try to print another system's
                        \ label on this row

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case
 STA QQ17

 JSR cpl                \ Call cpl to print out the system name for the seeds
                        \ in QQ15 (which now contains the seeds for the current
                        \ system)

.ee1

 LDA #0                 \ Now to plot the star, so set the high bytes of K, K3
 STA K3+1               \ and K4 to 0
 STA K4+1
 STA K+1

 LDA XX12               \ Set the low byte of K3 to XX12, the pixel x-coordinate
 STA K3                 \ of this system

 LDA QQ15+5             \ Fetch s2_hi for this system from QQ15+5, extract bit 0
 AND #1                 \ and add 2 to get the size of the star, which we store
 ADC #2                 \ in K. This will be either 2, 3 or 4, depending on the
 STA K                  \ value of bit 0, and whether the C flag is set (which
                        \ will vary depending on what happens in the above call
                        \ to cpl). Incidentally, the planet's average radius
                        \ also uses s2_hi, bits 0-3 to be precise, but that
                        \ doesn't mean the two sizes affect each other

                        \ We now have the following:
                        \
                        \   K(1 0)  = radius of star (2, 3 or 4)
                        \
                        \   K3(1 0) = pixel x-coordinate of system
                        \
                        \   K4(1 0) = pixel y-coordinate of system
                        \
                        \ which we can now pass to the SUN routine to draw a
                        \ small "sun" on the Short-range Chart for this system

 JSR FLFLLS             \ Call FLFLLS to reset the LSO block

 JSR SUN                \ Call SUN to plot a sun with radius K at pixel
                        \ coordinate (K3, K4)

 JSR FLFLLS             \ Call FLFLLS to reset the LSO block

 LDA #CYAN              \ Switch to colour 3, which is white in the chart view
 STA COL

.TT187

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 INC XX20               \ Increment the counter

 BEQ L5134              \ ???

 JMP TT182              \ Otherwise jump back up to TT182 to process the next
                        \ system

.L5134

 RTS

\ ******************************************************************************
\
\       Name: TT81
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the selected system's seeds to those of system 0
\
\ ------------------------------------------------------------------------------
\
\ Copy the three 16-bit seeds for the current galaxy's system 0 (QQ21) into the
\ seeds for the selected system (QQ15) - in other words, set the selected
\ system's seeds to those of system 0.
\
\ ******************************************************************************

.TT81

 LDX #5                 \ Set up a counter in X to copy six bytes (for three
                        \ 16-bit numbers)

 LDA QQ21,X             \ Copy the X-th byte in QQ21 to the X-th byte in QQ15
 STA QQ15,X

 DEX                    \ Decrement the counter

 BPL TT81+2             \ Loop back up to the LDA instruction if we still have
                        \ more bytes to copy

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT111
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the current system to the nearest system to a point
\
\ ------------------------------------------------------------------------------
\
\ Given a set of galactic coordinates in (QQ9, QQ10), find the nearest system
\ to this point in the galaxy, and set this as the currently selected system.
\
\ Arguments:
\
\   QQ9                 The x-coordinate near which we want to find a system
\
\   QQ10                The y-coordinate near which we want to find a system
\
\ Returns:
\
\   QQ8(1 0)            The distance from the current system to the nearest
\                       system to the original coordinates
\
\   QQ9                 The x-coordinate of the nearest system to the original
\                       coordinates
\
\   QQ10                The y-coordinate of the nearest system to the original
\                       coordinates
\
\   QQ15 to QQ15+5      The three 16-bit seeds of the nearest system to the
\                       original coordinates
\
\   ZZ                  The system number of the nearest system
\
\ Other entry points:
\
\   TT111-1             Contains an RTS
\
\   L5193               ???
\
\ ******************************************************************************

.TT111

 JSR TT81               \ Set the seeds in QQ15 to those of system 0 in the
                        \ current galaxy (i.e. copy the seeds from QQ21 to QQ15)

                        \ We now loop through every single system in the galaxy
                        \ and check the distance from (QQ9, QQ10). We get the
                        \ galactic coordinates of each system from the system's
                        \ seeds, like this:
                        \
                        \   x = s1_hi (which is stored in QQ15+3)
                        \   y = s0_hi (which is stored in QQ15+1)
                        \
                        \ so the following loops through each system in the
                        \ galaxy in turn and calculates the distance between
                        \ (QQ9, QQ10) and (s1_hi, s0_hi) to find the closest one

 LDY #127               \ Set Y = T = 127 to hold the shortest distance we've
 STY T                  \ found so far, which we initially set to half the
                        \ distance across the galaxy, or 127, as our coordinate
                        \ system ranges from (0,0) to (255, 255)

 LDA #0                 \ Set A = U = 0 to act as a counter for each system in
 STA U                  \ the current galaxy, which we start at system 0 and
                        \ loop through to 255, the last system

.TT130

 LDA QQ15+3             \ Set A = s1_hi - QQ9, the horizontal distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ9, QQ10)
 SBC QQ9

 BCS TT132              \ If a borrow didn't occur, i.e. s1_hi >= QQ9, then the
                        \ result is positive, so jump to TT132 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s1_hi - QQ9|)

.TT132

 LSR A                  \ Set S = A / 2
 STA S                  \       = |s1_hi - QQ9| / 2

 LDA QQ15+1             \ Set A = s0_hi - QQ10, the vertical distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ9, QQ10)
 SBC QQ10

 BCS TT134              \ If a borrow didn't occur, i.e. s0_hi >= QQ10, then the
                        \ result is positive, so jump to TT134 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s0_hi - QQ10|)

.TT134

 LSR A                  \ Set A = S + A / 2
 CLC                    \       = |s1_hi - QQ9| / 2 + |s0_hi - QQ10| / 2
 ADC S                  \
                        \ So A now contains the sum of the horizontal and
                        \ vertical distances, both divided by 2 so the result
                        \ fits into one byte, and although this doesn't contain
                        \ the actual distance between the systems, it's a good
                        \ enough approximation to use for comparing distances

 CMP T                  \ If A >= T, then this system's distance is bigger than
 BCS TT135              \ our "minimum distance so far" stored in T, so it's no
                        \ closer than the systems we have already found, so
                        \ skip to TT135 to move on to the next system

 STA T                  \ This system is the closest to (QQ9, QQ10) so far, so
                        \ update T with the new "distance" approximation

 LDX #5                 \ As this system is the closest we have found yet, we
                        \ want to store the system's seeds in case it ends up
                        \ being the closest of all, so we set up a counter in X
                        \ to copy six bytes (for three 16-bit numbers)

.TT136

 LDA QQ15,X             \ Copy the X-th byte in QQ15 to the X-th byte in QQ19,
 STA QQ19,X             \ where QQ15 contains the seeds for the system we just
                        \ found to be the closest so far, and QQ19 is temporary
                        \ storage

 DEX                    \ Decrement the counter

 BPL TT136              \ Loop back to TT136 if we still have more bytes to
                        \ copy

 LDA U                  \ Store the system number U in ZZ, so when we are done
 STA ZZ                 \ looping through all the candidates, the winner's
                        \ number will be in ZZ

.TT135

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 INC U                  \ Increment the system counter in U

 BNE TT130              \ If U > 0 then we haven't done all 256 systems yet, so
                        \ loop back up to TT130

                        \ We have now finished checking all the systems in the
                        \ galaxy, and the seeds for the closest system are in
                        \ QQ19, so now we want to copy these seeds to QQ15,
                        \ to set the selected system to this closest system

 LDX #5                 \ So we set up a counter in X to copy six bytes (for
                        \ three 16-bit numbers)

.TT137

 LDA QQ19,X             \ Copy the X-th byte in QQ19 to the X-th byte in QQ15,
 STA QQ15,X

 DEX                    \ Decrement the counter

 BPL TT137              \ Loop back to TT137 if we still have more bytes to
                        \ copy

 LDA QQ15+1             \ The y-coordinate of the system described by the seeds
 STA QQ10               \ in QQ15 is in QQ15+1 (s0_hi), so we copy this to QQ10
                        \ as this is where we store the selected system's
                        \ y-coordinate

 LDA QQ15+3             \ The x-coordinate of the system described by the seeds
 STA QQ9                \ in QQ15 is in QQ15+3 (s1_hi), so we copy this to QQ9
                        \ as this is where we store the selected system's
                        \ x-coordinate

                        \ We have now found the closest system to (QQ9, QQ10)
                        \ and have set it as the selected system, so now we
                        \ need to work out the distance between the selected
                        \ system and the current system

.L5193                  \ ???

 SEC                    \ Set A = QQ9 - QQ0, the horizontal distance between
 SBC QQ0                \ the selected system's x-coordinate (QQ9) and the
                        \ current system's x-coordinate (QQ0)

 BCS TT139              \ If a borrow didn't occur, i.e. QQ9 >= QQ0, then the
                        \ result is positive, so jump to TT139 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |QQ9 - QQ0|)

                        \ A now contains the difference between the two
                        \ systems' x-coordinates, with the sign removed. We
                        \ will refer to this as the x-delta ("delta" means
                        \ change or difference in maths)

.TT139

 JSR SQUA2              \ Set (A P) = A * A
                        \           = |QQ9 - QQ0| ^ 2
                        \           = x_delta ^ 2

 STA K+1                \ Store (A P) in K(1 0)
 LDA P
 STA K

 LDA QQ15+1             \ ???
 SEC
 SBC QQ1

 BCS TT141              \ If a borrow didn't occur, i.e. QQ10 >= QQ1, then the
                        \ result is positive, so jump to TT141 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |QQ10 - QQ1|)

.TT141

 LSR A                  \ Set A = A / 2

                        \ A now contains the difference between the two
                        \ systems' y-coordinates, with the sign removed, and
                        \ halved. We halve the value because the galaxy in
                        \ in Elite is rectangular rather than square, and is
                        \ twice as wide (x-axis) as it is high (y-axis), so to
                        \ get a distance that matches the shape of the
                        \ long-range galaxy chart, we need to halve the
                        \ distance between the vertical y-coordinates. We will
                        \ refer to this as the y-delta

 JSR SQUA2              \ Set (A P) = A * A
                        \           = (|QQ10 - QQ1| / 2) ^ 2
                        \           = y_delta ^ 2

                        \ By this point we have the following results:
                        \
                        \   K(1 0) = x_delta ^ 2
                        \    (A P) = y_delta ^ 2
                        \
                        \ so to find the distance between the two points, we
                        \ can use Pythagoras - so first we need to add the two
                        \ results together, and then take the square root

 PHA                    \ Store the high byte of the y-axis value on the stack,
                        \ so we can use A for another purpose

 LDA P                  \ Set Q = P + K, which adds the low bytes of the two
 CLC                    \ calculated values
 ADC K
 STA Q

 PLA                    \ Restore the high byte of the y-axis value from the
                        \ stack into A again

 ADC K+1                \ ???
 BCC L51C5

 LDA #&FF

.L51C5

 STA R

 JSR LL5                \ Set Q = SQRT(R Q), so Q now contains the distance
                        \ between the two systems, in terms of coordinates

                        \ We now store the distance to the selected system * 4
                        \ in the two-byte location QQ8, by taking (0 Q) and
                        \ shifting it left twice, storing it in (QQ8+1 QQ8)

 LDA Q                  \ First we shift the low byte left by setting
 ASL A                  \ A = Q * 2, with bit 7 of A going into the C flag

 LDX #0                 \ Now we set the high byte in QQ8+1 to 0 and rotate
 STX QQ8+1              \ the C flag into bit 0 of QQ8+1
 ROL QQ8+1

 ASL A                  \ And then we repeat the shift left of (QQ8+1 A)
 ROL QQ8+1

 STA QQ8                \ And store A in the low byte, QQ8, so QQ8(1 0) now
                        \ contains Q * 4. Given that the width of the galaxy is
                        \ 256 in coordinate terms, the width of the galaxy
                        \ would be 1024 in the units we store in QQ8

 JMP TT24               \ Call TT24 to calculate system data from the seeds in
                        \ QQ15 and store them in the relevant locations, so our
                        \ new selected system is fully set up, and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Type: Subroutine
\   Category: Flight
\    Summary: Print a message to say no hyperspacing inside the station
\
\ ------------------------------------------------------------------------------
\
\ Print "Docked" at the bottom of the screen to indicate we can't hyperspace
\ when docked.
\
\ ******************************************************************************

.hy6

 JSR CLYNS              \ Clear the bottom three text rows of the upper screen,
                        \ and move the text cursor to column 1 on row 21, i.e.
                        \ the start of the top row of the three bottom rows

 LDA #15                \ Move the text cursor to column 15 (the middle of the
 STA XC                 \ screen), setting A to 15 at the same time for the
                        \ following call to TT27

 LDA #RED               \ Switch to colour 2, which is magenta in the trade view
 STA COL                \ or red in the chart view

 LDA #205               \ Print extended token 205 ("DOCKED") and return from
 JMP DETOK              \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: hyp
\       Type: Subroutine
\   Category: Flight
\    Summary: Start the hyperspace process
\
\ ------------------------------------------------------------------------------
\
\ Called when "H" or CTRL-H is pressed during flight. Checks the following:
\
\   * We are in space
\
\   * We are not already in a hyperspace countdown
\
\ If CTRL is being held down, we jump to Ghy to engage the galactic hyperdrive,
\ otherwise we check that:
\
\   * The selected system is not the current system
\
\   * We have enough fuel to make the jump
\
\ and if all the pre-jump checks are passed, we print the destination on-screen
\ and start the countdown.
\
\ Other entry points:
\
\   TTX111              Used to rejoin this routine from the call to TTX110
\
\ ******************************************************************************

.hyp

 LDA QQ12               \ If we are docked (QQ12 = &FF) then jump to hy6 to
 BNE hy6                \ print an error message and return from the subroutine
                        \ using a tail call (as we can't hyperspace when docked)

 LDA QQ22+1             \ Fetch QQ22+1, which contains the number that's shown
                        \ on-screen during hyperspace countdown

 BEQ P%+3               \ If it is zero, skip the next instruction

 RTS                    \ The count is non-zero, so return from the subroutine

 LDA #CYAN              \ The count is zero, so switch to colour 3, which is
 STA COL                \ cyan in the space view

 JSR CTRL               \ Scan the keyboard to see if CTRL is currently pressed

 BMI Ghy                \ If it is, then the galactic hyperdrive has been
                        \ activated, so jump to Ghy to process it

 LDA QQ11               \ If the current view is 0 (i.e. the space view) then
 BEQ TTX110             \ jump to TTX110, which calls TT111 to set the current
                        \ system to the nearest system to (QQ9, QQ10), and jumps
                        \ back into this routine at TTX111 below

 AND #%11000000         \ If either bits 6 or 7 of the view number are set - so
 BNE P%+3               \ this is either the Short-range or Long-range Chart -
                        \ then skip the following instruction

 RTS                    \ This is not a chart view, so return from the
                        \ subroutine

 JSR hm                 \ This is a chart view, so call hm to redraw the chart
                        \ crosshairs

.TTX111

                        \ If we get here then the current view is either the
                        \ space view or a chart

 LDA QQ8                \ If either byte of the distance to the selected system
 ORA QQ8+1              \ in QQ8 are zero, skip the next instruction to make a
 BNE P%+3               \ copy of the destination seeds in safehouse

 RTS                    \ The selected system is the same as the current system,
                        \ so return from the subroutine

 LDX #5                 \ We now want to copy those seeds into safehouse, so we
                        \ so set a counter in X to copy 6 bytes

.sob

 LDA QQ15,X             \ Copy the X-th byte of QQ15 into the X-th byte of
 STA safehouse,X        \ safehouse

 DEX                    \ Decrement the loop counter

 BPL sob                \ Loop back to copy the next byte until we have copied
                        \ all six seed bytes

 LDA #7                 \ Move the text cursor to column 7, row 22 (in the
 STA XC                 \ middle of the bottom text row)
 LDA #22
 STA YC

 LDA #0                 \ Set QQ17 = 0 to switch to ALL CAPS
 STA QQ17

 LDA #189               \ Print recursive token 29 ("HYPERSPACE ")
 JSR TT27

 LDA QQ8+1              \ If the high byte of the distance to the selected
 BNE goTT147            \ system in QQ8 is > 0, then it is definitely too far to
                        \ jump (as our maximum range is 7.0 light years, or a
                        \ value of 70 in QQ8(1 0)), so jump to TT147 via goTT147
                        \ to print "RANGE?" and return from the subroutine using
                        \ a tail call

 LDA QQ14               \ Fetch our current fuel level from Q114 into A

 CMP QQ8                \ If our fuel reserves are greater then or equal to the
 BCS P%+5               \ distance to the selected system, then we have enough
                        \ fuel for this jump, so skip the following instruction
                        \ to start the hyperspace countdown

.goTT147

 JMP TT147              \ We don't have enough fuel to reach the destination, so
                        \ jump to TT147 to print "RANGE?" and return from the
                        \ subroutine using a tail call

 LDA #'-'               \ Print a hyphen
 JSR TT27

 JSR cpl                \ Call cpl to print the name of the selected system

                        \ Fall through into wW to start the hyperspace countdown

\ ******************************************************************************
\
\       Name: wW
\       Type: Subroutine
\   Category: Flight
\    Summary: Start a hyperspace countdown
\
\ ------------------------------------------------------------------------------
\
\ Start the hyperspace countdown (for both inter-system hyperspace and the
\ galactic hyperdrive).
\
\ Other entry points:
\
\   wW2                 Start the hyperspace countdown, starting the countdown
\                       from the value in A
\ ******************************************************************************

.wW

 LDA #15                \ The hyperspace countdown starts from 15, so set A to
                        \ to 15 so we can set the two hyperspace counters

.wW2

 STA QQ22+1             \ Set the number in QQ22+1 to 15, which is the number
                        \ that's shown on-screen during the hyperspace countdown

 STA QQ22               \ Set the number in QQ22 to 15, which is the internal
                        \ counter that counts down by 1 each iteration of the
                        \ main game loop, and each time it reaches zero, the
                        \ on-screen counter gets decremented, and QQ22 gets set
                        \ to 5, so setting QQ22 to 15 here makes the first tick
                        \ of the hyperspace counter longer than subsequent ticks

 TAX                    \ Print the 8-bit number in X (i.e. 15) at text location
 JMP ee3                \ (0, 1), padded to 5 digits, so it appears in the top
                        \ left corner of the screen, and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TTX110
\       Type: Subroutine
\   Category: Flight
\    Summary: Set the current system to the nearest system and return to hyp
\
\ ******************************************************************************

.TTX110

                        \ This routine is only called from the hyp routine, and
                        \ it jumps back into hyp at label TTX111

 JSR TT111              \ Call TT111 to set the current system to the nearest
                        \ system to (QQ9, QQ10), and put the seeds of the
                        \ nearest system into QQ15 to QQ15+5

 JMP TTX111             \ Return to TTX111 in the hyp routine

\ ******************************************************************************
\
\       Name: Ghy
\       Type: Subroutine
\   Category: Flight
\    Summary: Perform a galactic hyperspace jump
\  Deep dive: Twisting the system seeds
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Engage the galactic hyperdrive. Called from the hyp routine above if CTRL-H is
\ being pressed.
\
\ This routine also updates the galaxy seeds to point to the next galaxy. Using
\ a galactic hyperdrive rotates each seed byte to the left, rolling each byte
\ left within itself like this:
\
\   01234567 -> 12345670
\
\ to get the seeds for the next galaxy. So after 8 galactic jumps, the seeds
\ roll round to those of the first galaxy again.
\
\ We always arrive in a new galaxy at galactic coordinates (96, 96), and then
\ find the nearest system and set that as our location.
\
\ Other entry points:
\
\   zZ+1                Contains an RTS
\
\ ******************************************************************************

.Ghy

 LDX GHYP               \ Fetch GHYP, which tells us whether we own a galactic
 BEQ zZ+1               \ hyperdrive, and if it is zero, which means we don't,
                        \ return from the subroutine (as zZ+1 contains an RTS)

 INX                    \ We own a galactic hyperdrive, so X is &FF, so this
                        \ instruction sets X = 0

 STX GHYP               \ The galactic hyperdrive is a one-use item, so set GHYP
                        \ to 0 so we no longer have one fitted

 STX FIST               \ Changing galaxy also clears our criminal record, so
                        \ set our legal status in FIST to 0 ("clean")

 LDA #2                 \ Call wW2 with A = 2 to start the hyperspace countdown,
 JSR wW2                \ but starting the countdown from 2

 LDX #5                 \ To move galaxy, we rotate the galaxy's seeds left, so
                        \ set a counter in X for the 6 seed bytes

 INC GCNT               \ Increment the current galaxy number in GCNT

 LDA GCNT               \ Set GCNT = GCNT mod 8, so we jump from galaxy 7 back
 AND #&F7               \ to galaxy 0 (shown in-game as going from galaxy 8 back
 STA GCNT               \ to the starting point in galaxy 1) ???

.G1

 LDA QQ21,X             \ Load the X-th seed byte into A

 ASL A                  \ Set the C flag to bit 7 of the seed

 ROL QQ21,X             \ Rotate the seed in memory, which will add bit 7 back
                        \ in as bit 0, so this rolls the seed around on itself

 DEX                    \ Decrement the counter

 BPL G1                 \ Loop back for the next seed byte, until we have
                        \ rotated them all

\JSR DORND              \ This instruction is commented out in the original
                        \ source, and would set A and X to random numbers, so
                        \ perhaps the original plan was to arrive in each new
                        \ galaxy in a random place?

.zZ

 LDA #&60               \ Set (QQ9, QQ10) to (96, 96), which is where we always
 STA QQ9                \ arrive in a new galaxy (the selected system will be
 STA QQ10               \ set to the nearest actual system later on)

 JSR TT110              \ Call TT110 to show the front space view

 JSR TT111              \ Call TT111 to set the current system to the nearest
                        \ system to (QQ9, QQ10), and put the seeds of the
                        \ nearest system into QQ15 to QQ15+5

 LDX #5                 \ We now want to copy those seeds into safehouse, so we
                        \ so set a counter in Xto copy 6 bytes

.dumdeedum

 LDA QQ15,X             \ Copy the X-th byte of QQ15 into the X-th byte of
 STA safehouse,X        \ safehouse

 DEX                    \ Decrement the loop counter

 BPL dumdeedum          \ Loop back to copy the next byte until we have copied
                        \ all six seed bytes

 LDX #0                 \ Set the distance to the selected system in QQ8(1 0)
 STX QQ8                \ to 0
 STX QQ8+1

 LDA #116               \ Print recursive token 116 (GALACTIC HYPERSPACE ")
 JSR MESS               \ as an in-flight message

                        \ Fall through into jmp to set the system to the
                        \ current system and return from the subroutine there

\ ******************************************************************************
\
\       Name: jmp
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the current system to the selected system
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   (QQ0, QQ1)          The galactic coordinates of the new system
\
\ Other entry points:
\
\   hy5                 Contains an RTS
\
\ ******************************************************************************

.jmp

 LDA QQ9                \ Set the current system's galactic x-coordinate to the
 STA QQ0                \ x-coordinate of the selected system

 LDA QQ10               \ Set the current system's galactic y-coordinate to the
 STA QQ1                \ y-coordinate of the selected system

.hy5

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ee3
\       Type: Subroutine
\   Category: Text
\    Summary: Print the hyperspace countdown in the top-left of the screen
\
\ ------------------------------------------------------------------------------
\
\ 5 digits, left-padding with spaces for numbers with fewer than 3 digits (so
\ numbers < 10000 are right-aligned), with no decimal point.
\
\ Arguments:
\
\   X                   The number to print
\
\ ******************************************************************************

.ee3

 LDA #RED               \ Switch to colour 2, which is red in the space view
 STA COL

 LDA #1                 \ Move the text cursor to column 1
 STA XC

 STA YC                 \ Move the text cursor to row 1

 LDY #0                 \ Set Y = 0 for the high byte in pr6

 CLC                    \ ???
 LDA #&03
 JMP TT11

\ ******************************************************************************
\
\       Name: pr6
\       Type: Subroutine
\   Category: Text
\    Summary: Print 16-bit number, left-padded to 5 digits, no point
\
\ ------------------------------------------------------------------------------
\
\ Print the 16-bit number in (Y X) to 5 digits, left-padding with spaces for
\ numbers with fewer than 3 digits (so numbers < 10000 are right-aligned),
\ with no decimal point.
\
\ Arguments:
\
\   X                   The low byte of the number to print
\
\   Y                   The high byte of the number to print
\
\ ******************************************************************************

.pr6

 CLC                    \ Do not display a decimal point when printing

                        \ Fall through into pr5 to print X to 5 digits

\ ******************************************************************************
\
\       Name: pr5
\       Type: Subroutine
\   Category: Text
\    Summary: Print a 16-bit number, left-padded to 5 digits, and optional point
\
\ ------------------------------------------------------------------------------
\
\ Print the 16-bit number in (Y X) to 5 digits, left-padding with spaces for
\ numbers with fewer than 3 digits (so numbers < 10000 are right-aligned).
\ Optionally include a decimal point.
\
\ Arguments:
\
\   X                   The low byte of the number to print
\
\   Y                   The high byte of the number to print
\
\   C flag              If set, include a decimal point
\
\ ******************************************************************************

.pr5

 LDA #5                 \ Set the number of digits to print to 5

 JMP TT11               \ Call TT11 to print (Y X) to 5 digits and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT147
\       Type: Subroutine
\   Category: Text
\    Summary: Print an error when a system is out of hyperspace range
\
\ ------------------------------------------------------------------------------
\
\ Print "RANGE?" for when the hyperspace distance is too far
\
\ ******************************************************************************

.TT147

 LDA #202               \ Load A with token 42 ("RANGE") and fall through into
                        \ prq to print it, followed by a question mark

\ ******************************************************************************
\
\       Name: prq
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token followed by a question mark
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.prq

 JSR TT27               \ Print the text token in A

 LDA #'?'               \ Print a question mark and return from the
 JMP TT27               \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT151
\       Type: Subroutine
\   Category: Market
\    Summary: Print the name, price and availability of a market item
\  Deep dive: Market item prices and availability
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number of the market item to print, 0-16 (see QQ23
\                       for details of item numbers)
\
\ Returns:
\
\   QQ19+1              Byte #1 from the market prices table for this item
\
\   QQ24                The item's price / 4
\
\   QQ25                The item's availability
\
\ ******************************************************************************

.TT151q

                        \ We jump here from below if we are in witchspace

 PLA                    \ Restore the item number from the stack

 RTS                    \ Return from the subroutine

.TT151

 PHA                    \ Store the item number on the stack and in QQ14+4
 STA QQ19+4

 ASL A                  \ Store the item number * 4 in QQ19, so this will act as
 ASL A                  \ an index into the market prices table at QQ23 for this
 STA QQ19               \ item (as there are four bytes per item in the table)

 LDA MJ                 \ If we are in witchspace, we can't trade items, so jump
 BNE TT151q             \ up to TT151q to return from the subroutine

 LDA #1                 \ Move the text cursor to column 1, for the item's name
 JSR DOXC

 PLA                    \ Restore the item number

 ADC #208               \ Print recursive token 48 + A, which will be in the
 JSR TT27               \ range 48 ("FOOD") to 64 ("ALIEN ITEMS"), so this
                        \ prints the item's name

 LDA #14                \ Move the text cursor to column 14, for the price
 STA XC

 LDX QQ19               \ Fetch byte #1 from the market prices table (units and
 LDA QQ23+1,X           \ economic_factor) for this item and store in QQ19+1
 STA QQ19+1

 LDA QQ26               \ Fetch the random number for this system visit and
 AND QQ23+3,X           \ AND with byte #3 from the market prices table (mask)
                        \ to give:
                        \
                        \   A = random AND mask

 CLC                    \ Add byte #0 from the market prices table (base_price),
 ADC QQ23,X             \ so we now have:
 STA QQ24               \
                        \   A = base_price + (random AND mask)

 JSR TT152              \ Call TT152 to print the item's unit ("t", "kg" or
                        \ "g"), padded to a width of two characters

 JSR var                \ Call var to set QQ19+3 = economy * |economic_factor|
                        \ (and set the availability of Alien Items to 0)

 LDA QQ19+1             \ Fetch the byte #1 that we stored above and jump to
 BMI TT155              \ TT155 if it is negative (i.e. if the economic_factor
                        \ is negative)

 LDA QQ24               \ Set A = QQ24 + QQ19+3
 ADC QQ19+3             \
                        \       = base_price + (random AND mask)
                        \         + (economy * |economic_factor|)
                        \
                        \ which is the result we want, as the economic_factor
                        \ is positive

 JMP TT156              \ Jump to TT156 to multiply the result by 4

.TT155

 LDA QQ24               \ Set A = QQ24 - QQ19+3
 SEC                    \
 SBC QQ19+3             \       = base_price + (random AND mask)
                        \         - (economy * |economic_factor|)
                        \
                        \ which is the result we want, as economic_factor
                        \ is negative

.TT156

 STA QQ24               \ Store the result in QQ24 and P
 STA P

 LDA #0                 \ Set A = 0 and call GC2 to calculate (Y X) = (A P) * 4,
 JSR GC2                \ which is the same as (Y X) = P * 4 because A = 0

 SEC                    \ We now have our final price, * 10, so we can call pr5
 JSR pr5                \ to print (Y X) to 5 digits, including a decimal
                        \ point, as the C flag is set

 LDY QQ19+4             \ We now move on to availability, so fetch the market
                        \ item number that we stored in QQ19+4 at the start

 LDA #5                 \ Set A to 5 so we can print the availability to 5
                        \ digits (right-padded with spaces)

 LDX AVL,Y              \ Set X to the item's availability, which is given in
                        \ the AVL table

 STX QQ25               \ Store the availability in QQ25

 CLC                    \ Clear the C flag

 BEQ TT172              \ If none are available, jump to TT172 to print a tab
                        \ and a "-"

 JSR pr2+2              \ Otherwise print the 8-bit number in X to 5 digits,
                        \ right-aligned with spaces. This works because we set
                        \ A to 5 above, and we jump into the pr2 routine just
                        \ after the first instruction, which would normally
                        \ set the number of digits to 3

 JMP TT152              \ Print the unit ("t", "kg" or "g") for the market item,
                        \ with a following space if required to make it two
                        \ characters long

.TT172

 LDA #25                \ Move the text cursor to column 25
 JSR DOXC

 LDA #'-'               \ Print a "-" character by jumping to TT162+2, which
 BNE TT162+2            \ contains JMP TT27 (this BNE is effectively a JMP as A
                        \ will never be zero), and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: TT152
\       Type: Subroutine
\   Category: Market
\    Summary: Print the unit ("t", "kg" or "g") for a market item
\
\ ------------------------------------------------------------------------------
\
\ Print the unit ("t", "kg" or "g") for the market item whose byte #1 from the
\ market prices table is in QQ19+1, right-padded with spaces to a width of two
\ characters (so that's "t ", "kg" or "g ").
\
\ ******************************************************************************

.TT152

 LDA QQ19+1             \ Fetch the economic_factor from QQ19+1

 AND #96                \ If bits 5 and 6 are both clear, jump to TT160 to
 BEQ TT160              \ print "t" for tonne, followed by a space, and return
                        \ from the subroutine using a tail call

 CMP #32                \ If bit 5 is set, jump to TT161 to print "kg" for
 BEQ TT161              \ kilograms, and return from the subroutine using a tail
                        \ call

 JSR TT16a              \ Otherwise call TT16a to print "g" for grams, and fall
                        \ through into TT162 to print a space and return from
                        \ the subroutine

\ ******************************************************************************
\
\       Name: TT162
\       Type: Subroutine
\   Category: Text
\    Summary: Print a space
\
\ Other entry points:
\
\   TT162+2             Jump to TT27 to print the text token in A
\
\ ******************************************************************************

.TT162

 LDA #' '               \ Load a space character into A

 JMP TT27               \ Print the text token in A and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT160
\       Type: Subroutine
\   Category: Market
\    Summary: Print "t" (for tonne) and a space
\
\ ******************************************************************************

.TT160

 LDA #'t'               \ Load a "t" character into A

 JSR TT26               \ Print the character, using TT216 so that it doesn't
                        \ change the character case

 BCC TT162              \ Jump to TT162 to print a space and return from the
                        \ subroutine using a tail call (this BCC is effectively
                        \ a JMP as the C flag is cleared by TT26)

\ ******************************************************************************
\
\       Name: TT161
\       Type: Subroutine
\   Category: Market
\    Summary: Print "kg" (for kilograms)
\
\ ******************************************************************************

.TT161

 LDA #'k'               \ Load a "k" character into A

 JSR TT26               \ Print the character, using TT216 so that it doesn't
                        \ change the character case, and fall through into
                        \ TT16a to print a "g" character

\ ******************************************************************************
\
\       Name: TT16a
\       Type: Subroutine
\   Category: Market
\    Summary: Print "g" (for grams)
\
\ ******************************************************************************

.TT16a

 LDA #&67               \ Load a "k" character into A

 JMP TT26               \ Print the character, using TT216 so that it doesn't
                        \ change the character case, and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT163
\       Type: Subroutine
\   Category: Market
\    Summary: Print the headers for the table of market prices
\
\ ------------------------------------------------------------------------------
\
\ Print the column headers for the prices table in the Buy Cargo and Market
\ Price screens.
\
\ ******************************************************************************

.TT163

 LDA #17                \ Move the text cursor in XC to column 17
 JSR DOXC

 LDA #255               \ Print recursive token 95 token ("UNIT  QUANTITY
 BNE TT162+2            \ {crlf} PRODUCT   UNIT PRICE FOR SALE{crlf}{lf}") by
                        \ jumping to TT162+2, which contains JMP TT27 (this BNE
                        \ is effectively a JMP as A will never be zero), and
                        \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT167
\       Type: Subroutine
\   Category: Market
\    Summary: Show the Market Price screen (red key f7)
\
\ ******************************************************************************

.TT167

 LDA #16                \ Clear the top part of the screen, draw a white border,
 JSR TRADEMODE          \ and set up a printable trading screen with a view type
                        \ in QQ11 of 32 (Market Price screen)

 LDA #5                 \ Move the text cursor to column 4
 STA XC

 LDA #167               \ Print recursive token 7 ("{current system name} MARKET
 JSR NLIN3              \ PRICES") and draw a horizontal line at pixel row 19
                        \ to box in the title

 LDA #3                 \ Move the text cursor to row 3
 STA YC

 JSR TT163              \ Print the column headers for the prices table

 LDA #6                 \ Move the text cursor to row 6
 STA YC

 LDA #0                 \ We're going to loop through all the available market
 STA QQ29               \ items, so we set up a counter in QQ29 to denote the
                        \ current item and start it at 0

.TT168

 LDX #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case, with the
 STX QQ17               \ next letter in capitals

 JSR TT151              \ Call TT151 to print the item name, market price and
                        \ availability of the current item, and set QQ24 to the
                        \ item's price / 4, QQ25 to the quantity available and
                        \ QQ19+1 to byte #1 from the market prices table for
                        \ this item

 INC YC                 \ Move the text cursor down one row

 INC QQ29               \ Increment QQ29 to point to the next item

 LDA QQ29               \ If QQ29 >= 17 then jump to TT168 as we have done the
 CMP #17                \ last item
 BCC TT168

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: var
\       Type: Subroutine
\   Category: Market
\    Summary: Calculate QQ19+3 = economy * |economic_factor|
\
\ ------------------------------------------------------------------------------
\
\ Set QQ19+3 = economy * |economic_factor|, given byte #1 of the market prices
\ table for an item. Also sets the availability of Alien Items to 0.
\
\ This routine forms part of the calculations for market item prices (TT151)
\ and availability (GVL).
\
\ Arguments:
\
\   QQ19+1              Byte #1 of the market prices table for this market item
\                       (which contains the economic_factor in bits 0-5, and the
\                       sign of the economic_factor in bit 7)
\
\ ******************************************************************************

.var

 LDA QQ19+1             \ Extract bits 0-5 from QQ19+1 into A, to get the
 AND #31                \ economic_factor without its sign, in other words:
                        \
                        \   A = |economic_factor|

 LDY QQ28               \ Set Y to the economy byte of the current system

 STA QQ19+2             \ Store A in QQ19+2

 CLC                    \ Clear the C flag so we can do additions below

 LDA #0                 \ Set AVL+16 (availability of Alien Items) to 0,
 STA AVL+16             \ setting A to 0 in the process

.TT153

                        \ We now do the multiplication by doing a series of
                        \ additions in a loop, building the result in A. Each
                        \ loop adds QQ19+2 (|economic_factor|) to A, and it
                        \ loops the number of times given by the economy byte;
                        \ in other words, because A starts at 0, this sets:
                        \
                        \   A = economy * |economic_factor|

 DEY                    \ Decrement the economy in Y, exiting the loop when it
 BMI TT154              \ becomes negative

 ADC QQ19+2             \ Add QQ19+2 to A

 JMP TT153              \ Loop back to TT153 to do another addition

.TT154

 STA QQ19+3             \ Store the result in QQ19+3

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: hyp1
\       Type: Subroutine
\   Category: Universe
\    Summary: Process a jump to the system closest to (QQ9, QQ10)
\
\ ------------------------------------------------------------------------------
\
\ Do a hyperspace jump to the system closest to galactic coordinates
\ (QQ9, QQ10), and set up the current system's state to those of the new system.
\
\ Returns:
\
\   (QQ0, QQ1)          The galactic coordinates of the new system
\
\   QQ2 to QQ2+6        The seeds of the new system
\
\   EV                  Set to 0
\
\   QQ28                The new system's economy
\
\   tek                 The new system's tech level
\
\   gov                 The new system's government
\
\ Other entry points:
\
\   hyp1+3              Jump straight to the system at (QQ9, QQ10) without
\                       first calculating which system is closest. We do this
\                       if we already know that (QQ9, QQ10) points to a system
\
\ ******************************************************************************

.hyp1

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10)

 JSR jmp                \ Set the current system to the selected system

 LDX #5                 \ We now want to copy the seeds for the selected system
                        \ in QQ15 into QQ2, where we store the seeds for the
                        \ current system, so set up a counter in X for copying
                        \ 6 bytes (for three 16-bit seeds)

.TT112

 LDA safehouse,X        \ Copy the X-th byte in safehouse to the X-th byte in
 STA QQ2,X              \ QQ2

 DEX                    \ Decrement the counter

 BPL TT112              \ Loop back to TT112 if we still have more bytes to
                        \ copy

 INX                    \ Set X = 0 (as we ended the above loop with X = &FF)

 STX EV                 \ Set EV, the extra vessels spawning counter, to 0, as
                        \ we are entering a new system with no extra vessels
                        \ spawned

 LDA QQ3                \ Set the current system's economy in QQ28 to the
 STA QQ28               \ selected system's economy from QQ3

 LDA QQ5                \ Set the current system's tech level in tek to the
 STA tek                \ selected system's economy from QQ5

 LDA QQ4                \ Set the current system's government in gov to the
 STA gov                \ selected system's government from QQ4

                        \ Fall through into GVL to calculate the availability of
                        \ market items in the new system

\ ******************************************************************************
\
\       Name: GVL
\       Type: Subroutine
\   Category: Universe
\    Summary: Calculate the availability of market items
\  Deep dive: Market item prices and availability
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Calculate the availability for each market item and store it in AVL. This is
\ called on arrival in a new system.
\
\ Other entry points:
\
\   hyR                 Contains an RTS
\
\ ******************************************************************************

.GVL

 JSR DORND              \ Set A and X to random numbers

 STA QQ26               \ Set QQ26 to the random byte that's used in the market
                        \ calculations

 LDX #0                 \ We are now going to loop through the market item
 STX XX4                \ availability table in AVL, so set a counter in XX4
                        \ (and X) for the market item number, starting with 0

.hy9

 LDA QQ23+1,X           \ Fetch byte #1 from the market prices table (units and
 STA QQ19+1             \ economic_factor) for item number X and store it in
                        \ QQ19+1

 JSR var                \ Call var to set QQ19+3 = economy * |economic_factor|
                        \ (and set the availability of Alien Items to 0)

 LDA QQ23+3,X           \ Fetch byte #3 from the market prices table (mask) and
 AND QQ26               \ AND with the random number for this system visit
                        \ to give:
                        \
                        \   A = random AND mask

 CLC                    \ Add byte #2 from the market prices table
 ADC QQ23+2,X           \ (base_quantity) so we now have:
                        \
                        \   A = base_quantity + (random AND mask)

 LDY QQ19+1             \ Fetch the byte #1 that we stored above and jump to
 BMI TT157              \ TT157 if it is negative (i.e. if the economic_factor
                        \ is negative)

 SEC                    \ Set A = A - QQ19+3
 SBC QQ19+3             \
                        \       = base_quantity + (random AND mask)
                        \         - (economy * |economic_factor|)
                        \
                        \ which is the result we want, as the economic_factor
                        \ is positive

 JMP TT158              \ Jump to TT158 to skip TT157

.TT157

 CLC                    \ Set A = A + QQ19+3
 ADC QQ19+3             \
                        \       = base_quantity + (random AND mask)
                        \         + (economy * |economic_factor|)
                        \
                        \ which is the result we want, as the economic_factor
                        \ is negative

.TT158

 BPL TT159              \ If A < 0, then set A = 0, so we don't have negative
 LDA #0                 \ availability

.TT159

 LDY XX4                \ Fetch the counter (the market item number) into Y

 AND #%00111111         \ Take bits 0-5 of A, i.e. A mod 64, and store this as
 STA AVL,Y              \ this item's availability in the Y=th byte of AVL, so
                        \ each item has a maximum availability of 63t

 INY                    \ Increment the counter into XX44, Y and A
 TYA
 STA XX4

 ASL A                  \ Set X = counter * 4, so that X points to the next
 ASL A                  \ item's entry in the four-byte market prices table,
 TAX                    \ ready for the next loop

 CMP #63                \ If A < 63, jump back up to hy9 to set the availability
 BCC hy9                \ for the next market item

.hyR

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GTHG
\       Type: Subroutine
\   Category: Universe
\    Summary: Spawn a Thargoid ship and a Thargon companion
\
\ ******************************************************************************

.GTHG

 JSR Ze                 \ Call Ze to initialise INWK

 LDA #%11111111         \ Set the AI flag in byte #32 so that the ship has AI,
 STA INWK+32            \ is extremely and aggressively hostile, and has E.C.M.

 LDA #THG               \ Call NWSHP to add a new Thargoid ship to our local
 JSR NWSHP              \ bubble of universe

 LDA #TGL               \ Call NWSHP to add a new Thargon ship to our local
 JMP NWSHP              \ bubble of universe, and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: MJP
\       Type: Subroutine
\   Category: Flight
\    Summary: Process a mis-jump into witchspace
\
\ ------------------------------------------------------------------------------
\
\ Process a mis-jump into witchspace (which happens very rarely). Witchspace has
\ a strange, almost dust-free aspect to it, and it is populated by hostile
\ Thargoids. Using our escape pod will be fatal, and our position on the
\ galactic chart is in-between systems. It is a scary place...
\
\ There is a 1% chance that this routine is called from TT18 instead of doing
\ a normal hyperspace, or we can manually trigger a mis-jump by holding down
\ CTRL after first enabling the "author display" configuration option ("X") when
\ paused.
\
\ Other entry points:
\
\   ptg                 Called when the user manually forces a mis-jump
\
\   RTS111              Contains an RTS
\
\ ******************************************************************************

.ptg

 LSR COK                \ Set bit 0 of the competition flags in COK, so that the
 SEC                    \ copmpetition code will include the fact that we have
 ROL COK                \ manually forced a mis-jump into witchspace

.MJP

 LDA #3                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 3

 JSR LL164              \ Call LL164 to show the hyperspace tunnel and make the
                        \ hyperspace sound for a second time (as we already
                        \ called LL164 in TT18)

 JSR RES2               \ Reset a number of flight variables and workspaces, as
                        \ well as setting Y to &FF

 STY MJ                 \ Set the mis-jump flag in MJ to &FF, to indicate that
                        \ we are now in witchspace

.MJP1

 JSR GTHG               \ Call GTHG to spawn a Thargoid ship

 LDA #2                 \ Fetch the number of Thargoid ships from MANY+THG, and
 CMP MANY+THG           \ if it is less than 2, loop back to MJP1 to spawn
 BCS MJP1               \ another one, until we have three Thargoids ???

 STA NOSTM              \ Set NOSTM (the maximum number of stardust particles)
                        \ to 3, so there are fewer bits of stardust in
                        \ witchspace (normal space has a maximum of 18)

 LDX #0                 \ Initialise the front space view
 JSR LOOK1

 LDA QQ1                \ Fetch the current system's galactic y-coordinate in
 EOR #%00011111         \ QQ1 and flip bits 0-5, so we end up somewhere in the
 STA QQ1                \ vicinity of our original destination, but above or
                        \ below it in the galactic chart

 RTS                    \ Return from the subroutine

.RTS111

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT18
\       Type: Subroutine
\   Category: Flight
\    Summary: Try to initiate a jump into hyperspace
\
\ ------------------------------------------------------------------------------
\
\ Try to go through hyperspace. Called from TT102 in the main loop when the
\ hyperspace countdown has finished.
\
\ ******************************************************************************

.TT18

 LDA QQ14               \ Subtract the distance to the selected system (in QQ8)
 SEC                    \ from the amount of fuel in our tank (in QQ14) into A
 SBC QQ8

 BCS P%+4               \ If the subtraction didn't overflow, skip the next
                        \ instruction

 LDA #0                 \ The subtraction overflowed, so set A = 0 so we don't
                        \ end up with a negative amount of fuel

 STA QQ14               \ Store the updated fuel amount in QQ14

 LDA QQ11               \ If the current view is not a space view, jump to ee5
 BNE ee5                \ to skip the following

 JSR TT66               \ Clear the top part of the screen, draw a white border,
                        \ and set the current view type in QQ11 to 0 (space
                        \ view)

 JSR LL164              \ Call LL164 to show the hyperspace tunnel and make the
                        \ hyperspace sound

.ee5

 JSR CTRL               \ Scan the keyboard to see if CTRL is currently pressed,
                        \ returning a negative value in A if it is

 AND PATG               \ If the game is configured to show the author's names
                        \ on the start-up screen, then PATG will contain &FF,
                        \ otherwise it will be 0

 BMI ptg                \ By now, A will be negative if we are holding down CTRL
                        \ and author names are configured, which is what we have
                        \ to do in order to trigger a manual mis-jump, so jump
                        \ to ptg to do a mis-jump (ptg not only mis-jumps, but
                        \ updates the competition flags, so Acornsoft could tell
                        \ from the competition code whether this feature had
                        \ been used)

 JSR DORND              \ Set A and X to random numbers

 CMP #253               \ If A >= 253 (1% chance) then jump to MJP to trigger a
 BCS MJP                \ mis-jump into witchspace

\JSR TT111              \ This instruction is commented out in the original
                        \ source. It finds the closest system to coordinates
                        \ (QQ9, QQ10), but we don't need to do this as the
                        \ crosshairs will already be on a system by this point

 JSR hyp1+3             \ Jump straight to the system at (QQ9, QQ10) without
                        \ first calculating which system is closest

 JSR RES2               \ Reset a number of flight variables and workspaces

 JSR L5A24              \ ???

 LDA QQ11               \ If the current view in QQ11 is not a space view (0) or
 AND #%00111111         \ one of the charts (64 or 128), return from the
 BNE RTS111             \ subroutine (as RTS111 contains an RTS)

 JSR TTX66              \ Otherwise clear the screen and draw a white border

 LDA QQ11               \ If the current view is one of the charts, jump to
 BNE TT114              \ TT114 (from which we jump to the correct routine to
                        \ display the chart)

 INC QQ11               \ This is a space view, so increment QQ11 to 1

                        \ Fall through into TT110 to show the front space view

.TT110

 LDX QQ12
 BEQ NLUNCH

 JSR LAUN

 JSR RES2

 JSR TT111

 INC INWK+8
 JSR SOS1

 LDA #&80
 STA INWK+8
 INC INWK+7
 JSR NWSPS

 LDA #&0C
 STA DELTA
 JSR BAD

 ORA FIST
 STA FIST
 LDA #&FF
 STA QQ11
 JSR HFS1

.NLUNCH

 LDX #&00
 STX QQ12
 JMP LOOK1

.TT114

 BMI TT115

 JMP TT22

.TT115

 JMP TT23

.LCASH

 STX T1
 LDA CASH+3
 SEC
 SBC T1
 STA CASH+3
 STY T1
 LDA CASH+2
 SBC T1
 STA CASH+2
 LDA CASH+1
 SBC #&00
 STA CASH+1
 LDA CASH
 SBC #&00
 STA CASH
 BCS TT113

.MCASH

 TXA
 CLC
 ADC CASH+3
 STA CASH+3
 TYA
 ADC CASH+2
 STA CASH+2
 LDA CASH+1
 ADC #&00
 STA CASH+1
 LDA CASH
 ADC #&00
 STA CASH
 CLC

.TT113

 RTS

.GCASH

 JSR MULTU

.GC2

 ASL P
 ROL A
 ASL P
 ROL A
 TAY
 LDX P
 RTS

.bay

 JMP BAY

.EQSHP

 LDA #&20
 JSR TRADEMODE

 LDA #&0C
 STA XC
 LDA #&CF
 JSR spc

 LDA #&B9
 JSR NLIN3

 LDA #&80
 STA QQ17
 INC YC
 LDA tek
 CLC
 ADC #&03
 CMP #&0C
 BCC L5550

 LDA #&0E

.L5550

 STA Q
 STA QQ25
 INC Q
 LDA #&46
 SEC
 SBC QQ14
 ASL A
 STA L5735
 LDX #&01

.EQL1

 STX XX13
 JSR TT67

 LDX XX13
 CLC
 JSR pr2

 JSR TT162

 LDA XX13
 CLC
 ADC #&68
 JSR TT27

 LDA XX13
 JSR L56AA

 SEC
 LDA #&19
 STA XC
 LDA #&06
 JSR TT11

 LDX XX13
 INX
 CPX Q
 BCC EQL1

 JSR CLYNS

 LDA #&7F
 JSR prq

 JSR gnum

 BEQ bay

 BCS bay

 SBC #&00
 PHA
 LDA #&02
 STA XC
 INC YC
 PLA
 PHA
 JSR eq

 PLA
 BNE et0

 LDX #&46
 STX QQ14

.et0

 CMP #&01
 BNE et1

 LDX NOMSL
 INX
 LDY #&7C
 CPX #&05
 BCS pres

 STX NOMSL
 JSR msblob

 LDA #&01

.et1

 LDY #&6B
 CMP #&02
 BNE et2

 LDX #&25
 CPX CRGO
 BEQ pres

 STX CRGO

.et2

 CMP #&03
 BNE et3

 INY
 LDX ECM
 BNE pres

 DEC ECM

.et3

 CMP #&04
 BNE et4

 JSR qv

 LDA #&0F
 JSR refund

 LDA #&04

.et4

 CMP #&05
 BNE et5

 JSR qv

 LDA #&8F
 JSR refund

.et5

 LDY #&6F
 CMP #&06
 BNE et6

 LDX BST
 BEQ ed9

.pres

 STY K
 JSR prx

 JSR MCASH

 LDA K
 JSR spc

 LDA #&1F
 JSR TT27

.err

 JSR dn2

 JMP BAY

.ed9

 DEC BST

.et6

 INY
 CMP #&07
 BNE et7

 LDX ESCP
 BNE pres

 DEC ESCP

.et7

 INY
 CMP #&08
 BNE et8

 LDX BOMB
 BNE pres

 LDX #&7F
 STX BOMB

.et8

 INY
 CMP #&09
 BNE etA

 LDX ENGY
 BNE pres

 INC ENGY

.etA

 INY
 CMP #&0A
 BNE etB

 LDX DKCMP
 BNE pres

 DEC DKCMP

.etB

 INY
 CMP #&0B
 BNE et9

 LDX GHYP
 BNE pres

 DEC GHYP

.et9

 INY
 CMP #&0C
 BNE et10

 JSR qv

 LDA #&97
 JSR refund

.et10

 INY
 CMP #&0D
 BNE et11

 JSR qv

 LDA #&32
 JSR refund

.et11

 JSR dn

 JMP EQSHP

.dn

 JSR TT162

 LDA #&77
 JSR spc

.dn2

 JSR BEEP

 LDY #&19
 JMP DELAY

.eq

 JSR prx

 JSR LCASH

 BCS c

 LDA #&C5
 JSR prq

 JMP err

.L56AA

 SEC
 SBC #&01

.prx

 ASL A
 TAY
 LDX L5735,Y
 LDA L5736,Y
 TAY

.c

 RTS

.qv

 LDA tek
 CMP #&08
 BCC L56C3

 LDA #&20
 JSR TT66

.L56C3

 LDA #&10
 TAY
 STA YC

.qv1

 LDA #&0C
 STA XC
 TYA
 CLC
 ADC #&20
 JSR spc

 LDA YC
 CLC
 ADC #&50
 JSR TT27

 INC YC
 LDY YC
 CPY #&14
 BCC qv1

 JSR CLYNS

.qv2

 LDA #&AF
 JSR prq

 JSR TT217

 SEC
 SBC #&30
 CMP #&04
 BCC qv3

 JSR CLYNS

 JMP qv2

.qv3

 TAX
 RTS

.hm

 JSR TT103

 JSR TT111

 JSR TT103

 JMP CLYNS

.refund

 STA T1
 LDA LASER,X
 BEQ ref3

 LDY #&04
 CMP #&0F
 BEQ ref1

 LDY #&05
 CMP #&8F
 BEQ ref1

 LDY #&0C
 CMP #&97
 BEQ ref1

 LDY #&0D

.ref1

 STX ZZ
 TYA
 JSR prx

 JSR MCASH

 LDX ZZ

.ref3

 LDA T1
 STA LASER,X
 RTS

.L5735

 EQUB &01

.L5736

 EQUB &00,&2C,&01,&A0,&0F,&70,&17,&A0
 EQUB &0F,&10,&27,&82,&14,&10,&27,&28
 EQUB &23,&98,&3A,&10,&27,&50,&C3,&60
 EQUB &EA,&40,&1F

.cpl

 LDX #&05

.TT53

 LDA QQ15,X
 STA QQ19,X
 DEX
 BPL TT53

 LDY #&03
 BIT QQ15
 BVS L5761

 DEY

.L5761

 STY T

.TT55

 LDA QQ15+5
 AND #&1F
 BEQ L576E

 ORA #&80
 JSR TT27

.L576E

 JSR TT54

 DEC T
 BPL TT55

 LDX #&05

.TT56

 LDA QQ19,X
 STA QQ15,X
 DEX
 BPL TT56

 RTS

.cmn

 LDY #&00

.QUL4

 LDA NAME,Y
 CMP #&0D
 BEQ L578E

 JSR DASC

 INY
 BNE QUL4

.L578E

 RTS

.ypl

 BIT MJ
 BMI ypl16

 JSR TT62

 JSR cpl

.TT62

 LDX #&05

.TT78

 LDA QQ15,X
 LDY QQ2,X
 STA QQ2,X
 STY QQ15,X
 DEX
 BPL TT78

.ypl16

 RTS

.tal

 CLC
 LDX GCNT
 INX
 JMP pr2

.fwl

 LDA #&69
 JSR TT68

 LDX QQ14
 SEC
 JSR pr2

 LDA #&C3
 JSR plf

 LDA #&77
 BNE TT27

.csh

 LDX #&03

.pc1

 LDA CASH,X
 STA K,X
 DEX
 BPL pc1

 LDA #&09
 STA U
 SEC
 JSR BPRNT

 LDA #&E2

.plf

 JSR TT27

 JMP TT67

.TT68

 JSR TT27

.TT73

 LDA #&3A

.TT27

 TAX
 BEQ csh

 BMI TT43

 DEX
 BEQ tal

 DEX
 BEQ ypl

 DEX
 BNE L57F7

 JMP cpl

.L57F7

 DEX
 BEQ cmn

 DEX
 BEQ fwl

 DEX
 BNE L5805

 LDA #&80
 STA QQ17
 RTS

.L5805

 DEX
 DEX
 BNE L580C

 STX QQ17
 RTS

.L580C

 DEX
 BEQ crlf

 CMP #&60
 BCS ex

 CMP #&0E
 BCC L581B

 CMP #&20
 BCC qw

.L581B

 LDX QQ17
 BEQ TT74

 BMI TT41

 BIT QQ17
 BVS TT46

.TT42

 CMP #&41
 BCC TT44

 CMP #&5B
 BCS TT44

 ADC #&20

.TT44

 JMP DASC

.TT41

 BIT QQ17
 BVS TT45

 CMP #&41
 BCC TT74

 PHA
 TXA
 ORA #&40
 STA QQ17
 PLA
 BNE TT44

.qw

 ADC #&72
 BNE ex

.crlf

 LDA #&15
 JSR DOXC

 JMP TT73

.TT45

 CPX #&FF
 BEQ TT48

 CMP #&41
 BCS TT42

.TT46

 PHA
 TXA
 AND #&BF
 STA QQ17
 PLA

.TT74

 JMP DASC

.TT43

 CMP #&A0
 BCS TT47

 AND #&7F
 ASL A
 TAY
 LDA QQ16,Y
 JSR TT27

 LDA QQ16+1,Y
 CMP #&3F
 BEQ TT48

 JMP TT27

.TT47

 SBC #&A0

.ex

 TAX
 LDA #&00
 STA V
 LDA #&A0
 STA V+1
 LDY #&00
 TXA
 BEQ TT50

.TT51

 LDA (V),Y
 BEQ TT49

 INY
 BNE TT51

 INC V+1
 BNE TT51

.TT49

 INY
 BNE TT59

 INC V+1

.TT59

 DEX
 BNE TT51

.TT50

 TYA
 PHA
 LDA V+1
 PHA
 LDA (V),Y
 EOR #&23
 JSR TT27

 PLA
 STA V+1
 PLA
 TAY
 INY
 BNE L58B2

 INC V+1

.L58B2

 LDA (V),Y
 BNE TT50

.TT48

 RTS

 LDX #&15

.L58B9

 LDA ZP,X
 LDY ZP,X
 STA ZP,X
 STY ZP,X
 INX
 BNE L58B9

 RTS

.EX2

 LDA INWK+31
 ORA #&A0
 STA INWK+31
 RTS

.DOEXP

 LDA INWK+31
 AND #&40
 BEQ L58D5

 JSR PTCLS

.L58D5

 LDA INWK+6
 STA T
 LDA INWK+7
 CMP #&20
 BCC L58E3

 LDA #&FE
 BNE yy

.L58E3

 ASL T
 ROL A
 ASL T
 ROL A
 SEC
 ROL A

.yy

 STA Q
 LDY #&01
 LDA (XX19),Y
 STA L12A6
 ADC #&04
 BCS EX2

 STA (XX19),Y
 JSR DVID4

 LDA P
 CMP #&1C
 BCC L5907

 LDA #&FE
 BNE LABEL_1

.L5907

 ASL R
 ROL A
 ASL R
 ROL A
 ASL R
 ROL A

.LABEL_1

 DEY
 STA (XX19),Y
 LDA INWK+31
 AND #&BF
 STA INWK+31
 AND #&08
 BEQ TT48

 LDY #&02
 LDA (XX19),Y
 TAY

.EXL1

 LDA XX3-7,Y
 STA (XX19),Y
 DEY
 CPY #&06
 BNE EXL1

 LDA INWK+31
 ORA #&40
 STA INWK+31

.PTCLS

 LDY #&00
 LDA (XX19),Y
 STA Q
 INY
 LDA (XX19),Y
 BPL L593F

 EOR #&FF

.L593F

 LSR A
 LSR A
 LSR A
 LSR A
 ORA #&01
 STA U
 INY
 LDA (XX19),Y
 STA TGT
 LDA RAND+1
 PHA
 LDY #&06

.EXL5

 LDX #&03

.EXL3

 INY
 LDA (XX19),Y
 STA K3,X
 DEX
 BPL EXL3

 STY CNT
 LDY #&02

.EXL2

 INY
 LDA (XX19),Y
 EOR CNT
 STA &FFFF,Y
 CPY #&06
 BNE EXL2

 LDY U
 STY CNT2

.DORND2_UNROLLED

 CLC
 LDA RAND
 ROL A
 TAX
 ADC RAND+2
 STA RAND
 STX RAND+2
 LDA RAND+1
 TAX
 ADC RAND+3
 STA RAND+1
 STX RAND+3
 STA ZZ
 AND #&03
 TAX
 LDA L5A0D,X
 STA COL
 LDA K3+1
 STA R
 LDA K3
 JSR EXS1

 BNE EX11

 CPX #&BF
 BCS EX11

 STX Y1
 LDA K3+3
 STA R
 LDA K3+2
 JSR EXS1

 BNE EX4

 LDA Y1
 JSR PIXEL

.EX4

 DEC CNT2
 BPL DORND2_UNROLLED

 LDY CNT
 CPY TGT
 BCC EXL5

 PLA
 STA RAND+1
 LDA L0406
 STA RAND+3
 RTS

.EX11

 CLC
 LDA RAND
 ROL A
 TAX
 ADC RAND+2
 STA RAND
 STX RAND+2
 LDA RAND+1
 TAX
 ADC RAND+3
 STA RAND+1
 STX RAND+3
 JMP EX4

.EXS1

 STA S
 CLC
 LDA RAND
 ROL A
 TAX
 ADC RAND+2
 STA RAND
 STX RAND+2
 LDA RAND+1
 TAX
 ADC RAND+3
 STA RAND+1
 STX RAND+3
 ROL A
 BCS EX5

 JSR FMLTU

 ADC R
 TAX
 LDA S
 ADC #&00
 RTS

.EX5

 JSR FMLTU

 STA T
 LDA R
 SBC T
 TAX
 LDA S
 SBC #&00
 RTS

 EQUB &00

 EQUB &02

.L5A0D

 EQUB &0F,&F0,&0F,&FF

.SOS1

 JSR msblob

 LDA #&7F
 STA INWK+29
 STA INWK+30
 LDA tek
 AND #&02
 ORA #&80
 JMP NWSHP

.L5A24

 LDA L1264
 BEQ SOLAR

 LDA #&00
 STA QQ20
 STA QQ20+6
 JSR DORND

 AND #&0F
 ADC L1264
 ORA #&04
 ROL A
 STA L1264
 ROL L1265
 BPL SOLAR

 ROR L1265

.SOLAR

 LSR FIST
 JSR ZINF

 LDA QQ15+1
 AND #&03
 ADC #&03
 STA INWK+8
 ROR A
 STA INWK+2
 STA INWK+5
 JSR SOS1

 LDA QQ15+3
 AND #&07
 ORA #&81
 STA INWK+8
 LDA QQ15+5
 AND #&03
 STA INWK+2
 STA INWK+1
 LDA #&00
 STA INWK+29
 STA INWK+30
 LDA #&81
 JSR NWSHP

.NWSTARS

 LDA QQ11
 BNE WPSHPS

.nWq

 LDA #&FA
 STA COL
 LDY NOSTM

.SAL4

 JSR DORND

 ORA #&08
 STA SZ,Y
 STA ZZ
 JSR DORND

 STA SX,Y
 STA XX15
 JSR DORND

 STA SY,Y
 STA Y1
 JSR PIXEL2

 DEY
 BNE SAL4

.WPSHPS

 LDX #&00

.WSL1

 LDA FRIN,X
 BEQ WS2

 BMI WS1

 STA TYPE
 JSR GINF

 LDY #&1F

.WSL2

 LDA (INF),Y
 STA INWK,Y
 DEY
 BPL WSL2

 STX XSAV
 JSR SCAN

 LDX XSAV
 LDY #&1F
 LDA (INF),Y
 AND #&A7
 STA (INF),Y

.WS1

 INX
 BNE WSL1

.WS2

 LDX #&00
 STX LSP
 DEX
 STX LSX2
 STX LSY2

.FLFLLS

 LDY #&C7
 LDA #&00

.SAL6

 STA LSO,Y
 DEY
 BNE SAL6

 DEY
 STY LSX
 RTS

.DET1

 LDA #&06
 SEI
 STA VIA
 STX VIA+&01
 CLI
 RTS

.L5AF0

 DEX
 RTS

.SHD

 INX
 BEQ L5AF0

.DENGY

 DEC ENERGY
 PHP
 BNE L5AFC

 INC ENERGY

.L5AFC

 PLP
 RTS

.COMPAS

 JSR DOT

 LDA SSPR
 BNE SP1

 JSR SPS1

 JMP SP2

.SPS2

 ASL A
 TAX
 LDA #&00
 ROR A
 TAY
 LDA #&14
 STA Q
 TXA
 JSR DVID4

 LDX P
 TYA
 BMI LL163

 LDY #&00
 RTS

.LL163

 LDY #&FF
 TXA
 EOR #&FF
 TAX
 INX
 RTS

.SPS4

 LDX #&08

.SPL1

 LDA L0425,X
 STA K3,X
 DEX
 BPL SPL1

 JMP TAS2

.SP1

 JSR SPS4

.SP2

 LDA XX15
 JSR SPS2

 TXA
 ADC #&C3
 STA COMX
 LDA Y1
 JSR SPS2

 STX T
 LDA #&CC
 SBC T
 STA COMY
 LDA #&0F
 LDX X2
 BPL L5B5B

 LDA #&0C

.L5B5B

 STA COMC
 JMP DOT

.OOPS

 STA T
 LDX #&00
 LDY #&08
 LDA (INF),Y
 BMI OO1

 LDA FSH
 SBC T
 BCC OO2

 STA FSH
 RTS

.OO2

 LDX #&00
 STX FSH
 BCC OO3

.OO1

 LDA ASH
 SBC T
 BCC OO5

 STA ASH
 RTS

.OO5

 LDX #&00
 STX ASH

.OO3

 ADC ENERGY
 STA ENERGY
 BEQ L5B8F

 BCS L5B92

.L5B8F

 JMP DEATH

.L5B92

 JSR EXNO3

 JMP OUCH

.SPS3

 LDA L0401,X
 STA K3,X
 LDA L0402,X
 TAY
 AND #&7F
 STA K3+1,X
 TYA
 AND #&80
 STA K3+2,X
 RTS

.NWSPS

 JSR SPBLB

 LDX #&81
 STX INWK+32
 LDX #&00
 STX INWK+30
 STX NEWB
 STX FRIN+1
 DEX
 STX INWK+29
 LDX #&0A
 JSR NwS1

 JSR NwS1

 JSR NwS1

 LDA spasto
 STA L8002
 LDA L6761
 STA L8003
 LDA tek
 CMP #&0A
 BCC notadodo

 LDA L8040
 STA L8002
 LDA L8041
 STA L8003

.notadodo

 LDA #&7E
 STA XX19
 LDA #&10
 STA INWK+34
 LDA #&02

.NWSHP

 STA T
 LDX #&00

.NWL1

 LDA FRIN,X
 BEQ NW1

 INX
 CPX #&0C
 BCC NWL1

.NW3

 CLC

.L5C01

 RTS

.NW1

 JSR GINF

 LDA T
 BMI NW2

 ASL A
 TAY
 LDA XX21-1,Y
 BEQ NW3

 STA XX0+1
 LDA XX21-2,Y
 STA XX0
 CPY #&04
 BEQ NW6

 LDY #&05
 LDA (XX0),Y
 STA T1
 LDA SLSP
 SEC
 SBC T1
 STA XX19
 LDA SLSP+1
 SBC #&00
 STA INWK+34
 LDA XX19
 SBC INF
 TAY
 LDA INWK+34
 SBC INF+1
 BCC L5C01

 BNE NW4

 CPY #&25
 BCC L5C01

.NW4

 LDA XX19
 STA SLSP
 LDA INWK+34
 STA SLSP+1

.NW6

 LDY #&0E
 LDA (XX0),Y
 STA INWK+35
 LDY #&13
 LDA (XX0),Y
 AND #&07
 STA INWK+31
 LDA T

.NW2

 STA FRIN,X
 TAX
 BMI NW8

 CPX #&0F
 BEQ gangbang

 CPX #&03
 BCC NW7

 CPX #&0B
 BCS NW7

.gangbang

 INC JUNK

.NW7

 INC MANY,X

.NW8

 LDY T
 LDA L8041,Y
 AND #&6F
 ORA NEWB
 STA NEWB
 LDY #&24

.NWL3

 LDA INWK,Y
 STA (INF),Y
 DEY
 BPL NWL3

 SEC
 RTS

.NwS1

 LDA INWK,X
 EOR #&80
 STA INWK,X
 INX
 INX
 RTS

.ABORT

 LDX #&FF

.ABORT2

 STX MSTG
 LDX NOMSL
 JSR MSBAR

 STY MSAR
 RTS

 EQUB &04

 EQUB &00,&00,&00,&00

.PROJ

 LDA INWK
 STA P
 LDA INWK+1
 STA P+1
 LDA INWK+2
 JSR PLS6

 BCS L5CDD

 LDA K
 ADC #&80
 STA K3
 TXA
 ADC #&00
 STA K3+1
 LDA INWK+3
 STA P
 LDA INWK+4
 STA P+1
 LDA INWK+5
 EOR #&80
 JSR PLS6

 BCS L5CDD

 LDA K
 ADC #&60
 STA K4
 TXA
 ADC #&00
 STA K4+1
 CLC

.L5CDD

 RTS

.PL2

 LDA TYPE
 LSR A
 BCS L5CE6

 JMP WPLS2

.L5CE6

 JMP WPLS

.PLANET

 LDA #&AF
 STA COL
 LDA INWK+8
 CMP #&30
 BCS PL2

 ORA INWK+7
 BEQ PL2

 JSR PROJ

 BCS PL2

 LDA #&60
 STA P+1
 LDA #&00
 STA P
 JSR DVID3B2

 LDA K+1
 BEQ PL82

 LDA #&F8
 STA K

.PL82

 LDA TYPE
 LSR A
 BCC PL9

 JMP SUN

.PL9

 JSR WPLS2

 JSR CIRCLE

 BCS PL20

 LDA K+1
 BEQ PL25

.PL20

 RTS

.PL25

 LDA TYPE
 CMP #&80
 BNE PL26

 LDA K
 CMP #&06
 BCC PL20

 LDA INWK+14
 EOR #&80
 STA P
 LDA INWK+20
 JSR PLS4

 LDX #&09
 JSR PLS1

 STA K2
 STY XX16
 JSR PLS1

 STA K2+1
 STY XX16+1
 LDX #&0F
 JSR PLS5

 JSR PLS2

 LDA INWK+14
 EOR #&80
 STA P
 LDA INWK+26
 JSR PLS4

 LDX #&15
 JSR PLS5

 JMP PLS2

.PL26

 LDA INWK+20
 BMI PL20

 LDX #&0F
 JSR PLS3

 CLC
 ADC K3
 STA K3
 TYA
 ADC K3+1
 STA K3+1
 JSR PLS3

 STA P
 LDA K4
 SEC
 SBC P
 STA K4
 STY P
 LDA K4+1
 SBC P
 STA K4+1
 LDX #&09
 JSR PLS1

 LSR A
 STA K2
 STY XX16
 JSR PLS1

 LSR A
 STA K2+1
 STY XX16+1
 LDX #&15
 JSR PLS1

 LSR A
 STA K2+2
 STY XX16+2
 JSR PLS1

 LSR A
 STA K2+3
 STY XX16+3
 LDA #&40
 STA TGT
 LDA #&00
 STA CNT2
 JMP PLS22

.PLS1

 LDA INWK,X
 STA P
 LDA INWK+1,X
 AND #&7F
 STA P+1
 LDA INWK+1,X
 AND #&80
 JSR DVID3B2

 LDA K
 LDY K+1
 BEQ L5DD5

 LDA #&FE

.L5DD5

 LDY K+3
 INX
 INX
 RTS

.PLS2

 LDA #&1F
 STA TGT

.PLS22

 LDX #&00
 STX CNT
 DEX
 STX FLAG

.PLL4

 LDA CNT2
 AND #&1F
 TAX
 LDA SNE,X
 STA Q
 LDA K2+2
 JSR FMLTU

 STA R
 LDA K2+3
 JSR FMLTU

 STA K
 LDX CNT2
 CPX #&21
 LDA #&00
 ROR A
 STA XX16+5
 LDA CNT2
 CLC
 ADC #&10
 AND #&1F
 TAX
 LDA SNE,X
 STA Q
 LDA K2+1
 JSR FMLTU

 STA K+2
 LDA K2
 JSR FMLTU

 STA P
 LDA CNT2
 ADC #&0F
 AND #&3F
 CMP #&21
 LDA #&00
 ROR A
 STA XX16+4
 LDA XX16+5
 EOR XX16+2
 STA S
 LDA XX16+4
 EOR XX16
 JSR ADD

 STA T
 BPL PL42

 TXA
 EOR #&FF
 CLC
 ADC #&01
 TAX
 LDA T
 EOR #&7F
 ADC #&00
 STA T

.PL42

 TXA
 ADC K3
 STA XX18+4
 LDA T
 ADC K3+1
 STA XX18+5
 LDA K
 STA R
 LDA XX16+5
 EOR XX16+3
 STA S
 LDA K+2
 STA P
 LDA XX16+4
 EOR XX16+1
 JSR ADD

 EOR #&80
 STA T
 BPL PL43

 TXA
 EOR #&FF
 CLC
 ADC #&01
 TAX
 LDA T
 EOR #&7F
 ADC #&00
 STA T

.PL43

 JSR BLINE

 CMP TGT
 BEQ L5E8C

 BCS PL40

.L5E8C

 LDA CNT2
 CLC
 ADC STP
 AND #&3F
 STA CNT2
 JMP PLL4

.PL40

 RTS

.L5E99

 JMP WPLS

.PLF3

 TXA
 EOR #&FF
 CLC
 ADC #&01
 TAX

.PLF17

 LDA #&FF
 BNE PLF5

.SUN

 LDA #&F0
 STA COL
 LDA #&01
 STA LSX
 JSR CHKON

 BCS L5E99

 LDA #&00
 LDX K
 CPX #&60
 ROL A
 CPX #&28
 ROL A
 CPX #&10
 ROL A
 STA CNT
 LDA L0099
 LDX P+2
 BNE PLF2

 CMP P+1
 BCC PLF2

 LDA P+1
 BNE PLF2

 LDA #&01

.PLF2

 STA TGT
 LDA L0099
 SEC
 SBC K4
 TAX
 LDA #&00
 SBC K4+1
 BMI PLF3

 BNE PLF4

 INX
 DEX
 BEQ PLF17

 CPX K
 BCC PLF5

.PLF4

 LDX K
 LDA #&00

.PLF5

 STX V
 STA V+1
 LDA K
 JSR SQUA2

 STA K2+1
 LDA P
 STA K2
 LDY L0099
 LDA SUNX
 STA YY
 LDA SUNX+1
 STA YY+1

.PLFL2

 CPY TGT
 BEQ PLFL

 LDA LSO,Y
 BEQ PLFL13

 JSR HLOIN2

.PLFL13

 DEY
 BNE PLFL2

.PLFL

 LDA V
 JSR SQUA2

 STA T
 LDA K2
 SEC
 SBC P
 STA Q
 LDA K2+1
 SBC T
 STA R
 STY Y1
 JSR LL5

 LDY Y1
 JSR DORND

 AND CNT
 CLC
 ADC Q
 BCC PLF44

 LDA #&FF

.PLF44

 LDX LSO,Y
 STA LSO,Y
 BEQ PLF11

 LDA SUNX
 STA YY
 LDA SUNX+1
 STA YY+1
 TXA
 JSR EDGES

 LDA XX15
 STA XX
 LDA X2
 STA XX+1
 LDA K3
 STA YY
 LDA K3+1
 STA YY+1
 LDA LSO,Y
 JSR EDGES

 BCS PLF23

 LDA X2
 LDX XX
 STX X2
 STA XX
 JSR HLOIN

.PLF23

 LDA XX
 STA XX15
 LDA XX+1
 STA X2

.PLF16

 JSR HLOIN

.PLF6

 DEY
 BEQ PLF8

 LDA V+1
 BNE PLF10

 DEC V
 BNE PLFL

 DEC V+1

.PLFLS

 JMP PLFL

.PLF11

 LDX K3
 STX YY
 LDX K3+1
 STX YY+1
 JSR EDGES

 BCC PLF16

 LDA #&00
 STA LSO,Y
 BEQ PLF6

.PLF10

 LDX V
 INX
 STX V
 CPX K
 BCC PLFLS

 BEQ PLFLS

 LDA SUNX
 STA YY
 LDA SUNX+1
 STA YY+1

.PLFL3

 LDA LSO,Y
 BEQ PLF9

 JSR HLOIN2

.PLF9

 DEY
 BNE PLFL3

.PLF8

 CLC
 LDA K3
 STA SUNX
 LDA K3+1
 STA SUNX+1

.RTS2

 RTS

.CIRCLE

 JSR CHKON

 BCS RTS2

 LDA #&00
 STA LSX2
 LDX K
 LDA #&08
 CPX #&08
 BCC PL89

 LSR A
 CPX #&3C
 BCC PL89

 LSR A

.PL89

 STA STP

.CIRCLE2

 LDX #&FF
 STX FLAG
 INX
 STX CNT

.PLL3

 LDA CNT
 JSR FMLTU2

 LDX #&00
 STX T
 LDX CNT
 CPX #&21
 BCC PL37

 EOR #&FF
 ADC #&00
 TAX
 LDA #&FF
 ADC #&00
 STA T
 TXA
 CLC

.PL37

 ADC K3
 STA XX18+4
 LDA K3+1
 ADC T
 STA XX18+5
 LDA CNT
 CLC
 ADC #&10
 JSR FMLTU2

 TAX
 LDA #&00
 STA T
 LDA CNT
 ADC #&0F
 AND #&3F
 CMP #&21
 BCC PL38

 TXA
 EOR #&FF
 ADC #&00
 TAX
 LDA #&FF
 ADC #&00
 STA T
 CLC

.PL38

 JSR BLINE

 CMP #&41
 BCS L6041

 JMP PLL3

.L6041

 CLC
 RTS

.WPLS2

 LDY LSX2
 BNE WP1

.WPL1

 CPY LSP
 BCS WP1

 LDA LSY2,Y
 CMP #&FF
 BEQ WP2

 STA Y2
 LDA LSX2,Y
 STA X2
 JSR LL30

 INY
 LDA SWAP
 BNE WPL1

 LDA X2
 STA XX15
 LDA Y2
 STA Y1
 JMP WPL1

.WP2

 INY
 LDA LSX2,Y
 STA XX15
 LDA LSY2,Y
 STA Y1
 INY
 JMP WPL1

.WP1

 LDA #&01
 STA LSP
 LDA #&FF
 STA LSX2

.L6086

 RTS

.WPLS

 LDA LSX
 BMI L6086

 LDA SUNX
 STA YY
 LDA SUNX+1
 STA YY+1
 LDY #&BF

.WPL2

 LDA LSO,Y
 BEQ L609D

 JSR HLOIN2

.L609D

 DEY
 BNE WPL2

 DEY
 STY LSX
 RTS

.EDGES

 STA T
 CLC
 ADC YY
 STA X2
 LDA YY+1
 ADC #&00
 BMI ED1

 BEQ L60B7

 LDA #&FF
 STA X2

.L60B7

 LDA YY
 SEC
 SBC T
 STA XX15
 LDA YY+1
 SBC #&00
 BNE ED3

 CLC
 RTS

.ED3

 BPL ED1

 LDA #&00
 STA XX15
 CLC
 RTS

.ED1

 LDA #&00
 STA LSO,Y
 SEC
 RTS

.CHKON

 LDA K3
 CLC
 ADC K
 LDA K3+1
 ADC #&00
 BMI PL21

 LDA K3
 SEC
 SBC K
 LDA K3+1
 SBC #&00
 BMI PL31

 BNE PL21

.PL31

 LDA K4
 CLC
 ADC K
 STA P+1
 LDA K4+1
 ADC #&00
 BMI PL21

 STA P+2
 LDA K4
 SEC
 SBC K
 TAX
 LDA K4+1
 SBC #&00
 BMI PL44

 BNE PL21

 CPX L0099
 RTS

.PL21

 SEC
 RTS

.PLS3

 JSR PLS1

 STA P
 LDA #&DE
 STA Q
 STX U
 JSR MULTU

 LDX U
 LDY K+3
 BPL PL12

 EOR #&FF
 CLC
 ADC #&01
 BEQ PL12

 LDY #&FF
 RTS

.PL12

 LDY #&00
 RTS

.PLS4

 STA Q
 JSR ARCTAN

 LDX INWK+14
 BMI L613B

 EOR #&80

.L613B

 LSR A
 LSR A
 STA CNT2
 RTS

.PLS5

 JSR PLS1

 STA K2+2
 STY XX16+2
 JSR PLS1

 STA K2+3
 STY XX16+3
 RTS

.PLS6

 JSR DVID3B2

 LDA K+3
 AND #&7F
 ORA K+2
 BNE PL21

 LDX K+1
 CPX #&04
 BCS PL6

 LDA K+3
 BPL PL6

 LDA K
 EOR #&FF
 ADC #&01
 STA K
 TXA
 EOR #&FF
 ADC #&00
 TAX

.PL44

 CLC

.PL6

 RTS

.L6174

 JSR t

 CMP #&59
 BEQ PL6

 CMP #&4E
 BNE L6174

 CLC
 RTS

.TT17

 LDA QQ11
 BNE L618A

 JSR DOKEY

 TXA
 RTS

.L618A

 JSR DOKEY

 LDA JSTK
 BEQ L61A3

 LDA JSTY
 JSR L61D4

 TAY
 LDA JSTX
 EOR #&FF
 JSR L61D4

 TAX
 LDA KL
 RTS

.L61A3

 LDA KL
 LDX #&00
 LDY #&00
 CMP #&8C
 BNE L61AE

 DEX

.L61AE

 CMP #&8D
 BNE L61B3

 INX

.L61B3

 CMP #&8E
 BNE L61B8

 DEY

.L61B8

 CMP #&8F
 BNE L61BD

 INY

.L61BD

 PHX
 LDA #&00
 JSR DKS4

 BMI L61C9

 PLX
 LDA KL
 RTS

.L61C9

 PLA
 ASL A
 ASL A
 TAX
 TYA
 ASL A
 ASL A
 TAY
 LDA KL
 RTS

.L61D4

 LSR A
 LSR A
 LSR A
 LSR A
 LSR A
 ADC #&00
 SBC #&03
 RTS

.KS3

 LDA P
 STA SLSP
 LDA P+1
 STA SLSP+1
 RTS

.KS1

 LDX XSAV
 JSR KILLSHP

 LDX XSAV
 JMP MAL1

.KS4

 JSR ZINF

 JSR FLFLLS

 STA FRIN+1
 STA SSPR
 JSR SPBLB

 LDA #&06
 STA INWK+5
 LDA #&81
 JMP NWSHP

.KS2

 LDX #&FF

.KSL4

 INX
 LDA FRIN,X
 BEQ KS3

 CMP #&01
 BNE KSL4

 TXA
 ASL A
 TAY
 LDA UNIV,Y
 STA SC
 LDA UNIV+1,Y
 STA SC+1
 LDY #&20
 LDA (SC),Y
 BPL KSL4

 AND #&7F
 LSR A
 CMP XX4
 BCC KSL4

 BEQ KS6

 SBC #&01
 ASL A
 ORA #&80
 STA (SC),Y
 BNE KSL4

.KS6

 LDA #&00
 STA (SC),Y
 BEQ KSL4

.KILLSHP

 STX XX4
 LDA MSTG
 CMP XX4
 BNE KS5

 LDY #&0C
 JSR ABORT

 LDA #&C8
 JSR MESS

.KS5

 LDY XX4
 LDX FRIN,Y
 CPX #&02
 BEQ KS4

 CPX #&1F
 BNE lll

 LDA TP
 ORA #&02
 STA TP
 INC TALLY+1

.lll

 CPX #&0F
 BEQ blacksuspenders

 CPX #&03
 BCC KS7

 CPX #&0B
 BCS KS7

.blacksuspenders

 DEC JUNK

.KS7

 DEC MANY,X
 LDX XX4
 LDY #&05
 LDA (XX0),Y
 LDY #&21
 CLC
 ADC (INF),Y
 STA P
 INY
 LDA (INF),Y
 ADC #&00
 STA P+1

.KSL1

 INX
 LDA FRIN,X
 STA FRIN-1,X
 BNE L629E

 JMP KS2

.L629E

 ASL A
 TAY
 LDA XX21-2,Y
 STA SC
 LDA XX21-1,Y
 STA SC+1
 LDY #&05
 LDA (SC),Y
 STA T
 LDA P
 SEC
 SBC T
 STA P
 LDA P+1
 SBC #&00
 STA P+1
 TXA
 ASL A
 TAY
 LDA UNIV,Y
 STA SC
 LDA UNIV+1,Y
 STA SC+1
 LDY #&24
 LDA (SC),Y
 STA (INF),Y
 DEY
 LDA (SC),Y
 STA (INF),Y
 DEY
 LDA (SC),Y
 STA K+1
 LDA P+1
 STA (INF),Y
 DEY
 LDA (SC),Y
 STA K
 LDA P
 STA (INF),Y
 DEY

.KSL2

 LDA (SC),Y
 STA (INF),Y
 DEY
 BPL KSL2

 LDA SC
 STA INF
 LDA SC+1
 STA INF+1
 LDY T

.KSL3

 DEY
 LDA (K),Y
 STA (P),Y
 TYA
 BNE KSL3

 BEQ KSL1

.THERE

 LDX GCNT
 DEX
 BNE THEX

 LDA QQ0
 CMP #&90
 BNE THEX

 LDA QQ1
 CMP #&21
 BEQ L6318

.THEX

 CLC

.L6318

 RTS

 PHA
 LSR A
 LSR A
 LSR A
 LSR A
 JSR L6324

 PLA
 AND #&0F

.L6324

 CMP #&0A
 BCS L632D

 ADC #&30
 JMP CHPR

.L632D

 ADC #&36
 JMP CHPR

.RESET

 JSR ZERO

 LDX #&06

.SAL3

 STA BETA,X
 DEX
 BPL SAL3

 STX L2C5A
 TXA
 STA QQ12
 LDX #&02

.REL5

 STA FSH,X
 DEX
 BPL REL5

.RES2

 LDA #&14
 STA NOSTM
 LDX #&FF
 STX LSX2
 STX LSY2
 STX MSTG
 LDA #&80
 STA JSTY
 STA ALP2
 STA BET2
 ASL A
 STA BETA
 STA BET1
 STA ALP2+1
 STA BET2+1
 STA MCNT
 LDA #&03
 STA DELTA
 STA ALPHA
 STA ALP1
 LDA #&00
 STA L0098
 LDA #&BF
 STA L0099
 LDA SSPR
 BEQ L6382

 JSR SPBLB

.L6382

 LDA ECMA
 BEQ yu

 JSR ECMOF

.yu

 JSR WPSHPS

 JSR ZERO

 LDA #&00
 STA SLSP
 LDA #&08
 STA SLSP+1

.ZINF

 LDY #&24
 LDA #&00

.ZI1

 STA INWK,Y
 DEY
 BPL ZI1

 LDA #&60
 STA INWK+18
 STA INWK+22
 ORA #&80
 STA INWK+14
 RTS

.msblob

 LDX #&04

.ss

 CPX NOMSL
 BEQ SAL8

 LDY #&00
 JSR MSBAR

 DEX
 BNE ss

 RTS

.SAL8

 LDY #&0C
 JSR MSBAR

 DEX
 BNE SAL8

 RTS

.me2

 LDA QQ11
 BNE L63D9

 LDA MCH
 JSR MESS

 LDA #&00
 STA DLY
 JMP me3

.L63D9

 JSR CLYNS

 JMP me3

.Ze

 JSR ZINF

 JSR DORND

 STA T1
 AND #&80
 STA INWK+2
 TXA
 AND #&80
 STA INWK+5
 LDA #&19
 STA INWK+1
 STA INWK+4
 STA INWK+7
 TXA
 CMP #&F5
 ROL A
 ORA #&C0
 STA INWK+32
 CLC

.DORND

 LDA RAND
 ROL A
 TAX
 ADC RAND+2
 STA RAND
 STX RAND+2
 LDA RAND+1
 TAX
 ADC RAND+3
 STA RAND+1
 STX RAND+3
 RTS

.MTT4

 JSR DORND

 LSR A
 STA INWK+32
 STA INWK+29
 ROL INWK+31
 AND #&1F
 ORA #&10
 STA INWK+27
 JSR DORND

 BMI nodo

 LDA INWK+32
 ORA #&C0
 STA INWK+32
 LDX #&10
 STX NEWB

.nodo

 AND #&02
 ADC #&0B
 CMP #&0F
 BEQ TT100

 JSR NWSHP

.TT100

 JSR M%

 DEC DLY
 BEQ me2

 BPL me3

 INC DLY

.me3

 DEC MCNT
 BEQ L6453

.ytq

 JMP MLOOP

.L6453

 LDA MJ
 BNE ytq

 JSR DORND

 CMP #&23
 BCS MTT1

 LDA JUNK
 CMP #&03
 BCS MTT1

 JSR ZINF

 LDA #&26
 STA INWK+7
 JSR DORND

 STA INWK
 STX INWK+3
 AND #&80
 STA INWK+2
 TXA
 AND #&80
 STA INWK+5
 ROL INWK+1
 ROL INWK+1
 JSR DORND

 BVS MTT4

 ORA #&6F
 STA INWK+29
 LDA SSPR
 BNE MTT1

 TXA
 BCS MTT2

 AND #&1F
 ORA #&10
 STA INWK+27
 BCC MTT3

.MTT2

 ORA #&7F
 STA INWK+30

.MTT3

 JSR DORND

 CMP #&FC
 BCC thongs

 LDA #&0F
 STA INWK+32
 BNE whips

.thongs

 CMP #&0A
 AND #&01
 ADC #&05

.whips

 JSR NWSHP

.MTT1

 LDA SSPR
 BEQ L64BC

.MLOOPS

 JMP MLOOP

.L64BC

 JSR BAD

 ASL A
 LDX L0E5E
 BEQ L64C8

 ORA FIST

.L64C8

 STA T
 JSR Ze

 CMP #&88
 BEQ fothg

 CMP T
 BCS L64DA

 LDA #&10
 JSR NWSHP

.L64DA

 LDA L0E5E
 BNE MLOOPS

 DEC EV
 BPL MLOOPS

 INC EV
 LDA TP
 AND #&0C
 CMP #&08
 BNE nopl

 JSR DORND

 CMP #&DC
 BCC nopl

.fothg2

 JSR GTHG

.nopl

 JSR DORND

 LDY gov
 BEQ LABEL_2

 CMP #&5A
 BCS MLOOPS

 AND #&07
 CMP gov
 BCC MLOOPS

.LABEL_2

 JSR Ze

 CMP #&64
 BCS mt1

 INC EV
 AND #&03
 ADC #&18
 TAY
 JSR THERE

 BCC NOCON

 LDA #&F9
 STA INWK+32
 LDA TP
 AND #&03
 LSR A
 BCC NOCON

 ORA L0E6D
 BEQ YESCON

.NOCON

 LDA #&04
 STA NEWB
 JSR DORND

 CMP #&C8
 ROL A
 ORA #&C0
 STA INWK+32
 TYA
 EQUB &2C

.YESCON

 LDA #&1F

.focoug

 JSR NWSHP

 JMP MLOOP

.fothg

 LDA L0406
 AND #&3E
 BNE fothg2

 LDA #&12
 STA INWK+27
 LDA #&79
 STA INWK+32
 LDA #&20
 BNE focoug

.mt1

 AND #&03
 STA EV
 STA XX13

.mt3

 JSR DORND

 STA T
 JSR DORND

 AND T
 AND #&07
 ADC #&11
 JSR NWSHP

 DEC XX13
 BPL mt3

.MLOOP

 LDX #&FF
 TXS
 LDX GNTMP
 BEQ EE20

 DEC GNTMP

.EE20

 LDX LASCT
 BEQ NOLASCT

 DEX
 BEQ L658D

 DEX

.L658D

 STX LASCT

.NOLASCT

 JSR DIALS

 LDA QQ11
 BEQ L65A2

 AND PATG
 LSR A
 BCS L65A2

 LDY #&02
 JSR DELAY

.L65A2

 JSR TT17

.FRCE

 JSR TT102

 LDA QQ12
 BEQ L65AF

 JMP MLOOP

.L65AF

 JMP TT100

.TT102

 CMP #&88
 BNE L65B9

 JMP STATUS

.L65B9

 CMP #&84
 BNE L65C0

 JMP TT22

.L65C0

 CMP #&85
 BNE L65C7

 JMP TT23

.L65C7

 CMP #&86
 BNE TT92

 JSR TT111

 JMP TT25

.TT92

 CMP #&89
 BNE L65D8

 JMP TT213

.L65D8

 CMP #&87
 BNE L65DF

 JMP TT167

.L65DF

 CMP #&80
 BNE fvw

 JMP TT110

.fvw

 BIT QQ12
 BPL INSP

 CMP #&83
 BNE L65F1

 JMP EQSHP

.L65F1

 CMP #&81
 BNE L65F8

 JMP TT219

.L65F8

 CMP #&40
 BNE nosave

 JSR SVE

 BCC L6604

 JMP QU5

.L6604

 JMP BAY

.nosave

 CMP #&82
 BNE LABEL_3

 JMP TT208

.INSP

 CMP #&81
 BEQ L6620

 CMP #&82
 BEQ L661D

 CMP #&83
 BNE LABEL_3

 LDX #&03
 EQUB &2C

.L661D

 LDX #&02
 EQUB &2C

.L6620

 LDX #&01
 JMP LOOK1

.LABEL_3

 LDA KL
 CMP #&48
 BNE NWDAV5

 JMP hyp

.NWDAV5

 CMP #&44
 BEQ T95

 CMP #&46
 BNE HME1

 LDA QQ12
 BEQ t95

 LDA QQ11
 AND #&C0
 BEQ t95

 JMP HME2

.HME1

 STA T1
 LDA QQ11
 AND #&C0
 BEQ TT107

 LDA QQ22+1
 BNE TT107

 LDA T1
 CMP #&4F
 BNE ee2

 JSR TT103

 JSR ping

 JMP TT103

.ee2

 JSR TT16

.TT107

 LDA QQ22+1
 BEQ t95

 DEC QQ22
 BNE t95

 LDX QQ22+1
 DEX
 JSR ee3

 LDA #&05
 STA QQ22
 LDX QQ22+1
 JSR ee3

 DEC QQ22+1
 BNE t95

 JMP TT18

.t95

 RTS

.T95

 LDA QQ11
 AND #&C0
 BEQ t95

 JSR hm

 JSR cpl

 LDA #&80
 STA QQ17
 LDA #&0C
 JSR DASC

 JMP TT146

.BAD

 LDA QQ20+3
 CLC
 ADC QQ20+6
 ASL A
 ADC QQ20+10
 RTS

.FAROF

 LDA #&E0

.FAROF2

 CMP INWK+1
 BCC FA1

 CMP INWK+4
 BCC FA1

 CMP INWK+7

.FA1

 RTS

.MAS4

 ORA INWK+1
 ORA INWK+4
 ORA INWK+7
 RTS

.L66B8

 EQUB &FF

.BRBR

 LDX L66B8
 TXS
 JSR MASTER_SWAP_ZP_3000

 STZ CATF
 LDY #&00
 LDA #&07

.BRBRLOOP

 JSR CHPR

 INY
 LDA (&FD),Y
 BNE BRBRLOOP

 JSR t

 JMP SVE

.DEATH

 LDY #&04
 JSR NOISE

 JSR RES2

 ASL DELTA
 ASL DELTA
 LDX #&18
 JSR DET1

 LDA #&0D
 JSR TT66

 STZ QQ11
 JSR BOX

 JSR nWq

 LDA #&FF
 STA COL
 LDA #&0C
 STA XC
 STA YC
 LDA #&92
 JSR ex

.D1

 JSR Ze

 LSR A
 LSR A
 STA INWK
 LDY #&00
 STY INWK+1
 STY INWK+4
 STY INWK+7
 STY INWK+32
 DEY
 STY MCNT
 EOR #&2A
 STA INWK+3
 ORA #&50
 STA INWK+6
 TXA
 AND #&8F
 STA INWK+29
 LDY #&40
 STY LASCT
 SEC
 ROR A
 AND #&87
 STA INWK+30
 LDX #&05
 LDA L8007
 BEQ D3

 BCC D3

 DEX

.D3

 JSR fq1

 JSR DORND

 AND #&80
 LDY #&1F
 STA (INF),Y
 LDA FRIN+4
 BEQ D1

 LDA #&00
 STA DELTA
 JSR M%

.D2

 JSR M%

 DEC LASCT
 BNE D2

 LDX #&1F
 JSR DET1

 JMP DEATH2

.spasto

 DEY

.L6761

 DEY

.BEGIN

 LDX #&1E
 LDA #&00

.BEL1

 STA COMC,X
 DEX
 BPL BEL1

 LDA L8002
 STA spasto
 LDA L8003
 STA L6761
 JSR L68BB

 LDX #&FF
 TXS
 JSR RESET

.DEATH2

 LDX #&FF
 TXS
 JSR RES2

 JSR U%

 LDA #&03
 STA XC
 LDX #&0B
 LDA #&06
 LDY #&C8
 JSR TITLE

 CPX #&59
 BNE QU5

 JSR DFAULT

 JSR SVE

.QU5

 JSR DFAULT

 JSR msblob

 LDA #&07
 LDX #&20
 LDY #&64
 JSR TITLE

 JSR ping

 JSR TT111

 JSR jmp

 LDX #&05

.likeTT112

 LDA QQ15,X
 STA QQ2,X
 DEX
 BPL likeTT112

 INX
 STX EV
 LDA QQ3
 STA QQ28
 LDA QQ5
 STA tek
 LDA QQ4
 STA gov

.BAY

 LDA #&FF
 STA QQ12
 LDA #&88
 JMP FRCE

.DFAULT

 LDX #&54

.QUL1

 LDA NA%-1,X
 STA NAME-1,X
 DEX
 BNE QUL1

 STX QQ11

.L67EC

 JSR CHECK

 CMP CHK
 BNE L67EC

 EOR #&A9
 TAX
 LDA COK
 CPX CHK2
 BEQ tZ

 ORA #&80

.tZ

 ORA #&08
 STA COK
 RTS

.TITLE

 STY L1229
 PHA
 STX TYPE
 JSR RESET

 JSR U%

 JSR ZINF

 LDA #&20
 JSR SETVDU19

 LDA #&0D
 JSR TT66

 LDA #&F0
 STA COL
 LDA #&00
 STA QQ11
 LDA #&60
 STA INWK+14
 LDA #&60
 STA INWK+7
 LDX #&7F
 STX INWK+29
 STX INWK+30
 INX
 STX QQ17
 LDA TYPE
 JSR NWSHP

 LDA #&06
 STA XC
 LDA #&1E
 JSR plf

 LDA #&0A
 JSR DASC

 LDA #&06
 STA XC
 LDA PATG
 BEQ awe

 LDA #&0D
 JSR DETOK

.awe

 LDY #&00
 STY DELTA
 STY JSTK
 LDA #&14
 STA YC
 LDA #&01
 STA XC
 PLA
 JSR DETOK

 LDA #&07
 STA XC
 LDA #&0C
 JSR DETOK

 LDA #&0C
 STA CNT2
 LDA #&05
 STA MCNT
 STZ JSTK

.TLL2

 LDA INWK+7
 CMP #&01
 BEQ TL1

 DEC INWK+7

.TL1

 JSR MVEIT

 LDX L1229
 STX INWK+6
 LDA #&00
 STA INWK
 STA INWK+3
 JSR LL9

 DEC MCNT
 LDA VIA+&40
 AND #&10
 BEQ TL2

 JSR RDKEY

 BEQ TLL2

 RTS

.TL2

 DEC JSTK
 RTS

.CHECK

 LDX #&49
 CLC
 TXA

.QUL2

 ADC NA%+7,X            \ Add the X-1-th byte of the data block to A, plus the
                        \ C flag

 EOR NA%+8,X            \ EOR A with the X-th byte of the data block
 DEX
 BNE QUL2

 RTS

.L68BB

 LDY #&60

.L68BD

 LDA DEFAULT%,Y
 STA NA%,Y
 DEY
 BPL L68BD

 LDY #&07
 STY L6A8B
 RTS

.TRNME

 LDX #&07
 LDA L6A8A
 STA L6A8B

.GTL1

 LDA INWK+5,X
 STA NA%,X
 DEX
 BPL GTL1

.TR1

 LDX #&07

.GTL2

 LDA NA%,X
 STA INWK+5,X
 DEX
 BPL GTL2

 RTS

.GTNMEW

 LDX #&04

.GTL3

 LDA S1%,X
 STA INWK,X
 DEX
 BPL GTL3

 LDA #&07
 STA L695D
 LDA #&08
 JSR DETOK

 JSR MT26

 LDA #&09
 STA L695D
 TYA
 BEQ TR1

 STY L6A8A
 RTS

.MT26

 LDA COL
 PHA
 LDA #&F0
 STA COL
 LDY #&08
 JSR DELAY

 JSR FLKB

 LDY #&00

.L691B

 JSR TT217

 CMP #&0D
 BEQ L6945

 CMP #&1B
 BEQ L694E

 CMP #&7F
 BEQ L6953

 CPY L695D
 BCS L693E

 CMP L695E
 BCC L693E

 CMP L695F
 BCS L693E

 STA INWK+5,Y
 INY
 EQUB &2C

.L693E

 LDA #&07

.L6940

 JSR CHPR

 BCC L691B

.L6945

 STA INWK+5,Y
 LDA #&0C
 JSR CHPR

 EQUB &24

.L694E

 SEC
 PLA
 STA COL
 RTS

.L6953

 TYA
 BEQ L693E

 DEY
 LDA #&7F
 BNE L6940

.L695B

 EQUB &A1

 EQUB &00

.L695D

 EQUB &09

.L695E

 EQUB &21

.L695F

 EQUB &7B

.L6960                    \ See JMTB

 LDA #&03
 CLC
 ADC L2C5E
 JMP DETOK

.L6969                    \ See JMTB
 LDA #&02
 SEC
 SBC L2C5E
 JMP DETOK

.ZERO

 LDX #&3C
 LDA #&00

.ZEL2

 STA FRIN,X
 DEX
 BPL ZEL2

 RTS

.CATS

 JSR GTDRV

 BCS L69A5

 STA L6ACB
 STA DTW7
 LDA #&03
 JSR DETOK

 LDA #&01
 STA CATF
 STA XC
 JSR MASTER_SWAP_ZP_3000

 LDX #&C7
 LDY #&6A
 JSR OSCLI

 JSR MASTER_SWAP_ZP_3000

 STZ CATF
 CLC

.L69A5

 RTS

.DELT

 JSR CATS

 BCS SVE

 LDA L6ACB
 STA L6AD5
 LDA #&08
 JSR DETOK

 JSR MT26

 TYA
 BEQ SVE

 LDX #&09

.DELL1

 LDA INWK+4,X
 STA L6AD6,X
 DEX
 BNE DELL1

 JSR MASTER_SWAP_ZP_3000

 LDX #&CD
 LDY #&6A
 JSR OSCLI

 JSR MASTER_SWAP_ZP_3000

 JMP SVE

.SVE

 TSX
 STX L66B8
 JSR TRADE

 LDA #&01
 JSR DETOK

 JSR t

 CMP #&31
 BEQ MASTER_LOAD

 CMP #&32
 BEQ SV1

 CMP #&33
 BEQ CAT

 CMP #&34
 BNE L69FB

 JSR DELT

 JMP SVE

.L69FB

 CMP #&35
 BNE L6A0F

 LDA #&E0
 JSR DETOK

 JSR L6174

 BCC L6A0F

 JSR L68BB

 JMP DFAULT

.L6A0F

 CLC
 RTS

.CAT

 JSR CATS

 JSR t

 JMP SVE

.MASTER_LOAD

 JSR GTNMEW

 JSR GTDRV

 BCS L6A2C

 STA L6B05
 JSR LOD

 JSR TRNME

 SEC

.L6A2C

 RTS

.SV1

 JSR GTNMEW

 JSR TRNME

 LSR SVC
 LDA #&04
 JSR DETOK

 LDX #&4C

.SVL1

 LDA TP,X
 STA NA%+8,X
 DEX
 BPL SVL1

 JSR CHECK

 STA CHK
 PHA
 ORA #&80
 STA K
 EOR COK
 STA K+2
 EOR CASH+2
 STA K+1
 EOR #&5A
 EOR TALLY+1
 STA K+3
 CLC
 JSR TT67

 JSR TT67

 PLA
 EOR #&A9
 STA CHK2
 LDY #&4C

.L6A71

 LDA NA%+8,Y
 STA L0791,Y
 DEY
 BPL L6A71

 JSR GTDRV

 BCS L6A85

 STA L6AE5
 JSR L6B16

.L6A85

 EQUB &20

 EQUB &DF,&67,&18,&60

.L6A8A

 EQUB &07

.L6A8B

 EQUB &07

.GTDRV

 LDA #&02
 JSR DETOK

 JSR t

 ORA #&10
 JSR CHPR

 PHA
 JSR FEED

 PLA
 CMP #&30
 BCC LOR

 CMP #&34
 RTS

.LOD

 JSR ZEBC

 LDA L0791
 BMI L6ABA

 LDY #&4C

.LOL1

 LDA L0791,Y
 STA NA%+8,Y
 DEY
 BPL LOL1

.LOR

 SEC
 RTS

.L6ABA

 LDA #&09
 JSR DETOK

 JSR t

 JMP SVE

 RTS

 RTS

 EQUS "CAT"

 EQUS " "

.L6ACB

 EQUS "1"

 EQUB &0D

 EQUS "DELE"

 EQUS "TE :"

.L6AD5

 EQUS "1"

.L6AD6

 EQUS ".1234567"

 EQUB &0D

 EQUS "SAVE :"

.L6AE5

 EQUS "1.E."

.L6AE9

 EQUS "JAMESON  E7E +100 0 0"

 EQUB &0D

 EQUS "LOAD :"

.L6B05

 EQUS "1.E."

.L6B09

 EQUS "JAMESON  E7E"

 EQUB &0D

.L6B16

 LDY #&4C

.L6B18

 LDA NA%+8,Y
 STA LSX2,Y
 DEY
 BPL L6B18

 LDA #&00
 LDY #&4C

.L6B25

 STA LSX2,Y
 INY
 BNE L6B25

 LDY #&00

.L6B2D

 LDA NA%,Y
 CMP #&0D
 BEQ L6B3C

 STA L6AE9,Y
 INY
 CPY #&07
 BCC L6B2D

.L6B3C

 LDA #&20
 STA L6AE9,Y
 INY
 CPY #&07
 BCC L6B3C

 JSR MASTER_SWAP_ZP_3000

 LDX #&DF
 LDY #&6A
 JSR OSCLI

 JMP MASTER_SWAP_ZP_3000

.ZEBC

 LDY #&00

.L6B55

 LDA INWK+5,Y
 CMP #&0D
 BEQ L6B64

 STA L6B09,Y
 INY
 CPY #&07
 BCC L6B55

.L6B64

 LDA #&20
 STA L6B09,Y
 INY
 CPY #&07
 BCC L6B64

 JSR MASTER_SWAP_ZP_3000

 LDX #&FF
 LDY #&6A
 JSR OSCLI

 JSR MASTER_SWAP_ZP_3000

 LDY #&4C

.L6B7D

 LDA LSX2,Y
 STA L0791,Y
 DEY
 BPL L6B7D

 RTS

 RTS

.SPS1

 LDX #&00
 JSR SPS3

 LDX #&03
 JSR SPS3

 LDX #&06
 JSR SPS3

.TAS2

 LDA K3
 ORA K3+3
 ORA K3+6
 ORA #&01
 STA K3+9
 LDA K3+1
 ORA K3+4
 ORA K3+7

.TAL2

 ASL K3+9
 ROL A
 BCS TA2

 ASL K3
 ROL K3+1
 ASL K3+3
 ROL K3+4
 ASL K3+6
 ROL K3+7
 BCC TAL2

.TA2

 LDA K3+1
 LSR A
 ORA K3+2
 STA XX15
 LDA K3+4
 LSR A
 ORA K3+5
 STA Y1
 LDA K3+7
 LSR A
 ORA K3+8
 STA X2

.NORM

 LDA XX15
 JSR SQUA

 STA R
 LDA P
 STA Q
 LDA Y1
 JSR SQUA

 STA T
 LDA P
 ADC Q
 STA Q
 LDA T
 ADC R
 STA R
 LDA X2
 JSR SQUA

 STA T
 LDA P
 ADC Q
 STA Q
 LDA T
 ADC R
 STA R
 JSR LL5

 LDA XX15
 JSR TIS2

 STA XX15
 LDA Y1
 JSR TIS2

 STA Y1
 LDA X2
 JSR TIS2

 STA X2
 RTS

.WARP

 LDX JUNK
 LDA FRIN+2,X
 ORA SSPR
 ORA MJ
 BNE WA1

 LDY L0408
 BMI WA3

 TAY
 JSR MAS2

 CMP #&02
 BCC WA1

.WA3

 LDY L042D
 BMI WA2

 LDY #&25
 JSR m

 CMP #&02
 BCC WA1

.WA2

 LDA #&81
 STA S
 STA R
 STA P
 LDA L0408
 JSR ADD

 STA L0408
 LDA L042D
 JSR ADD

 STA L042D
 LDA #&01
 STA QQ11
 STA MCNT
 LSR A
 STA EV
 LDX VIEW
 JMP LOOK1

.WA1

 JMP BEEP_LONG_LOW

 RTS

.DKS3

 TXA
 CMP L2C62,Y
 BNE Dk3

 LDA DAMP,Y
 EOR #&FF
 STA DAMP,Y
 BPL L6C83

 JSR BELL

.L6C83

 JSR BELL

 TYA
 PHA
 LDY #&14
 JSR DELAY

 PLA
 TAY

.Dk3

 RTS

.DOKEY

 JSR L7ED7

 LDA auto
 BEQ L6CF2

 JSR ZINF

 LDA #&60
 STA INWK+14
 ORA #&80
 STA INWK+22
 STA TYPE
 LDA DELTA
 STA INWK+27
 JSR DOCKIT

 LDA INWK+27
 CMP #&16
 BCC L6CB4

 LDA #&16

.L6CB4

 STA DELTA
 LDA #&FF
 LDX #&0F
 LDY INWK+28
 BEQ DK11

 BMI L6CC2

 LDX #&0B

.L6CC2

 STA KL,X

.DK11

 LDA #&80
 LDX #&0D
 ASL INWK+29
 BEQ DK12

 BCC L6CD0

 LDX #&0E

.L6CD0

 BIT INWK+29
 BPL DK14

 LDA #&40
 STA JSTX
 LDA #&00

.DK14

 STA KL,X
 LDA JSTX

.DK12

 STA JSTX
 LDA #&80
 LDX #&06
 ASL INWK+30
 BEQ DK13

 BCS L6CEC

 LDX #&08

.L6CEC

 STA KL,X
 LDA JSTY

.DK13

 STA JSTY

.L6CF2

 LDA JSTK
 BEQ DK15

 LDA L12A7
 EOR L2C5B
 ORA #&01
 STA JSTX
 LDA L12A8
 EOR #&FF
 EOR L2C5B
 EOR L2C5A
 STA JSTY
 LDA VIA+&40
 AND #&10
 BNE DK4

 LDA #&FF
 STA KY7
 BNE DK4

.DK15

 LDX JSTX
 LDA #&07
 LDY L00D0
 BEQ L6D26

 JSR BUMP2

.L6D26

 LDY L00D1
 BEQ L6D2D

 JSR REDU2

.L6D2D

 STX JSTX
 ASL A
 LDX JSTY
 LDY L00C9
 BEQ L6D39

 JSR REDU2

.L6D39

 LDY L00CB
 BEQ L6D40

 JSR BUMP2

.L6D40

 STX JSTY

.DK4

 LDX KL
 CPX #&8B
 BNE DK2

.FREEZE

 JSR WSCAN

 JSR RDKEY

 CPX #&51
 BNE DK6

 LDX #&FF
 STX L2C55
 LDX #&51

.DK6

 LDY #&00

.DKL4

 JSR DKS3

 INY
 CPY #&09
 BNE DKL4

 LDA L2C61
 CPX #&2E
 BEQ L6D70

 CPX #&2C
 BNE L6D83

 DEC A
 EQUB &24

.L6D70

 INC A
 TAY
 AND #&F8
 BNE L6D79

 STY L2C61

.L6D79

 PHX
 JSR BEEP

 LDY #&0A
 JSR DELAY

 PLX

.L6D83

 CPX #&42
 BNE nobit

 LDA BSTK
 EOR #&FF
 STA BSTK
 STA JSTK
 STA L2C5B
 BPL L6D9A

 JSR BELL

.L6D9A

 JSR BELL

.nobit

 CPX #&53
 BNE DK7

 LDA #&00
 STA L2C55

.DK7

 CPX #&1B
 BNE L6DAD

 JMP DEATH2

.L6DAD

 CPX #&7F
 BNE FREEZE

.DK2

 RTS

.TT217

 STY YSAV

.t

 LDY #&02
 JSR DELAY

 JSR RDKEY

 BNE t

.t2

 JSR RDKEY

 BEQ t2

 LDY YSAV
 TAX

.out

 RTS

.me1

 STX DLY
 PHA
 LDA #&0F
 STA COL
 LDA MCH
 JSR mes9

 PLA

.MESS

 PHA
 LDX QQ11
 BEQ L6DDE

 JSR CLYNS

.L6DDE

 LDA #&15
 STA YC
 LDA #&0F
 STA COL
 LDX #&00
 STX QQ17
 LDA messXC
 STA XC
 PLA
 LDY #&14
 CPX DLY
 BNE me1

 STY DLY
 STA MCH
 LDA #&C0
 STA DTW4
 LDA de
 LSR A
 LDA #&00
 BCC L6E0B

 LDA #&0A

.L6E0B

 STA DTW5
 LDA MCH
 JSR TT27

 LDA #&20
 SEC
 SBC DTW5
 LSR A
 STA messXC
 STA XC
 JSR MT15

 LDA MCH

.mes9

 JSR TT27

 LSR de
 BCC out

 LDA #&FD
 JMP TT27

.OUCH

 JSR DORND

 BMI out

 CPX #&16
 BCS out

 LDA QQ20,X
 BEQ out

 LDA DLY
 BNE out

 LDY #&03
 STY de
 STA QQ20,X
 CPX #&11
 BCS ou1

 TXA
 ADC #&D0
 JMP MESS

.ou1

 BEQ ou2

 CPX #&12
 BEQ ou3

 TXA
 ADC #&5D
 JMP MESS

.ou2

 LDA #&6C
 JMP MESS

.ou3

 LDA #&6F
 JMP MESS

.QQ23

 EQUB &13

.L6E6E

 EQUB &82

.L6E6F

 EQUB &06

.L6E70

 EQUB &01,&14,&81,&0A,&03,&41,&83,&02
 EQUB &07,&28,&85,&E2,&1F,&53,&85,&FB
 EQUB &0F,&C4,&08,&36,&03,&EB,&1D,&08
 EQUB &78,&9A,&0E,&38,&03,&75,&06,&28
 EQUB &07,&4E,&01,&11,&1F,&7C,&0D,&1D
 EQUB &07,&B0,&89,&DC,&3F,&20,&81,&35
 EQUB &03,&61,&A1,&42,&07,&AB,&A2,&37
 EQUB &1F,&2D,&C1,&FA,&0F,&35,&0F,&C0
 EQUB &07

.TI2

 TYA
 LDY #&02
 JSR TIS3

 STA INWK+20
 JMP TI3

.TI1

 TAX
 LDA Y1
 AND #&60
 BEQ TI2

 LDA #&02
 JSR TIS3

 STA INWK+18
 JMP TI3

.TIDY

 LDA INWK+10
 STA XX15
 LDA INWK+12
 STA Y1
 LDA INWK+14
 STA X2
 JSR NORM

 LDA XX15
 STA INWK+10
 LDA Y1
 STA INWK+12
 LDA X2
 STA INWK+14
 LDY #&04
 LDA XX15
 AND #&60
 BEQ TI1

 LDX #&02
 LDA #&00
 JSR TIS3

 STA INWK+16

.TI3

 LDA INWK+16
 STA XX15
 LDA INWK+18
 STA Y1
 LDA INWK+20
 STA X2
 JSR NORM

 LDA XX15
 STA INWK+16
 LDA Y1
 STA INWK+18
 LDA X2
 STA INWK+20
 LDA INWK+12
 STA Q
 LDA INWK+20
 JSR MULT12

 LDX INWK+14
 LDA INWK+18
 JSR TIS1

 EOR #&80
 STA INWK+22
 LDA INWK+16
 JSR MULT12

 LDX INWK+10
 LDA INWK+20
 JSR TIS1

 EOR #&80
 STA INWK+24
 LDA INWK+18
 JSR MULT12

 LDX INWK+12
 LDA INWK+16
 JSR TIS1

 EOR #&80
 STA INWK+26
 LDA #&00
 LDX #&0E

.TIL1

 STA INWK+9,X
 DEX
 DEX
 BPL TIL1

 RTS

.TIS2

 TAY
 AND #&7F
 CMP Q
 BCS TI4

 LDX #&FE
 STX T

.TIL2

 ASL A
 CMP Q
 BCC L6F65

 SBC Q

.L6F65

 ROL T
 BCS TIL2

 LDA T
 LSR A
 LSR A
 STA T
 LSR A
 ADC T
 STA T
 TYA
 AND #&80
 ORA T
 RTS

.TI4

 TYA
 AND #&80
 ORA #&60
 RTS

.TIS3

 STA P+2
 LDA INWK+10,X
 STA Q
 LDA INWK+16,X
 JSR MULT12

 LDX INWK+10,Y
 STX Q
 LDA INWK+16,Y
 JSR MAD

 STX P
 LDY P+2
 LDX INWK+10,Y
 STX Q
 EOR #&80
 STA P+1
 EOR Q
 AND #&80
 STA T
 LDA #&00
 LDX #&10
 ASL P
 ROL P+1
 ASL Q
 LSR Q

.DVL2

 ROL A
 CMP Q
 BCC L6FBA

 SBC Q

.L6FBA

 ROL P
 ROL P+1
 DEX
 BNE DVL2

 LDA P
 ORA T
 RTS

 EQUB &02

 EQUB &0F,&31,&32,&33,&34,&35,&36,&37
 EQUB &38,&39,&30,&31,&32,&33,&34,&35
 EQUB &36,&37

.SHPPT

 JSR PROJ

 ORA K3+1
 BNE nono

 LDA K4
 CMP #&BE
 BCS nono

 JSR Shpt

 LDA K4
 CLC
 ADC #&01
 JSR Shpt

 LDA #&08
 ORA INWK+31
 STA INWK+31
 JMP LL155

.nono

 LDA #&F7
 AND INWK+31
 STA INWK+31
 JMP LL155

.Shpt

 STA Y1
 STA Y2
 LDA K3
 STA XX15
 CLC
 ADC #&03
 BCC L7012

 LDA #&FF

.L7012

 STA X2
 JMP L78F8

.LL5

 LDY R
 LDA Q
 STA S
 LDX #&00
 STX Q
 LDA #&08
 STA T

.LL6

 CPX Q
 BCC LL7

 BNE LL8

 CPY #&40
 BCC LL7

.LL8

 TYA
 SBC #&40
 TAY
 TXA
 SBC Q
 TAX

.LL7

 ROL Q
 ASL S
 TYA
 ROL A
 TAY
 TXA
 ROL A
 TAX
 ASL S
 TYA
 ROL A
 TAY
 TXA
 ROL A
 TAX
 DEC T
 BNE LL6

 RTS

.LL28

 CMP Q
 BCS LL2

 STA widget
 TAX
 BEQ LLfix

 LDA logL,X
 LDX Q
 SEC
 SBC logL,X
 LDX widget
 LDA log,X
 LDX Q
 SBC log,X
 BCS LL2

 TAX
 LDA antilog,X

.LLfix

 STA R
 RTS

 BCS LL2

 LDX #&FE
 STX R

.LL31

 ASL A
 BCS LL29

 CMP Q
 BCC L7082

 SBC Q

.L7082

 ROL R
 BCS LL31

 RTS

.LL29

 SBC Q
 SEC
 ROL R
 BCS LL31

 LDA R
 RTS

.LL2

 LDA #&FF
 STA R
 RTS

.LL38

 EOR S
 BMI LL39

 LDA Q
 CLC
 ADC R
 RTS

.LL39

 LDA R
 SEC
 SBC Q
 BCC L70A9

 CLC
 RTS

.L70A9

 PHA
 LDA S
 EOR #&80
 STA S
 PLA
 EOR #&FF
 ADC #&01
 RTS

.LL51

 LDX #&00
 LDY #&00

.ll51

 LDA XX15
 STA Q
 LDA XX16,X
 JSR FMLTU

 STA T
 LDA Y1
 EOR XX16+1,X
 STA S
 LDA X2
 STA Q
 LDA XX16+2,X
 JSR FMLTU

 STA Q
 LDA T
 STA R
 LDA Y2
 EOR XX16+3,X
 JSR LL38

 STA T
 LDA XX15+4
 STA Q
 LDA XX16+4,X
 JSR FMLTU

 STA Q
 LDA T
 STA R
 LDA XX15+5
 EOR XX16+5,X
 JSR LL38

 STA XX12,Y
 LDA S
 STA XX12+1,Y
 INY
 INY
 TXA
 CLC
 ADC #&06
 TAX
 CMP #&11
 BCC ll51

 RTS

.LL25

 JMP PLANET

.LL9

 LDX TYPE
 BMI LL25

 LDA shpcol,X
 STA COL
 LDA #&1F
 STA XX4
 LDY #&01
 STY XX14
 DEY
 LDA #&08
 BIT INWK+31
 BNE L712B

 LDA #&00
 EQUB &2C

.L712B

 LDA (XX19),Y
 STA XX14+1
 LDA NEWB
 BMI EE51

 LDA #&20
 BIT INWK+31
 BNE EE28

 BPL EE28

 ORA INWK+31
 AND #&3F
 STA INWK+31
 LDA #&00
 LDY #&1C
 STA (INF),Y
 LDY #&1E
 STA (INF),Y
 JSR EE51

 LDY #&01
 LDA #&12
 STA (XX19),Y
 LDY #&07
 LDA (XX0),Y
 LDY #&02
 STA (XX19),Y

.EE55

 INY
 JSR DORND

 STA (XX19),Y
 CPY #&06
 BNE EE55

.EE28

 LDA INWK+8
 BPL LL10

.LL14

 LDA INWK+31
 AND #&20
 BEQ EE51

 LDA INWK+31
 AND #&F7
 STA INWK+31
 JMP DOEXP

.EE51

 LDA #&08
 BIT INWK+31
 BEQ L7186

 EOR INWK+31
 STA INWK+31
 JMP LL155

.L7186

 RTS

.LL10

 LDA INWK+7
 CMP #&C0
 BCS LL14

 LDA INWK
 CMP INWK+6
 LDA INWK+1
 SBC INWK+7
 BCS LL14

 LDA INWK+3
 CMP INWK+6
 LDA INWK+4
 SBC INWK+7
 BCS LL14

 LDY #&06
 LDA (XX0),Y
 TAX
 LDA #&FF
 STA XX3,X
 STA XX3+1,X
 LDA INWK+6
 STA T
 LDA INWK+7
 LSR A
 ROR T
 LSR A
 ROR T
 LSR A
 ROR T
 LSR A
 BNE LL13

 LDA T
 ROR A
 LSR A
 LSR A
 LSR A
 STA XX4
 BPL LL17

.LL13

 LDY #&0D
 LDA (XX0),Y
 CMP INWK+7
 BCS LL17

 LDA #&20
 AND INWK+31
 BNE LL17

 JMP SHPPT

.LL17

 LDX #&05

.LL15

 LDA INWK+21,X
 STA XX16,X
 LDA INWK+15,X
 STA XX16+6,X
 LDA INWK+9,X
 STA XX16+12,X
 DEX
 BPL LL15

 LDA #&C5
 STA Q
 LDY #&10

.LL21

 LDA XX16,Y
 ASL A
 LDA XX16+1,Y
 ROL A
 JSR LL28

 LDX R
 STX XX16,Y
 DEY
 DEY
 BPL LL21

 LDX #&08

.ll91

 LDA INWK,X
 STA XX18,X
 DEX
 BPL ll91

 LDA #&FF
 STA K4+1
 LDY #&0C
 LDA INWK+31
 AND #&20
 BEQ EE29

 LDA (XX0),Y
 LSR A
 LSR A
 TAX
 LDA #&FF

.EE30

 STA K3,X
 DEX
 BPL EE30

 INX
 STX XX4

.LL41

 JMP LL42

.EE29

 LDA (XX0),Y
 BEQ LL41

 STA XX20
 LDY #&12
 LDA (XX0),Y
 TAX
 LDA XX18+7
 TAY
 BEQ LL91

.L723C

 INX
 LSR XX18+4
 ROR XX18+3
 LSR XX18+1
 ROR XX18
 LSR A
 ROR XX18+6
 TAY
 BNE L723C

.LL91

 STX XX17
 LDA XX18+8
 STA XX15+5
 LDA XX18
 STA XX15
 LDA XX18+2
 STA Y1
 LDA XX18+3
 STA X2
 LDA XX18+5
 STA Y2
 LDA XX18+6
 STA XX15+4
 JSR LL51

 LDA XX12
 STA XX18
 LDA XX12+1
 STA XX18+2
 LDA XX12+2
 STA XX18+3
 LDA XX12+3
 STA XX18+5
 LDA XX12+4
 STA XX18+6
 LDA XX12+5
 STA XX18+8
 LDY #&04
 LDA (XX0),Y
 CLC
 ADC XX0
 STA V
 LDY #&11
 LDA (XX0),Y
 ADC XX0+1
 STA V+1
 LDY #&00

.LL86

 LDA (V),Y
 STA XX12+1
 AND #&1F
 CMP XX4
 BCS LL87

 TYA
 LSR A
 LSR A
 TAX
 LDA #&FF
 STA K3,X
 TYA
 ADC #&04
 TAY
 JMP LL88

.LL87

 LDA XX12+1
 ASL A
 STA XX12+3
 ASL A
 STA XX12+5
 INY
 LDA (V),Y
 STA XX12
 INY
 LDA (V),Y
 STA XX12+2
 INY
 LDA (V),Y
 STA XX12+4
 LDX XX17
 CPX #&04
 BCC LL92

 LDA XX18
 STA XX15
 LDA XX18+2
 STA Y1
 LDA XX18+3
 STA X2
 LDA XX18+5
 STA Y2
 LDA XX18+6
 STA XX15+4
 LDA XX18+8
 STA XX15+5
 JMP LL89

.ovflw

 LSR XX18
 LSR XX18+6
 LSR XX18+3
 LDX #&01

.LL92

 LDA XX12
 STA XX15
 LDA XX12+2
 STA X2
 LDA XX12+4
 DEX
 BMI LL94

.L72F9

 LSR XX15
 LSR X2
 LSR A
 DEX
 BPL L72F9

.LL94

 STA R
 LDA XX12+5
 STA S
 LDA XX18+6
 STA Q
 LDA XX18+8
 JSR LL38

 BCS ovflw

 STA XX15+4
 LDA S
 STA XX15+5
 LDA XX15
 STA R
 LDA XX12+1
 STA S
 LDA XX18
 STA Q
 LDA XX18+2
 JSR LL38

 BCS ovflw

 STA XX15
 LDA S
 STA Y1
 LDA X2
 STA R
 LDA XX12+3
 STA S
 LDA XX18+3
 STA Q
 LDA XX18+5
 JSR LL38

 BCS ovflw

 STA X2
 LDA S
 STA Y2

.LL89

 LDA XX12
 STA Q
 LDA XX15
 JSR FMLTU

 STA T
 LDA XX12+1
 EOR Y1
 STA S
 LDA XX12+2
 STA Q
 LDA X2
 JSR FMLTU

 STA Q
 LDA T
 STA R
 LDA XX12+3
 EOR Y2
 JSR LL38

 STA T
 LDA XX12+4
 STA Q
 LDA XX15+4
 JSR FMLTU

 STA Q
 LDA T
 STA R
 LDA XX15+5
 EOR XX12+5
 JSR LL38

 PHA
 TYA
 LSR A
 LSR A
 TAX
 PLA
 BIT S
 BMI L7395

 LDA #&00

.L7395

 STA K3,X
 INY

.LL88

 CPY XX20
 BCS LL42

 JMP LL86

.LL42

 LDY XX16+2
 LDX XX16+3
 LDA XX16+6
 STA XX16+2
 LDA XX16+7
 STA XX16+3
 STY XX16+6
 STX XX16+7
 LDY XX16+4
 LDX XX16+5
 LDA XX16+12
 STA XX16+4
 LDA XX16+13
 STA XX16+5
 STY XX16+12
 STX XX16+13
 LDY XX16+10
 LDX XX16+11
 LDA XX16+14
 STA XX16+10
 LDA XX16+15
 STA XX16+11
 STY XX16+14
 STX XX16+15
 LDY #&08
 LDA (XX0),Y
 STA XX20
 LDA XX0
 CLC
 ADC #&14
 STA V
 LDA XX0+1
 ADC #&00
 STA V+1
 LDY #&00
 STY CNT

.LL48

 STY XX17
 LDA (V),Y
 STA XX15
 INY
 LDA (V),Y
 STA X2
 INY
 LDA (V),Y
 STA XX15+4
 INY
 LDA (V),Y
 STA T
 AND #&1F
 CMP XX4
 BCC L742F

 INY
 LDA (V),Y
 STA P
 AND #&0F
 TAX
 LDA K3,X
 BNE LL49

 LDA P
 LSR A
 LSR A
 LSR A
 LSR A
 TAX
 LDA K3,X
 BNE LL49

 INY
 LDA (V),Y
 STA P
 AND #&0F
 TAX
 LDA K3,X
 BNE LL49

 LDA P
 LSR A
 LSR A
 LSR A
 LSR A
 TAX
 LDA K3,X
 BNE LL49

.L742F

 JMP LL50

.LL49

 LDA T
 STA Y1
 ASL A
 STA Y2
 ASL A
 STA XX15+5
 JSR LL51

 LDA INWK+2
 STA X2
 EOR XX12+1
 BMI LL52

 CLC
 LDA XX12
 ADC INWK
 STA XX15
 LDA INWK+1
 ADC #&00
 STA Y1
 JMP LL53

.LL52

 LDA INWK
 SEC
 SBC XX12
 STA XX15
 LDA INWK+1
 SBC #&00
 STA Y1
 BCS LL53

 EOR #&FF
 STA Y1
 LDA #&01
 SBC XX15
 STA XX15
 BCC L7474

 INC Y1

.L7474

 LDA X2
 EOR #&80
 STA X2

.LL53

 LDA INWK+5
 STA XX15+5
 EOR XX12+3
 BMI LL54

 CLC
 LDA XX12+2
 ADC INWK+3
 STA Y2
 LDA INWK+4
 ADC #&00
 STA XX15+4
 JMP LL55

.LL54

 LDA INWK+3
 SEC
 SBC XX12+2
 STA Y2
 LDA INWK+4
 SBC #&00
 STA XX15+4
 BCS LL55

 EOR #&FF
 STA XX15+4
 LDA Y2
 EOR #&FF
 ADC #&01
 STA Y2
 LDA XX15+5
 EOR #&80
 STA XX15+5
 BCC LL55

 INC XX15+4

.LL55

 LDA XX12+5
 BMI LL56

 LDA XX12+4
 CLC
 ADC INWK+6
 STA T
 LDA INWK+7
 ADC #&00
 STA U
 JMP LL57

.LL61

 LDX Q
 BEQ LL84

 LDX #&00

.LL63

 LSR A
 INX
 CMP Q
 BCS LL63

 STX S
 JSR LL28

 LDX S
 LDA R

.LL64

 ASL A
 ROL U
 BMI LL84

 DEX
 BNE LL64

 STA R
 RTS

.LL84

 LDA #&32
 STA R
 STA U
 RTS

.LL62

 LDA #&80
 SEC
 SBC R
 STA XX3,X
 INX
 LDA #&00
 SBC U
 STA XX3,X
 JMP LL66

.LL56

 LDA INWK+6
 SEC
 SBC XX12+4
 STA T
 LDA INWK+7
 SBC #&00
 STA U
 BCC LL140

 BNE LL57

 LDA T
 CMP #&04
 BCS LL57

.LL140

 LDA #&00
 STA U
 LDA #&04
 STA T

.LL57

 LDA U
 ORA Y1
 ORA XX15+4
 BEQ LL60

 LSR Y1
 ROR XX15
 LSR XX15+4
 ROR Y2
 LSR U
 ROR T
 JMP LL57

.LL60

 LDA T
 STA Q
 LDA XX15
 CMP Q
 BCC LL69

 JSR LL61

 JMP LL65

.LL69

 JSR LL28

.LL65

 LDX CNT
 LDA X2
 BMI LL62

 LDA R
 CLC
 ADC #&80
 STA XX3,X
 INX
 LDA U
 ADC #&00
 STA XX3,X

.LL66

 TXA
 PHA
 LDA #&00
 STA U
 LDA T
 STA Q
 LDA Y2
 CMP Q
 BCC LL67

 JSR LL61

 JMP LL68

.LL70

 LDA #&60
 CLC
 ADC R
 STA XX3,X
 INX
 LDA #&00
 ADC U
 STA XX3,X
 JMP LL50

.LL67

 JSR LL28

.LL68

 PLA
 TAX
 INX
 LDA XX15+5
 BMI LL70

 LDA #&60
 SEC
 SBC R
 STA XX3,X
 INX
 LDA #&00
 SBC U
 STA XX3,X

.LL50

 CLC
 LDA CNT
 ADC #&04
 STA CNT
 LDA XX17
 ADC #&06
 TAY
 BCS LL72

 CMP XX20
 BCS LL72

 JMP LL48

.LL72

 LDA INWK+31
 AND #&20
 BEQ EE31

 LDA INWK+31
 ORA #&08
 STA INWK+31
 JMP DOEXP

.EE31

 LDY #&09
 LDA (XX0),Y
 STA XX20
 LDA #&08
 ORA INWK+31
 STA INWK+31
 LDY #&00
 STY XX17
 BIT INWK+31
 BVC LL170

 LDA INWK+31
 AND #&BF
 STA INWK+31
 LDY #&06
 LDA (XX0),Y
 TAY
 LDX XX3,Y
 STX XX15
 INX
 BEQ LL170

 LDX XX3+1,Y
 STX Y1
 INX
 BEQ LL170

 LDX XX3+2,Y
 STX X2
 LDX XX3+3,Y
 STX Y2
 LDA #&00
 STA XX15+4
 STA XX15+5
 STA XX12+1
 LDA INWK+6
 STA XX12
 LDA INWK+2
 BPL L7616

 DEC XX15+4

.L7616

 JSR LL145

 BCS LL170

 JSR L78F8

.LL170

 LDY #&03
 CLC
 LDA (XX0),Y
 ADC XX0
 STA V
 LDY #&10
 LDA (XX0),Y
 ADC XX0+1
 STA V+1
 LDY #&05
 LDA (XX0),Y
 STA CNT

.LL75

 LDY #&00
 LDA (V),Y
 CMP XX4
 BCC LL78

 INY
 LDA (V),Y
 STA P
 AND #&0F
 TAX
 LDA K3,X
 BNE LL79

 LDA P
 LSR A
 LSR A
 LSR A
 LSR A
 TAX
 LDA K3,X
 BEQ LL78

.LL79

 INY
 LDA (V),Y
 TAX
 LDA XX3,X
 STA XX15
 LDA XX3+1,X
 STA Y1
 LDA XX3+2,X
 STA X2
 LDA XX3+3,X
 STA Y2
 INY
 LDA (V),Y
 TAX
 LDA XX3,X
 STA XX15+4
 LDA XX3+2,X
 STA XX12
 LDA XX3+3,X
 STA XX12+1
 LDA XX3+1,X
 STA XX15+5
 JSR LL147

 BCS LL78

 JSR L78F8

.LL78

 LDA XX14
 CMP CNT
 BCS LL81

 LDA V
 CLC
 ADC #&04
 STA V
 BCC ll81

 INC V+1

.ll81

 INC XX17
 LDY XX17
 CPY XX20
 BCC LL75

.LL81

 JMP LL155

.LL118

 LDA Y1
 BPL LL119

 STA S
 JSR LL120

 TXA
 CLC
 ADC X2
 STA X2
 TYA
 ADC Y2
 STA Y2
 LDA #&00
 STA XX15
 STA Y1
 TAX

.LL119

 BEQ LL134

 STA S
 DEC S
 JSR LL120

 TXA
 CLC
 ADC X2
 STA X2
 TYA
 ADC Y2
 STA Y2
 LDX #&FF
 STX XX15
 INX
 STX Y1

.LL134

 LDA Y2
 BPL LL135

 STA S
 LDA X2
 STA R
 JSR LL123

 TXA
 CLC
 ADC XX15
 STA XX15
 TYA
 ADC Y1
 STA Y1
 LDA #&00
 STA X2
 STA Y2

.LL135

 LDA X2
 SEC
 SBC #&C0
 STA R
 LDA Y2
 SBC #&00
 STA S
 BCC LL136

 JSR LL123

 TXA
 CLC
 ADC XX15
 STA XX15
 TYA
 ADC Y1
 STA Y1
 LDA #&BF
 STA X2
 LDA #&00
 STA Y2

.LL136

 RTS

.LL120

 LDA XX15
 STA R
 JSR LL129

 PHA
 LDX T
 BNE LL121

.LL122

 LDA #&00
 TAX
 TAY
 LSR S
 ROR R
 ASL Q
 BCC LL126

.LL125

 TXA
 CLC
 ADC R
 TAX
 TYA
 ADC S
 TAY

.LL126

 LSR S
 ROR R
 ASL Q
 BCS LL125

 BNE LL126

 PLA
 BPL LL133

 RTS

.LL123

 JSR LL129

 PHA
 LDX T
 BNE LL122

.LL121

 LDA #&FF
 TAY
 ASL A
 TAX

.LL130

 ASL R
 ROL S
 LDA S
 BCS LL131

 CMP Q
 BCC LL132

.LL131

 SBC Q
 STA S
 LDA R
 SBC #&00
 STA R
 SEC

.LL132

 TXA
 ROL A
 TAX
 TYA
 ROL A
 TAY
 BCS LL130

 PLA
 BMI LL128

.LL133

 TXA
 EOR #&FF
 ADC #&01
 TAX
 TYA
 EOR #&FF
 ADC #&00
 TAY

.LL128

 RTS

.LL129

 LDX XX12+2
 STX Q
 LDA S
 BPL LL127

 LDA #&00
 SEC
 SBC R
 STA R
 LDA S
 PHA
 EOR #&FF
 ADC #&00
 STA S
 PLA

.LL127

 EOR XX12+3
 RTS

.LL145

 LDA #&00
 STA SWAP
 LDA XX15+5

.LL147

 LDX #&BF
 ORA XX12+1
 BNE LL107

 CPX XX12
 BCC LL107

 LDX #&00

.LL107

 STX XX13
 LDA Y1
 ORA Y2
 BNE LL83

 LDA #&BF
 CMP X2
 BCC LL83

 LDA XX13
 BNE LL108

.LL146

 LDA X2
 STA Y1
 LDA XX15+4
 STA X2
 LDA XX12
 STA Y2
 CLC
 RTS

.LL109

 SEC
 RTS

.LL108

 LSR XX13

.LL83

 LDA XX13
 BPL LL115

 LDA Y1
 AND XX15+5
 BMI LL109

 LDA Y2
 AND XX12+1
 BMI LL109

 LDX Y1
 DEX
 TXA
 LDX XX15+5
 DEX
 STX XX12+2
 ORA XX12+2
 BPL LL109

 LDA X2
 CMP #&C0
 LDA Y2
 SBC #&00
 STA XX12+2
 LDA XX12
 CMP #&C0
 LDA XX12+1
 SBC #&00
 ORA XX12+2
 BPL LL109

.LL115

 TYA
 PHA
 LDA XX15+4
 SEC
 SBC XX15
 STA XX12+2
 LDA XX15+5
 SBC Y1
 STA XX12+3
 LDA XX12
 SEC
 SBC X2
 STA XX12+4
 LDA XX12+1
 SBC Y2
 STA XX12+5
 EOR XX12+3
 STA S
 LDA XX12+5
 BPL LL110

 LDA #&00
 SEC
 SBC XX12+4
 STA XX12+4
 LDA #&00
 SBC XX12+5
 STA XX12+5

.LL110

 LDA XX12+3
 BPL LL111

 SEC
 LDA #&00
 SBC XX12+2
 STA XX12+2
 LDA #&00
 SBC XX12+3

.LL111

 TAX
 BNE LL112

 LDX XX12+5
 BEQ LL113

.LL112

 LSR A
 ROR XX12+2
 LSR XX12+5
 ROR XX12+4
 JMP LL111

.LL113

 STX T
 LDA XX12+2
 CMP XX12+4
 BCC LL114

 STA Q
 LDA XX12+4
 JSR LL28

 JMP LL116

.LL114

 LDA XX12+4
 STA Q
 LDA XX12+2
 JSR LL28

 DEC T

.LL116

 LDA R
 STA XX12+2
 LDA S
 STA XX12+3
 LDA XX13
 BEQ LL138

 BPL LLX117

.LL138

 JSR LL118

 LDA XX13
 BPL LL124

 LDA Y1
 ORA Y2
 BNE LL137

 LDA X2
 CMP #&C0
 BCS LL137

.LLX117

 LDX XX15
 LDA XX15+4
 STA XX15
 STX XX15+4
 LDA XX15+5
 LDX Y1
 STX XX15+5
 STA Y1
 LDX X2
 LDA XX12
 STA X2
 STX XX12
 LDA XX12+1
 LDX Y2
 STX XX12+1
 STA Y2
 JSR LL118

 DEC SWAP

.LL124

 PLA
 TAY
 JMP LL146

.LL137

 PLA
 TAY
 SEC
 RTS

.LL155

 LDY XX14

.L78D3

 CPY XX14+1
 BCS L78F1

 LDA (XX19),Y
 INY
 STA XX15
 LDA (XX19),Y
 INY
 STA Y1
 LDA (XX19),Y
 INY
 STA X2
 LDA (XX19),Y
 INY
 STA Y2
 JSR LL30

 JMP L78D3

.L78F1

 LDA XX14
 LDY #&00
 STA (XX19),Y

.L78F7

 RTS

.L78F8

 LDY XX14
 CPY XX14+1
 PHP
 LDX #&03

.L78FF

 LDA XX15,X
 STA XX12,X
 DEX
 BPL L78FF

 JSR LL30

 LDA (XX19),Y
 STA XX15
 LDA XX12
 STA (XX19),Y
 INY
 LDA (XX19),Y
 STA Y1
 LDA XX12+1
 STA (XX19),Y
 INY
 LDA (XX19),Y
 STA X2
 LDA XX12+2
 STA (XX19),Y
 INY
 LDA (XX19),Y
 STA Y2
 LDA XX12+3
 STA (XX19),Y
 INY
 STY XX14
 PLP
 BCS L78F7

 JMP LL30

.MVEIT

 LDA INWK+31
 AND #&A0
 BNE MV30

 LDA MCNT
 EOR XSAV
 AND #&0F
 BNE MV3

 JSR TIDY

.MV3

 LDX TYPE
 BPL L794D

 JMP MV40

.L794D

 LDA INWK+32
 BPL MV30

 CPX #&01
 BEQ MV26

 LDA MCNT
 EOR XSAV
 AND #&07
 BNE MV30

.MV26

 JSR TACTICS

.MV30

 JSR SCAN

 LDA INWK+27
 ASL A
 ASL A
 STA Q
 LDA INWK+10
 AND #&7F
 JSR FMLTU

 STA R
 LDA INWK+10
 LDX #&00
 JSR L7ADF

 LDA INWK+12
 AND #&7F
 JSR FMLTU

 STA R
 LDA INWK+12
 LDX #&03
 JSR L7ADF

 LDA INWK+14
 AND #&7F
 JSR FMLTU

 STA R
 LDA INWK+14
 LDX #&06
 JSR L7ADF

 LDA INWK+27
 CLC
 ADC INWK+28
 BPL L79A2

 LDA #&00

.L79A2

 LDY #&0F
 CMP (XX0),Y
 BCC L79AA

 LDA (XX0),Y

.L79AA

 STA INWK+27
 LDA #&00
 STA INWK+28
 LDX ALP1
 LDA INWK
 EOR #&FF
 STA P
 LDA INWK+1
 JSR MLTU2-2

 STA P+2
 LDA ALP2+1
 EOR INWK+2
 LDX #&03
 JSR MVT6

 STA K2+3
 LDA P+1
 STA K2+1
 EOR #&FF
 STA P
 LDA P+2
 STA K2+2
 LDX BET1
 JSR MLTU2-2

 STA P+2
 LDA K2+3
 EOR BET2
 LDX #&06
 JSR MVT6

 STA INWK+8
 LDA P+1
 STA INWK+6
 EOR #&FF
 STA P
 LDA P+2
 STA INWK+7
 JSR MLTU2

 STA P+2
 LDA K2+3
 STA INWK+5
 EOR BET2
 EOR INWK+8
 BPL MV43

 LDA P+1
 ADC K2+1
 STA INWK+3
 LDA P+2
 ADC K2+2
 STA INWK+4
 JMP MV44

.MV43

 LDA K2+1
 SBC P+1
 STA INWK+3
 LDA K2+2
 SBC P+2
 STA INWK+4
 BCS MV44

 LDA #&01
 SBC INWK+3
 STA INWK+3
 LDA #&00
 SBC INWK+4
 STA INWK+4
 LDA INWK+5
 EOR #&80
 STA INWK+5

.MV44

 LDX ALP1
 LDA INWK+3
 EOR #&FF
 STA P
 LDA INWK+4
 JSR MLTU2-2

 STA P+2
 LDA ALP2
 EOR INWK+5
 LDX #&00
 JSR MVT6

 STA INWK+2
 LDA P+2
 STA INWK+1
 LDA P+1
 STA INWK

.MV45

 LDA DELTA
 STA R
 LDA #&80
 LDX #&06
 JSR MVT1

 LDA TYPE
 AND #&81
 CMP #&81
 BNE L7A68

 RTS

.L7A68

 LDY #&09
 JSR MVS4

 LDY #&0F
 JSR MVS4

 LDY #&15
 JSR MVS4

 LDA INWK+30
 AND #&80
 STA RAT2
 LDA INWK+30
 AND #&7F
 BEQ MV8

 CMP #&7F
 SBC #&00
 ORA RAT2
 STA INWK+30
 LDX #&0F
 LDY #&09
 JSR MVS5

 LDX #&11
 LDY #&0B
 JSR MVS5

 LDX #&13
 LDY #&0D
 JSR MVS5

.MV8

 LDA INWK+29
 AND #&80
 STA RAT2
 LDA INWK+29
 AND #&7F
 BEQ MV5

 CMP #&7F
 SBC #&00
 ORA RAT2
 STA INWK+29
 LDX #&0F
 LDY #&15
 JSR MVS5

 LDX #&11
 LDY #&17
 JSR MVS5

 LDX #&13
 LDY #&19
 JSR MVS5

.MV5

 LDA INWK+31
 AND #&A0
 BNE MVD1

 LDA INWK+31
 ORA #&10
 STA INWK+31
 JMP SCAN

.MVD1

 LDA INWK+31
 AND #&EF
 STA INWK+31
 RTS

.L7ADF

 AND #&80

.MVT1

 ASL A
 STA S
 LDA #&00
 ROR A
 STA T
 LSR S
 EOR INWK+2,X
 BMI MV10

 LDA R
 ADC INWK,X
 STA INWK,X
 LDA S
 ADC INWK+1,X
 STA INWK+1,X
 LDA INWK+2,X
 ADC #&00
 ORA T
 STA INWK+2,X
 RTS

.MV10

 LDA INWK,X
 SEC
 SBC R
 STA INWK,X
 LDA INWK+1,X
 SBC S
 STA INWK+1,X
 LDA INWK+2,X
 AND #&7F
 SBC #&00
 ORA #&80
 EOR T
 STA INWK+2,X
 BCS MV11

 LDA #&01
 SBC INWK,X
 STA INWK,X
 LDA #&00
 SBC INWK+1,X
 STA INWK+1,X
 LDA #&00
 SBC INWK+2,X
 AND #&7F
 ORA T
 STA INWK+2,X

.MV11

 RTS

.MVS4

 LDA ALPHA
 STA Q
 LDX INWK+2,Y
 STX R
 LDX INWK+3,Y
 STX S
 LDX INWK,Y
 STX P
 LDA INWK+1,Y
 EOR #&80
 JSR MAD

 STA INWK+3,Y
 STX INWK+2,Y
 STX P
 LDX INWK,Y
 STX R
 LDX INWK+1,Y
 STX S
 LDA INWK+3,Y
 JSR MAD

 STA INWK+1,Y
 STX INWK,Y
 STX P
 LDA BETA
 STA Q
 LDX INWK+2,Y
 STX R
 LDX INWK+3,Y
 STX S
 LDX INWK+4,Y
 STX P
 LDA INWK+5,Y
 EOR #&80
 JSR MAD

 STA INWK+3,Y
 STX INWK+2,Y
 STX P
 LDX INWK+4,Y
 STX R
 LDX INWK+5,Y
 STX S
 LDA INWK+3,Y
 JSR MAD

 STA INWK+5,Y
 STX INWK+4,Y
 RTS

.MVT6

 TAY
 EOR INWK+2,X
 BMI MV50

 LDA P+1
 CLC
 ADC INWK,X
 STA P+1
 LDA P+2
 ADC INWK+1,X
 STA P+2
 TYA
 RTS

.MV50

 LDA INWK,X
 SEC
 SBC P+1
 STA P+1
 LDA INWK+1,X
 SBC P+2
 STA P+2
 BCC MV51

 TYA
 EOR #&80
 RTS

.MV51

 LDA #&01
 SBC P+1
 STA P+1
 LDA #&00
 SBC P+2
 STA P+2
 TYA
 RTS

.MV40

 LDA ALPHA
 EOR #&80
 STA Q
 LDA INWK
 STA P
 LDA INWK+1
 STA P+1
 LDA INWK+2
 JSR MULT3

 LDX #&03
 JSR MVT3

 LDA K+1
 STA K2+1
 STA P
 LDA K+2
 STA K2+2
 STA P+1
 LDA BETA
 STA Q
 LDA K+3
 STA K2+3
 JSR MULT3

 LDX #&06
 JSR MVT3

 LDA K+1
 STA P
 STA INWK+6
 LDA K+2
 STA P+1
 STA INWK+7
 LDA K+3
 STA INWK+8
 EOR #&80
 JSR MULT3

 LDA K+3
 AND #&80
 STA T
 EOR K2+3
 BMI MV1

 LDA K
 CLC
 ADC K2
 LDA K+1
 ADC K2+1
 STA INWK+3
 LDA K+2
 ADC K2+2
 STA INWK+4
 LDA K+3
 ADC K2+3
 JMP MV2

.MV1

 LDA K
 SEC
 SBC K2
 LDA K+1
 SBC K2+1
 STA INWK+3
 LDA K+2
 SBC K2+2
 STA INWK+4
 LDA K2+3
 AND #&7F
 STA P
 LDA K+3
 AND #&7F
 SBC P
 STA P
 BCS MV2

 LDA #&01
 SBC INWK+3
 STA INWK+3
 LDA #&00
 SBC INWK+4
 STA INWK+4
 LDA #&00
 SBC P
 ORA #&80

.MV2

 EOR T
 STA INWK+5
 LDA ALPHA
 STA Q
 LDA INWK+3
 STA P
 LDA INWK+4
 STA P+1
 LDA INWK+5
 JSR MULT3

 LDX #&00
 JSR MVT3

 LDA K+1
 STA INWK
 LDA K+2
 STA INWK+1
 LDA K+3
 STA INWK+2
 JMP MV45

.PLUT

 LDX VIEW
 BEQ L7CD1

 DEX
 BNE PU2

 LDA INWK+2
 EOR #&80
 STA INWK+2
 LDA INWK+8
 EOR #&80
 STA INWK+8
 LDA INWK+10
 EOR #&80
 STA INWK+10
 LDA INWK+14
 EOR #&80
 STA INWK+14
 LDA INWK+16
 EOR #&80
 STA INWK+16
 LDA INWK+20
 EOR #&80
 STA INWK+20
 LDA INWK+22
 EOR #&80
 STA INWK+22
 LDA INWK+26
 EOR #&80
 STA INWK+26

.L7CD1

 RTS

.PU2

 LDA #&00
 CPX #&02
 ROR A
 STA RAT2
 EOR #&80
 STA RAT
 LDA INWK
 LDX INWK+6
 STA INWK+6
 STX INWK
 LDA INWK+1
 LDX INWK+7
 STA INWK+7
 STX INWK+1
 LDA INWK+2
 EOR RAT
 TAX
 LDA INWK+8
 EOR RAT2
 STA INWK+2
 STX INWK+8
 LDY #&09
 JSR PUS1

 LDY #&0F
 JSR PUS1

 LDY #&15

.PUS1

 LDA INWK,Y
 LDX INWK+4,Y
 STA INWK+4,Y
 STX INWK,Y
 LDA INWK+1,Y
 EOR RAT
 TAX
 LDA INWK+5,Y
 EOR RAT2
 STA INWK+1,Y
 STX INWK+5,Y

.LO2

 RTS

.LQ

 STX VIEW
 JSR TT66

 JSR SIGHT

 LDA BOMB
 BPL L7D32

 JSR L31AC

.L7D32

 JMP NWSTARS

.LOOK1

 LDA #&00
 JSR SETVDU19

 LDY QQ11
 BNE LQ

 CPX VIEW
 BEQ LO2

 STX VIEW
 JSR TT66

 JSR FLIP

 LDA BOMB
 BPL L7D54

 JSR L31AC

.L7D54

 JSR WPSHPS

.SIGHT

 LDY VIEW
 LDA LASER,Y
 BEQ LO2

 LDY #&00
 CMP #&0F
 BEQ L7D70

 INY
 CMP #&8F
 BEQ L7D70

 INY
 CMP #&97
 BEQ L7D70

 INY

.L7D70

 LDA L7D8B,Y
 STA COL
 LDA #&80
 STA QQ19
 LDA #&48
 STA QQ19+1
 LDA #&14
 STA QQ19+2
 JSR TT15

 LDA #&0A
 STA QQ19+2
 JMP TT15

.L7D8B

 EQUB &0F

 EQUB &FF,&FF,&0F

 EQUB &FA

 EQUB &FA,&FA,&FA

.TT66

 STA QQ11
 JSR TTX66

 JSR MT2

 LDA #&00
 STA LSP
 LDA #&80
 STA QQ17
 STA DTW2
 JSR FLFLLS

 LDA #&00
 STA LAS2
 STA DLY
 STA de
 LDX QQ22+1
 BEQ OLDBOX

 JSR ee3

.OLDBOX

 LDA QQ11
 BNE tt66

 LDA #&0B
 STA XC
 LDA #&FF
 STA COL
 LDA VIEW
 ORA #&60
 JSR TT27

 JSR TT162

 LDA #&AF
 JSR TT27

.tt66

 LDX #&00
 STX QQ17
 RTS

.L7DDC

 EQUB &00

 EQUB &40,&FE,&A0,&5F,&8C,&43,&FE,&8E
 EQUB &4F,&FE,&EA,&AE,&4F,&FE,&60,&51
 EQUB &33,&34,&35,&84,&38,&87,&2D,&5E
 EQUB &8C,&36,&37,&BC,&00,&FC,&60,&80
 EQUB &57,&45,&54,&37,&49,&39,&30,&5F
 EQUB &8E,&38,&39,&BC,&00,&FD,&60,&31
 EQUB &32,&44,&52,&36,&55,&4F,&50,&5B
 EQUB &8F,&81,&82,&0D,&4C,&20,&02,&01
 EQUB &41,&58,&46,&59,&4A,&4B,&40,&3A
 EQUB &0D,&83,&7F,&AE,&4C,&FE,&FD,&02
 EQUB &53,&43,&47,&48,&4E,&4C,&3B,&5D
 EQUB &7F,&85,&84,&86,&4C,&FA,&00,&00
 EQUB &5A,&20,&56,&42,&4D,&2C,&2E,&2F
 EQUB &8B,&30,&31,&33,&00,&00,&00,&1B
 EQUB &81,&82,&83,&85,&86,&88,&89,&5C
 EQUB &8D,&34,&35,&32,&2C,&4E,&E3

.KYTB

 EQUB &22,&23,&35,&37,&41,&42,&45,&51
 EQUB &52,&60,&62,&65,&66,&67,&68,&70
 EQUB &F0

.RDKEY_REAL

 JSR U%

 LDA #&10
 CLC

.L7E73

 LDY #&03
 SEI
 STY VIA+&40
 LDY #&7F
 STY VIA+&43
 STA VIA+&4F
 LDY VIA+&4F
 LDA #&0B
 STA VIA+&40
 CLI
 TYA
 BMI DKS1

.L7E8D

 ADC #&01
 BPL L7E73

 CLD
 LDA L00CB
 EOR #&FF
 AND KY19
 STA KY19
 LDA KL
 TAX
 RTS

.DKS1

 EOR #&80
 STA KL

.L7EA2

 CMP KYTB,X
 BCC L7E8D

 BEQ L7EAC

 INX
 BNE L7EA2

.L7EAC

 DEC KY17,X
 INX
 CLC
 BCC L7E8D

.CTRL

 LDA #&01

.DKS4

 LDX #&03
 SEI
 STX VIA+&40
 LDX #&7F
 STX VIA+&43
 STA VIA+&4F
 LDX VIA+&4F
 LDA #&0B
 STA VIA+&40
 CLI
 TXA
 RTS

.U%

 LDA #&00
 LDX #&11

.DKL3

 STA JSTY,X
 DEX
 BNE DKL3

 RTS

.L7ED7

 SED

.RDKEY

 TYA
 PHA
 JSR RDKEY_REAL

 PLA
 TAY
 LDA L7DDC,X
 STA KL
 TAX
 RTS

.L7EE6

 RTS

.ECMOF

 LDA #&00
 STA ECMA
 STA ECMP
 JMP ECBLB

.SFRMIS

 LDX #&01
 JSR SFS1-2

 BCC L7EE6

 LDA #&78
 JSR MESS

 LDY #&08
 JMP NOISE

.EXNO2

 LDA L1266
 CLC
 ADC L8062,X
 STA L1266
 LDA TALLY
 ADC L8083,X
 STA TALLY
 BCC EXNO3

 INC TALLY+1
 LDA #&65
 JSR MESS

.EXNO3

 LDY #&04
 JMP NOISE

.EXNO

 LDY #&06
 JMP NOISE

.BRKBK

 LDA #&B9
 STA BRKV
 LDA #&66
 STA BRKV+1
 LDA #&85
 STA WRCHV
 LDA #&20
 STA WRCHV+1
 JSR MASTER_MOVE_ZP_3000

 JSR STARTUP

 JMP L1377

 CLI
 RTI

.BeebDisEndAddr

\ ******************************************************************************
\
\ Save output/BCODE.unprot.bin
\
\ ******************************************************************************

PRINT "S.BCODE ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
SAVE "output/BCODE.unprot.bin", CODE%, P%, LOAD%

