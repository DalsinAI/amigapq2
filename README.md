# Progress Quest 2 for GFOS

The AmiCradle Team's port of pq2 (Nick Bollom's remake of Progress Quest,
the RPG that plays itself) to GFOS: AmigaOS 3.2 with GFOpenUp, 68040/68060,
in its own 80 x 24 console window. It ships as a release archive with an
Installer and as the GFOpenUp part Parts/ProgressQuest2.

Upstream is fetched at build time (package/pq2.lock) and patched
(amiga/patches); this repository holds only the Amiga port, and the small
Amiga console curses (amiga/curses) it shares with the other console
ports. See [AMIGA_PORT.md](AMIGA_PORT.md).

GPL-3.0, like pq2; amiga/curses is MIT. Copyright (c) 2026 AmiCradle Team.
