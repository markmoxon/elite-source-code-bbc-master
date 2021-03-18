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

f0 = &20                \ Internal key number for red key f0 (Launch, Front)
f1 = &71                \ Internal key number for red key f1 (Buy Cargo, Rear)
f2 = &72                \ Internal key number for red key f2 (Sell Cargo, Left)
f3 = &73                \ Internal key number for red key f3 (Equip Ship, Right)
f4 = &14                \ Internal key number for red key f4 (Long-range Chart)
f5 = &74                \ Internal key number for red key f5 (Short-range Chart)
f6 = &75                \ Internal key number for red key f6 (Data on System)
f7 = &16                \ Internal key number for red key f7 (Market Price)
f8 = &76                \ Internal key number for red key f8 (Status Mode)
f9 = &77                \ Internal key number for red key f9 (Inventory)

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
\       Name: TT26
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
\ WRCHV is set to point here by the loading process.
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

.TT26

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
 STA L4000
 STA L41F8
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

.NLIN3

 JSR TT27

.NLIN4

 LDA #&13
 BNE NLIN2

.NLIN

 LDA #&17

.L359D

 INC YC

.NLIN2

 STA Y1
 LDA #&0F
 STA COL
 LDX #&02
 STX XX15
 LDX #&FE
 STX X2
 JSR HLOIN3

 LDA #&FF
 STA COL
 RTS

.HLOIN2

 JSR EDGES

 STY Y1
 LDA #&00
 STA LSO,Y
 JMP HLOIN

.BLINE

 TXA
 ADC K4
 STA XX18+6
 LDA K4+1
 ADC T
 STA XX18+7
 LDA FLAG
 BEQ BL1

 INC FLAG

.BL5

 LDY LSP
 LDA #&FF
 CMP LSY2-1,Y
 BEQ BL7

 STA LSY2,Y
 INC LSP
 BNE BL7

.BL1

 LDA XX18
 STA XX15
 LDA XX18+1
 STA Y1
 LDA XX18+2
 STA X2
 LDA XX18+3
 STA Y2
 LDA XX18+4
 STA XX15+4
 LDA XX18+5
 STA XX15+5
 LDA XX18+6
 STA XX12
 LDA XX18+7
 STA XX12+1
 JSR LL145

 BCS BL5

 LDA SWAP
 BEQ BL9

 LDA XX15
 LDY X2
 STA X2
 STY XX15
 LDA Y1
 LDY Y2
 STA Y2
 STY Y1

.BL9

 LDY LSP
 LDA LSY2-1,Y
 CMP #&FF
 BNE BL8

 LDA XX15
 STA LSX2,Y
 LDA Y1
 STA LSY2,Y
 INY

.BL8

 LDA X2
 STA LSX2,Y
 LDA Y2
 STA LSY2,Y
 INY
 STY LSP
 JSR LL30

 LDA XX13
 BNE BL5

.BL7

 LDA XX18+4
 STA XX18
 LDA XX18+5
 STA XX18+1
 LDA XX18+6
 STA XX18+2
 LDA XX18+7
 STA XX18+3
 LDA CNT
 CLC
 ADC STP
 STA CNT
 RTS

.FLIP

 LDA #&FA
 STA COL
 LDY NOSTM

.FLL1

 LDX SY,Y
 LDA SX,Y
 STA Y1
 STA SY,Y
 TXA
 STA XX15
 STA SX,Y
 LDA SZ,Y
 STA ZZ
 JSR PIXEL2

 DEY
 BNE FLL1

 RTS

.STARS

 LDA #&FA
 STA COL
 LDX VIEW
 BEQ STARS1

 DEX
 BNE ST11

 JMP STARS6

.ST11

 JMP STARS2

.STARS1

 LDY NOSTM

.STL1

 JSR DV42

 LDA R
 LSR P
 ROR A
 LSR P
 ROR A
 ORA #&01
 STA Q
 LDA SZL,Y
 SBC DELT4
 STA SZL,Y
 LDA SZ,Y
 STA ZZ
 SBC DELT4+1
 STA SZ,Y
 JSR MLU1

 STA YY+1
 LDA P
 ADC SYL,Y
 STA YY
 STA R
 LDA Y1
 ADC YY+1
 STA YY+1
 STA S
 LDA SX,Y
 STA XX15
 JSR MLU2

 STA XX+1
 LDA P
 ADC SXL,Y
 STA XX
 LDA XX15
 ADC XX+1
 STA XX+1
 EOR ALP2+1
 JSR MLS1

 JSR ADD

 STA YY+1
 STX YY
 EOR ALP2
 JSR MLS2

 JSR ADD

 STA XX+1
 STX XX
 LDX BET1
 LDA YY+1
 EOR BET2+1
 JSR L44EA

 STA Q
 JSR MUT2

 ASL P
 ROL A
 STA T
 LDA #&00
 ROR A
 ORA T
 JSR ADD

 STA XX+1
 TXA
 STA SXL,Y
 LDA YY
 STA R
 LDA YY+1
 STA S
 LDA #&00
 STA P
 LDA BETA
 EOR #&80
 JSR PIX1

 LDA XX+1
 STA XX15
 STA SX,Y
 AND #&7F
 CMP #&78
 BCS KILL1

 LDA YY+1
 STA SY,Y
 STA Y1
 AND #&7F
 CMP #&78
 BCS KILL1

 LDA SZ,Y
 CMP #&10
 BCC KILL1

 STA ZZ

.STC1

 JSR PIXEL2

 DEY
 BEQ L375A

 JMP STL1

.L375A

 RTS

.KILL1

 JSR DORND

 ORA #&04
 STA Y1
 STA SY,Y
 JSR DORND

 ORA #&08
 STA XX15
 STA SX,Y
 JSR DORND

 ORA #&90
 STA SZ,Y
 STA ZZ
 LDA Y1
 JMP STC1

.STARS6

 LDY NOSTM

.STL6

 JSR DV42

 LDA R
 LSR P
 ROR A
 LSR P
 ROR A
 ORA #&01
 STA Q
 LDA SX,Y
 STA XX15
 JSR MLU2

 STA XX+1
 LDA SXL,Y
 SBC P
 STA XX
 LDA XX15
 SBC XX+1
 STA XX+1
 JSR MLU1

 STA YY+1
 LDA SYL,Y
 SBC P
 STA YY
 STA R
 LDA Y1
 SBC YY+1
 STA YY+1
 STA S
 LDA SZL,Y
 ADC DELT4
 STA SZL,Y
 LDA SZ,Y
 STA ZZ
 ADC DELT4+1
 STA SZ,Y
 LDA XX+1
 EOR ALP2
 JSR MLS1

 JSR ADD

 STA YY+1
 STX YY
 EOR ALP2+1
 JSR MLS2

 JSR ADD

 STA XX+1
 STX XX
 LDA YY+1
 EOR BET2+1
 LDX BET1
 JSR L44EA

 STA Q
 LDA XX+1
 STA S
 EOR #&80
 JSR MUT1

 ASL P
 ROL A
 STA T
 LDA #&00
 ROR A
 ORA T
 JSR ADD

 STA XX+1
 TXA
 STA SXL,Y
 LDA YY
 STA R
 LDA YY+1
 STA S
 LDA #&00
 STA P
 LDA BETA
 JSR PIX1

 LDA XX+1
 STA XX15
 STA SX,Y
 LDA YY+1
 STA SY,Y
 STA Y1
 AND #&7F
 CMP #&6E
 BCS KILL6

 LDA SZ,Y
 CMP #&A0
 BCS KILL6

 STA ZZ

.STC6

 JSR PIXEL2

 DEY
 BEQ ST3_UC

 JMP STL6

.ST3_UC

 RTS

.KILL6

 JSR DORND

 AND #&7F
 ADC #&0A
 STA SZ,Y
 STA ZZ
 LSR A
 BCS ST4_UC

 LSR A
 LDA #&FC
 ROR A
 STA XX15
 STA SX,Y
 JSR DORND

 STA Y1
 STA SY,Y
 JMP STC6

.ST4_UC

 JSR DORND

 STA XX15
 STA SX,Y
 LSR A
 LDA #&E6
 ROR A
 STA Y1
 STA SY,Y
 BNE STC6

.MAS1

 LDA INWK,Y
 ASL A
 STA K+1
 LDA INWK+1,Y
 ROL A
 STA K+2
 LDA #&00
 ROR A
 STA K+3
 JSR MVT3

 STA INWK+2,X
 LDY K+1
 STY INWK,X
 LDY K+2
 STY INWK+1,X
 AND #&7F
 RTS

.m

 LDA #&00

.MAS2

 ORA L0402,Y
 ORA L0405,Y
 ORA L0408,Y
 AND #&7F
 RTS

.MAS3

 LDA L0401,Y
 JSR SQUA2

 STA R
 LDA L0404,Y
 JSR SQUA2

 ADC R
 BCS MA30

 STA R
 LDA L0407,Y
 JSR SQUA2

 ADC R
 BCC L38CC

.MA30

 LDA #&FF

.L38CC

 RTS

.wearedocked

 LDA #&CD
 JSR DETOK

 JSR TT67_DUPLICATE

 JMP L3915

.st4

 LDX #&09
 CMP #&19
 BCS st3

 DEX
 CMP #&0A
 BCS st3

 DEX
 CMP #&02
 BCS st3

 DEX
 BNE st3

.STATUS

 LDA #&08
 JSR TRADEMODE

 JSR TT111

 LDA #&07
 STA XC
 LDA #&7E
 JSR NLIN3

 LDA #&0F
 LDY QQ12
 BNE wearedocked

 LDA #&E6
 LDY JUNK
 LDX FRIN+2,Y
 BEQ st6

 LDY ENERGY
 CPY #&80
 ADC #&01

.st6

 JSR plf

.L3915

 LDA #&7D
 JSR spc

 LDA #&13
 LDY FIST
 BEQ st5

 CPY #&32
 ADC #&01

.st5

 JSR plf

 LDA #&10
 JSR spc

 LDA TALLY+1
 BNE st4

 TAX
 LDA TALLY
 LSR A
 LSR A

.L3938

 INX
 LSR A
 BNE L3938

.st3

 TXA
 CLC
 ADC #&15
 JSR plf

 LDA #&12
 JSR plf2

 LDA ESCP
 BEQ L3952

 LDA #&70
 JSR plf2

.L3952

 LDA BST
 BEQ L395C

 LDA #&6F
 JSR plf2

.L395C

 LDA ECM
 BEQ L3966

 LDA #&6C
 JSR plf2

