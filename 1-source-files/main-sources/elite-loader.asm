\ ******************************************************************************
\
\ BBC MASTER ELITE LOADER SOURCE
\
\ BBC Master Elite was written by Ian Bell and David Braben and is copyright
\ Acornsoft 1986
\
\ The code on this site has been reconstructed from a disassembly of the version
\ released on Ian Bell's personal website at http://www.elitehomepage.org/
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://www.bbcelite.com/terminology
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * M128Elt.bin
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 CPU 1                  \ Switch to 65SC12 assembly, as this code runs on the
                        \ BBC Master

 _SNG47                 = (_VARIANT = 1)
 _COMPACT               = (_VARIANT = 2)

 GUARD &C000            \ Guard against assembling over MOS memory

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

 CODE% = &0E00          \ The address where the code will be run

 LOAD% = &0E00          \ The address where the code will be loaded

 N% = 67                \ N% is set to the number of bytes in the VDU table, so
                        \ we can loop through them below

 S% = &2C6C             \ The address of the main entry point workspace in the
                        \ main game code

 VIA = &FE00            \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

 OSWRCH = &FFEE         \ The address for the OSWRCH routine

 OSBYTE = &FFF4         \ The address for the OSBYTE routine

 OSCLI = &FFF7          \ The address for the OSCLI routine

\ ******************************************************************************
\
\       Name: ZP
\       Type: Workspace
\    Address: &0070 to &0075
\   Category: Workspaces
\    Summary: Important variables used by the loader
\
\ ******************************************************************************

 ORG &0002

IF _COMPACT

.MOS

 SKIP 1                 \ Determines whether we are running on a Master Compact
                        \
                        \   * 0 = This is a Master Compact
                        \
                        \   * &FF = This is not a Master Compact

ENDIF

 ORG &0070

.ZP

 SKIP 2                 \ Stores addresses used for moving content around

.P

 SKIP 1                 \ Temporary storage, used in a number of places

.Q

 SKIP 1                 \ Temporary storage, used in a number of places

.YY

 SKIP 1                 \ Temporary storage, used in a number of places

.T

 SKIP 1                 \ Temporary storage, used in a number of places

 ORG &00F4

.LATCH

 SKIP 2                 \ The RAM copy of the currently selected paged ROM/RAM
                        \ in SHEILA &30

\ ******************************************************************************
\
\ ELITE LOADER
\
\ ******************************************************************************

 ORG CODE%

\ ******************************************************************************
\
\       Name: B%
\       Type: Variable
\   Category: Drawing the screen
\    Summary: VDU commands for setting the square mode 1 screen
\  Deep dive: The split-screen mode in BBC Micro Elite
\             Drawing monochrome pixels in mode 4
\
\ ------------------------------------------------------------------------------
\
\ This block contains the bytes that get written by OSWRCH to set up the screen
\ mode (this is equivalent to using the VDU statement in BASIC).
\
\ It defines the whole screen using a square, monochrome mode 1 configuration;
\ the mode 2 part for the dashboard is implemented in the IRQ1 routine.
\
\ The top part of Elite's screen mode is based on mode 1 but with the following
\ differences:
\
\   * 64 columns, 31 rows (256 x 248 pixels) rather than 80, 32
\
\   * The horizontal sync position is at character 90 rather than 98, which
\     pushes the screen to the right (which centres it as it's not as wide as
\     the normal screen modes)
\
\   * Screen memory goes from &4000 to &7EFF
\
\   * In the Master version of Elite, the screen mode is actually based on mode
\     129 rather than mode 1, so shadow RAM (known as LYNNE) is used to store
\     the screen memory, though in all other respects the screen mode is the
\     same as if it were based on mode 1
\
\   * The text window is 1 row high and 13 columns wide, and is at (2, 16)
\
\   * The cursor is disabled
\
\ This almost-square mode 1 variant makes life a lot easier when drawing to the
\ screen, as there are 256 pixels on each row (or, to put it in screen memory
\ terms, there are two pages of memory per row of pixels).
\
\ There is also an interrupt-driven routine that switches the bytes-per-pixel
\ setting from that of mode 1 to that of mode 2, when the raster reaches the
\ split between the space view and the dashboard. See the deep dive on "The
\ split-screen mode" for details.
\
\ ******************************************************************************

