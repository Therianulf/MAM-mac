#!/bin/bash
# Proves the spawn shim: a host program spawns "./mnm/mnm.exe --token T" with
# libmamplay.dylib inserted, and a fake MAM_BIN records what it was called with.
# Needs cc (Xcode command line tools). Runs entirely in a temp folder.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/mam-shim-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

cc -arch arm64 -dynamiclib -O2 -o "$work/libmamplay.dylib" "$here/shim/mamplay.c"
cc -arch arm64 -O2 -o "$work/test_host" "$here/shim/test_host.c"

mkdir -p "$work/mnm"
printf 'MZ not a mach-o\n' > "$work/mnm/mnm.exe"   # a PE stand-in: not spawnable
chmod +x "$work/mnm/mnm.exe"
cat > "$work/fake-mam" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$MAM_TEST_OUT"
exit 0
EOF
chmod +x "$work/fake-mam"

cd "$work"
# Without the shim the spawn must fail (macOS cannot run a PE).
if ./test_host ./mnm//mnm.exe --token T >/dev/null 2>&1; then
    echo "FAIL: spawning a PE succeeded without the shim"; exit 1
fi
# With the shim, the call lands on MAM_BIN with the original path and args.
MAM_TEST_OUT="$work/out.txt" MAM_BIN="$work/fake-mam" \
DYLD_INSERT_LIBRARIES="$work/libmamplay.dylib" ./test_host ./mnm//mnm.exe --token T
expected=$'play\n--exe\n./mnm//mnm.exe\n--token\nT'
if [[ "$(cat "$work/out.txt")" != "$expected" ]]; then
    echo "FAIL: shim passed:"; cat "$work/out.txt"; exit 1
fi
# A non-.exe spawn must pass through untouched.
MAM_BIN="$work/fake-mam" DYLD_INSERT_LIBRARIES="$work/libmamplay.dylib" \
    ./test_host /usr/bin/true
echo "shim test: ok"
