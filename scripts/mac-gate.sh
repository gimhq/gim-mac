#!/usr/bin/env bash
# Builds and tests a commit on the shared macOS build host from station.
#
#   scripts/mac-gate.sh build-test [--sha <commit>] [--keep]
#
# Ships `git archive <sha>` (default HEAD, which needs a clean tree) to ~/gim-ci/<id>-<short sha>/gim-mac/ on the Mac
# (GIM_MAC_HOST, default a@100.99.1.8; id = GIM_GATE_ID, default the last component of the branch name) and
# `git archive` of Packages/GIMKit from gim-ios (GIM_IOS_REPO, default /srv/gimhq/gim-ios; GIM_IOS_REF, default HEAD)
# to ~/gim-ci/<id>-<short sha>/gim-ios/, so project.yml's ../gim-ios/Packages/GIMKit resolves. There, under the shared
# lock ~/gim-ci/.lock-xcode, it runs xcodegen, builds the GIM app, runs the GIMTests unit tests and `swift test` of
# GIMKit. Raw xcodebuild logs, the xcbeautify output and the zipped xcresult bundles are copied to
# .tmp/mac/<short sha>/. Prints one `[mac-gate] mode=build-test sha=… ios=… build=… app-tests=… kit=…` summary line and
# exits non-zero on any failure. The Mac work dir is removed on success and kept on failure or with --keep.
set -euo pipefail

usage() {
    echo "usage: $0 build-test [--sha <commit>] [--keep]" >&2
    exit 2
}

