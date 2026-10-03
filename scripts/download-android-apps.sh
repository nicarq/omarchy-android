#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
destination="${1:-$ROOT/dist/android-apps}"
if (( $# > 1 )) || [[ "$destination" == --* ]]; then
  printf 'usage: %s [DESTINATION]\n' "$0" >&2
  exit 2
fi
mkdir -p "$destination"
temporary_file=''
trap '[[ -z "$temporary_file" ]] || rm -f -- "$temporary_file"' EXIT

checksum() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

while IFS='|' read -r name filename target_sdk url expected extra; do
  [[ -n "$name" && "$name" != \#* ]] || continue
  if [[ ! "$filename" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*\.apk$ ||
        ! "$target_sdk" =~ ^[0-9]+$ ||
        "$url" != https://github.com/termux/*/releases/download/* ||
        ! "$expected" =~ ^[0-9a-f]{64}$ || -n "$extra" ]]; then
    printf 'Invalid Android app lock record: %s\n' "$name" >&2
    exit 1
  fi
  target="$destination/$filename"
  if [[ -e "$target" ]]; then
    if [[ "$(checksum "$target")" != "$expected" ]]; then
      printf 'Checksum mismatch for existing file: %s\n' "$target" >&2
      exit 1
    fi
  else
    temporary_file="$(mktemp "$destination/.apk-download.XXXXXX")"
    curl --fail --location --retry 3 --proto '=https' --proto-redir '=https' \
      --output "$temporary_file" "$url"
    if [[ "$(checksum "$temporary_file")" != "$expected" ]]; then
      printf 'Checksum mismatch for %s. The nightly may have changed; review upstream before updating the lock.\n' "$name" >&2
      exit 1
    fi
    mv -- "$temporary_file" "$target"
    temporary_file=''
  fi
  printf 'Verified %s (target SDK %s): %s\n' "$name" "$target_sdk" "$target"
done < "$ROOT/manifest/android-apps.lock"
