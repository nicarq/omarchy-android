#!/usr/bin/env bash
set -Eeuo pipefail

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/source" && pwd -P)"
extras_dir="$(dirname -- "$source_dir")"
[[ "$(id -u)" == 0 && -f /etc/omarchy-android-release ]] || {
  printf 'Run through scripts/install-btop-android.sh in Termux.\n' >&2
  exit 1
}

# Use the image's existing package database; do not upgrade the graphics stack.
pacman -S --needed --noconfirm gcc make
make -C "$source_dir" THREADS=2 GPU_SUPPORT=false LTO= QUIET=true
python3 "$extras_dir/smoke.py" "$source_dir/bin/btop"

install -Dm755 "$source_dir/bin/btop" /usr/local/libexec/btop-android.new
mv -f /usr/local/libexec/btop-android.new /usr/local/libexec/btop-android
install -Dm755 "$extras_dir/btop" /usr/local/bin/btop
install -Dm644 "$source_dir/LICENSE" /usr/local/share/licenses/btop-android/LICENSE
install -Dm644 "$extras_dir/android.patch" /usr/local/share/btop-android/android.patch
printf '%s\n' 'btop v1.4.7, commit 6e39144aaf5a6bc01b9f795010b0914431067183' \
  > /usr/local/share/btop-android/SOURCE
sha256sum "$extras_dir/android.patch" /usr/local/libexec/btop-android \
  >> /usr/local/share/btop-android/SOURCE
python3 "$extras_dir/configure.py"
chown -R omarchy:omarchy /home/omarchy/.config/btop
printf 'Installed Android btop. Open a new terminal and run btop.\n'
