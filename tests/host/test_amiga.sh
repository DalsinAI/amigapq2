#!/bin/sh
# Host tests of the Progress Quest 2 port, on the build machine (cc, and a
# c++ with C++23 and zlib):
#  1. amiga/curses on its own (tests/host/test_curses.c);
#  2. amiga/patches apply to upstream at the locked commit;
#  3. the whole game, patched as on the Amiga (-D__amigaos__), built with
#     amiga/curses and amiga/amiga_start.cpp, run with typed keys through
#     tests/host/con_script.c (every read gets the next key; the run ends
#     a set number of reads after the last): the main menu shows; a new
#     character, named with Backspace and letters, is saved as NAME.pq2 in
#     User/; the game goes on by itself (a task's bar fills); Esc quits;
#     the load screen lists the saved game and loads it; progress bars
#     are ASCII.
#   PQ=/path/to/pq2 JSON=/path/to/json (at package/pq2.lock's commits) sh tests/host/test_amiga.sh
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PQ=${PQ:?PQ is upstream pq2}
JSON=${JSON:?JSON is nlohmann/json}
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
CUR="$ROOT/amiga/curses"
pass=0 fail=0
ok() { pass=$((pass + 1)); }
no() { fail=$((fail + 1)); echo "FAIL: $*"; }

# 1
cc -std=c99 -Wall -Wextra -Werror -I"$CUR" -o "$T/test_curses" \
    "$CUR/curses.c" "$ROOT/tests/host/con_test.c" "$ROOT/tests/host/test_curses.c"
if "$T/test_curses"; then ok; else no "curses"; fi

# 2
cp -R "$PQ" "$T/pq"
rm -rf "$T/pq/.git"
for p in "$ROOT"/amiga/patches/*.patch; do
    if (cd "$T/pq" && patch -s -p1 < "$p"); then ok; else no "patch $p"; fi
done

# 3
if ! printf '#include <format>\n#include <zlib.h>\nint main(){return 0;}\n' | \
        c++ -std=c++23 -x c++ - -o "$T/probe" -lz 2>/dev/null; then
    echo "pq2 host tests: $pass passed, $fail failed (no C++23 or zlib here: the game is not built)"
    [ "$fail" -eq 0 ]
    exit
fi
mkdir -p "$T/obj"
F="-std=c++23 -O1 -w -D__amigaos__ -DNCURSES_ENABLED -I$CUR -I$T/pq/game -I$T/pq/utils -I$T/pq/gui -I$T/pq/ncurses -I$JSON/single_include"
for f in "$T"/pq/game/*.cpp "$T"/pq/utils/*.cpp "$T"/pq/gui/*.cpp "$T"/pq/ncurses/*.cpp; do
    d=$(basename "$(dirname "$f")")
    c++ $F -c "$f" -o "$T/obj/$d-$(basename "$f" .cpp).o"
done
c++ $F -Dmain=pq2_main -c "$T/pq/main.cpp" -o "$T/obj/main.o"
c++ -std=c++23 -O1 -Wall -DPQ2_HOST_TEST -I"$CUR" -c "$ROOT/amiga/amiga_start.cpp" -o "$T/obj/amiga_start.o"
cc -std=c99 -O1 -Wall -I"$CUR" -c "$CUR/curses.c" -o "$T/obj/curses.o"
cc -std=c99 -O1 -Wall -DCON_TEST_PREFIX -I"$CUR" -c "$ROOT/tests/host/con_test.c" -o "$T/obj/con_test.o"
cc -std=c99 -O1 -Wall -D_DEFAULT_SOURCE -I"$CUR" -c "$ROOT/tests/host/con_script.c" -o "$T/obj/con_script.o"
c++ -o "$T/pq2" "$T"/obj/*.o -lz
ok

G="$T/game"
mkdir -p "$G"
S="$G/screen"
# play KEYS IDLE: the screen IDLE reads (of 100 ms) after the last key is in $S
play() {
    printf "$1" > "$T/keys"
    (cd "$G" && CON_POLL=1 CON_IDLE="$2" CON_KEYS="$T/keys" CON_SCREEN="$S" "$T/pq2" > /dev/null)
}
BS='\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'

play '' 3
grep -q 'Start New Game' "$S" && grep -q 'Load Game' "$S" && ok || no "main menu"
[ -d "$G/User" ] && ok || no "User/ made"

# new game, the name typed, down to Sold! (Name, Race, Class, Roll, Sold!)
play "\r${BS}Hudzen\233B\233B\233B\233B\r" 40
grep -q 'Hudzen: lvl 1' "$S" && ok || no "the game screen for Hudzen"
[ -f "$G/User/Hudzen.pq2" ] && ok || no "User/Hudzen.pq2 saved"
grep -q '#' "$S" && ok || no "a bar fills by itself"
if LC_ALL=C grep -q '[^ -~]' "$S"; then no "only ASCII on the screen"; else ok; fi

# Esc on the main menu quits: the game ends before the reads run out, so
# no screen is written
rm -f "$S"
play '\033' 50
[ ! -f "$S" ] && ok || no "Esc on the main menu quits"

# the load screen lists the save and loads it
play '\233B\r' 3
grep -q 'Hudzen.pq2' "$S" && ok || no "load screen lists Hudzen.pq2"
play '\233B\r\r' 5
grep -q 'Hudzen: lvl' "$S" && ok || no "Hudzen loaded"

echo "pq2 host tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
