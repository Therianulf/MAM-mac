#!/bin/bash
# End-to-end test of bin/mam in a temp MAM_HOME: install (DXMT, no icon), the
# launcher wrapper (a compiled stub stands in for the stock launcher binary), the
# migration of an old bundle layout by 'mam launcher' and by 'mam install', a
# console-only wine check, play dry-runs, the D3DMetal licence gate and path,
# uninstall.
# Opens no window and touches nothing outside its temp folders: HOME is a temp
# folder too, so the real icon and the launcher's saved login are out of reach.
# Set MAM_CACHE to a folder holding the four downloads to skip ~270 MB of fetching.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
export MAM_HOME=$(mktemp -d "${TMPDIR:-/tmp}/mam-install-test.XXXXXX")
export HOME=$(mktemp -d "${TMPDIR:-/tmp}/mam-install-home.XXXXXX")
stub_dir=$(mktemp -d "${TMPDIR:-/tmp}/mam-install-stub.XXXXXX")
trap 'rm -rf "$MAM_HOME" "$HOME" "$stub_dir"' EXIT
mam="$here/bin/mam"
step() { printf '\n== %s\n' "$*"; }

if [[ -n ${MAM_CACHE:-} ]]; then mkdir -p "$MAM_HOME/downloads"; cp "$MAM_CACHE"/* "$MAM_HOME/downloads/"; fi

step "install (dxmt, no icon)"
"$mam" install --yes --no-app --renderer dxmt | grep -vE '^\s+[0-9.]+%|####' | grep -E '^\[|^  - (prefix|launcher|built|DXMT)|ERROR'
[[ -x $MAM_HOME/Runtime/Frameworks/wswine.bundle/bin/wine ]]
[[ -d $MAM_HOME/Prefix/drive_c/windows/system32 ]]
[[ -x $MAM_HOME/Launcher/mnm_patcher_app.app/Contents/MacOS/mnm_launcher ]]
[[ -f $MAM_HOME/Prefix/drive_c/windows/system32/winemetal.dll ]]
[[ ! -e $HOME/Applications/Monsters\ \&\ Memories.app ]]

step "launcher wrapper"
command -v cc >/dev/null || { echo "FAIL: cc is needed for the launcher stub"; exit 1; }
# a compiled stub: dyld strips DYLD_* for /bin/bash, so a script could not show DYLD_INSERT_LIBRARIES
cat > "$stub_dir/stub.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
static const char *env_or_empty(const char *name) { const char *value = getenv(name); return value ? value : ""; }
int main(int argc, char **argv) {
    char cwd[4096];
    for (int index = 1; index < argc; index++) printf("stub arg %s\n", argv[index]);
    printf("stub DYLD_INSERT_LIBRARIES=%s\n", env_or_empty("DYLD_INSERT_LIBRARIES"));
    printf("stub MAM_HOME=%s\n", env_or_empty("MAM_HOME"));
    printf("stub MAM_BIN=%s\n", env_or_empty("MAM_BIN"));
    printf("stub cwd=%s\n", getcwd(cwd, sizeof cwd) ? cwd : "");
    return 0;
}
EOF
cc -arch arm64 -O2 -o "$stub_dir/stub" "$stub_dir/stub.c"
bundle=$MAM_HOME/Launcher/mnm_patcher_app.app/Contents/MacOS
launcher_log=$MAM_HOME/Logs/launcher.log
[[ $(head -c 2 "$bundle/mnm_launcher") == '#!' ]]
[[ -x $bundle/mnm_launcher ]]
file -b "$bundle/mnm_launcher.real" | grep -q Mach-O
grep -qxF "export MAM_HOME=$(printf %q "$MAM_HOME")" "$bundle/mnm_launcher"
grep -q "launcher \"\$@\"" "$bundle/mnm_launcher"
cp "$bundle/mnm_launcher.real" "$stub_dir/real.orig"
cp "$stub_dir/stub" "$bundle/mnm_launcher.real"
: > "$launcher_log"
# as Finder starts it: no MAM_HOME, working directory /, a process serial number argument
(cd / && env -u MAM_HOME "$bundle/mnm_launcher" -psn_0_1 >/dev/null)
grep -qx 'stub arg --stinky-cheese' "$launcher_log"
! grep -q 'psn_' "$launcher_log"
grep -qx "stub DYLD_INSERT_LIBRARIES=$MAM_HOME/lib/libmamplay.dylib" "$launcher_log"
grep -qx "stub MAM_HOME=$MAM_HOME" "$launcher_log"
grep -qx "stub MAM_BIN=$mam" "$launcher_log"
grep -qx "stub cwd=$(cd "$MAM_HOME/Game" && pwd -P)" "$launcher_log"
[[ $(grep -c '^stub cwd=' "$launcher_log") == 1 ]]   # started once: no recursion through the wrapper
cp "$stub_dir/real.orig" "$bundle/mnm_launcher.real"

step "old-layout launcher is migrated by 'mam launcher'"
cp "$stub_dir/stub" "$bundle/mnm_launcher"; rm -f "$bundle/mnm_launcher.real"
: > "$launcher_log"
"$mam" launcher >/dev/null
[[ $(head -c 2 "$bundle/mnm_launcher") == '#!' ]]
cmp -s "$stub_dir/stub" "$bundle/mnm_launcher.real"
grep -qx 'stub arg --stinky-cheese' "$launcher_log"
cp "$stub_dir/real.orig" "$bundle/mnm_launcher.real"   # the next wrap is automatic; later steps see a real install

step "wine console check"
"$mam" wine cmd /c ver | tr -d '\r' | grep -q 'Microsoft Windows 10'

step "play dry-run as the shim calls it"
mkdir -p "$MAM_HOME/Game/mnm"; printf 'MZ' > "$MAM_HOME/Game/mnm/mnm.exe"
tok="h.$(printf '{"exp":9999999999}' | base64 | tr -d '=\n' | tr '/+' '_-').s"
out=$(cd "$MAM_HOME/Game" && "$mam" play --dry-run --exe ./mnm//mnm.exe --token "$tok")
grep -q 'exec .*wine mnm.exe -force-d3d11 --token' <<<"$out"
grep -q 'WINEDLLOVERRIDES=mscoree,mshtml=d;dxgi,d3d11,d3d10core=b' <<<"$out"

step "expired token refused"
bad="h.$(printf '{"exp":1000}' | base64 | tr -d '=\n').s"
if "$mam" play --dry-run --token "$bad" 2>/dev/null; then echo "FAIL: expired token accepted"; exit 1; fi

step "fresh runtime, d3dmetal, no --yes, no terminal: licence shown and refused"
if out=$("$mam" install --no-app --reinstall --renderer d3dmetal </dev/null 2>&1); then
    echo "FAIL: D3DMetal installed without the licence"; exit 1; fi
grep -q 'GAME PORTING TOOLKIT' <<<"$out"
grep -q 'licence not accepted' <<<"$out"
[[ ! -e $MAM_HOME/Runtime/Frameworks/renderer/d3dmetal ]]

step "old-layout launcher: install migrates it and does not download it again"
cp "$stub_dir/stub" "$bundle/mnm_launcher"; rm -f "$bundle/mnm_launcher.real"

step "d3dmetal path (licence auto-accepted by --yes; runtime and prefix kept; icon in the temp HOME)"
out=$("$mam" install --yes --renderer d3dmetal)
icon="$HOME/Applications/Monsters & Memories.app"
grep -qxF "export MAM_HOME=$(printf %q "$MAM_HOME")" "$icon/Contents/MacOS/launch"
grep -q 'GAME PORTING TOOLKIT' <<<"$out"
grep -E '^  - (D3DMetal|prefix kept|launcher kept)' <<<"$out"
[[ -d $MAM_HOME/Runtime/Frameworks/renderer/d3dmetal/external/D3DMetal.framework ]]
cmp -s "$stub_dir/stub" "$bundle/mnm_launcher.real"
[[ $(head -c 2 "$bundle/mnm_launcher") == '#!' ]]
"$mam" env | grep -q 'CX_ACTIVE_GRAPHICS_BACKEND=d3dmetal'
"$mam" wine --version | grep -q 'wine-10.0'

step "doctor"
doctor_out=$(SKIP_NET=1 "$mam" doctor)   # captured: grep -q closing the pipe early would kill doctor under pipefail
grep -q 'doctor: all good' <<<"$doctor_out"
grep -q 'launcher: .*mnm_patcher_app.app' <<<"$doctor_out"

step "uninstall (removes this install's icon)"
"$mam" uninstall --yes >/dev/null
[[ ! -d $MAM_HOME/Runtime && ! -d $MAM_HOME/Prefix && ! -d $MAM_HOME/Launcher ]]
[[ ! -e $icon ]]

step "uninstall keeps an icon that opens another MAM_HOME"
mkdir -p "$MAM_HOME" "$icon/Contents/MacOS"; printf '#!/bin/bash\nexport MAM_HOME=/elsewhere\n' > "$icon/Contents/MacOS/launch"
"$mam" uninstall --yes >/dev/null
[[ -f $icon/Contents/MacOS/launch ]]
echo "install test: ok"