.L3966

 LDA #&71
 STA XX4

.stqv

 TAY
 LDX L11ED,Y
 BEQ L3973

 JSR plf2

.L3973

 INC XX4
 LDA XX4
 CMP #&75
 BCC stqv

 LDX #&00

.st

 STX CNT
 LDY LASER,X
 BEQ st1

 TXA
 CLC
 ADC #&60
 JSR spc

 LDA #&67
 LDX CNT
 LDY LASER,X
 CPY #&8F
 BNE L3998

 LDA #&68

.L3998

 CPY #&97
 BNE L399E

 LDA #&75

.L399E

 CPY #&32
 BNE L39A4

 LDA #&76

.L39A4

 JSR plf2

.st1

 LDX CNT
 INX
 CPX #&04
 BCC st

 RTS

.plf2

 JSR plf

 LDA #&06
 STA XC
 RTS

.MVT3

 LDA K+3
 STA S
 AND #&80
 STA T
 EOR INWK+2,X
 BMI MV13

 LDA K+1
 CLC
 ADC INWK,X
 STA K+1
 LDA K+2
 ADC INWK+1,X
 STA K+2
 LDA K+3
 ADC INWK+2,X
 AND #&7F
 ORA T
 STA K+3
 RTS

.MV13

 LDA S
 AND #&7F
 STA S
 LDA INWK,X
 SEC
 SBC K+1
 STA K+1
 LDA INWK+1,X
 SBC K+2
 STA K+2
 LDA INWK+2,X
 AND #&7F
 SBC S
 ORA #&80
 EOR T
 STA K+3
 BCS MV14

 LDA #&01
 SBC K+1
 STA K+1
 LDA #&00
 SBC K+2
 STA K+2
 LDA #&00
 SBC K+3
 AND #&7F
 ORA T
 STA K+3

.MV14

 RTS

.MVS5

 LDA INWK+1,X
 AND #&7F
 LSR A
 STA T
 LDA INWK,X
 SEC
 SBC T
 STA R
 LDA INWK+1,X
 SBC #&00
 STA S
 LDA INWK,Y
 STA P
 LDA INWK+1,Y
 AND #&80
 STA T
 LDA INWK+1,Y
 AND #&7F
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P
 ORA T
 EOR RAT2
 STX Q
 JSR ADD

 STA K+1
 STX K
 LDX Q
 LDA INWK+1,Y
 AND #&7F
 LSR A
 STA T
 LDA INWK,Y
 SEC
 SBC T
 STA R
 LDA INWK+1,Y
 SBC #&00
 STA S
 LDA INWK,X
 STA P
 LDA INWK+1,X
 AND #&80
 STA T
 LDA INWK+1,X
 AND #&7F
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P
 ORA T
 EOR #&80
 EOR RAT2
 STX Q
 JSR ADD

 STA INWK+1,Y
 STX INWK,Y
 LDX Q
 LDA K
 STA INWK,X
 LDA K+1
 STA INWK+1,X
 RTS

.L3A9F

 EQUB &48,&76,&E8,&00

.pr2

 LDA #&03

.L3AA5

 LDY #&00

.TT11

 STA U
 LDA #&00
 STA K
 STA K+1
 STY K+2
 STX K+3

.BPRNT

 LDX #&0B
 STX T
 PHP
 BCC TT30

 DEC T
 DEC U

.TT30

 LDA #&0B
 SEC
 STA XX17
 SBC U
 STA U
 INC U
 LDY #&00
 STY S
 JMP TT36

.TT35

 ASL K+3
 ROL K+2
 ROL K+1
 ROL K
 ROL S
 LDX #&03

.tt35_lc

 LDA K,X
 STA XX15,X
 DEX
 BPL tt35_lc

 LDA S
 STA XX15+4
 ASL K+3
 ROL K+2
 ROL K+1
 ROL K
 ROL S
 ASL K+3
 ROL K+2
 ROL K+1
 ROL K
 ROL S
 CLC
 LDX #&03

.tt36_lc

 LDA K,X
 ADC XX15,X
 STA K,X
 DEX
 BPL tt36_lc

 LDA XX15+4
 ADC S
 STA S
 LDY #&00

.TT36

 LDX #&03
 SEC

.tt37_lc

 LDA K,X
 SBC L3A9F,X
 STA XX15,X
 DEX
 BPL tt37_lc

 LDA S
 SBC #&17
 STA XX15+4
 BCC TT37

 LDX #&03

.tt38_lc

 LDA XX15,X
 STA K,X
 DEX
 BPL tt38_lc

 LDA XX15+4
 STA S
 INY
 JMP TT36

.TT37

 TYA
 BNE TT32

 LDA T
 BEQ TT32

 DEC U
 BPL TT34

 LDA #&20
 BNE tt34_lc

.TT32

 LDY #&00
 STY T
 CLC
 ADC #&30

.tt34_lc

 JSR DASC

.TT34

 DEC T
 BPL L3B54

 INC T

.L3B54

 DEC XX17
 BMI rT10

 BNE L3B62

 PLP
 BCC L3B62

 LDA #&2E
 JSR DASC

.L3B62

 JMP TT35

.rT10

 RTS

.DTW1

 EQUB &20

.DTW2

 EQUB &FF

.DTW3

 EQUB &00

.DTW4

 EQUB &00

.DTW5

 EQUB &00

.DTW6

 EQUB &00

.DTW8

 EQUB &FF

.FEED

 LDA #&0C
 EQUB &2C

.MT16

 LDA #&41
DTW7 = MT16+1

.DASC

 STX SC
 LDX #&FF
 STX DTW8
 CMP #&2E
 BEQ DA8

 CMP #&3A
 BEQ DA8

 CMP #&0A
 BEQ DA8

 CMP #&0C
 BEQ DA8

 CMP #&20
 BEQ DA8

 INX

.DA8

 STX DTW2
 LDX SC
 BIT DTW4
 BMI L3B9B

 JMP TT26

.L3B9B

 BIT DTW4
 BVS L3BA4

 CMP #&0C
 BEQ DA1

.L3BA4

 LDX DTW5
 STA BUF,X
 LDX SC
 INC DTW5
 CLC
 RTS

.DA1

 TXA
 PHA
 TYA
 PHA

.DA5

 LDX DTW5
 BEQ L3C32

 CPX #&1F
 BCC DA6

 LSR SC+1

.DA11

 LDA SC+1
 BMI L3BC8

 LDA #&40
 STA SC+1

.L3BC8

 LDY #&1D

.DAL1

 LDA BUF+LL
 CMP #&20
 BEQ DA2

.DAL2

 DEY
 BMI DA11

 BEQ DA11

 LDA BUF,Y
 CMP #&20
 BNE DAL2

 ASL SC+1
 BMI DAL2

 STY SC
 LDY DTW5

.DAL6

 LDA BUF,Y
 STA BUF+1,Y
 DEY
 CPY SC
 BCS DAL6

 INC DTW5

.DAL3

 CMP BUF,Y
 BNE DAL1

 DEY
 BPL DAL3

 BMI DA11

.DA2

 LDX #&1E
 JSR DAS1

 LDA #&0C
 JSR TT26

 LDA DTW5
 SBC #&1E
 STA DTW5
 TAX
 BEQ L3C32

 LDY #&00
 INX

.DAL4

 LDA BUF+LL+1,Y
 STA BUF,Y
 INY
 DEX
 BNE DAL4

 BEQ DA5

.DAS1

 LDY #&00

.DAL5

 LDA BUF,Y
 JSR TT26

 INY
 DEX
 BNE DAL5

 RTS

.DA6

 JSR DAS1

.L3C32

 STX DTW5
 PLA
 TAY
 PLA
 TAX
 LDA #&0C

.L3C3B

 EQUB &2C

.BELL

 LDA #&07
 JMP TT26

.ESCAPE

 JSR RES2

 LDX #&0B
 STX TYPE
 JSR FRS1

 BCS ES1

 LDX #&18
 JSR FRS1

.ES1

 LDA #&08
 STA INWK+27
 LDA #&C2
 STA INWK+30
 LSR A
 STA INWK+32

.ESL1

 JSR MVEIT

 LDA QQ11
 ORA VIEW
 BNE L3C6A

 JSR LL9

.L3C6A

 DEC INWK+32
 BNE ESL1

 JSR SCAN

 LDA #&00
 LDX #&10

.ESL2

 STA QQ20,X
 DEX
 BPL ESL2

 STA FIST
 STA ESCP
 LDA #&46
 STA QQ14
 JMP GOIN

.HME2

 LDA #&FF
 STA COL
 LDA #&0E
 JSR DETOK

 JSR TT103

 JSR TT81

 LDA #&00
 STA XX20

.HME3

 JSR MT14

 JSR cpl

 LDX DTW5
 LDA INWK+5,X
 CMP #&0D
 BNE HME6

.HME4

 DEX
 LDA INWK+5,X
 ORA #&20
 CMP BUF,X
 BEQ HME4

 TXA
 BMI HME5

.HME6

 JSR TT20

 INC XX20
 BNE HME3

 JSR TT111

 JSR TT103

 JSR BEEP_LONG_LOW

 LDA #&D7
 JMP DETOK

.HME5

 LDA QQ15+3
 STA QQ9
 LDA QQ15+1
 STA QQ10
 JSR TT111

 JSR TT103

 JSR MT15

 JMP T95_UC

.L3CE1

 EQUB &0B

 EQUB &44,&3B,&00,&82,&B0,&00,&00,&00
 EQUB &05,&50,&11,&05,&D1,&28,&05,&40
 EQUB &06,&10,&60,&90,&13,&10,&D1,&00
 EQUB &00,&00,&14,&51,&F8,&10,&60,&75
 EQUB &00,&00,&00

.HALL

 LDA #&00
 JSR SETVDU19

 LDA #&00
 JSR TT66

 JSR DORND

 BPL HA7

 AND #&03
 STA T
 ASL A
 ASL A
 ASL A
 ADC T
 TAX
 LDY #&03
 STY CNT2

.HAL8

 LDY #&02

.HAL9

 LDA L3CE1,X
 STA XX15,Y
 INX
 DEY
 BPL HAL9

 TXA
 PHA
 JSR HAS1

 PLA
 TAX
 DEC CNT2
 BNE HAL8

 LDY #&80
 BNE HA9

.HA7

 LSR A
 STA Y1
 JSR DORND

 STA XX15
 JSR DORND

 AND #&03
 ADC #&11
 STA X2
 JSR HAS1

 LDY #&00

.HA9

 STY HCNT
 JMP HANGER

