\ ******************************************************************************
\
\ BBC MASTER ELITE README
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
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * README.txt
\
\ ******************************************************************************

INCLUDE "1-source-files/main-sources/elite-build-options.asm"

_SNG47                  = (_VARIANT = 1)
_COMPACT                = (_VARIANT = 2)

.readme

 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13
 EQUS "Acornsoft Elite"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Version: BBC Master"
 EQUB 10, 13

IF _SNG47

 EQUS "Variant: Acornsoft SNG47 release"
 EQUB 10, 13
 EQUS "Product: Acornsoft SNG47"
 EQUB 10, 13

ELIF _COMPACT

 EQUS "Variant: Master Compact release"
 EQUB 10, 13
 EQUS "Product: Superior Software"
 EQUB 10, 13

ENDIF

 EQUB 10, 13
 EQUS "See www.bbcelite.com for details"
 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13

SAVE "3-assembled-output/README.txt", readme, P%

