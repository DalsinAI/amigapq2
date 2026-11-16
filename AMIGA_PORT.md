Progress Quest 2 for GFOS
=========================

A port of pq2, Nick Bollom's remake of Eric Fredricksen's Progress Quest,
from https://github.com/nbollom/pq2 at commit
62416beb54f48d4d9aa66b55e436287f12491285 (2025.0), for GFOS: AmigaOS 3.2
with GFOpenUp, on a 68040 or 68060. The ncurses interface, on a small
curses for the Amiga console.

Roll a character, sell it, and watch: it kills monsters, sells loot, learns
spells and works through the plot by itself.

Status: the whole game, patched as on the Amiga, passes its host tests (a
new character is saved and plays on by itself, the load screen finds and
loads it); built in Cradle's os32-gcc16-open6 stove; not yet run in a lab.


What you need
-------------

- AmigaOS 3.2 (GFOS) on a 68040 or 68060. The FPU is used when there is
  one; the game needs none (an LC040 is fine).
- About 2.5 MB of disk and 4 MB of memory. No libraries.


How to play
-----------

Run Install-ProgressQuest2 (or copy the ProgressQuest2 drawer where you
want it), then double-click ProgressQuest2, or from a Shell:

    ProgressQuest2 [SAVEFILE]

The game opens its own window, 80 by 24 characters in the screen's font.
Start New Game: type a name (Backspace rubs out), the cursor keys move
between Name, Random, Race, Class, Roll, Unroll and Sold!, Return or Space
chooses, Tab steps through the lists. Sold! saves NAME.pq2 and starts the
game. On the game screen F1 to F5 show the equipment, spells, inventory,
plot and quests, p shows the bars' percentages, - and + change how often
the screen is drawn, Esc closes a list or saves and quits. Load Game lists
the saved games.

The saved games are in the drawer's User drawer, which
Install-ProgressQuest2 and GFOpenUp keep when they update the game; a
SAVEFILE named in a Shell is taken from there.

Not on the Amiga: the load screen shows only the User drawer (AmigaOS
names are not POSIX paths for the C++ library to walk), the bars are drawn
in ASCII (# and +, the console fonts have no block characters), and
daemon mode (the signals it needs are Unix's).


Building
--------

    make -f amiga/Makefile.amigaos -j4 PQ=/path/to/pq2 JSON=/path/to/json STOVE=/path/to/os32-gcc16-open6

with PQ upstream at the locked commit and amiga/patches applied and JSON
nlohmann/json at its locked commit, or, in Cradle, stove_build with the
os32-gcc16-open6 stove and target package (package/build-amiga.sh), which
fetches both and patches upstream, runs the host tests, packs
ProgressQuest2-VERSION-68040.lha and makes the GFOpenUp part
Parts/ProgressQuest2 (GFOpenUpTool INSTALL Parts/ProgressQuest2 puts the
game in SYS:Games/ProgressQuest2). zlib is the stove's (port-deps).


What was changed
----------------

- amiga/patches/0001-amigaos-console-and-saves.patch, each change under
  __amigaos__: the progress bars in ASCII; the screen erased, not cleared,
  before each drawing (a clear repaints the whole window ten times a
  second); the load screen lists the .pq2 files of the current directory
  only, and does nothing on Return when there are none; no daemon mode.
- amiga/curses: a small curses (MIT) on the Amiga console, the same as the
  Umoria port's: windows and subwindows, attributes, boxes and lines in
  ASCII, drawing by difference, the cursor and function keys as KEY_
  codes, timeouts with WaitForChar, its own CON: window in raw mode;
  ncurses.h includes it.
- amiga/amiga_start.cpp: User/ in the drawer made and made the current
  directory, the Workbench start, the window's title, a 256 KB stack, and
  statvfs (the C++ library's std::filesystem::space wants it; libnix has
  none, and the game never asks).
- tests/host/: curses checked on its own (37 checks), the patch applied to
  upstream, and the whole patched game built on the build machine and
  played with typed keys through a test console (12 checks in all).
- amiga/: the Makefile, the GlowIcons (our own art), the Installer script
  and its spec. package/: the archive and the GFOpenUp part.

The AmiCradle Team.