.HAS1

 JSR ZINF

 LDA XX15
 STA INWK+6
 LSR A
 ROR INWK+2
 LDA Y1
 STA INWK
 LSR A
 LDA #&01
 ADC #&00
 STA INWK+7
 LDA #&80
 STA INWK+5
 STA RAT2
 LDA #&0B
 STA INWK+34
 JSR DORND

 STA XSAV

.HAL5

 LDX #&15
 LDY #&09
 JSR MVS5

 LDX #&17
 LDY #&0B
 JSR MVS5

 LDX #&19
 LDY #&0D
 JSR MVS5

 DEC XSAV
 BNE HAL5

 LDY X2
 BEQ HA1

 TYA
 ASL A
 TAX
 LDA XX21-2,X
 STA XX0
 LDA XX21-1,X
 STA XX0+1
 BEQ HA1

 LDY #&01
 LDA (XX0),Y
 STA Q
 INY
 LDA (XX0),Y
 STA R
 JSR LL5

 LDA #&64
 SBC Q
 LSR A
 STA INWK+3
 JSR TIDY

 JMP LL9

.HA1

 RTS

.TA35_DUPLICATE

 LDA INWK
 ORA INWK+3
 ORA INWK+6
 BNE TA87_DUPLICATE

 LDA #&50
 JSR OOPS

.TA87_DUPLICATE

 LDX #&04
 BNE L3E37

.TA34

 LDA #&00
 JSR MAS4

 BEQ L3DE0

 JMP TN4

.L3DE0

 JSR L3E3A

 JSR EXNO3

 LDA #&FA
 JMP OOPS

.TA18

 LDA ECMA
 BNE TA35_DUPLICATE

 LDA INWK+32
 ASL A
 BMI TA34

 LSR A
 TAX
 LDA UNIV,X
 STA V
 LDA UNIV+1,X
 JSR VCSUB

 LDA K3+2
 ORA K3+5
 ORA K3+8
 AND #&7F
 ORA K3+1
 ORA K3+4
 ORA K3+7
 BNE TA64

 LDA INWK+32
 CMP #&82
 BEQ TA35_DUPLICATE

 LDY #&1F
 LDA (V),Y
 BIT L3E48
 BNE TA35

 ORA #&80
 STA (V),Y

.TA35

 LDA INWK
 ORA INWK+3
 ORA INWK+6
 BNE TA87

 LDA #&50
 JSR OOPS

.TA87

 LDA INWK+32
 AND #&7F
 LSR A
 TAX

.L3E37

 JSR EXNO2

.L3E3A

 ASL INWK+31
 SEC
 ROR INWK+31

.TA1

 RTS

.TA64

 JSR DORND

 CMP #&10
 BCS TA19S

.M32

 LDY #&20
L3E48 = M32+1
 LDA (V),Y
 LSR A
 BCS L3E51

.TA19S

 JMP TA19

.L3E51

 JMP ECBLB2

.TACTICS

 LDA #&03
 STA RAT
 LDA #&04
 STA RAT2
 LDA #&16
 STA CNT2
 CPX #&01
 BEQ TA18

 CPX #&02
 BNE TA13

 LDA NEWB
 AND #&04
 BNE TN5

 LDA L0E58
 BNE TA1

 JSR DORND

 CMP #&FD
 BCC TA1

 AND #&01
 ADC #&08
 TAX
 BNE TN6

.TN5

 JSR DORND

 CMP #&F0
 BCC TA1

 LDA L0E5E
 CMP #&06
 BCS TA22

 LDX #&10

.TN6

 LDA #&F1
 JMP SFS1

.TA13

 CPX #&0F
 BNE TA17

 JSR DORND

 CMP #&C8
 BCC TA22

 LDX #&00
 STX INWK+32
 LDX #&24
 STX NEWB
 AND #&03
 ADC #&11
 TAX
 JSR TN6

 LDA #&00
 STA INWK+32
 RTS

.TA17

 LDY #&0E
 LDA INWK+35
 CMP (XX0),Y
 BCS TA21

 INC INWK+35

.TA21

 CPX #&1E
 BNE TA14

 LDA L0E6B
 BNE TA14

 LSR INWK+32
 ASL INWK+32
 LSR INWK+27

.TA22

 RTS

.TA14

 JSR DORND

 LDA NEWB
 LSR A
 BCC TN1

 CPX #&32
 BCS TA22

.TN1

 LSR A
 BCC TN2

 LDX FIST
 CPX #&28
 BCC TN2

 LDA NEWB
 ORA #&04
 STA NEWB
 LSR A
 LSR A

.TN2

 LSR A
 BCS TN3

 LSR A
 LSR A
 BCC GOPL

 JMP DOCKIT

.GOPL

 JSR SPS1

 JMP TA151

.TN3

 LSR A
 BCC TN4

 LDA SSPR
 BEQ TN4

 LDA INWK+32
 AND #&81
 STA INWK+32

.TN4

 LDX #&08

.TAL1

 LDA INWK,X
 STA K3,X
 DEX
 BPL TAL1

.TA19

 JSR TAS2

 LDY #&0A
 JSR TAS3

 STA CNT
 LDA TYPE
 CMP #&01
 BNE L3F28

 JMP TA20

.L3F28

 CMP #&0E
 BNE TN7

 JSR DORND

 CMP #&C8
 BCC TN7

 JSR DORND

 LDX #&17
 CMP #&64
 BCS L3F3E

 LDX #&11

.L3F3E

 JMP TN6

.TN7

 JSR DORND

 CMP #&FA
 BCC TA7

 JSR DORND

 ORA #&68
 STA INWK+29

.TA7

 LDY #&0E
 LDA (XX0),Y
 LSR A
 CMP INWK+35
 BCC TA3

 LSR A
 LSR A
 CMP INWK+35
 BCC ta3_lc

 JSR DORND

 CMP #&E6
 BCC ta3_lc

 LDX TYPE
 LDA L8041,X
 BPL ta3_lc

 LDA NEWB
 AND #&F0
 STA NEWB
 LDY #&24
 STA (INF),Y
 LDA #&00
 STA INWK+32
 JMP SESCP

.ta3_lc

 LDA INWK+31
 AND #&07
 BEQ TA3

 STA T
 JSR DORND

 AND #&1F
 CMP T
 BCS TA3

 LDA ECMA
 BNE TA3

 DEC INWK+31
 LDA TYPE
 CMP #&1D
 BNE TA16

 LDX #&1E
 LDA INWK+32
 JMP SFS1

.TA16

 JMP SFRMIS

.TA3

 LDA #&00
 JSR MAS4

 AND #&E0
 BNE TA4

 LDX CNT
 CPX #&A0
 BCC TA4

 LDY #&13
 LDA (XX0),Y
 AND #&F8
 BEQ TA4

 LDA INWK+31
 ORA #&40
 STA INWK+31
 CPX #&A3
 BCC TA4

 LDA (XX0),Y
 LSR A
 JSR OOPS

 DEC INWK+28
 LDA ECMA
 BNE L4039

 JSR BEING_HIT_NOISE

.TA4

 LDA INWK+7
 CMP #&03
 BCS TA5

 LDA INWK+1
 ORA INWK+4
 AND #&FE
 BEQ TA15

.TA5

 JSR DORND

 ORA #&80
 CMP INWK+32
 BCS TA15

.TA20

 JSR TAS6

 LDA CNT
 EOR #&80

.TA152

 STA CNT

.TA15

 LDY #&10
 JSR TAS3

 TAX
 EOR #&80
 AND #&80
 STA INWK+30

.L4000

 TXA
 ASL A
 CMP RAT2
 BCC TA11

 LDA RAT
 ORA INWK+30
 STA INWK+30

.TA11

 LDA INWK+29
 ASL A
 CMP #&20
 BCS TA12

 LDY #&16
 JSR TAS3

 TAX
 EOR INWK+30
 AND #&80
 EOR #&80
 STA INWK+29
 TXA
 ASL A
 CMP RAT2
 BCC TA12

 LDA RAT
 ORA INWK+29
 STA INWK+29

.TA12

 LDA CNT
 BMI TA9

 CMP CNT2
 BCC TA9

 LDA #&03
 STA INWK+28

.L4039

 RTS

.TA9

 AND #&7F
 CMP #&12
 BCC TA10

 LDA #&FF
 LDX TYPE
 CPX #&01
 BNE L4049

 ASL A

.L4049

 STA INWK+28

.TA10

 RTS

.TA151

 LDY #&0A
 JSR TAS3

 CMP #&98
 BCC ttt

 LDX #&00
 STX RAT2

.ttt

 JMP TA152

.DOCKIT

 LDA #&06
 STA RAT2
 LSR A
 STA RAT
 LDA #&1D
 STA CNT2
 LDA SSPR
 BNE L406F

.GOPLS

 JMP GOPL

.L406F

 JSR VCSU1

 LDA K3+2
 ORA K3+5
 ORA K3+8
 AND #&7F
 BNE GOPLS

 JSR TA2

 LDA Q
 STA K
 JSR TAS2

 LDY #&0A
 JSR TAS4

 BMI PH1

 CMP #&23
 BCC PH1

 LDY #&0A
 JSR TAS3

 CMP #&A2
 BCS PH3

 LDA K
 CMP #&9D
 BCC PH2

 LDA TYPE
 BMI PH3

.PH2

 JSR TAS6

 JSR TA151

.PH22

 LDX #&00
 STX INWK+28
 INX
 STX INWK+27
 RTS

.PH1

 JSR VCSU1

 JSR DCS1

 JSR DCS1

 JSR TAS2

 JSR TAS6

 JMP TA151

.TN11

 INC INWK+28
 LDA #&7F
 STA INWK+29
 BNE TN13

.PH3

 LDX #&00
 STX RAT2
 STX INWK+30
 LDA TYPE
 BPL PH32

 EOR XX15
 EOR Y1
 ASL A
 LDA #&02
 ROR A
 STA INWK+29
 LDA XX15
 ASL A
 CMP #&0C
 BCS PH22

 LDA Y1
 ASL A
 LDA #&02
 ROR A
 STA INWK+30
 LDA Y1
 ASL A
 CMP #&0C
 BCS PH22

.PH32

 STX INWK+29
 LDA INWK+22
 STA XX15
 LDA INWK+24
 STA Y1
 LDA INWK+26
 STA X2
 LDY #&10
 JSR TAS4

 ASL A
 CMP #&42
 BCS TN11

 JSR PH22

.TN13

 LDA K3+10
 BNE TNRTS

 ASL NEWB
 SEC
 ROR NEWB

