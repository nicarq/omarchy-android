#!/usr/bin/env bash

# Keep a bundled libweston-14 module out of newer Termux Weston processes.
# The compatibility renderer uses the X11 backend shipped with Termux Weston.
select_weston_x11_module() {
  local mode="$1" bundled_module="$2" version
  if [[ ${OMARCHY_WESTON_X11_MODULE+x} ]]; then
    printf '%s' "$OMARCHY_WESTON_X11_MODULE"
    return 0
  fi
  case "$mode" in
    virgl) return 0 ;;
    kgsl)
      version="$(weston --version)" || return 1
      if [[ ! "$version" =~ ^weston[[:space:]]+14\. ]]; then
        printf 'The bundled KGSL backend requires Weston 14; found %s. Use --gpu software or build a matching backend.\n' "$version" >&2
        return 1
      fi
      printf '%s' "$bundled_module"
      ;;
    *) printf 'Unsupported GPU mode: %s\n' "$mode" >&2; return 1 ;;
  esac
}