.B%

 EQUB 22, 129           \ Switch to screen mode 129

 EQUB 28                \ Define a text window as follows:
 EQUB 2, 17, 15, 16     \
                        \   * Left = 2
                        \   * Right = 15
                        \   * Top = 16
                        \   * Bottom = 17
                        \
                        \ i.e. 1 row high, 13 columns wide at (2, 16)

 EQUB 23, 0, 6, 31      \ Set 6845 register R6 = 31
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "vertical displayed" register, and sets
                        \ the number of displayed character rows to 31. For
                        \ comparison, this value is 32 for standard modes 1 and
                        \ 2, but we claw back the last row for storing code just
                        \ above the end of screen memory

 EQUB 23, 0, 12, &08    \ Set 6845 register R12 = &08 and R13 = &00
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This sets 6845 registers (R12 R13) = &0800 to point
 EQUB 23, 0, 13, &00    \ to the start of screen memory in terms of character
 EQUB 0, 0, 0           \ rows. There are 8 pixel lines in each character row,
 EQUB 0, 0, 0           \ so to get the actual address of the start of screen
                        \ memory, we multiply by 8:
                        \
                        \   &0800 * 8 = &4000
                        \
                        \ So this sets the start of screen memory to &4000

 EQUB 23, 0, 1, 64      \ Set 6845 register R1 = 64
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "horizontal displayed" register, which
                        \ defines the number of character blocks per horizontal
                        \ character row. For comparison, this value is 80 for
                        \ modes 1 and 2, but our custom screen is not as wide at
                        \ only 64 character blocks across

 EQUB 23, 0, 2, 90      \ Set 6845 register R2 = 90
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "horizontal sync position" register, which
                        \ defines the position of the horizontal sync pulse on
                        \ the horizontal line in terms of character widths from
                        \ the left-hand side of the screen. For comparison this
                        \ is 98 for modes 1 and 2, but needs to be adjusted for
                        \ our custom screen's width

 EQUB 23, 0, 10, 32     \ Set 6845 register R10 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "cursor start" register, so this sets the
                        \ cursor start line at 0, effectively disabling the
                        \ cursor

\ ******************************************************************************
\
\       Name: Elite loader
\       Type: Subroutine
\   Category: Loader
\    Summary: Perform a number of OS calls, check for sideways RAM, load and
\             move the main game data, and load and run the main game code
\
\ ------------------------------------------------------------------------------
\
\ The loader loads and moves the following files. There is no decryption at this
\ stage - that is all done by the main game code.
\
\   * The BDATA game data file is loaded into main memory at &1300-&54FF, and is
\     then moved as follows:
\
\       * &1300-&21FF is moved to &7000-&7EFF in screen memory (i.e. shadow RAM)
\         for the dashboard
\
\       * &2200-&54FF is moved to &7F00-&B1FF in main memory, where the main
\         game code will decrypt it
\
\   * The main game code file is loaded into main memory at &1300 and the game
\     is started by jumping to &2C6C
\
\ The main game code file is called BCODE in the Master release and ELITE in the
\ Master Compact release. BCODE loads into &1300-&7F47, while ELITE loads into
\ &1300-&7FEC.
\
\ The main game code is then responsible for decrypting BDATA (from &8000 to
\ &B1FF) and BCODE/ELITE (from the end of the DEEOR routine to the end of the
\ file).
\
\ ******************************************************************************

.ENTRY

 LDA #16                \ Call OSBYTE with A = 16 and X = 0 to set the ADC to
 LDX #0                 \ sample no channels from the joystick/Bitstik
 JSR OSBYTE

IF _COMPACT

 LDA #129               \ Call OSBYTE with A = 129, X = 0 and Y = &FF to detect
 LDX #0                 \ the machine type. This call is undocumented and is not
 LDY #&FF               \ the recommended way to determine the machine type
 JSR OSBYTE             \ (OSBYTE 0 is the correct way), but this call returns
                        \ the following:
                        \
                        \   * X = Y = &F5 if this is a Master Compact with MOS 5

 LDA #&FF               \ Set A = &FF, the value we want to store in the MOS
                        \ flag if this is not a Master Compact

 CPX #&F5               \ If X <> &F5, skip the following instruction as this is
 BNE P%+4               \ a Master Compact

 LDA #0                 \ This is a Master Compact, so set A = 0

 STA MOS                \ Store the value of A in MOS, which will be 0 if this
                        \ is a Master Compact, or &FF if it isn't

ENDIF

 LDA #200               \ Call OSBYTE with A = 200, X = 1 and Y = 0 to disable
 LDX #1                 \ the ESCAPE key and disable memory clearing if the
 JSR OSB                \ BREAK key is pressed

 LDA #13                \ Call OSBYTE with A = 13, X = 0 and Y = 0 to disable
 LDX #0                 \ the "output buffer empty" event
 JSR OSB

 LDA #144               \ Call OSBYTE with A = 144, X = 255 and Y = 0 to move
 LDX #255               \ the screen down one line and turn screen interlace on
 LDY #0
 JSR OSBYTE

 LDA #144               \ Repeat the above command, which has the effect of
 LDX #255               \ setting the interlace to the original value, as the
 JSR OSBYTE             \ OSBYTE call above returns the original setting in Y

 LDA #225               \ Call OSBYTE with A = 225, X = 128 and Y = 0 to set
 LDX #128               \ the function keys to return ASCII codes for SHIFT-fn
 JSR OSB                \ keys (i.e. add 128)

 LDA #13                \ Call OSBYTE with A = 13, X = 2 and Y = 0 to disable
 LDX #2                 \ the "character entering buffer" event
 JSR OSB

 LDA #LO(B%)            \ Set ZP(1 0) to point to the VDU code table at B%
 STA ZP
 LDA #HI(B%)
 STA ZP+1

 LDY #0                 \ We are now going to send the N% VDU bytes in the table
                        \ at B% to OSWRCH to set up the special mode 1 screen
                        \ that forms the basis for the split-screen mode