.TNRTS

 RTS

.VCSU1

 LDA #&25
 STA V
 LDA #&04

.VCSUB

 STA V+1
 LDY #&02
 JSR TAS1

 LDY #&05
 JSR TAS1

 LDY #&08

.TAS1

 LDA (V),Y
 EOR #&80
 STA K+3
 DEY
 LDA (V),Y
 STA K+2
 DEY
 LDA (V),Y
 STA K+1
 STY U
 LDX U
 JSR MVT3

 LDY U
 STA K3+2,X
 LDA K+2
 STA K3+1,X
 LDA K+1
 STA K3,X
 RTS

.TAS4

 LDX L0425,Y
 STX Q
 LDA XX15
 JSR MULT12

 LDX L0427,Y
 STX Q
 LDA Y1
 JSR MAD

 STA S
 STX R
 LDX L0429,Y
 STX Q
 LDA X2
 JMP MAD

.TAS6

 LDA XX15
 EOR #&80
 STA XX15
 LDA Y1
 EOR #&80
 STA Y1
 LDA X2
 EOR #&80
 STA X2
 RTS

.DCS1

 JSR L418B

.L418B

 LDA L042F
 LDX #&00
 JSR TAS7

 LDA L0431
 LDX #&03
 JSR TAS7

 LDA L0433
 LDX #&06

.TAS7

 ASL A
 STA R
 LDA #&00
 ROR A
 EOR #&80
 EOR K3+2,X
 BMI TS71

 LDA R
 ADC K3,X
 STA K3,X
 BCC TS72

 INC K3+1,X

.TS72

 RTS

.TS71

 LDA K3,X
 SEC
 SBC R
 STA K3,X
 LDA K3+1,X
 SBC #&00
 STA K3+1,X
 BCS TS72

 LDA K3,X
 EOR #&FF
 ADC #&01
 STA K3,X
 LDA K3+1,X
 EOR #&FF
 ADC #&00
 STA K3+1,X
 LDA K3+2,X
 EOR #&80
 STA K3+2,X
 JMP TS72

.HITCH

 CLC
 LDA INWK+8
 BNE HI1

 LDA TYPE
 BMI HI1

 LDA INWK+31
 AND #&20
 ORA INWK+1
 ORA INWK+4
 BNE HI1

 LDA INWK
 JSR SQUA2

.L41F7

 STA S
L41F8 = L41F7+1
 LDA P
 STA R
 LDA INWK+3
 JSR SQUA2

 TAX
 LDA P
 ADC R
 STA R
 TXA
 ADC S
 BCS TN10

 STA S
 LDY #&02
 LDA (XX0),Y
 CMP S
 BNE HI1

 DEY
 LDA (XX0),Y
 CMP R

.HI1

 RTS

.TN10

 CLC
 RTS

.FRS1

 JSR ZINF

 LDA #&1C
 STA INWK+3
 LSR A
 STA INWK+6
 LDA #&80
 STA INWK+5
 LDA MSTG
 ASL A
 ORA #&80
 STA INWK+32

.fq1

 LDA #&60
 STA INWK+14
 ORA #&80
 STA INWK+22
 LDA DELTA
 ROL A
 STA INWK+27
 TXA
 JMP NWSHP

.FRMIS

 LDX #&01
 JSR FRS1

 BCC FR1

 LDX MSTG
 JSR GINF

 LDA FRIN,X
 JSR ANGRY

 LDY #&00
 JSR ABORT

 DEC NOMSL
 LDY #&08
 JSR NOISE

.ANGRY

 CMP #&02
 BEQ AN2

 LDY #&24
 LDA (INF),Y
 AND #&20
 BEQ L4274

 JSR AN2

.L4274

 LDY #&20
 LDA (INF),Y
 BEQ HI1

 ORA #&80
 STA (INF),Y
 LDY #&1C
 LDA #&02
 STA (INF),Y
 ASL A
 LDY #&1E
 STA (INF),Y
 LDA TYPE
 CMP #&0B
 BCC AN3

 LDY #&24
 LDA (INF),Y
 ORA #&04
 STA (INF),Y

.AN3

 RTS

.AN2

 LDA L0449
 ORA #&04
 STA L0449
 RTS

.FR1

 LDA #&C9
 JMP MESS

.SESCP

 LDX #&03

.L42A8

 LDA #&FE

.SFS1

 STA T1
 TXA
 PHA
 LDA XX0
 PHA
 LDA XX0+1
 PHA
 LDA INF
 PHA
 LDA INF+1
 PHA
 LDY #&24

.FRL2

 LDA INWK,Y
 STA XX3,Y
 LDA (INF),Y
 STA INWK,Y
 DEY
 BPL FRL2

 LDA TYPE
 CMP #&02
 BNE rx

 TXA
 PHA
 LDA #&20
 STA INWK+27
 LDX #&00
 LDA INWK+10
 JSR SFS2

 LDX #&03
 LDA INWK+12
 JSR SFS2

 LDX #&06
 LDA INWK+14
 JSR SFS2

 PLA
 TAX

.rx

 LDA T1
 STA INWK+32
 LSR INWK+29
 ASL INWK+29
 TXA
 CMP #&09
 BCS NOIL

 CMP #&04
 BCC NOIL

 PHA
 JSR DORND

 ASL A
 STA INWK+30
 TXA
 AND #&0F
 STA INWK+27
 LDA #&FF
 ROR A
 STA INWK+29
 PLA

.NOIL

 JSR NWSHP

 PLA
 STA INF+1
 PLA
 STA INF
 LDX #&24

.FRL3

 LDA XX3,X
 STA INWK,X
 DEX
 BPL FRL3

 PLA
 STA XX0+1
 PLA
 STA XX0
 PLA
 TAX
 RTS

.SFS2

 ASL A
 STA R
 LDA #&00
 ROR A
 JMP MVT1

.LL164

 LDY #&0A
 JSR NOISE

 LDY #&0B
 JSR NOISE

 LDA #&04
 STA HFX
 JSR HFS2

 STZ HFX
 RTS

.LAUN

 LDY #&08
 JSR NOISE

 LDA #&08

.HFS2

 STA STP
 LDA QQ11
 PHA
 LDA #&00
 JSR TT66

 PLA
 STA QQ11

.HFS1

 LDX #&80
 STX K3
 LDX #&60
 STX K4
 LDX #&00
 STX XX4
 STX K3+1
 STX K4+1

.HFL5

 JSR HFL1

 INC XX4
 LDX XX4
 CPX #&08
 BNE HFL5

 RTS

.HFL1

 LDA XX4
 AND #&07
 CLC
 ADC #&08
 STA K

.HFL2

 LDA #&01
 STA LSP
 JSR CIRCLE2

 ASL K
 BCS HF8

 LDA K
 CMP #&A0
 BCC HFL2

.HF8

 RTS

.STARS2

 LDA #&00
 CPX #&02
 ROR A
 STA RAT
 EOR #&80
 STA RAT2
 JSR ST2

 LDY NOSTM

.STL2

 LDA SZ,Y
 STA ZZ
 LSR A
 LSR A
 LSR A
 JSR DV41

 LDA P
 STA L009B
 EOR RAT2
 STA S
 LDA SXL,Y
 STA P
 LDA SX,Y
 STA XX15
 JSR ADD

 STA S
 STX R
 LDA SY,Y
 STA Y1
 EOR BET2
 LDX BET1
 JSR L44EA

 JSR ADD

 STX XX
 STA XX+1
 LDX SYL,Y
 STX R
 LDX Y1
 STX S
 LDX BET1
 EOR BET2+1
 JSR L44EA

 JSR ADD

 STX YY
 STA YY+1
 LDX ALP1
 EOR ALP2
 JSR L44EA

 STA Q
 LDA XX
 STA R
 LDA XX+1
 STA S
 EOR #&80
 JSR MAD

 STA XX+1
 TXA
 STA SXL,Y
 LDA YY
 STA R
 LDA YY+1
 STA S
 JSR MAD

 STA S
 STX R
 LDA #&00
 STA P
 LDA ALPHA
 JSR PIX1

 LDA XX+1
 STA SX,Y
 STA XX15
 AND #&7F
 EOR #&7F
 CMP L009B
 BCC KILL2

 BEQ KILL2

 LDA YY+1
 STA SY,Y
 STA Y1
 AND #&7F
 CMP #&74
 BCS ST5_UC

.STC2

 JSR PIXEL2

 DEY
 BEQ ST2

 JMP STL2

.ST2

 LDA ALPHA
 EOR RAT
 STA ALPHA
 LDA ALP2
 EOR RAT
 STA ALP2
 EOR #&80
 STA ALP2+1
 LDA BET2
 EOR RAT
 STA BET2
 EOR #&80
 STA BET2+1
 RTS

.KILL2

 JSR DORND

 STA Y1
 STA SY,Y
 LDA #&73
 ORA RAT
 STA XX15
 STA SX,Y
 BNE STF1

.ST5_UC

 JSR DORND

 STA XX15
 STA SX,Y
 LDA #&6E
 ORA ALP2+1
 STA Y1
 STA SY,Y

.STF1

 JSR DORND

 ORA #&08
 STA ZZ
 STA SZ,Y
 BNE STC2

.MU5

 STA K
 STA K+1
 STA K+2
 STA K+3
 CLC
 RTS

.MULT3

 STA R
 AND #&7F
 STA K+2
 LDA Q
 AND #&7F
 BEQ MU5

 SEC
 SBC #&01
 STA T
 LDA P+1
 LSR K+2
 ROR A
 STA K+1
 LDA P
 ROR A
 STA K
 LDA #&00
 LDX #&18

.MUL2

 BCC L44C9

 ADC T

.L44C9

 ROR A
 ROR K+2
 ROR K+1
 ROR K
 DEX
 BNE MUL2

 STA T
 LDA R
 EOR Q
 AND #&80
 ORA T
 STA K+3
 RTS

.MLS2

 LDX XX
 STX R
 LDX XX+1
 STX S

.MLS1

 LDX ALP1

.L44EA

 STX P
 TAX
 AND #&80
 STA T
 TXA
 AND #&7F
 BEQ MU6

 TAX
 DEX
 STX T1
 LDA #&00
 LSR P
 BCC L4502

 ADC T1

.L4502

 ROR A
 ROR P
 BCC L4509

 ADC T1

.L4509

 ROR A
 ROR P
 BCC L4510

 ADC T1

.L4510

 ROR A
 ROR P
 BCC L4517

 ADC T1

