# btop on rootless Android

The stock ARM64 btop 1.4.7 can exit in `Shared::init()` with permission denied
for `/sys/devices`. Android restricts these hardware and kernel interfaces,
even when PRoot presents the guest user as root.

This optional patch skips restricted probes when `BTOP_ANDROID_PROOT=1`.
It displays real system memory and readable Termux processes. Process CPU
percentages use elapsed `CLOCK_BOOTTIME` and readable task CPU ticks.
System CPU, sensors, and network throughput are explicitly unavailable;
the PRoot guest's static `/proc/stat`, `/proc/uptime`, and `/proc/loadavg`
substitutes must not be shown as live phone statistics.

## Install

From this repository in **Termux**, with Omarchy already installed:

```bash
./scripts/install-btop-android.sh
```

The installer fetches upstream btop v1.4.7 at commit
`6e39144aaf5a6bc01b9f795010b0914431067183`, applies `android.patch`, and
compiles with two jobs inside the existing guest. It installs GCC and Make
from the guest's existing package database if needed. Allow approximately
300 MB for build dependencies, plus source and build space. It does not run
a system upgrade. If those pinned package versions have disappeared from
the mirror, stop and review package availability before upgrading the guest.

The build must pass a terminal test covering startup, all four panels,
live refresh, resize, and clean exit before installation. The new binary is
`/usr/local/libexec/btop-android`; `/usr/local/bin/btop` enables its Android
profile. The package-owned `/usr/bin/btop` remains available. The configuration
keeps the existing theme, shows CPU availability, memory and processes, and
disables hardware/disk probes. Its first backup is `btop.conf.before-android`
in `~/.config/btop`.

Open a new Omarchy terminal and run `btop`, or run `hash -r` in an existing
Bash terminal first. Other Android apps' processes remain inaccessible.
Recompilation may be required after a future guest C++ runtime upgrade.

## Undo

As the guest's PRoot root user, remove `/usr/local/bin/btop` and
`/usr/local/libexec/btop-android`. Restore `~omarchy/.config/btop/btop.conf`
from its `.before-android` backup if desired. The original packaged btop
will again be selected and will still have Android's original limitations.

This optional component is separate from the prebuilt release image and its
component lock. The installed source revision, patch, binary checksum, and
Apache-2.0 license are retained under `/usr/local/share/btop-android` and
`/usr/local/share/licenses/btop-android`. The patch was AI generated and
compiled and tested on the Android 17 Pixel Fold; it is not an upstream release.
