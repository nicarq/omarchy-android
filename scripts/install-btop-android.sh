#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
revision=6e39144aaf5a6bc01b9f795010b0914431067183
if (( $# != 0 )) || [[ -z "${PREFIX:-}" || ! -x "$PREFIX/bin/proot-distro" ]]; then
  printf 'Run %s without arguments inside Termux after installing Omarchy.\n' "$0" >&2
  exit 2
fi

build_dir="$(mktemp -d "${TMPDIR:-$PREFIX/tmp}/btop-android.XXXXXX")"
trap 'rm -rf -- "$build_dir"' EXIT
git init -q "$build_dir/source"
git -C "$build_dir/source" fetch --depth 1 https://github.com/aristocratos/btop.git "$revision"
git -C "$build_dir/source" checkout -q --detach FETCH_HEAD
[[ "$(git -C "$build_dir/source" rev-parse HEAD)" == "$revision" ]]
git -C "$build_dir/source" apply "$ROOT/extras/btop/android.patch"
cp "$ROOT"/extras/btop/{android.patch,btop,configure.py,install-guest.sh,smoke.py} "$build_dir/"

proot-distro login --isolated --bind "$build_dir:/opt/btop-android-build" \
  omarchy-android -- bash /opt/btop-android-build/install-guest.sh