[[ $# -ge 1 ]] || usage
mode=$1
shift
[[ $mode == build-test ]] || usage
sha=
keep=
while [[ $# -gt 0 ]]; do
    case $1 in
    --sha)
        [[ $# -ge 2 ]] || usage
        sha=$2
        shift 2
        ;;
    --keep)
        keep=1
        shift
        ;;
    *)
        usage
        ;;
    esac
done

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
host=${GIM_MAC_HOST:-a@100.99.1.8}
id=${GIM_GATE_ID:-$(git -C "$repo" branch --show-current | sed 's|.*/||')}
ios_repo=${GIM_IOS_REPO:-/srv/gimhq/gim-ios}
ios_ref=${GIM_IOS_REF:-HEAD}
if [[ -z $sha ]]; then
    if [[ -n $(git -C "$repo" status --porcelain --untracked-files=no) ]]; then
        echo "error: the working tree has uncommitted changes; commit them or pass --sha" >&2
        exit 1
    fi
    sha=HEAD
fi
sha=$(git -C "$repo" rev-parse --verify "$sha^{commit}")
short=${sha:0:7}
ios_sha=$(git -C "$ios_repo" rev-parse --verify "$ios_ref^{commit}")
ios_short=${ios_sha:0:7}
name=$id-$short
root=gim-ci/$name
work=$root/gim-mac
local_out=$repo/.tmp/mac/$short

mac() {
    ssh -o BatchMode=yes -o ServerAliveInterval=30 "$host" "$@"
}

# Runs on the Mac with /bin/bash (3.2) as `gate.sh <name> <short sha> <gim-ios short sha>` from the gim-mac work dir.
# shellcheck disable=SC2016
remote_script='
set -uo pipefail
name=$1 short=$2 ios_short=$3
eval "$(/opt/homebrew/bin/brew shellenv)"
work=$PWD
out=$work/.tmp/gate
results=$work/.tmp/results
derived=$work/.tmp/DerivedData
lock=$HOME/gim-ci/.lock-xcode
owner="$name pid=$$ since $(date -u +%Y-%m-%dT%H:%M:%SZ)"
signing="CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM="
locked=""
build=fail app_tests=fail kit=fail
mkdir -p "$out" "$results"

cleanup() {
    if [ -n "$locked" ]; then
        current=$(cat "$lock/owner" 2>/dev/null)
        if [ -z "$current" ] || [ "$current" = "$owner" ]; then
            rm -f "$lock/owner"
            rmdir "$lock" && echo "[mac-gate] released $lock"
        else
            echo "[mac-gate] $lock is owned by \"$current\", leaving it" >&2
        fi
    fi
}
trap cleanup EXIT
trap "exit 129" HUP INT TERM

# Polls every 20 s for up to 40 min.
for attempt in $(seq 1 120); do
    if mkdir "$lock" 2>/dev/null; then
        locked=1
        echo "$owner" >"$lock/owner"
        break
    fi
    echo "[mac-gate] waiting for $lock held by: $(cat "$lock/owner" 2>/dev/null || echo unknown) ($attempt/120)"
    sleep 20
done
if [ -z "$locked" ]; then
    echo "[mac-gate] error: $lock not acquired within 40 min" >&2
    exit 1
fi
echo "[mac-gate] acquired $lock"

# Runs a command with its output tee-d to $out/<log>.log and piped to xcbeautify ($out/<log>.xcbeautify.log).
run() {
    log=$1
    shift
    echo "[mac-gate] $log: $*"
    "$@" 2>&1 | tee "$out/$log.log" | xcbeautify --disable-colored-output | tee "$out/$log.xcbeautify.log"
}

# Like run, without xcbeautify (swift test output).
run_plain() {
    log=$1
    shift
    echo "[mac-gate] $log: $*"
    "$@" 2>&1 | tee "$out/$log.log"
}

# shellcheck disable=SC2086
if xcodegen generate >"$out/xcodegen.log" 2>&1 \
    && run build xcodebuild build -project GIM.xcodeproj -scheme GIM -destination "platform=macOS" \
        -derivedDataPath "$derived" -resultBundlePath "$results/GIM-build.xcresult" $signing; then
    build=ok
fi
if [ "$build" = ok ]; then
    # shellcheck disable=SC2086
    run app-tests xcodebuild test -project GIM.xcodeproj -scheme GIM -destination "platform=macOS" \
        -derivedDataPath "$derived" -resultBundlePath "$results/GIM-tests.xcresult" $signing && app_tests=ok
fi
run_plain kit-test swift test --package-path ../gim-ios/Packages/GIMKit && kit=ok

for bundle in "$results"/*.xcresult; do
    [ -d "$bundle" ] && ditto -c -k --keepParent "$bundle" "$out/$(basename "$bundle").zip"
done

summary="[mac-gate] mode=build-test sha=$short ios=$ios_short build=$build app-tests=$app_tests kit=$kit"
echo "$summary" >"$out/summary.txt"
case "$build $app_tests $kit" in
*fail*) exit 1 ;;
esac
'

echo "[mac-gate] shipping $sha and gim-ios $ios_sha (GIMKit) to $host:~/$root"
mac "rm -rf ~/$root && mkdir -p ~/$work/.tmp ~/$root/gim-ios"
git -C "$repo" archive "$sha" | mac "tar -x -C ~/$work"
git -C "$ios_repo" archive "$ios_sha" Packages/GIMKit | mac "tar -x -C ~/$root/gim-ios"
printf '%s' "$remote_script" | mac "cat >~/$work/.tmp/gate.sh"

status=0
# shellcheck disable=SC2029
mac "cd ~/$work && /bin/bash .tmp/gate.sh $name $short $ios_short" </dev/null || status=$?

rm -rf "$local_out"
mkdir -p "$local_out"
mac "tar -c -C ~/$work/.tmp/gate ." | tar -x -C "$local_out" || status=1

summary=$(cat "$local_out/summary.txt" 2>/dev/null || true)
if [[ -z $summary ]]; then
    summary="[mac-gate] mode=$mode sha=$short ios=$ios_short build=fail app-tests=fail kit=fail"
    status=1
fi
echo "[mac-gate] logs and xcresult bundles in $local_out"
if [[ $status -eq 0 && -z $keep ]]; then
    mac "rm -rf ~/$root"
else
    echo "[mac-gate] kept $host:~/$root"
fi
echo "$summary"
exit "$status"