.L4517

 ROR A
 ROR P
 BCC L451E

 ADC T1

.L451E

 ROR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P
 ORA T
 RTS

.MU6

 STA P+1
 STA P
 RTS

.SQUA

 AND #&7F

.SQUA2

 STA P
 TAX
 BNE MU11

.MU1

 CLC
 STX P
 TXA
 RTS

.MLU1

 LDA SY,Y
 STA Y1

.MLU2

 AND #&7F
 STA P

.MULTU

 LDX Q
 BEQ MU1

.MU11

 DEX
 STX T
 LDA #&00
 TAX
 LSR P
 BCC L4557

 ADC T

.L4557

 ROR A
 ROR P
 BCC L455E

 ADC T

.L455E

 ROR A
 ROR P
 BCC L4565

 ADC T

.L4565

 ROR A
 ROR P
 BCC L456C

 ADC T

.L456C

 ROR A
 ROR P
 BCC L4573

 ADC T

.L4573

 ROR A
 ROR P
 BCC L457A

 ADC T

.L457A

 ROR A
 ROR P
 BCC L4581

 ADC T

.L4581

 ROR A
 ROR P
 BCC L4588

 ADC T

.L4588

 ROR A
 ROR P
 RTS

.FMLTU2

 AND #&1F
 TAX
 LDA SNE,X
 STA Q
 LDA K

.FMLTU

 STX P
 STA widget
 TAX
 BEQ MU3

 LDA logL,X
 LDX Q
 BEQ MU3again

 CLC
 ADC logL,X
 LDA log,X
 LDX widget
 ADC log,X
 BCC MU3again

 TAX
 LDA antilog,X
 LDX P
 RTS

.MU3again

 LDA #&00

.MU3

 LDX P
 RTS

.L45BE

 STX Q

.MLTU2

 EOR #&FF
 LSR A
 STA P+1
 LDA #&00
 LDX #&10
 ROR P

.MUL7

 BCS MU21

 ADC Q
 ROR A
 ROR P+1
 ROR P
 DEX
 BNE MUL7

 RTS

.MU21

 LSR A
 ROR P+1
 ROR P
 DEX
 BNE MUL7

 RTS

 LDX ALP1
 STX P

.MUT2

 LDX XX+1
 STX S

.MUT1

 LDX XX
 STX R

.MULT1

 TAX
 AND #&7F
 LSR A
 STA P
 TXA
 EOR Q
 AND #&80
 STA T
 LDA Q
 AND #&7F
 BEQ mu10

 TAX
 DEX
 STX T1
 LDA #&00
 TAX
 BCC L460B

 ADC T1

.L460B

 ROR A
 ROR P
 BCC L4612

 ADC T1

.L4612

 ROR A
 ROR P
 BCC L4619

 ADC T1

.L4619

 ROR A
 ROR P
 BCC L4620

 ADC T1

.L4620

 ROR A
 ROR P
 BCC L4627

 ADC T1

.L4627

 ROR A
 ROR P
 BCC L462E

 ADC T1

.L462E

 ROR A
 ROR P
 BCC L4635

 ADC T1

.L4635

 ROR A
 ROR P
 LSR A
 ROR P
 ORA T
 RTS

.mu10

 STA P
 RTS

.MULT12

 JSR MULT1

 STA S
 LDA P
 STA R
 RTS

.TAS3

 LDX INWK,Y
 STX Q
 LDA XX15
 JSR MULT12

 LDX INWK+2,Y
 STX Q
 LDA Y1
 JSR MAD

 STA S
 STX R
 LDX INWK+4,Y
 STX Q
 LDA X2

.MAD

 JSR MULT1

.ADD

 STA T1
 AND #&80
 STA T
 EOR S
 BMI MU8

 LDA R
 CLC
 ADC P
 TAX
 LDA S
 ADC T1
 ORA T
 RTS

.MU8

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
 BCS MU9

 STA U
 TXA
 EOR #&FF
 ADC #&01
 TAX
 LDA #&00
 SBC U
 ORA #&80

.MU9

 EOR T
 RTS

.TIS1

 STX Q
 EOR #&80
 JSR MAD

 TAX
 AND #&80
 STA T
 TXA
 AND #&7F
 LDX #&FE
 STX T1

.DVL3

 ASL A
 CMP #&60
 BCC DV4

 SBC #&60

.DV4

 ROL T1
 BCS DVL3

 LDA T1
 ORA T
 RTS

.DV42

 LDA SZ,Y

.DV41

 STA Q
 LDA DELTA

.DVID4

 ASL A
 STA P
 LDA #&00
 ROL A
 CMP Q
 BCC L46DC

 SBC Q

.L46DC

 ROL P
 ROL A
 CMP Q
 BCC L46E5

 SBC Q

.L46E5

 ROL P
 ROL A
 CMP Q
 BCC L46EE

 SBC Q

.L46EE

 ROL P
 ROL A
 CMP Q
 BCC L46F7

 SBC Q

.L46F7

 ROL P
 ROL A
 CMP Q
 BCC L4700

 SBC Q

.L4700

 ROL P
 ROL A
 CMP Q
 BCC L4709

 SBC Q

.L4709

 ROL P
 ROL A
 CMP Q
 BCC L4712

 SBC Q

.L4712

 ROL P
 ROL A
 CMP Q
 BCC L471B

 SBC Q

.L471B

 ROL P
 LDX #&00
 STA widget
 TAX
 BEQ LLfix_DUPLICATE

 LDA logL,X
 LDX Q
 SEC
 SBC logL,X
 LDX widget
 LDA log,X
 LDX Q
 SBC log,X
 BCS LL2_DUPLICATE

 TAX
 LDA antilog,X

.LLfix_DUPLICATE

 STA R
 RTS

.LL2_DUPLICATE

 LDA #&FF
 STA R
 RTS

.DVID3B2

 STA P+2
 LDA INWK+6
 ORA #&01
 STA Q
 LDA INWK+7
 STA R
 LDA INWK+8
 STA S
 LDA P
 ORA #&01
 STA P
 LDA P+2
 EOR S
 AND #&80
 STA T
 LDY #&00
 LDA P+2
 AND #&7F

.DVL9

 CMP #&40
 BCS DV14

 ASL P
 ROL P+1
 ROL A
 INY
 BNE DVL9

.DV14

 STA P+2
 LDA S
 AND #&7F

.DVL6

 DEY
 ASL Q
 ROL R
 ROL A
 BPL DVL6

 STA Q
 LDA #&FE
 STA R
 LDA P+2

.LL31_DUPLICATE

 ASL A
 BCS LL29_DUPLICATE

 CMP Q
 BCC L4794

 SBC Q

.L4794

 ROL R
 BCS LL31_DUPLICATE

 JMP LL31_DUPLICATE_RTS

.LL29_DUPLICATE

 SBC Q
 SEC
 ROL R
 BCS LL31_DUPLICATE

 LDA R

.LL31_DUPLICATE_RTS

 LDA #&00
 STA K+1
 STA K+2
 STA K+3
 TYA
 BPL DV12

 LDA R

.DVL8

 ASL A
 ROL K+1
 ROL K+2
 ROL K+3
 INY
 BNE DVL8

 STA K
 LDA K+3
 ORA T
 STA K+3
 RTS

.DV13

 LDA R
 STA K
 LDA T
 STA K+3
 RTS

.DV12

 BEQ DV13

 LDA R

.DVL10

 LSR A
 DEY
 BNE DVL10

 STA K
 LDA T
 STA K+3
 RTS

.cntr

 LDA auto
 BNE cnt2_lc

 LDA DAMP
 BNE RE1

.cnt2_lc

 TXA
 BPL BUMP

 DEX
 BMI L485E

.BUMP

 INX
 BNE RE1

 DEX
 BEQ BUMP

.RE1

 RTS

.BUMP2

 STA T
 TXA
 CLC
 ADC T
 TAX
 BCC RE2

 LDX #&FF

.RE2

 BPL djd1

.L4800

 LDA T
 RTS

.REDU2

 STA T
 TXA
 SEC
 SBC T
 TAX
 BCS RE3

 LDX #&01

.RE3

 BPL L4800

.djd1

 LDA DJD
 BNE L4800

 LDX #&80
 BMI L4800

.ARCTAN

 LDA P
 EOR Q
 STA T1
 LDA Q
 BEQ AR2

 ASL A
 STA Q
 LDA P
 ASL A
 CMP Q
 BCS AR1

 JSR ARS1

 SEC

.AR4

 LDX T1
 BMI AR3

 RTS

.AR1

 LDX Q
 STA Q
 STX P
 TXA
 JSR ARS1

 STA T
 LDA #&40
 SBC T
 BCS AR4

.AR2

 LDA #&3F
 RTS

.AR3

 STA T
 LDA #&80
 SBC T
 RTS

.ARS1

 JSR LL28

 LDA R
 LSR A
 LSR A
 LSR A
 TAX
 LDA ACT,X

.L485E

 RTS

.LASLI

 JSR DORND

 AND #&07
 ADC #&5C
 STA LASY
 JSR DORND

 AND #&07
 ADC #&7C
 STA LASX
 LDA GNTMP
 ADC #&08
 STA GNTMP
 JSR DENGY

.LASLI2

 LDA QQ11
 BNE L485E

 LDA #&F0
 STA COL
 LDA #&20
 LDY #&E0
 DEC LASY
 DEC LASY
 JSR las_lc

 INC LASY
 INC LASY
 LDA #&30
 LDY #&D0

.las_lc

 STA X2
 LDA LASX
 STA XX15
 LDA LASY
 STA Y1
 LDA #&BF
 STA Y2
 JSR LL30

 LDA LASX
 STA XX15
 LDA LASY
 STA Y1
 STY X2
 LDA #&BF
 STA Y2
 JMP LL30

.PDESC

 LDA QQ8
 ORA QQ8+1
 BNE PD1

 LDA QQ12
 BPL PD1

 LDY #&00

.PDL1

 LDA RUPLA-1,Y
 CMP ZZ
 BNE PD2

 LDA RUGAL-1,Y
 AND #&7F
 CMP GCNT
 BNE PD2

 LDA RUGAL-1,Y
 BMI PD3

 LDA TP
 LSR A
 BCC PD1

 JSR MT14

 LDA #&01
 EQUB &2C

.PD3

 LDA #&B0
 JSR DETOK2

 TYA
 JSR DETOK3

 LDA #&B1
 BNE PD4

.PD2

 DEY
 BNE PDL1

.PD1

 LDX #&03

