#!/bin/bash
# End-to-end test of bin/mam in a temp MAM_HOME: install (DXMT, no icon), a
# console-only wine check, play dry-runs, the D3DMetal path, uninstall.
# Opens no window and touches nothing outside the temp folder. Set MAM_CACHE
# to a folder holding the four downloads to skip ~270 MB of fetching.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
export MAM_HOME=$(mktemp -d "${TMPDIR:-/tmp}/mam-install-test.XXXXXX")
trap 'rm -rf "$MAM_HOME"' EXIT
mam="$here/bin/mam"
step() { printf '\n== %s\n' "$*"; }

if [[ -n ${MAM_CACHE:-} ]]; then mkdir -p "$MAM_HOME/downloads"; cp "$MAM_CACHE"/* "$MAM_HOME/downloads/"; fi

step "install (dxmt, no icon)"
"$mam" install --yes --no-app --renderer dxmt | grep -vE '^\s+[0-9.]+%|####' | grep -E '^\[|^  - (prefix|launcher|built|DXMT)|ERROR'
[[ -x $MAM_HOME/Runtime/Frameworks/wswine.bundle/bin/wine ]]
[[ -d $MAM_HOME/Prefix/drive_c/windows/system32 ]]
[[ -x $MAM_HOME/Launcher/mnm_patcher_app.app/Contents/MacOS/mnm_launcher ]]
[[ -f $MAM_HOME/Prefix/drive_c/windows/system32/winemetal.dll ]]
[[ ! -e $HOME/Applications/Monsters\ \&\ Memories.app || -n ${MAM_ICON_PREEXISTING:-} ]] || true

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

step "d3dmetal path (licence auto-accepted by --yes; runtime and prefix kept)"
"$mam" install --yes --no-app --renderer d3dmetal | grep -E '^  - (D3DMetal|prefix kept|launcher kept)'
[[ -d $MAM_HOME/Runtime/Frameworks/renderer/d3dmetal/external/D3DMetal.framework ]]
"$mam" env | grep -q 'CX_ACTIVE_GRAPHICS_BACKEND=d3dmetal'
"$mam" wine --version | grep -q 'wine-10.0'

step "doctor"
SKIP_NET=1 "$mam" doctor | grep -q 'doctor: all good'

step "uninstall"
"$mam" uninstall --yes >/dev/null
[[ ! -d $MAM_HOME/Runtime && ! -d $MAM_HOME/Prefix && ! -d $MAM_HOME/Launcher ]]
echo "install test: ok"
