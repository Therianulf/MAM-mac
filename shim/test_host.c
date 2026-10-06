// test_host.c — stands in for the launcher in tests: spawns argv[1..] the way
// the launcher spawns the game (posix_spawnp, inherited environment) and
// exits with the child's status. Used only by tests/shim_test.sh.
#include <spawn.h>
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "usage: test_host <path> [args...]\n");
        return 2;
    }
    pid_t pid;
    int rc = posix_spawnp(&pid, argv[1], NULL, NULL, &argv[1], environ);
    if (rc != 0) {
        fprintf(stderr, "spawn failed: errno %d\n", rc);
        return 3;
    }
    int status = 0;
    waitpid(pid, &status, 0);
    return WIFEXITED(status) ? WEXITSTATUS(status) : 4;
}