.LOOP

 LDA (ZP),Y             \ Pass the Y-th byte of the B% table to OSWRCH
 JSR OSWRCH

 INY                    \ Increment the loop counter

 CPY #N%                \ Loop back for the next byte until we have done them
 BNE LOOP               \ all (the number of bytes was set in N% above)

 LDA #%00001111         \ Set the Access Control latch at SHEILA &34, as
 STA VIA+&34            \ follows:
                        \
                        \   * Bit 7 = IRR = 0: Do not IRQ the CPU with this
                        \   * Bit 6 = TST = 0: Must be set to 0
                        \   * Bit 5 = IFJ = 0: &FC00-&FDFF maps to the 1Mhz bus
                        \   * Bit 4 = ITU = 0: CPU can access external co-pro
                        \   * Bit 3 = Y = 1: &C000-&DFFF set to 8K private RAM
                        \   * Bit 2 = X = 1: &3000-&7FFF set to 20K shadow RAM
                        \   * Bit 1 = E = 1: All shadow RAM locations accessible
                        \   * Bit 0 = D = 1: Display shadow RAM as screen memory
                        \
                        \ In short, this switches the screen memory, which is in
                        \ shadow RAM, into the memory map at &3000-&7FFF, so now
                        \ we can poke directly to the screen memory, and it also
                        \ maps the filing system RAM space into &C000-&DFFF
                        \ (HAZEL), in place of the MOS VDU workspace

 JSR PLL1               \ Call PLL1 to draw Saturn

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control latch at
 STA VIA+&34            \ SHEILA &34, which changes the following:
                        \
                        \   * Bit 2 = X = 0: &3000-&7FFF set to main RAM
                        \   * Bit 1 = E = 0: VDU shadow RAM locations accessible
                        \
                        \ In short, this switches the screen memory, which is in
                        \ shadow RAM, out of the memory map, so &3000-&7FFF is
                        \ now mapped to main RAM and we can't update the screen

 LDA #4                 \ Call OSBYTE with A = 4, X = 1 and Y = 0 to disable
 LDX #1                 \ cursor editing, so the cursor keys return ASCII values
 JSR OSB                \ and can therefore be used in-game

 LDA #9                 \ Call OSBYTE with A = 9, X = 0 and Y = 0 to disable
 LDX #0                 \ flashing colours
 JSR OSB

 LDX #LO(MESS1)         \ Set (Y X) to point to MESS1 ("L.BDATA FFFF1300")
 LDY #HI(MESS1)

 JSR OSCLI              \ Call OSCLI to run the OS command in MESS1, which
                        \ loads the BDATA file to address &1300-&54FF, appending
                        \ &FFFF to the address to make sure it loads in the main
                        \ BBC Master rather than getting passed across the Tube
                        \ to the Second Processor, if one is fitted

 LDA #6                 \ Set the RAM copy of the currently selected paged ROM
 STA LATCH              \ to 6, so it matches the paged ROM selection latch at
                        \ SHEILA &30 that we are about to set

 LDA VIA+&30            \ Set bits 0-3 of the ROM Select latch at SHEILA &30 to
 AND #%11110000         \ 6, to switch sideways RAM bank 6 into &8000-&BFFF in
 ORA #6                 \ main memory
 STA VIA+&30

 LDA #%10101010         \ Set A and location &8000 to %10101010
 STA &8000

 LSR A                  \ Shift A and location &8000 right
 LSR &8000

 CMP &8000              \ If A matches location &8000 (i.e. both now contain
 BEQ OK                 \ %01010101) then jump to OK, as ROM bank 6 is writable
                        \ and does indeed contain sideways RAM rather than a
                        \ paged ROM, which is what we need for running the game

 BRK                    \ Otherwise we can't run the game, so terminate the
                        \ loader with the following error message

 EQUB 0                 \ Error number

 EQUB 22, 7             \ Switch to mode 7 and clear the screen

 EQUS "ELITE needs RAM in slot #6"

 EQUB 0                 \ End of error message

