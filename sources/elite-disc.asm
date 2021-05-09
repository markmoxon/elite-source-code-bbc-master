\ ******************************************************************************
\
\ BBC MASTER ELITE DISC IMAGE SCRIPT
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
\ This source file produces one of the following SSD disc images, depending on
\ which release is being built:
\
\   * elite-master-sng47.ssd
\   * elite-master-compact.ssd
\
\ This can be loaded into an emulator or a real BBC Master.
\
\ ******************************************************************************

INCLUDE "sources/elite-header.h.asm"

_SNG47                  = (_RELEASE = 1)
_COMPACT                = (_RELEASE = 2)

IF _SNG47
 PUTFILE "output/M128Elt.bin", "M128Elt", &FF0E00, &FF0E43
 PUTFILE "output/BDATA.bin", "BDATA", &000000, &000000
 PUTFILE "output/BCODE.bin", "BCODE", &000000, &000000
ELIF _COMPACT
 PUTFILE "output/M128Elt.bin", "!BOOT", &000E00, &000E43
 PUTFILE "output/BDATA.bin", "BDATA", &001300, &001300
 PUTFILE "output/BCODE.bin", "ELITE", &001300, &002C6C
ENDIF
