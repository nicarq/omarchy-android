#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
export PROJECT_ROOT
source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/options.sh"
source "$PROJECT_ROOT/lib/install.sh"
source "$PROJECT_ROOT/lib/graphics.sh"

temporary_root="$(mktemp -d)"
trap 'rm -rf -- "$temporary_root"' EXIT

# Logging must not become part of the path captured by the installer.
OA_INSTALL_TEMP="$temporary_root"
curl() { return 0; }
bundle="$(download_release_bundle 2>"$temporary_root/download.log")"
[[ "$bundle" == "$temporary_root/$(release_field asset)" ]]
grep -F 'Downloading verified stable ARM64 release' "$temporary_root/download.log" >/dev/null
unset -f curl

OA_PREFIX="$temporary_root"
OA_GPU=software
OA_REFRESH=auto
mkdir -p "$OA_PREFIX/config"
write_runtime_config
grep -Fx 'OMARCHY_GPU_MODE=virgl' "$OA_PREFIX/config/runtime.conf" >/dev/null
grep -Fx 'OMARCHY_REFRESH_MHZ=60000' "$OA_PREFIX/config/runtime.conf" >/dev/null
OA_REFRESH=90
write_runtime_config
grep -Fx 'OMARCHY_REFRESH_MHZ=90000' "$OA_PREFIX/config/runtime.conf" >/dev/null

unset OMARCHY_WESTON_X11_MODULE
weston() { printf 'weston 16.0.0\n'; }
[[ -z "$(select_weston_x11_module virgl /bundled/libweston-14/x11-backend.so)" ]]
if select_weston_x11_module kgsl /bundled/libweston-14/x11-backend.so 2>/dev/null; then
  printf 'Accepted a Weston 14 backend for Weston 16\n' >&2
  exit 1
fi
weston() { printf 'weston 14.0.2\n'; }
[[ "$(select_weston_x11_module kgsl /bundled/libweston-14/x11-backend.so)" == /bundled/libweston-14/x11-backend.so ]]
OMARCHY_WESTON_X11_MODULE=/custom/x11-backend.so
[[ "$(select_weston_x11_module virgl /unused)" == /custom/x11-backend.so ]]
OMARCHY_WESTON_X11_MODULE=''
[[ -z "$(select_weston_x11_module kgsl /unused)" ]]
printf 'installer compatibility tests passed\n'