.OK

 LDA #%00001111         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA &34 to switch screen memory into &3000-&7FFF

                        \ We now want to copy &F pages of memory (&F00 bytes)
                        \ from &1300-&21FF to &7000-&7EFF in screen memory

 LDX #&F                \ Set a page counter in X to copy &F pages

 LDA #&13               \ Set ZP(1 0) = &1300
 STA ZP+1
 STZ ZP

 STZ P                  \ Set P(1 0) = &7000
 LDA #&70
 STA P+1

 LDY #0                 \ Set Y = 0 to act as a byte counter within each page

.MPL1

 LDA (ZP),Y             \ Copy the Y-th byte of the memory block at ZP(1 0) to
 STA (P),Y              \ the Y-th byte of the memory block at P(1 0)

 DEY                    \ Decrement the byte counter

 BNE MPL1               \ Loop back to copy the next byte until we have copied a
                        \ whole page of 256 bytes

 INC ZP+1               \ Increment the high bytes of both ZP(1 0) and P(1 0)
 INC P+1                \ so we copy the next page in memory

 DEX                    \ Decrement the page counter

 BNE MPL1               \ Loop back to copy the next page until we have done all
                        \ &F of them

 LDA #%00001001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA &34 to switch main memory back into &3000-&7FFF

                        \ We now want to copy &33 pages of memory (&3300 bytes)
                        \ from &2200-&54FF to &7F00-&B1FF in main memory

                        \ --- Mod: Code removed for Compendium: --------------->

\LDX #&33               \ Set a page counter in X to copy &33 pages

                        \ --- And replaced by: -------------------------------->

IF _SNG47

 LDX #&34               \ Set a page counter in X to copy &34 pages

ELIF _COMPACT

 LDX #&35               \ Set a page counter in X to copy &35 pages, plus one
                        \ extra page for the flicker-free planet code that we
                        \ have added at &B300

ENDIF

                        \ --- End of replacement ------------------------------>

.MPL2

 LDA (ZP),Y             \ Copy the Y-th byte of the memory block at ZP(1 0) to
 STA (P),Y              \ the Y-th byte of the memory block at P(1 0)

 DEY                    \ Decrement the byte counter

 BNE MPL2               \ Loop back to copy the next byte until we have copied a
                        \ whole page of 256 bytes

 INC ZP+1               \ Increment the high bytes of both ZP(1 0) and P(1 0)
 INC P+1                \ so we copy the next page in memory

 DEX                    \ Decrement the page counter

 BNE MPL2               \ Loop back to copy the next page until we have done all
                        \ &33 of them

 CLI                    \ Enable interrupts

 LDX #LO(MESS2)         \ Set (Y X) to point to MESS2 ("L.BCODE FFFF1300" in the
 LDY #HI(MESS2)         \ Master release, or "L.ELITE FFFF1300" in the Master
                        \ Compact release)

 JSR OSCLI              \ Call OSCLI to run the OS command in MESS2, which loads
                        \ the BCODE/ELITE file to address &1300-&7F48, appending
                        \ &FFFF to the address to make sure it loads in the main
                        \ BBC Master rather than getting passed across the Tube
                        \ to the Second Processor, if one is fitted

 LDX #LO(MESS3)         \ Set (Y X) to point to MESS3 ("DIR E")
 LDY #HI(MESS3)

 JSR OSCLI              \ Call OSCLI to run the OS command in MESS3, which
                        \ changes the disc directory to E

 LDA #6                 \ Set the RAM copy of the currently selected paged ROM
 STA LATCH              \ to 6, so it matches the paged ROM selection latch at
                        \ SHEILA &30 that we are about to set

 LDA VIA+&30            \ Switch ROM bank 6 into memory by setting bits 0-3 of
 AND #%11110000         \ the ROM selection latch at SHEILA &30 to 6
 ORA #6
 STA VIA+&30

 JMP S%                 \ Jump to the start of the main game code at S%, which
                        \ we just loaded in the BCODE/ELITE file

\ ******************************************************************************
\
\       Name: PLL1 (Part 1 of 3)
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw Saturn on the loading screen (draw the planet)
\  Deep dive: Drawing Saturn on the loading screen
\
\ ******************************************************************************

