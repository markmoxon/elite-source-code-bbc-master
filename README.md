# Fully documented source code for Elite on the BBC Master

[BBC Micro (cassette)](https://github.com/markmoxon/cassette-elite-beebasm) | [BBC Micro (disc)](https://github.com/markmoxon/disc-elite-beebasm) | [6502 Second Processor](https://github.com/markmoxon/6502sp-elite-beebasm) | **BBC Master** | [Acorn Electron](https://github.com/markmoxon/electron-elite-beebasm) | [Elite-A](https://github.com/markmoxon/elite-a-beebasm)

![Screenshot of Elite on the BBC Master](https://www.bbcelite.com/images/github/Elite-Master.png)

This repository contains source code for Elite on the BBC Master, with every single line documented and (for the most part) explained.

It is a companion to the [bbcelite.com website](https://www.bbcelite.com).

See the [introduction](#introduction) for more information.

## Contents

* [Introduction](#introduction)

* [Acknowledgements](#acknowledgements)

  * [A note on licences, copyright etc.](#user-content-a-note-on-licences-copyright-etc)

* [Browsing the source in an IDE](#browsing-the-source-in-an-ide)

* [Folder structure](#folder-structure)

* [Flicker-free Elite](#flicker-free-elite)

* [Building Elite from the source](#building-elite-from-the-source)

  * [Requirements](#requirements)
  * [Build targets](#build-targets)
  * [Windows](#windows)
  * [Mac and Linux](#mac-and-linux)
  * [Verifying the output](#verifying-the-output)
  * [Log files](#log-files)
  * [Auto-deploying to the b2 emulator](#auto-deploying-to-the-b2-emulator)

* [Building different variants of BBC Master Elite](#building-different-variants-of-bbc-master-elite)

  * [Building the SNG47 release](#building-the-sng47-release)
  * [Building the Master Compact release](#building-the-master-compact-release)
  * [Differences between the variants](#differences-between-the-variants)

* [Notes on the original source files](#notes-on-the-original-source-files)

  * [Producing byte-accurate binaries](#producing-byte-accurate-binaries)

## Introduction

This repository contains source code for Elite on the BBC Master, with every single line documented and (for the most part) explained.

You can build the fully functioning game from this source. [Two variants](#building-different-variants-of-bbc-master-elite) are currently supported: the Acornsoft SNG47 release, and the Superior Software release for the Master Compact.

It is a companion to the [bbcelite.com website](https://www.bbcelite.com), which contains all the code from this repository, but laid out in a much more human-friendly fashion. The links at the top of this page will take you to repositories for the other versions of Elite that are covered by this project.

* If you want to browse the source and read about how Elite works under the hood, you will probably find [the website](https://www.bbcelite.com) is a better place to start than this repository.

* If you would rather explore the source code in your favourite IDE, then the [annotated source](1-source-files/main-sources/elite-source.asm) is what you're looking for. It contains the exact same content as the website, so you won't be missing out (the website is generated from the source files, so they are guaranteed to be identical). You might also like to read the section on [Browsing the source in an IDE](#browsing-the-source-in-an-ide) for some tips.

* If you want to build Elite from the source on a modern computer, to produce a working game disc that can be loaded into a BBC Master or an emulator, then you want the section on [Building Elite from the source](#building-elite-from-the-source).

My hope is that this repository and the [accompanying website](https://www.bbcelite.com) will be useful for those who want to learn more about Elite and what makes it tick. It is provided on an educational and non-profit basis, with the aim of helping people appreciate one of the most iconic games of the 8-bit era.

## Acknowledgements

BBC Master Elite was written by Ian Bell and David Braben and is copyright &copy; Acornsoft 1986.

The code on this site has been reconstructed from a disassembly of the version released on [Ian Bell's personal website](http://www.elitehomepage.org/).

The commentary is copyright &copy; Mark Moxon. Any misunderstandings or mistakes in the documentation are entirely my fault.

Huge thanks are due to the original authors for not only creating such an important piece of my childhood, but also for releasing the source code for us to play with; to Paul Brink for his annotated disassembly; and to Kieran Connell for his [BeebAsm version](https://github.com/kieranhj/elite-beebasm), which I forked as the original basis for this project. You can find more information about this project in the [accompanying website's project page](https://www.bbcelite.com/about_site/about_this_project.html).

The following archive from Ian Bell's personal website forms the basis for this project:

* [BBC Elite, Master version](http://www.elitehomepage.org/archive/a/b8020001.zip)

### A note on licences, copyright etc.

This repository is _not_ provided with a licence, and there is intentionally no `LICENSE` file provided.

According to [GitHub's licensing documentation](https://docs.github.com/en/free-pro-team@latest/github/creating-cloning-and-archiving-repositories/licensing-a-repository), this means that "the default copyright laws apply, meaning that you retain all rights to your source code and no one may reproduce, distribute, or create derivative works from your work".

The reason for this is that my commentary is intertwined with the original Elite source code, and the original source code is copyright. The whole site is therefore covered by default copyright law, to ensure that this copyright is respected.

Under GitHub's rules, you have the right to read and fork this repository... but that's it. No other use is permitted, I'm afraid.

My hope is that the educational and non-profit intentions of this repository will enable it to stay hosted and available, but the original copyright holders do have the right to ask for it to be taken down, in which case I will comply without hesitation. I do hope, though, that along with the various other disassemblies and commentaries of this source, it will remain viable.

## Browsing the source in an IDE

If you want to browse the source in an IDE, you might find the following useful.

* The most interesting files are in the [main-sources](1-source-files/main-sources) folder:

  * The main game's source code is in the [elite-source.asm](1-source-files/main-sources/elite-source.asm) and [elite-data.asm](1-source-files/main-sources/elite-data.asm) files (containing the game code and game data respectively) - this is the motherlode and probably contains all the stuff you're interested in.

  * The game's loader is in the [elite-loader.asm](1-source-files/main-sources/elite-loader.asm) file - this is mainly concerned with setup and copy protection.

* It's probably worth skimming through the [notes on terminology and notations](https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html) on the accompanying website, as this explains a number of terms used in the commentary, without which it might be a bit tricky to follow at times (in particular, you should understand the terminology I use for multi-byte numbers).

* The accompanying website contains [a number of "deep dive" articles](https://www.bbcelite.com/deep_dives/), each of which goes into an aspect of the game in detail. Routines that are explained further in these articles are tagged with the label `Deep dive:` and the relevant article name.

* There are loads of routines and variables in Elite - literally hundreds. You can find them in the source files by searching for the following: `Type: Subroutine`, `Type: Variable`, `Type: Workspace` and `Type: Macro`.

* If you know the name of a routine, you can find it by searching for `Name: <name>`, as in `Name: SCAN` (for the 3D scanner routine) or `Name: LL9` (for the ship-drawing routine).

* The entry point for the [main game code](1-source-files/main-sources/elite-source.asm) is routine `TT170`, which you can find by searching for `Name: TT170`. If you want to follow the program flow all the way from the title screen around the main game loop, then you can find a number of [deep dives on program flow](https://www.bbcelite.com/deep_dives/) on the accompanying website.

* The source code is designed to be read at an 80-column width and with a monospaced font, just like in the good old days.

I hope you enjoy exploring the inner workings of BBC Elite as much as I have.

## Folder structure

There are five main folders in this repository, which reflect the order of the build process.

* [1-source-files](1-source-files) contains all the different source files, such as the main assembler source files, image binaries, fonts, boot files and so on.

* [2-build-files](2-build-files) contains build-related scripts, such as the checksum, encryption and crc32 verification scripts.

* [3-assembled-output](3-assembled-output) contains the output from the assembly process, when the source files are assembled and the results processed by the build files.

* [4-reference-binaries](4-reference-binaries) contains the correct binaries for each variant, so we can verify that our assembled output matches the reference.

* [5-compiled-game-discs](5-compiled-game-discs) contains the final output of the build process: an SSD disc image that contains the compiled game and which can be run on real hardware or in an emulator.

## Flicker-free Elite

This repository also includes a flicker-free version, which incorporates a fix for planets so they no longer flicker. The flicker-free code is in a separate branch called `flicker-free`, and apart from the code differences for reducing flicker, this branch is identical to the main branch and the same build process applies.

The annotated source files in the `flicker-free` branch contain both the original Acornsoft code and all of the modifications for flicker-free Elite, so you can look through the source to see exactly what's changed. Any code that I've removed from the original version is commented out in the source files, so when they are assembled they produce the flicker-free binaries, while still containing details of all the modifications. You can find all the diffs by searching the sources for `Mod:`.

For more information on flicker-free Elite, see the [hacks section of the accompanying website](https://www.bbcelite.com/hacks/flicker-free_elite.html).

## Building Elite from the source

### Requirements

You will need the following to build Elite from the source:

* BeebAsm, which can be downloaded from the [BeebAsm repository](https://github.com/stardot/beebasm). Mac and Linux users will have to build their own executable with `make code`, while Windows users can just download the `beebasm.exe` file.

* Python. Both versions 2.7 and 3.x should work.

* Mac and Linux users may need to install `make` if it isn't already present (for Windows users, `make.exe` is included in this repository).

For details of how the build process works, see the [build documentation on bbcelite.com](https://www.bbcelite.com/about_site/building_elite.html).

Let's look at how to build Elite from the source.

### Build targets

There are two main build targets available. They are:

* `build` - An unencrypted version
* `encrypt` - An encrypted version that includes the same obfuscation as the released version of the game

The unencrypted version should be more useful for anyone who wants to make modifications to the game code. It includes a default commander with lots of cash and equipment, which makes it easier to test the game. As this target produces unencrypted files, the binaries produced will be quite different to the binaries on the original source disc, which are encrypted.

The encrypted version contains an obfuscated version of the game binary, along with the standard default commander.

Builds are supported for both Windows and Mac/Linux systems. In all cases the build process is defined in the `Makefile` provided.

### Windows

For Windows users, there is a batch file called `make.bat` to which you can pass one of the build targets above. Before this will work, you should edit the batch file and change the values of the `BEEBASM` and `PYTHON` variables to point to the locations of your `beebasm.exe` and `python.exe` executables. You also need to change directory to the repository folder (i.e. the same folder as `make.bat`).

All being well, doing one of the following:

```
make.bat build
```

```
make.bat encrypt
```

will produce a file called `elite-master-sng47.ssd` in the `5-compiled-game-discs` folder that contains the SNG47 release, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

### Mac and Linux

The build process uses a standard GNU `Makefile`, so you just need to install `make` if your system doesn't already have it. If BeebAsm or Python are not on your path, then you can either fix this, or you can edit the `Makefile` and change the `BEEBASM` and `PYTHON` variables in the first two lines to point to their locations. You also need to change directory to the repository folder (i.e. the same folder as `Makefile`).

All being well, doing one of the following:

```
make build
```

```
make encrypt
```

will produce a file called `elite-master-sng47.ssd` in the `5-compiled-game-discs` folder that contains the SNG47 release, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

### Verifying the output

The build process also supports a verification target that prints out checksums of all the generated files, along with the checksums of the files from the original sources.

You can run this verification step on its own, or you can run it once a build has finished. To run it on its own, use the following command on Windows:

```
make.bat verify
```

or on Mac/Linux:

```
make verify
```

To run a build and then verify the results, you can add two targets, like this on Windows:

```
make.bat encrypt verify
```

or this on Mac/Linux:

```
make encrypt verify
```

The Python script `crc32.py` in the `2-build-files` folder does the actual verification, and shows the checksums and file sizes of both sets of files, alongside each other, and with a Match column that flags any discrepancies. If you are building an unencrypted set of files then there will be lots of differences, while the encrypted files should mostly match (see the Differences section below for more on this).

The binaries in the `4-reference-binaries` folder are those extracted from the released version of the game, while those in the `3-assembled-output` folder are produced by the build process. For example, if you don't make any changes to the code and build the project with `make encrypt verify`, then this is the output of the verification process:

```
Results for variant: sng47
[--originals--]  [---output----]
Checksum   Size  Checksum   Size  Match  Filename
-----------------------------------------------------------
d52370e7  27720  d52370e7  27720   Yes   BCODE.bin
86e9fa69  27720  86e9fa69  27720   Yes   BCODE.unprot.bin
bf10f02b  16896  bf10f02b  16896   Yes   BDATA.bin
f7a27087  16896  f7a27087  16896   Yes   BDATA.unprot.bin
6dce29cc    721  6dce29cc    721   Yes   M128Elt.bin
```

All the compiled binaries match the originals, so we know we are producing the same final game as the release version.

### Log files

During compilation, details of every step are output in a file called `compile.txt` in the `3-assembled-output` folder. If you have problems, it might come in handy, and it's a great reference if you need to know the addresses of labels and variables for debugging (or just snooping around).

### Auto-deploying to the b2 emulator

For users of the excellent [b2 emulator](https://github.com/tom-seddon/b2), you can include the build parameter `b2` to automatically load and boot the assembled disc image in b2. The b2 emulator must be running for this to work.

For example, to build, verify and load into b2, you can do this on Windows:

```
make.bat encrypt verify b2
```

or this on Mac/Linux:

```
make encrypt verify b2
```

Note that you should manually choose the correct platform in b2 (I intentionally haven't automated this part to make it easier to test across multiple platforms).

## Building different variants of BBC Master Elite

This repository contains the source code for two different variants of BBC Master Elite:

* The Acornsoft SNG47 release, which was the first appearance of BBC Master Elite, and the one included on all subsequent discs

* The Superior Software release for the Master Compact

By default the build process builds the SNG47 release, but you can build a specified variant using the `variant=` build parameter.

### Building the SNG47 release

You can add `variant=sng47` to produce the `elite-master-sng47.ssd` file that contains the SNG47 release, though that's the default value so it isn't necessary.

The verification checksums for this version are shown above.

### Building the Master Compact release

You can build the Master Compact release by appending `variant=compact` to the `make` command, like this on Windows:

```
make.bat encrypt verify variant=compact
```

or this on a Mac or Linux:

```
make encrypt verify variant=compact
```

This will produce a file called `elite-master-compact.ssd` in the `5-compiled-game-discs` folder that contains the Master Compact release.

The verification checksums for this version are as follows:

```
Results for variant: compact
[--originals--]  [---output----]
Checksum   Size  Checksum   Size  Match  Filename
-----------------------------------------------------------
d5cbbba9  27904  d5cbbba9  27904   Yes   BCODE.bin
bd689545  27904  bd689545  27904   Yes   BCODE.unprot.bin
8c9d6d1f  16896  8c9d6d1f  16896   Yes   BDATA.bin
5993627f  16896  5993627f  16896   Yes   BDATA.unprot.bin
107b98cc    740  107b98cc    740   Yes   M128Elt.bin
```

### Differences between the variants

You can see the differences between the variants by searching the source code for `_SNG47` (for features in the SNG47 release) or `_COMPACT` (for features in the Master Compact release). The main differences in the Master Compact release compared to the SNG47 release are:

* Support for the Compact's digital joystick. The analogue stick is still supported, but if this release is run on a Compact, then the digital stick is read instead.

* Support for ADFS and the single disc drive on the Compact. This essentially replaces the "Which Drive?" prompt in the disc access menu with "Which Directory?", and changes the formatting of the disc catalogue to fit it on-screen. There is also additional code to claim and release the NMI workspace when disc access is required, as ADFS uses zero page differently to DFS.

See the [accompanying website](https://www.bbcelite.com/master/releases.html) for a comprehensive list of differences between the variants.

## Notes on the original source files

### Producing byte-accurate binaries

The `4-reference-binaries/<variant>/workspaces` folders (where `<variant>` is the variant) contain binary files that match the workspaces in the original game binaries (a workspace being a block of memory, such as `LBUF` or `LSX2`). Instead of initialising workspaces with null values like BeebAsm, the original BBC Micro source code creates its workspaces by simply incrementing the `P%` and `O%` program counters, which means that the workspaces end up containing whatever contents the allocated memory had at the time. As the source files are broken into multiple BBC BASIC programs that run each other sequentially, this means the workspaces in the source code tend to contain either fragments of these BBC BASIC source programs, or assembled code from an earlier stage. This doesn't make any difference to the game code, which either intialises the workspaces at runtime or just ignores their initial contents, but if we want to be able to produce byte-accurate binaries from the modern BeebAsm assembly process, we need to include this "workspace noise" when building the project, and that's what the binaries in the `4-reference-binaries/<variant>/workspaces` folder are for. These binaries are only loaded by the `encrypt` target; for the `build` target, workspaces are initialised with zeroes.

Here's an example of how these binaries are included, in this case for the `log` workspace in the `ELTA` section:

```
.log

IF _MATCH_ORIGINAL_BINARIES

 IF _SNG47
  INCBIN "4-reference-binaries/sng47/workspaces/ELTA-log.bin"
 ELIF _COMPACT
  INCBIN "4-reference-binaries/compact/workspaces/ELTA-log.bin"
 ENDIF

ELSE

  SKIP 1

 FOR I%, 1, 255

  B% = INT(&2000 * LOG(I%) / LOG(2) + 0.5)

  EQUB B% DIV 256

 NEXT

ENDIF
```

---

Right on, Commanders!

_Mark Moxon_