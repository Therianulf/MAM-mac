// mamplay.c — loaded into the official launcher with DYLD_INSERT_LIBRARIES.
// The launcher's Play button spawns "<dir>/mnm.exe --token <jwt>", which macOS
// cannot run. This interposes posix_spawn/posix_spawnp: any spawn whose path
// ends in ".exe" becomes "$MAM_BIN play --exe <path> <original args>", so the
// launcher's child is the Wine launch and "Game is running" works as on Windows.
// Spawns of anything else (the launcher's own restart, /usr/bin/open) pass through.
//
// Build: cc -arch arm64 -dynamiclib -O2 -o libmamplay.dylib mamplay.c
// Approach credit: seathasky/MnM-on-Mac v1 (MIT), MnMPlayRedirect/PlayRedirect.c.

#include <errno.h>
#include <spawn.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

static int ends_with_exe(const char *path) {
    size_t n = path ? strlen(path) : 0;
    return n >= 4 && strcasecmp(path + n - 4, ".exe") == 0;
}

static int redirect(pid_t *pid, const char *path,
                    const posix_spawn_file_actions_t *actions,
                    const posix_spawnattr_t *attrs,
                    char *const argv[], char *const envp[], int use_path_search) {
    const char *mam = getenv("MAM_BIN");
    if (!ends_with_exe(path) || !mam || !*mam) {
        return use_path_search ? posix_spawnp(pid, path, actions, attrs, argv, envp)
                               : posix_spawn(pid, path, actions, attrs, argv, envp);
    }
    int argc = 0;
    while (argv && argv[argc]) argc++;
    char **nargv = calloc((size_t)argc + 5, sizeof(char *));
    if (!nargv) return ENOMEM;
    int i = 0;
    nargv[i++] = (char *)mam;
    nargv[i++] = "play";
    nargv[i++] = "--exe";
    nargv[i++] = (char *)path;
    for (int k = 1; k < argc; k++) nargv[i++] = argv[k];
    nargv[i] = NULL;
    int rc = posix_spawn(pid, mam, actions, attrs, nargv, envp);
    free(nargv);
    return rc;
}

static int mam_posix_spawn(pid_t *pid, const char *path,
                           const posix_spawn_file_actions_t *actions,
                           const posix_spawnattr_t *attrs,
                           char *const argv[], char *const envp[]) {
    return redirect(pid, path, actions, attrs, argv, envp, 0);
}

static int mam_posix_spawnp(pid_t *pid, const char *path,
                            const posix_spawn_file_actions_t *actions,
                            const posix_spawnattr_t *attrs,
                            char *const argv[], char *const envp[]) {
    return redirect(pid, path, actions, attrs, argv, envp, 1);
}

#define MAM_INTERPOSE(replacement, original)                                          \
    __attribute__((used)) static struct { const void *r; const void *o; }             \
    mam_interpose_##original __attribute__((section("__DATA,__interpose"))) = {       \
        (const void *)(unsigned long)&replacement, (const void *)(unsigned long)&original }

MAM_INTERPOSE(mam_posix_spawn, posix_spawn);
MAM_INTERPOSE(mam_posix_spawnp, posix_spawnp);