.PLL1

                        \ The following loop iterates CNT(1 0) times, i.e. &300
                        \ or 768 times, and draws the planet part of the
                        \ loading screen's Saturn

 STA RAND+1             \ Store A in RAND+1 among the hard-coded random seeds
                        \ in RAND. We set A to %00001111 before calling the PLL1
                        \ routine, so this sets the random number generator so
                        \ that it always generates the same numbers every time,
                        \ which is probably not what was intended (other
                        \ versions read the 6522 System VIA timer to use as a
                        \ seed, which is random). As a result, if you look at
                        \ the Saturn on the Master loading screen, it is always
                        \ exactly the same, every time you run the game

 JSR DORND              \ Set A and X to random numbers, say A = r1

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r1^2

 STA ZP+1               \ Set ZP(1 0) = (A P)
 LDA P                  \             = r1^2
 STA ZP

 JSR DORND              \ Set A and X to random numbers, say A = r2

 STA YY                 \ Set YY = A
                        \        = r2

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r2^2

 TAX                    \ Set (X P) = (A P)
                        \           = r2^2

 LDA P                  \ Set (A ZP) = (X P) + ZP(1 0)
 ADC ZP                 \
 STA ZP                 \ first adding the low bytes

 TXA                    \ And then adding the high bytes
 ADC ZP+1

 BCS PLC1               \ If the addition overflowed, jump down to PLC1 to skip
                        \ to the next pixel

 STA ZP+1               \ Set ZP(1 0) = (A ZP)
                        \             = r1^2 + r2^2

 LDA #1                 \ Set ZP(1 0) = &4001 - ZP(1 0) - (1 - C)
 SBC ZP                 \             = 128^2 - ZP(1 0)
 STA ZP                 \
                        \ (as the C flag is clear), first subtracting the low
                        \ bytes

 LDA #&40               \ And then subtracting the high bytes
 SBC ZP+1
 STA ZP+1

 BCC PLC1               \ If the subtraction underflowed, jump down to PLC1 to
                        \ skip to the next pixel

                        \ If we get here, then both calculations fitted into
                        \ 16 bits, and we have:
                        \
                        \   ZP(1 0) = 128^2 - (r1^2 + r2^2)
                        \
                        \ where ZP(1 0) >= 0

 JSR ROOT               \ Set ZP = SQRT(ZP(1 0))

 LDA ZP                 \ Set X = ZP >> 1
 LSR A                  \       = SQRT(128^2 - (a^2 + b^2)) / 2
 TAX

 LDA YY                 \ Set A = YY
                        \       = r2

 CMP #128               \ If YY >= 128, set the C flag (so the C flag is now set
                        \ to bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 6 and 7 are now the same, i.e. A is a random number in
                        \ one of these ranges:
                        \
                        \   %00000000 - %00111111  = 0 to 63    (r2 = 0 - 127)
                        \   %11000000 - %11111111  = 192 to 255 (r2 = 128 - 255)
                        \
                        \ The PIX routine flips bit 7 of A before drawing, and
                        \ that makes -A in these ranges:
                        \
                        \   %10000000 - %10111111  = 128-191
                        \   %01000000 - %01111111  = 64-127
                        \
                        \ so that's in the range 64 to 191

 JSR PIX                \ Draw a pixel at screen coordinate (X, -A), i.e. at
                        \
                        \   (ZP / 2, -A)
                        \
                        \ where ZP = SQRT(128^2 - (r1^2 + r2^2))
                        \
                        \ So this is the same as plotting at (x, y) where:
                        \
                        \   r1 = random number from 0 to 255
                        \   r2 = random number from 0 to 255
                        \   (r1^2 + r2^2) < 128^2
                        \
                        \   y = r2, squished into 64 to 191 by negation
                        \
                        \   x = SQRT(128^2 - (r1^2 + r2^2)) / 2
                        \
                        \ which is what we want

.PLC1

 DEC CNT                \ Decrement the counter in CNT (the low byte)

 BNE PLL1               \ Loop back to PLL1 until CNT = 0

 DEC CNT+1              \ Decrement the counter in CNT+1 (the high byte)

 BNE PLL1               \ Loop back to PLL1 until CNT+1 = 0

\ ******************************************************************************
\
\       Name: PLL1 (Part 2 of 3)
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw Saturn on the loading screen (draw the stars)
\  Deep dive: Drawing Saturn on the loading screen
\
\ ******************************************************************************

                        \ The following loop iterates CNT2(1 0) times, i.e. &1DD
                        \ or 477 times, and draws the background stars on the
                        \ loading screen

.PLL2

 JSR DORND              \ Set A and X to random numbers, say A = r3

 TAX                    \ Set X = A
                        \       = r3

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r3^2

 STA ZP+1               \ Set ZP+1 = A
                        \          = r3^2 / 256

 JSR DORND              \ Set A and X to random numbers, say A = r4

 STA YY                 \ Set YY = r4

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r4^2

 ADC ZP+1               \ Set A = A + r3^2 / 256
                        \       = r4^2 / 256 + r3^2 / 256
                        \       = (r3^2 + r4^2) / 256

 CMP #&11               \ If A < 17, jump down to PLC2 to skip to the next pixel
 BCC PLC2

 LDA YY                 \ Set A = r4

 JSR PIX                \ Draw a pixel at screen coordinate (X, -A), i.e. at
                        \ (r3, -r4), where (r3^2 + r4^2) / 256 >= 17
                        \
                        \ Negating a random number from 0 to 255 still gives a
                        \ random number from 0 to 255, so this is the same as
                        \ plotting at (x, y) where:
                        \
                        \   x = random number from 0 to 255
                        \   y = random number from 0 to 255
                        \   (x^2 + y^2) div 256 >= 17
                        \
                        \ which is what we want

