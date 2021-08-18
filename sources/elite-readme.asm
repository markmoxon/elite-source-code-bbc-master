\ ******************************************************************************
\
\ BBC MASTER ELITE README
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
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * output/README.txt
\
\ ******************************************************************************

INCLUDE "sources/elite-header.h.asm"

_SNG47                  = (_RELEASE = 1)
_COMPACT                = (_RELEASE = 2)

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
 EQUS "Release: Official Acornsoft release"
 EQUB 10, 13
 EQUS "Code no: Acornsoft SNG47 v1.0"
 EQUB 10, 13
ELIF _COMPACT
 EQUS "Release: Master Compact version"
 EQUB 10, 13
 EQUS "Code no: Superior Software"
 EQUB 10, 13
ENDIF
 EQUB 10, 13
 EQUS "See www.bbcelite.com for details"
 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13

SAVE "output/README.txt", readme, P%

