#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
temporary_root="$(mktemp -d)"
trap 'rm -rf -- "$temporary_root"' EXIT
cp "$ROOT/runtime/host/omarchy-android-reflow" "$temporary_root/reflow"
cat > "$temporary_root/omarchy-android-hyprctl" <<'EOF'
#!/usr/bin/env bash
set -eu
directory="$(dirname -- "$0")"
if [[ -f "$directory/unavailable" ]]; then exit 1; fi
if [[ "$1" == monitors ]]; then
  if [[ -f "$directory/sampled" ]]; then
    touch "$directory/ready"
    echo '  1728x1660@60.00000 at 0x0'
  else
    touch "$directory/sampled"
    echo '  960x1920@60.00000 at 0x0'
  fi
elif [[ "$1" == eval ]]; then
  test -f "$directory/ready"
    touch "$directory/reflowed"
fi
EOF
chmod +x "$temporary_root/omarchy-android-hyprctl"

# A configure event can reach X11 before the nested compositor processes it.
bash "$temporary_root/reflow" 1728 1660
test -f "$temporary_root/reflowed"

rm "$temporary_root/reflowed"
touch "$temporary_root/unavailable"
# The first resize happens before Hyprland has started on a cold launch.
bash "$temporary_root/reflow" 1728 1660
test ! -e "$temporary_root/reflowed"
if bash "$temporary_root/reflow" invalid 1660; then
  echo 'Reflow accepted invalid dimensions' >&2
  exit 1
fi
printf 'display reflow tests passed\n'
