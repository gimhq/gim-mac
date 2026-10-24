#!/usr/bin/env bash
# Vendors a gim-core Apple build (Swift package with GIMCore.xcframework.zip) from a gim-client-sdk CI run or a
# local dir.
#
#   scripts/sync-gim-core.sh <gim-client-sdk run id>
#   scripts/sync-gim-core.sh --from-dir <dir> --core-sha <sha>
#
# The first form downloads the `gim-core-ios-<head sha>` artifact of the run with `gh`. The second form uses a
# directory with the same layout as that artifact. Either way the zip is verified against its .sha256,
# Vendor/GIMCore is replaced with the artifact contents and Vendor/GIMCore/GIM_CORE_VERSION is written
# (`<core version>+<short sha>`).
set -euo pipefail

usage() {
    echo "usage: $0 <gim-client-sdk run id>" >&2
    echo "       $0 --from-dir <dir> --core-sha <sha>" >&2
    exit 2
}

core_repo=gimhq/gim-client-sdk
from_dir=
core_sha=
run_id=
if [[ $# -eq 1 && $1 != -* ]]; then
    run_id=$1
elif [[ $# -eq 4 ]]; then
    while [[ $# -gt 0 ]]; do
        case $1 in
        --from-dir) from_dir=$2 ;;
        --core-sha) core_sha=$2 ;;
        *) usage ;;
        esac
        shift 2
    done
    if [[ -z $from_dir || -z $core_sha ]]; then
        usage
    fi
    core_sha=${core_sha,,}
    if [[ ! $core_sha =~ ^[0-9a-f]{7,40}$ ]]; then
        echo "error: --core-sha must be 7-40 hex characters, got '$core_sha'" >&2
        exit 2
    fi
    if [[ ! -d $from_dir ]]; then
        echo "error: $from_dir is not a directory" >&2
        exit 1
    fi
else
    usage
fi

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
vendor=$repo/Vendor/GIMCore

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

if [[ -n $run_id ]]; then
    head_sha=$(gh run view "$run_id" -R "$core_repo" --json headSha -q .headSha)
    if [[ ! $head_sha =~ ^[0-9a-f]{40}$ ]]; then
        echo "error: unexpected head sha '$head_sha' for run $run_id" >&2
        exit 1
    fi
    artifact=gim-core-ios-$head_sha

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    echo "Downloading $artifact from $core_repo run $run_id"
    gh run download "$run_id" -R "$core_repo" -n "$artifact" -D "$tmp"
    src=$tmp
else
    head_sha=$core_sha
    src=$(cd "$from_dir" && pwd)
    echo "Using $src (gim-core $head_sha)"
fi

zip=$src/GIMCore.xcframework.zip
for file in "$src/Package.swift" "$zip" "$zip.sha256" "$src/Sources/GIMCore/GIMCore.swift" "$src/GIM_CORE_VERSION"; do
    if [[ ! -f $file ]]; then
        echo "error: artifact is missing ${file#"$src"/}" >&2
        exit 1
    fi
done

expected=$(cut -d' ' -f1 <"$zip.sha256" | tr -d '[:space:]')
actual=$(sha256 "$zip")
if [[ $expected != "$actual" ]]; then
    echo "error: checksum mismatch for GIMCore.xcframework.zip (expected $expected, got $actual)" >&2
    exit 1
fi

core_version=$(tr -d '[:space:]' <"$src/GIM_CORE_VERSION")
version=${core_version%%+*}+${head_sha:0:7}

rm -rf "$vendor"
mkdir -p "$vendor"
cp -R "$src/." "$vendor/"
echo "$version" >"$vendor/GIM_CORE_VERSION"

echo "Vendored gim-core $version (sha256 $actual)"
