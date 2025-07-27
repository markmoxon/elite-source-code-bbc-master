\ ******************************************************************************
\
\ BBC MASTER ELITE README SOURCE
\
\ BBC Master Elite was written by Ian Bell and David Braben and is copyright
\ Acornsoft 1986
\
\ The code in this file has been reconstructed from a disassembly of the version
\ released on Ian Bell's personal website at http://www.elitehomepage.org/
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://elite.bbcelite.com/terminology
\
\ The deep dive articles referred to in this commentary can be found at
\ https://elite.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces a README file for BBC Master Elite.
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * README.txt
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 _SNG47                 = (_VARIANT = 1)
 _COMPACT               = (_VARIANT = 2)

.readme

 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13
 EQUS "Acornsoft Elite (Compendium version)"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "For the BBC Micro B+"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Based on the Acornsoft SNG47 release"
 EQUB 10, 13
 EQUS "of Elite by Ian Bell and David Braben"
 EQUB 10, 13
 EQUS "Copyright (c) Acornsoft 1985"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Contains the BBC Master version with"
 EQUB 10, 13
 EQUS "flicker-free planet drawing and more,"
 EQUB 10, 13
 EQUS "all backported by Mark Moxon"
 EQUB 10, 13
 EQUB 10, 13

 EQUS "See www.bbcelite.com for details"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Build: ", TIME$("%F %T")
 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13

 SAVE "3-assembled-output/README.txt", readme, P%