.PLC2

 DEC CNT2               \ Decrement the counter in CNT2 (the low byte)

 BNE PLL2               \ Loop back to PLL2 until CNT2 = 0

 DEC CNT2+1             \ Decrement the counter in CNT2+1 (the high byte)

 BNE PLL2               \ Loop back to PLL2 until CNT2+1 = 0

\ ******************************************************************************
\
\       Name: PLL1 (Part 3 of 3)
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw Saturn on the loading screen (draw the rings)
\  Deep dive: Drawing Saturn on the loading screen
\
\ ******************************************************************************

                        \ The following loop iterates CNT3(1 0) times, i.e. &333
                        \ or 819 times, and draws the rings around the loading
                        \ screen's Saturn

.PLL3

 JSR DORND              \ Set A and X to random numbers, say A = r5

 STA ZP                 \ Set ZP = r5

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r5^2

 STA ZP+1               \ Set ZP+1 = A
                        \          = r5^2 / 256

 JSR DORND              \ Set A and X to random numbers, say A = r6

 STA YY                 \ Set YY = r6

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r6^2

 STA T                  \ Set T = A
                        \       = r6^2 / 256

 ADC ZP+1               \ Set ZP+1 = A + r5^2 / 256
 STA ZP+1               \          = r6^2 / 256 + r5^2 / 256
                        \          = (r5^2 + r6^2) / 256

 LDA ZP                 \ Set A = ZP
                        \       = r5

 CMP #128               \ If A >= 128, set the C flag (so the C flag is now set
                        \ to bit 7 of ZP, i.e. bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 6 and 7 are now the same

 CMP #128               \ If A >= 128, set the C flag (so again, the C flag is
                        \ set to bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 5-7 are now the same, i.e. A is a random number in one
                        \ of these ranges:
                        \
                        \   %00000000 - %00011111  = 0-31
                        \   %11100000 - %11111111  = 224-255
                        \
                        \ In terms of signed 8-bit integers, this is a random
                        \ number from -32 to 31. Let's call it r7

 ADC YY                 \ Set A = A + YY
                        \       = r7 + r6

 TAX                    \ Set X = A
                        \       = r6 + r7

 JSR SQUA2              \ Set (A P) = A * A
                        \           = (r6 + r7)^2

 TAY                    \ Set Y = A
                        \       = (r6 + r7)^2 / 256

 ADC ZP+1               \ Set A = A + ZP+1
                        \       = (r6 + r7)^2 / 256 + (r5^2 + r6^2) / 256
                        \       = ((r6 + r7)^2 + r5^2 + r6^2) / 256

 BCS PLC3               \ If the addition overflowed, jump down to PLC3 to skip
                        \ to the next pixel

 CMP #80                \ If A >= 80, jump down to PLC3 to skip to the next
 BCS PLC3               \ pixel

 CMP #32                \ If A < 32, jump down to PLC3 to skip to the next pixel
 BCC PLC3

 TYA                    \ Set A = Y + T
 ADC T                  \       = (r6 + r7)^2 / 256 + r6^2 / 256
                        \       = ((r6 + r7)^2 + r6^2) / 256

 CMP #16                \ If A >= 16, skip to PL1 to plot the pixel
 BCS PL1

 LDA ZP                 \ If ZP is positive (i.e. r5 < 128), jump down to PLC3
 BPL PLC3               \ to skip to the next pixel

.PL1

                        \ If we get here then the following is true:
                        \
                        \   32 <= ((r6 + r7)^2 + r5^2 + r6^2) / 256 < 80
                        \
                        \ and either this is true:
                        \
                        \   ((r6 + r7)^2 + r6^2) / 256 >= 16
                        \
                        \ or both these are true:
                        \
                        \   ((r6 + r7)^2 + r6^2) / 256 < 16
                        \   r5 >= 128

 LDA YY                 \ Set A = YY
                        \       = r6

 JSR PIX                \ Draw a pixel at screen coordinate (X, -A), where:
                        \
                        \   X = (random -32 to 31) + r6
                        \   A = r6
                        \
                        \ Negating a random number from 0 to 255 still gives a
                        \ random number from 0 to 255, so this is the same as
                        \ plotting at (x, y) where:
                        \
                        \   r5 = random number from 0 to 255
                        \   r6 = random number from 0 to 255
                        \   r7 = r5, squashed into -32 to 31
                        \
                        \   x = r6 + r7
                        \   y = r6
                        \
                        \   32 <= ((r6 + r7)^2 + r5^2 + r6^2) / 256 < 80
                        \
                        \   Either: ((r6 + r7)^2 + r6^2) / 256 >= 16
                        \
                        \   Or:     ((r6 + r7)^2 + r6^2) / 256 <  16
                        \           r5 >= 128
                        \
                        \ which is what we want

