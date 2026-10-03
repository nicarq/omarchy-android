# Android 17 and Pixel compatibility

This fork targets the rootless Termux route on ARM64 Pixels. It does not
replace Android, unlock the bootloader, or turn the phone into a native Arch
Linux installation. Android API support and an APK's target SDK are separate
from whether the Omarchy desktop works on a particular GPU.

## Android app dependencies

`manifest/android-apps.lock` records official APK URLs and SHA-256 checksums.
Run `./scripts/download-android-apps.sh` to download and verify them on a
computer. No APK is rebuilt or re-signed by this fork.

- Termux: upstream stable v0.118.3, ARM64, target SDK 28.
- Termux:X11: official nightly published 2026-10-01, **standalone** flavor,
  target SDK 34. Its source revision is pinned in `manifest/components.lock`.

The standalone X11 flavor installed on the Android 17 test device without
the old-target Play Protect block. The shared-UID flavor targets SDK 28 and
was blocked with that warning. Standalone keeps a separate app UID; Termux
may receive less CPU time when only X11 is foreground, so performance needs
to be measured rather than assumed.

Termux itself still uses target SDK 28. Upstream documents that raising the
target activates Android's restriction on executing files from writable app
data. Changing an Omarchy dependency pin cannot solve that architectural
constraint. Installation may require an explicit per-app approval on the
phone. This fork does not disable Play Protect or automate those approvals.

The stable debug Termux APK can also show a 16 KB ELF-alignment warning.
The test phone currently uses 4 KB kernel pages; that does not establish
support for a phone running a 16 KB kernel.

Sources: [X11 build flavors](https://github.com/termux/termux-x11/blob/0e1ebb4c180f4e8e7a14a80f7cd0db8301791b6d/lorie-app/build.gradle),
[Termux target-SDK constraint](https://github.com/termux/termux-packages/wiki/Termux-and-Android-10),
[Android 17 behavior changes](https://developer.android.com/about/versions/17/behavior-changes-all).

## Pixel graphics and current Termux packages

Use the compatibility renderer on a Pixel without `/dev/kgsl-3d0`:

```bash
pkg update -y
pkg upgrade -y
./install.sh doctor --gpu software
./install.sh --yes --gpu software --refresh 60 --share none
```

Enable Developer options -> **Disable child process restrictions** before
installation. Keep Termux running when using Termux:X11.

The compatibility path uses VirGL for the guest and pixman for Weston. It
loads the X11 backend supplied by the installed Termux Weston package,
including Weston 16. It does not inject the release bundle's Weston 14 module
into Weston 16. Automatic refresh defaults to 60 Hz for this path. The
launcher also disables KGSL-specific DMA-BUF advertisement and export by
default in VirGL mode. These flags were enabled unconditionally upstream;
disabling them allowed the Pixel's guest desktop to start. The bundled KGSL
backend still requires Weston 14; the launcher reports an ABI
mismatch instead of trying to load it into a newer Weston.

`OMARCHY_WESTON_X11_MODULE` is an advanced override for a locally built,
ABI-matching module. An explicitly empty value selects Weston's own module.
The default stock compatibility backend advertises 60 Hz; a different
requested guest refresh does not guarantee a different presentation rate.

Android 17 also changes memory limits, background audio, keyboard restoration,
and pointer capture. A successful installation does not prove those features
or suspend/resume behavior; verify them on the actual phone. No global memory
limit or audio protection is changed by this fork.

## Validation record

Device checks on 2026-10-03: Pixel 11 Pro Fold, Android 17 / API 37, ARM64,
PowerVR graphics, 4096-byte kernel pages. No device identifiers are recorded.

- Both official Android apps installed; standalone X11 targets SDK 34.
- Termux package candidates/install: Weston 16.0.0, PRoot Distro 5.9.0,
  Termux:X11 companion 1.03.01-6, VirGL renderer 1.3.0-1.
- Installer doctor passes required checks; GPU selects VirGL/pixman fallback.
- The upstream v0.1.1 guest installed and passed all installed-image smoke
  tests, including Hyprland, Chromium, Foot, and Quickshell version checks.
- Weston 16 loaded its own X11 backend with pixman. VirGL, Hyprland and
  Omarchy Shell started; `hyprctl monitors` reported 960x1920 at 60 Hz, scale 2.
- Foot opened as a native Wayland window and accepted Android keyboard input;
  `uname -m` returned `aarch64`. Hyprland reported no configuration errors.
- A complete stop and restart passed with the final mode-specific defaults
  and normal logging. Omarchy Shell and Foot started again.
- Audio, Chromium rendering, fold/unfold transitions, suspend/resume, and
  sustained performance have not been validated.

Launch the desktop from the actual Termux terminal. Starting its graphics
processes under ADB `run-as` uses a different Android security context and
failed Weston's shared-memory allocation during testing. ADB `run-as` was
usable for file transfer and non-graphical installation checks.

The guest remains the checksummed upstream v0.1.1 image. Its patched Mesa,
Aquamarine, Hyprland, and Omarchy package set has not been blindly upgraded;
those components need a coordinated rebuild and graphics validation.