.PDL1_BRACES

 LDA QQ15+2,X
 STA RAND,X
 DEX
 BPL PDL1_BRACES

 LDA #&05

.PD4

 JMP DETOK

.BRIEF2

 LDA TP
 ORA #&04
 STA TP
 LDA #&0B

.BRP

 LDX #&FF
 STX COL
 JSR DETOK

 JMP BAY

.BRIEF3

 LDA TP
 AND #&F0
 ORA #&0A
 STA TP
 LDA #&DE
 BNE BRP

.DEBRIEF2

 LDA TP
 ORA #&04
 STA TP
 LDA #&02
 STA ENGY
 INC TALLY+1
 LDA #&DF
 BNE BRP

.DEBRIEF

 LSR TP
 ASL TP
 LDX #&50
 LDY #&C3
 JSR MCASH

 LDA #&0F

.BRPS

 BNE BRP

.BRIEF

 LSR TP
 SEC
 ROL TP
 JSR BRIS

 JSR ZINF

 LDA #&1F
 STA TYPE
 JSR NWSHP

 LDA #&01
 JSR DOXC

 STA INWK+7
 LDA #&0D
 JSR TT66

 LDA #&40
 STA MCNT

.BRL1

 LDX #&7F
 STX INWK+29
 STX INWK+30
 JSR LL9

 JSR MVEIT

 DEC MCNT
 BNE BRL1

.BRL2

 LSR INWK
 INC INWK+6
 BEQ BR2

 INC INWK+6
 BEQ BR2

 LDX INWK+3
 INX
 CPX #&78
 BCC L499D

 LDX #&78

.L499D

 STX INWK+3
 JSR LL9

 JSR MVEIT

 DEC MCNT
 JMP BRL2

.BR2

 INC INWK+7
 JSR PAS1

 LDA #&0A
 BNE BRPS

.BRIS

 LDA #&D8
 JSR DETOK

 LDY #&64
 JMP DELAY

.PAUSE

 JSR PAS1

.L49C0

 BNE PAUSE

L49C1 = L49C0+1

.PAL1

 JSR PAS1

 BEQ PAL1

 LDA #&00
 STA INWK+31
 LDA #&01
 JSR TT66

 JSR LL9

.MT23

 LDA #&0A
 EQUB &2C

.MT29

 LDA #6
 STA YC
 LDA #&FF
 STA COL
 JMP MT13

.PAS1

 LDA #&78
 STA INWK+3
 LDA #&00
 STA INWK
 STA INWK+6
 LDA #&02
 STA INWK+7
 JSR LL9

 JSR MVEIT

 JMP RDKEY

.PAUSE2

 JSR RDKEY

 BNE PAUSE2

 JSR RDKEY

 BEQ PAUSE2

 RTS

.GINF

 TXA
 ASL A
 TAY
 LDA UNIV,Y
 STA INF
 LDA UNIV+1,Y
 STA INF+1
 RTS

.ping

 LDX #&01

.pl1

 LDA QQ0,X
 STA QQ9,X
 DEX
 BPL pl1

 RTS

.MTIN

 EQUB &10

 EQUB &15,&1A,&1F,&9B,&A0,&2E,&A5,&24
 EQUB &29,&3D,&33,&38,&AA,&42,&47,&4C
 EQUB &51,&56,&8C,&60,&65,&87,&82,&5B
 EQUB &6A,&B4,&B9,&BE,&E1,&E6,&EB,&F0
 EQUB &F5,&FA,&73,&78,&7D

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

.tnpr1

 STA QQ29
 LDA #&01

.tnpr

 PHA
 LDX #&0C
 CPX QQ29
 BCC kg

.Tml

 ADC QQ20,X
 DEX
 BPL Tml

 ADC L1265
 CMP CRGO
 PLA
 RTS

.kg

 LDY QQ29
 ADC QQ20,Y
 CMP #&C8
 PLA
 RTS

.DOXC

 STA XC
 RTS

.DOYC

 STA YC
 RTS

 INC YC
 RTS

.TRADEMODE

 JSR TT66

 JSR FLKB

.L4A88

 LDA #&30
 JSR SETVDU19

 LDA #&FF
 STA COL
 RTS

.TT20

 JSR L4A95

.L4A95

 JSR TT54

.TT54

 LDA QQ15
 CLC
 ADC QQ15+2
 TAX
 LDA QQ15+1
 ADC QQ15+3
 TAY
 LDA QQ15+2
 STA QQ15
 LDA QQ15+3
 STA QQ15+1
 LDA QQ15+5
 STA QQ15+3
 LDA QQ15+4
 STA QQ15+2
 CLC
 TXA
 ADC QQ15+2
 STA QQ15+4
 TYA
 ADC QQ15+3
 STA QQ15+5
 RTS

.TT146

 LDA QQ8
 ORA QQ8+1
 BNE TT63

 INC YC
 RTS

.TT63

 LDA #&BF
 JSR TT68

 LDX QQ8
 LDY QQ8+1
 SEC
 JSR pr5

 LDA #&C3

.TT60

 JSR TT27

.TTX69

 INC YC

.TT69

 LDA #&80
 STA QQ17

.TT67

 LDA #&0C
 JMP TT27

.TT70

 LDA #&AD
 JSR TT27

 JMP TT72

.spc

 JSR TT27

 JMP TT162

.TT25

 LDA #&01
 JSR TRADEMODE

 LDA #&09
 STA XC
 LDA #&A3
 JSR NLIN3

 JSR TTX69

 JSR TT146

 LDA #&C2
 JSR TT68

 LDA QQ3
 CLC
 ADC #&01
 LSR A
 CMP #&02
 BEQ TT70

 LDA QQ3
 BCC TT71

 SBC #&05
 CLC

.TT71

 ADC #&AA
 JSR TT27

.TT72

 LDA QQ3
 LSR A
 LSR A
 CLC
 ADC #&A8
 JSR TT60

 LDA #&A2
 JSR TT68

 LDA QQ4
 CLC
 ADC #&B1
 JSR TT60

 LDA #&C4
 JSR TT68

 LDX QQ5
 INX
 CLC
 JSR pr2

 JSR TTX69

 LDA #&C0
 JSR TT68

 SEC
 LDX QQ6
 JSR pr2

 LDA #&C6
 JSR TT60

 LDA #&28
 JSR TT27

 LDA QQ15+4
 BMI TT75

 LDA #&BC
 JSR TT27

 JMP TT76

.TT75

 LDA QQ15+5
 LSR A
 LSR A
 PHA
 AND #&07
 CMP #&03
 BCS TT205

 ADC #&E3
 JSR spc

.TT205

 PLA
 LSR A
 LSR A
 LSR A
 CMP #&06
 BCS TT206

 ADC #&E6
 JSR spc

.TT206

 LDA QQ15+3
 EOR QQ15+1
 AND #&07
 STA QQ19
 CMP #&06
 BCS TT207

 ADC #&EC
 JSR spc

.TT207

 LDA QQ15+5
 AND #&03
 CLC
 ADC QQ19
 AND #&07
 ADC #&F2
 JSR TT27

.TT76

 LDA #&53
 JSR TT27

 LDA #&29
 JSR TT60

 LDA #&C1
 JSR TT68

 LDX QQ7
 LDY QQ7+1
 JSR pr6

 JSR TT162

 STZ QQ17
 LDA #&4D
 JSR TT27

 LDA #&E2
 JSR TT60

 LDA #&FA
 JSR TT68

 LDA QQ15+5
 LDX QQ15+3
 AND #&0F
 CLC
 ADC #&0B
 TAY
 JSR pr5

 JSR TT162

 LDA #&6B
 JSR DASC

 LDA #&6D
 JSR DASC

 JSR TTX69

 JMP PDESC

.TT24

 LDA QQ15+1
 AND #&07
 STA QQ3
 LDA QQ15+2
 LSR A
 LSR A
 LSR A
 AND #&07
 STA QQ4
 LSR A
 BNE TT77

 LDA QQ3
 ORA #&02
 STA QQ3

.TT77

 LDA QQ3
 EOR #&07
 CLC
 STA QQ5
 LDA QQ15+3
 AND #&03
 ADC QQ5
 STA QQ5
 LDA QQ4
 LSR A
 ADC QQ5
 STA QQ5
 ASL A
 ASL A
 ADC QQ3
 ADC QQ4
 ADC #&01
 STA QQ6
 LDA QQ3
 EOR #&07
 ADC #&03
 STA P
 LDA QQ4
 ADC #&04
 STA Q
 JSR MULTU

 LDA QQ6
 STA Q
 JSR MULTU

 ASL P
 ROL A
 ASL P
 ROL A
 ASL P
 ROL A
 STA QQ7+1
 LDA P
 STA QQ7
 RTS

.TT22

 LDA #&40
 JSR TT66

 LDA #&10
 JSR SETVDU19

 LDA #&FF
 STA COL
 LDA #&07
 STA XC
 JSR TT81

 LDA #&C7
 JSR TT27

 JSR NLIN

 LDA #&99
 JSR L359D

 JSR TT14

 LDX #&00

.TT83

 STX XSAV
 LDX QQ15+3
 LDY QQ15+4
 TYA
 ORA #&50
 STA ZZ
 LDA #&0F
 STA COL
 LDA QQ15+1
 JSR L4A42

 CLC
 ADC #&18
 JSR PIXEL

 JSR TT20

 LDX XSAV
 INX
 BNE TT83

 LDA QQ9
 JSR L4A44

 STA QQ19
 LDA QQ10
 JSR L4A42

 STA QQ19+1
 LDA #&04
 STA QQ19+2
 LDA #&AF
 STA COL

.TT15

 LDA #&18
 LDX QQ11
 BPL TT178

 LDA #&00

.TT178

 STA QQ19+5
 LDA QQ19
 SEC
 SBC QQ19+2
 BIT QQ11
 BMI TT84

 BCC L4CC7

 CMP #&02
 BCS TT84

.L4CC7

 LDA #&02

.TT84

 STA XX15
 LDA QQ19
 CLC
 ADC QQ19+2
 BCS L4CD6

 CMP #&FE
 BCC TT85

.L4CD6

 LDA #&FE

.TT85

 STA X2
 LDA QQ19+1
 CLC
 ADC QQ19+5
 STA Y1
 JSR HLOIN3

 LDA QQ19+1
 SEC
 SBC QQ19+2
 BCS TT86

 LDA #&00

.TT86

 CLC
 ADC QQ19+5
 STA Y1
 LDA QQ19+1
 CLC
 ADC QQ19+2
 ADC QQ19+5
 CMP #&98
 BCC TT87

 LDX QQ11
 BMI TT87

 LDA #&98

