#!/bin/sh
# The release archive and the GFOpenUp part, for Cradle's stove_build
# (target package):
#  1. upstream Progress Quest 2 and nlohmann/json, fetched at the commits
#     package/pq2.lock names (they are never kept in this repository), with
#     amiga/patches applied to Progress Quest 2;
#  2. the host tests (tests/host/test_amiga.sh), when the machine has C and C++
#     compilers (C++23);
#  3. the game built by amiga/Makefile.amigaos;
#  4. the drawer, its icon and the Installer script beside it packed as
#     NAME-VERSION-68040.lha (tools/pack_dist.py), with its .sha256 and a
#     short .readme;
#  5. OUT/Parts/ProgressQuest2, a GFOpenUp part: its Part file and the drawer's
#     files for SYS:Games/ProgressQuest2, installed with
#       GFOpenUpTool INSTALL Parts/ProgressQuest2
# Nothing is published from here.
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/.." && pwd)
. "$HERE/package.env"
. "$HERE/pq2.lock"
OUT=${OUT:-"$ROOT/build-amiga-package"}
mkdir -p "$OUT"
OUT=$(CDPATH= cd -- "$OUT" && pwd)
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK=${WORK:-"$HOME/.cache/amigapq2"}
cd "$ROOT"
t0=$(date +%s)

# 1. upstream and the JSON library at the locked commits, patched afresh
fetch() { # DIR URL COMMIT
    if [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" != "$3" ]; then
        rm -rf "$1"; mkdir -p "$1"
        git -C "$1" init -q
        git -C "$1" fetch -q --depth 1 "$2" "$3"
        git -C "$1" checkout -q FETCH_HEAD
    fi
    git -C "$1" checkout -q -- . && git -C "$1" clean -qfdx
}
PQ="$WORK/pq2"
JSON="$WORK/json"
fetch "$PQ" "$PQ_URL" "$PQ_COMMIT"
fetch "$JSON" "$JSON_URL" "$JSON_COMMIT"

# 2. the host tests (on the unpatched copy: they apply the patches themselves)
if command -v cc >/dev/null 2>&1 && command -v c++ >/dev/null 2>&1; then
    PQ="$PQ" JSON="$JSON" sh tests/host/test_amiga.sh
fi
for p in "$ROOT"/amiga/patches/*.patch; do
    git -C "$PQ" apply "$p"
done

# 3. the game (a stove's compiler is in its prefix/, or STOVE is the prefix)
if [ -x "$STOVE/prefix/bin/m68k-amigaos-gcc" ]; then PREFIX="$STOVE/prefix"; else PREFIX="$STOVE"; fi
make -f amiga/Makefile.amigaos PQ="$PQ" JSON="$JSON" STOVE="$STOVE" PREFIX="$PREFIX" -j4 $TARGET > "$OUT/build-output.txt" 2>&1 || { tail -n 60 "$OUT/build-output.txt"; exit 1; }

# 4. the archive
python3 "$ROOT/tools/pack_dist.py" --dist "$DIST" --name "$NAME" --out "$OUT"

# 5. the GFOpenUp part
sh "$ROOT/package/write-part.sh" "$DIST/$NAME" "$OUT/Parts/$NAME" "$NAME" "$PORT_VERSION" \
    "Progress Quest 2: the RPG that plays itself, a remake of Progress Quest"
echo "part: $(grep -c '^copy' "$OUT/Parts/$NAME/Part") files, $(du -sk "$OUT/Parts/$NAME" | cut -f1) KB"
# Version reads this: the linker's --gc-sections must not drop it
grep -a -q '[$]VER: ' "$DIST/$NAME/$NAME" || { echo "FAIL: no \$VER string in $NAME"; exit 1; }
ls -l "$DIST/$NAME/$NAME"
echo "total: $(( $(date +%s) - t0 )) s"
