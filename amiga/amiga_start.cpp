// The start of Progress Quest 2 on the Amiga, before upstream's main()
// (built as pq2_main, -Dmain=pq2_main):
//  - the saved games (NAME.pq2) go to the player's own drawer, User/ in
//    the game's drawer (PROGDIR:), made on the first start and kept by an
//    update: User/ is made the current directory, where upstream saves and
//    where its load screen looks (amiga/patches);
//  - from Workbench (argc 0, argv is the WBStartup message) the game
//    starts as "pq2" with no options would: the main menu;
//  - the window's title (amiga/curses);
//  - statvfs, which the stove's C++ library calls for
//    std::filesystem::space (never used here) and libnix has not got.
// With -DPQ2_HOST_TEST the same runs on the build machine in the current
// directory (tests/host).
//
// Copyright (c) 2026 AmiCradle Team. GPL-3.0, like Progress Quest 2.

#include <cerrno>
#include <cstdlib>
#include <sys/stat.h>
#include <unistd.h>

#include "curses.h"

#ifndef PQ2_HOST_TEST
#include <dos/dos.h>
#include <proto/dos.h>

extern "C" {
// for C++'s exceptions and the game's state
unsigned long __stack = 256 * 1024;
}
static const char version[] __attribute__((used)) =
    "$VER: ProgressQuest2 2025.0 (16.11.2026)";
static BPTR old_dir, user_dir;

static void restore_dir() {
    if (user_dir) {
        (void) CurrentDir(old_dir);
        UnLock(user_dir);
    }
}

struct statvfs;
int statvfs(const char *, struct statvfs *) {
    errno = ENOSYS;
    return -1;
}
#endif

int pq2_main(int argc, const char *const *argv);

int main(int argc, char *argv[]) {
    static const char *const wb_argv[] = {"pq2", nullptr};

#ifndef PQ2_HOST_TEST
    (void) version;
    BPTR home = GetProgramDir();
    if (!home) {
        return 20;
    }
    old_dir = CurrentDir(home);
    (void) mkdir("User", 0755);
    user_dir = Lock((CONST_STRPTR) "User", SHARED_LOCK);
    if (!user_dir) {
        (void) CurrentDir(old_dir);
        return 20;
    }
    (void) CurrentDir(user_dir);
    atexit(restore_dir);
#else
    (void) mkdir("User", 0755);
    if (chdir("User") != 0) {
        return 20;
    }
#endif

    curses_title = "Progress Quest 2";
    if (argc < 1) {
        return pq2_main(1, wb_argv);
    }
    return pq2_main(argc, argv);
}