.PLC3

 DEC CNT3               \ Decrement the counter in CNT3 (the low byte)

 BNE PLL3               \ Loop back to PLL3 until CNT3 = 0

 DEC CNT3+1             \ Decrement the counter in CNT3+1 (the high byte)

 BNE PLL3               \ Loop back to PLL3 until CNT3+1 = 0

\ ******************************************************************************
\
\       Name: DORND
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Generate random numbers
\  Deep dive: Generating random numbers
\             Fixing ship positions
\
\ ------------------------------------------------------------------------------
\
\ Set A and X to random numbers (though note that X is set to the random number
\ that was returned in A the last time DORND was called).
\
\ The C and V flags are also set randomly.
\
\ This is a simplified version of the DORND routine in the main game code. It
\ swaps the two calculations around and omits the ROL A instruction, but is
\ otherwise very similar. See the DORND routine in the main game code for more
\ details.
\
\ ******************************************************************************

.DORND

 LDA RAND+1             \ r1´ = r1 + r3 + C
 TAX                    \ r3´ = r1
 ADC RAND+3
 STA RAND+1
 STX RAND+3

 LDA RAND               \ X = r2´ = r0
 TAX                    \ A = r0´ = r0 + r2
 ADC RAND+2
 STA RAND
 STX RAND+2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: RAND
\       Type: Variable
\   Category: Drawing planets
\    Summary: The random number seed used for drawing Saturn
\
\ ******************************************************************************

.RAND

 EQUD &34785349

\ ******************************************************************************
\
\       Name: SQUA2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = A * A
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of signed 8-bit numbers:
\
\   (A P) = A * A
\
\ This uses a similar approach to routine SQUA2 in the main game code, which
\ itself uses the MU11 routine to do the multiplication. However, this version
\ first ensures that A is positive, so it can support signed numbers.
\
\ ******************************************************************************

.SQUA2

 BPL SQUA               \ If A > 0, jump to SQUA

 EOR #&FF               \ Otherwise we need to negate A for the SQUA algorithm
 CLC                    \ to work, so we do this using two's complement, by
 ADC #1                 \ setting A = ~A + 1

.SQUA

 STA Q                  \ Set Q = A and P = A

 STA P                  \ Set P = A

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDY #8                 \ Set up a counter in Y to count the 8 bits in P

 LSR P                  \ Set P = P >> 1
                        \ and C flag = bit 0 of P

.SQL1

 BCC SQ1                \ If C (i.e. the next bit from P) is set, do the
 CLC                    \ addition for this bit of P:
 ADC Q                  \
                        \   A = A + Q

.SQ1

 ROR A                  \ Shift A right to catch the next digit of our result,
                        \ which the next ROR sticks into the left end of P while
                        \ also extracting the next bit of P

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation into the C flag

 DEY                    \ Decrement the loop counter

 BNE SQL1               \ Loop back for the next bit until P has been rotated
                        \ all the way

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PIX
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a single pixel at a specific coordinate
\
\ ------------------------------------------------------------------------------
\
\ Draw a pixel at screen coordinate (X, -A). The sign bit of A gets flipped
\ before drawing, and then the routine uses the same approach as the PIXEL
\ routine in the main game code, except it plots a single pixel from TWOS
\ instead of a two pixel dash from TWOS2. This applies to the top part of the
\ screen (the four-colour mode 1 space view).
\
\ See the PIXEL routine in the main game code for more details.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The screen x-coordinate of the pixel to draw
\
\   A                   The screen y-coordinate of the pixel to draw, negated
\
\ ******************************************************************************

.PIX

 TAY                    \ Copy A into Y, for use later

 EOR #%10000000         \ Flip the sign of A

 LSR A                  \ Set ZP+1 = &40 + 2 * (A >> 3)
 LSR A
 LSR A
 ASL A
 ORA #&40
 STA ZP+1

 TXA                    \ Set (C ZP) = (X >> 2) * 8
 EOR #%10000000         \
 AND #%11111100         \ i.e. the C flag contains bit 8 of the calculation
 ASL A
 STA ZP

 BCC P%+4               \ If the C flag is set, i.e. bit 8 of the above
 INC ZP+1               \ calculation was a 1, increment ZP+1 so that ZP(1 0)
                        \ points to the second page in this character row (i.e.
                        \ the right half of the row)

 TYA                    \ Set Y = Y AND %111
 AND #%00000111
 TAY

 TXA                    \ Set X = X AND %111
 AND #%00000111
 TAX

 LDA TWOS,X             \ Fetch a pixel from TWOS and poke it into ZP+Y
 STA (ZP),Y

 RTS                    \ Return from the subroutine

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
\ split screen). See the PIX routine for details.
\
\ ******************************************************************************