.TT87

 STA Y2
 LDA QQ19
 STA XX15
 STA X2
 JMP LL30

.TT126

 LDA #&68
 STA QQ19
 LDA #&5A
 STA QQ19+1
 LDA #&10
 STA QQ19+2
 LDA #&AF
 STA COL
 JSR TT15

 LDA QQ14
 JSR L4A43

 STA K
 JMP TT128

.TT14

 LDA QQ11
 BMI TT126

 LDA QQ14
 LSR A
 JSR L4A42

 STA K
 LDA QQ0
 JSR L4A44

 STA QQ19
 LDA QQ1
 JSR L4A42

 STA QQ19+1
 LDA #&07
 STA QQ19+2
 LDA #&FF
 STA COL
 JSR TT15

 LDA QQ19+1
 CLC
 ADC #&18
 STA QQ19+1

.TT128

 LDA QQ19
 STA K3
 LDA QQ19+1
 STA K4
 STZ K4+1
 STZ K3+1
 LDX #&01
 STX LSP
 INX
 STX STP
 LDA #&F0
 STA COL
 JMP CIRCLE2

.TT219

 LDA #&02
 JSR TRADEMODE

 JSR TT163

 LDA #&80
 STA QQ17
 LDA #&00
 STA QQ29

.TT220

 JSR TT151

 LDA QQ25
 BNE TT224

 JMP TT222

.TQ4

 LDY #&B0

.Tc

 JSR TT162

 TYA
 JSR prq

 JSR dn2

.TT224

 JSR CLYNS

 LDA #&CC
 JSR TT27

 LDA QQ29
 CLC
 ADC #&D0
 JSR TT27

 LDA #&2F
 JSR TT27

 JSR TT152

 LDA #&3F
 JSR TT27

 JSR TT67

 LDX #&00
 STX R
 LDX #&0C
 STX T1
 JSR gnum

 BCS TQ4

 STA P
 JSR tnpr

 LDY #&CE
 LDA R
 BEQ L4DD8

 BCS Tc

.L4DD8

 LDA QQ24
 STA Q
 JSR GCASH

 JSR LCASH

 LDY #&C5
 BCC Tc

 LDY QQ29
 LDA R
 PHA
 CLC
 ADC QQ20,Y
 STA QQ20,Y
 LDA AVL,Y
 SEC
 SBC R
 STA AVL,Y
 PLA
 BEQ TT222

 JSR dn

.TT222

 LDA QQ29
 CLC
 ADC #&05
 JSR DOYC

 LDA #&00
 JSR DOXC

 INC QQ29
 LDA QQ29
 CMP #&11
 BCS BAY2

 JMP TT220

.BAY2

 LDA #&89
 JMP FRCE

.gnum

 LDA #&F0
 STA COL
 LDX #&00
 STX R
 LDX #&0C
 STX T1

.TT223

 JSR TT217

 LDX R
 BNE NWDAV2

 CMP #&59
 BEQ NWDAV1

 CMP #&4E
 BEQ NWDAV3

.NWDAV2

 STA Q
 SEC
 SBC #&30
 BCC OUT

 CMP #&0A
 BCS BAY2

 STA S
 LDA R
 CMP #&1A
 BCS OUT_DUPLICATE

 ASL A
 STA T
 ASL A
 ASL A
 ADC T
 ADC S
 BCS OUT_DUPLICATE

 STA R
 CMP QQ25
 BEQ TT226

 BCS OUT_DUPLICATE

.TT226

 LDA Q
 JSR DASC

 DEC T1
 BNE TT223

.OUT

 LDA #&FF
 STA COL
 LDA R
 RTS

.NWDAV1

 JSR DASC

 LDA QQ25
 STA R
 JMP OUT

.NWDAV3

 JSR DASC

 STZ R
 JMP OUT

.NWDAV4

 JSR TT67

 LDA #&B0
 JSR prq

 JSR dn2

 LDY QQ29
 JMP NWDAVxx

.OUT_DUPLICATE

 LDA Q
 JSR DASC

 SEC
 JMP OUT

.TT208

 LDA #&04
 JSR TRADEMODE

 LDA #&0A
 STA XC
 LDA #&CD
 JSR TT27

 LDA #&CE
 JSR NLIN3

 JSR TT67

.TT210

 LDY #&00

.TT211

 STY QQ29

.NWDAVxx

 LDX QQ20,Y
 BEQ TT212

 TYA
 ASL A
 ASL A
 TAY
 LDA L6E6E,Y
 STA QQ19+1
 TXA
 PHA
 JSR TT69

 CLC
 LDA QQ29
 ADC #&D0
 JSR TT27

 LDA #&0E
 JSR DOXC

 PLA
 TAX
 STA QQ25
 CLC
 JSR pr2

 JSR TT152

 LDA QQ11
 CMP #&04
 BNE TT212

 LDA #&CD
 JSR TT27

 LDA #&CE
 JSR DETOK

 JSR gnum

 BEQ TT212

 BCS NWDAV4

 LDA QQ29
 LDX #&FF
 STX QQ17
 JSR TT151

 LDY QQ29
 LDA QQ20,Y
 SEC
 SBC R
 STA QQ20,Y
 LDA R
 STA P
 LDA QQ24
 STA Q
 JSR GCASH

 JSR MCASH

 LDA #&00
 STA QQ17

.TT212

 LDY QQ29
 INY
 CPY #&11
 BCC TT211

 LDA QQ11
 CMP #&04
 BNE L4F3E

 JSR dn2

 JMP BAY2

.L4F3E

 JSR TT69

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

.TT213

 LDA #&08
 JSR TRADEMODE

 LDA #&0B
 STA XC
 LDA #&A4
 JSR TT60

 JSR NLIN4

 JSR fwl

 LDA CRGO
 CMP #&1A
 BCC L4F96

 LDA #&6B
 JSR TT27

.L4F96

 JMP TT210

 JSR TT27

 LDA #&CE
 JSR DETOK

 JSR TT217

 ORA #&20
 CMP #&79
 BEQ TT218

 LDA #&6E
 JMP DASC

.TT218

 JSR DASC

 SEC
 RTS

.TT16

 TXA
 PHA
 DEY
 TYA
 EOR #&FF
 PHA
 JSR WSCAN

 JSR TT103

 PLA
 STA QQ19+3
 LDA QQ10
 JSR TT123

 LDA QQ19+4
 STA QQ10
 STA QQ19+1
 PLA
 STA QQ19+3
 LDA QQ9
 JSR TT123

 LDA QQ19+4
 STA QQ9
 STA QQ19

.TT103

 LDA #&AF
 STA COL
 LDA QQ11
 BMI TT105

 LDA QQ9
 JSR L4A44

 STA QQ19
 LDA QQ10
 JSR L4A42

 STA QQ19+1
 LDA #&04
 STA QQ19+2
 JMP TT15

.TT123

 STA QQ19+4
 CLC
 ADC QQ19+3
 LDX QQ19+3
 BMI TT124

 BCC TT125

 RTS

.TT124

 BCC TT180

.TT125

 STA QQ19+4

.TT180

 RTS

.TT105

 LDA QQ9
 SEC
 SBC QQ0
 BCS L5017

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

 ASL A
 ASL A
 CLC
 ADC #&68
 JSR L4A43

 STA QQ19
 LDA QQ10
 SEC
 SBC QQ1
 BCS L503D

 EOR #&FF
 ADC #&01

.L503D

 CMP #&23
 BCS TT180

 LDA QQ10
 SEC
 SBC QQ1
 ASL A
 CLC
 ADC #&5A
 JSR L4A43

 STA QQ19+1
 LDA #&08
 STA QQ19+2
 LDA #&AF
 STA COL
 JMP TT15

.TT23

 LDA #&80
 JSR TT66

 LDA #&10
 JSR SETVDU19

 LDA #&FF
 STA COL
 LDA #&07
 STA XC
 LDA #&BE
 JSR NLIN3

 JSR TT14

 JSR TT103

 JSR TT81

 LDA #&FF
 STA COL
 LDA #&00
 STA XX20
 LDX #&18

.EE3

 STA INWK,X
 DEX
 BPL EE3

.TT182

 LDA QQ15+3
 SEC
 SBC QQ0
 BCS TT184

 EOR #&FF
 ADC #&01

.TT184

 CMP #&1D
 BCS L50FB

 LDA QQ15+1
 SEC
 SBC QQ1
 BCS TT186

 EOR #&FF
 ADC #&01

.TT186

 CMP #&28
 BCS L50FB

 LDA QQ15+3
 SEC
 SBC QQ0
 ASL A
 ASL A
 ADC #&68
 JSR L4A43

 STA XX12
 LSR A
 LSR A
 LSR A
 INC A
 STA XC
 LDA QQ15+1
 SEC
 SBC QQ1
 ASL A
 ADC #&5A
 JSR L4A43

 STA K4
 LSR A
 LSR A
 LSR A
 TAY
 LDX INWK,Y
 BEQ EE4

 INY
 LDX INWK,Y
 BEQ EE4

 DEY
 DEY
 LDX INWK,Y
 BNE ee1

.EE4

 STY YC
 CPY #&03
 BCC TT187

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

 LDA #&FF
 STA INWK,Y
 LDA #&80
 STA QQ17
 JSR cpl

.ee1

 LDA #&00
 STA K3+1
 STA K4+1
 STA K+1
 LDA XX12
 STA K3
 LDA QQ15+5
 AND #&01
 ADC #&02
 STA K
 JSR FLFLLS

 JSR SUN

 JSR FLFLLS

 LDA #&FF
 STA COL

.TT187

 JSR TT20

 INC XX20
 BEQ L5134

 JMP TT182

.L5134

 RTS

.TT81

 LDX #&05

.L5137

 LDA QQ21,X
 STA QQ15,X
 DEX
 BPL L5137

 RTS

.TT111

 JSR TT81

 LDY #&7F
 STY T
 LDA #&00
 STA U

.TT130

 LDA QQ15+3
 SEC
 SBC QQ9
 BCS TT132

 EOR #&FF
 ADC #&01

.TT132

 LSR A
 STA S
 LDA QQ15+1
 SEC
 SBC QQ10
 BCS TT134

 EOR #&FF
 ADC #&01

.TT134

 LSR A
 CLC
 ADC S
 CMP T
 BCS TT135

 STA T
 LDX #&05

.TT136

 LDA QQ15,X
 STA QQ19,X
 DEX
 BPL TT136

 LDA U
 STA ZZ

.TT135

 JSR TT20

 INC U
 BNE TT130

 LDX #&05

.TT137

 LDA QQ19,X
 STA QQ15,X
 DEX
 BPL TT137

 LDA QQ15+1
 STA QQ10
 LDA QQ15+3
 STA QQ9

.L5193

 SEC
 SBC QQ0
 BCS TT139

 EOR #&FF
 ADC #&01

.TT139

 JSR SQUA2

 STA K+1
 LDA P
 STA K
 LDA QQ15+1
 SEC
 SBC QQ1
 BCS TT141

 EOR #&FF
 ADC #&01

.TT141

 LSR A
 JSR SQUA2

 PHA
 LDA P
 CLC
 ADC K
 STA Q
 PLA
 ADC K+1
 BCC L51C5

 LDA #&FF

.L51C5

 STA R
 JSR LL5

 LDA Q
 ASL A
 LDX #&00
 STX QQ8+1
 ROL QQ8+1
 ASL A
 ROL QQ8+1
 STA QQ8
 JMP TT24

.hy6

 JSR CLYNS

 LDA #&0F
 STA XC
 LDA #&F0
 STA COL
 LDA #&CD
 JMP DETOK

.hyp

 LDA QQ12
 BNE hy6

 LDA QQ22+1
 BEQ L51F4

 RTS

.L51F4

 LDA #&FF
 STA COL
 JSR CTRL

 BMI Ghy

 LDA QQ11
 BEQ TTX110

 AND #&C0
 BNE L5206

 RTS

.L5206

 JSR hm

.TTX111

 LDA QQ8
 ORA QQ8+1
 BNE L5210

 RTS

.L5210

 LDX #&05

.sob

 LDA QQ15,X
 STA safehouse,X
 DEX
 BPL sob

 LDA #&07
 STA XC
 LDA #&16
 STA YC
 LDA #&00
 STA QQ17
 LDA #&BD
 JSR TT27

 LDA QQ8+1
 BNE goTT147

 LDA QQ14
 CMP QQ8
 BCS L5239

.goTT147

 JMP TT147

.L5239

 LDA #&2D
 JSR TT27

 JSR cpl

 LDA #&0F

.wW2

 STA QQ22+1
 STA QQ22
 TAX
 JMP ee3_lc

.TTX110

 JSR TT111

 JMP TTX111

.Ghy

 LDX GHYP
 BEQ L527A

 INX
 STX GHYP
 STX FIST
 LDA #&02
 JSR wW2

 LDX #&05
 INC GCNT
 LDA GCNT
 AND #&F7
 STA GCNT

.G1

 LDA QQ21,X
 ASL A
 ROL QQ21,X
 DEX
 BPL G1

.zZ_lc

 LDA #&60
L527A = zZ_lc+1
 STA QQ9
 STA QQ10
 JSR TT110

 JSR TT111

 LDX #&05

.dumdeedum

 LDA QQ15,X
 STA safehouse,X
 DEX
 BPL dumdeedum

 LDX #&00
 STX QQ8
 STX QQ8+1
 LDA #&74
 JSR MESS

.jmp

 LDA QQ9
 STA QQ0
 LDA QQ10
 STA QQ1
 RTS

.ee3_lc

 LDA #&F0
 STA COL
 LDA #&01
 STA XC
 STA YC
 LDY #&00
 CLC
 LDA #&03
 JMP TT11

.pr6

 CLC

.pr5

 LDA #&05
 JMP TT11

.TT147

 LDA #&CA

.prq

 JSR TT27

 LDA #&3F
 JMP TT27

.TT151q

 PLA
 RTS

.TT151

 PHA
 STA QQ19+4
 ASL A
 ASL A
 STA QQ19
 LDA MJ
 BNE TT151q

 LDA #&01
 JSR DOXC

 PLA
 ADC #&D0
 JSR TT27

 LDA #&0E
 STA XC
 LDX QQ19
 LDA L6E6E,X
 STA QQ19+1
 LDA QQ26
 AND L6E70,X
 CLC
 ADC L6E6D,X
 STA QQ24
 JSR TT152

 JSR var

 LDA QQ19+1
 BMI TT155

 LDA QQ24
 ADC QQ19+3
 JMP TT156

.TT155

 LDA QQ24
 SEC
 SBC QQ19+3

.TT156

 STA QQ24
 STA P
 LDA #&00
 JSR GC2

 SEC
 JSR pr5

 LDY QQ19+4
 LDA #&05
 LDX AVL,Y
 STX QQ25
 CLC
 BEQ TT172

 JSR L3AA5

 JMP TT152

.TT172

 LDA #&19
 JSR DOXC

 LDA #&2D
 BNE L5349

.TT152

 LDA QQ19+1
 AND #&60
 BEQ TT160

 CMP #&20
 BEQ TT161

 JSR TT16a

.TT162

 LDA #&20

.L5349

 JMP TT27

.TT160

 LDA #&74
 JSR DASC

 BCC TT162

.TT161

 LDA #&6B
 JSR DASC

.TT16a

 LDA #&67
 JMP DASC

.TT163

 LDA #&11
 JSR DOXC

 LDA #&FF
 BNE L5349

.TT167

 LDA #&10
 JSR TRADEMODE

 LDA #&05
 STA XC
 LDA #&A7
 JSR NLIN3

 LDA #&03
 STA YC
 JSR TT163

 LDA #&06
 STA YC
 LDA #&00
 STA QQ29

.TT168

 LDX #&80
 STX QQ17
 JSR TT151

 INC YC
 INC QQ29
 LDA QQ29
 CMP #&11
 BCC TT168

 RTS

.var

 LDA QQ19+1
 AND #&1F
 LDY QQ28
 STA QQ19+2
 CLC
 LDA #&00
 STA AVL+16

.TT153

 DEY
 BMI TT154

 ADC QQ19+2
 JMP TT153

.TT154

 STA QQ19+3
 RTS

 JSR TT111

.L53B5

 JSR jmp

 LDX #&05

.TT112

 LDA safehouse,X
 STA QQ2,X
 DEX
 BPL TT112

 INX
 STX EV
 LDA QQ3
 STA QQ28
 LDA QQ5
 STA tek
 LDA QQ4
 STA gov
 JSR DORND

 STA QQ26
 LDX #&00
 STX XX4

.hy9

 LDA L6E6E,X
 STA QQ19+1
 JSR var

 LDA L6E70,X
 AND QQ26
 CLC
 ADC L6E6F,X
 LDY QQ19+1
 BMI TT157

 SEC
 SBC QQ19+3
 JMP TT158

.TT157

 CLC
 ADC QQ19+3

.TT158

 BPL TT159

 LDA #&00

.TT159

 LDY XX4
 AND #&3F
 STA AVL,Y
 INY
 TYA
 STA XX4
 ASL A
 ASL A
 TAX
 CMP #&3F
 BCC hy9

 RTS

.GTHG

 JSR Ze

 LDA #&FF
 STA INWK+32
 LDA #&1D
 JSR NWSHP

 LDA #&1E
 JMP NWSHP

.ptg

 LSR COK
 SEC
 ROL COK

.MJP

 LDA #&03
 JSR TT66

 JSR LL164

 JSR RES2

 STY MJ

.MJP1

 JSR GTHG

 LDA #&02
 CMP L0E6B
 BCS MJP1

 STA NOSTM
 LDX #&00
 JSR LOOK1

 LDA QQ1
 EOR #&1F
 STA QQ1
 RTS

.RTS111

 RTS

.TT18

 LDA QQ14
 SEC
 SBC QQ8
 BCS L5461

 LDA #&00

.L5461

 STA QQ14
 LDA QQ11
 BNE ee5

 JSR TT66

 JSR LL164

.ee5

 JSR CTRL

 AND PATG
 BMI ptg

 JSR DORND

 CMP #&FD
 BCS MJP

 JSR L53B5

 JSR RES2

 JSR L5A24

 LDA QQ11
 AND #&3F
 BNE RTS111

 JSR TTX66

 LDA QQ11
 BNE TT114

 INC QQ11

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

.bay_lc

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

 BEQ bay_lc

 BCS bay_lc

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
 BNE yy_lc

.L58E3

 ASL T
 ROL A
 ASL T
 ROL A
 SEC
 ROL A

.yy_lc

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
 BNE PLF2_UC

 CMP P+1
 BCC PLF2_UC

 LDA P+1
 BNE PLF2_UC

 LDA #&01

.PLF2_UC

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

 JSR t_lc

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
 JMP TT26

.L632D

 ADC #&36
 JMP TT26

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
 BCS mt1_lc

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

.mt1_lc

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
 BEQ T95_UC

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
 BNE ee2_lc

 JSR TT103

 JSR ping

 JMP TT103

.ee2_lc

 JSR TT16

.TT107

 LDA QQ22+1
 BEQ t95

 DEC QQ22
 BNE t95

 LDX QQ22+1
 DEX
 JSR ee3_lc

 LDA #&05
 STA QQ22
 LDX QQ22+1
 JSR ee3_lc

 DEC QQ22+1
 BNE t95

 JMP TT18

.t95

 RTS

.T95_UC

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

 JSR TT26

 INY
 LDA (&FD),Y
 BNE BRBRLOOP

 JSR t_lc

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

 JSR TT26

 BCC L691B

.L6945

 STA INWK+5,Y
 LDA #&0C
 JSR TT26

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
 JSR L4A88

 LDA #&01
 JSR DETOK

 JSR t_lc

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

 JSR t_lc

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

 JSR t_lc

 ORA #&10
 JSR TT26

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

 JSR t_lc

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

.t_lc

 LDY #&02
 JSR DELAY

 JSR RDKEY

 BNE t_lc

.t2

 JSR RDKEY

 BEQ t2

 LDY YSAV
 TAX

.out_lc

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
 BCC out_lc

 LDA #&FD
 JMP TT27

.OUCH

 JSR DORND

 BMI out_lc

 CPX #&16
 BCS out_lc

 LDA QQ20,X
 BEQ out_lc

 LDA DLY
 BNE out_lc

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

.L6E6D

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

.ll51_lc

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
 BCC ll51_lc

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

.ll91_lc

 LDA INWK,X
 STA XX18,X
 DEX
 BPL ll91_lc

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
 BCC ll81_lc

 INC V+1

.ll81_lc

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
 JSR L45BE

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
 JSR L45BE

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
 JSR L45BE

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

 JSR ee3_lc

.OLDBOX

 LDA QQ11
 BNE tt66_lc

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

.tt66_lc

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
 JSR L42A8

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