.TWOS

 EQUB %10000000
 EQUB %01000000
 EQUB %00100000
 EQUB %00010000
 EQUB %00001000
 EQUB %00000100
 EQUB %00000010
 EQUB %00000001

\ ******************************************************************************
\
\       Name: CNT
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's planetary body
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL1 loop, which draws the planet part
\ of the loading screen's Saturn.
\
\ ******************************************************************************

.CNT

 EQUW &0300             \ The number of iterations of the PLL1 loop (768)

\ ******************************************************************************
\
\       Name: CNT2
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's background stars
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL2 loop, which draws the background
\ stars on the loading screen.
\
\ ******************************************************************************

.CNT2

 EQUW &01DD             \ The number of iterations of the PLL2 loop (477)

\ ******************************************************************************
\
\       Name: CNT3
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's rings
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL3 loop, which draws the rings
\ around the loading screen's Saturn.
\
\ ******************************************************************************

.CNT3

 EQUW &0333             \ The number of iterations of the PLL3 loop (819)

\ ******************************************************************************
\
\       Name: ROOT
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate ZP = SQRT(ZP(1 0))
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following square root:
\
\   ZP = SQRT(ZP(1 0))
\
\ This routine is identical to LL5 in the main game code - it even has the same
\ label names. The only difference is that LL5 calculates Q = SQRT(R Q), but
\ apart from the variables used, the instructions are identical, so see the LL5
\ routine in the main game code for more details on the algorithm used here.
\
\ ******************************************************************************

.ROOT

 LDY ZP+1               \ Set (Y Q) = ZP(1 0)
 LDA ZP
 STA Q

                        \ So now to calculate ZP = SQRT(Y Q)

 LDX #0                 \ Set X = 0, to hold the remainder

 STX ZP                 \ Set ZP = 0, to hold the result

 LDA #8                 \ Set P = 8, to use as a loop counter
 STA P

.LL6

 CPX ZP                 \ If X < ZP, jump to LL7
 BCC LL7

 BNE LL8                \ If X > ZP, jump to LL8

 CPY #64                \ If Y < 64, jump to LL7 with the C flag clear,
 BCC LL7                \ otherwise fall through into LL8 with the C flag set

.LL8

 TYA                    \ Set Y = Y - 64
 SBC #64                \
 TAY                    \ This subtraction will work as we know C is set from
                        \ the BCC above, and the result will not underflow as we
                        \ already checked that Y >= 64, so the C flag is also
                        \ set for the next subtraction

 TXA                    \ Set X = X - ZP
 SBC ZP
 TAX

.LL7

 ROL ZP                 \ Shift the result in Q to the left, shifting the C flag
                        \ into bit 0 and bit 7 into the C flag

 ASL Q                  \ Shift the dividend in (Y S) to the left, inserting
 TYA                    \ bit 7 from above into bit 0
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 ASL Q                  \ Shift the dividend in (Y S) to the left
 TYA
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 DEC P                  \ Decrement the loop counter

 BNE LL6                \ Loop back to LL6 until we have done 8 loops

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: OSB
\       Type: Subroutine
\   Category: Utility routines
\    Summary: A convenience routine for calling OSBYTE with Y = 0
\
\ ******************************************************************************

.OSB

 LDY #0                 \ Call OSBYTE with Y = 0, returning from the subroutine
 JMP OSBYTE             \ using a tail call (so we can call OSB to call OSBYTE
                        \ for when we know we want Y set to 0)

\ ******************************************************************************
\
\       Name: MESS1
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for loading the BDATA binary
\
\ ******************************************************************************

.MESS1

 EQUS "L.BDATA FFFF1300"    \ This is short for "*LOAD BDATA FFFF1300"
 EQUB 13

\ ******************************************************************************
\
\       Name: MESS2
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for loading the main game code binary
\
\ ******************************************************************************

.MESS2

IF _SNG47

 EQUS "L.BCODE FFFF1300"    \ This is short for "*LOAD BCODE FFFF1300"
 EQUB 13

ELIF _COMPACT

 EQUS "L.ELITE FFFF1300"    \ This is short for "*LOAD ELITE FFFF1300"
 EQUB 13

ENDIF

\ ******************************************************************************
\
\       Name: MESS3
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for changing the disc directory to E
\
\ ******************************************************************************

.MESS3

 EQUS "DIR E"
 EQUB 13

\ ******************************************************************************
\
\ Save M128Elt.bin
\
\ ******************************************************************************

 PRINT "S.M128Elt ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
 SAVE "3-assembled-output/M128Elt.bin", CODE%, P%, LOAD%

