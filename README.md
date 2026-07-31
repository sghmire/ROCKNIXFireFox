# Firefox for ROCKNIX

Run Mozilla's official Linux ARM64 Firefox build on the Retroid Pocket Flip 2
with touchscreen, gamepad mouse controls, and a Wayland onscreen keyboard.

> [!IMPORTANT]
> This is an independent community project. It is not affiliated with or
> supported by Mozilla or the ROCKNIX project.

## Status

| Device | ROCKNIX build | Status |
|---|---|---|
| Retroid Pocket Flip 2 (SM8250) | Nightly `20260731` | Tested and working |
| Other ARM64 ROCKNIX devices | — | Untested |

## Features

- Downloads Mozilla's current official Linux ARM64 Firefox release.
- Installs entirely under `/storage`; the immutable ROCKNIX system partition is
  not modified.
- Adds a `Ports > Firefox` launcher to EmulationStation.
- Maps the built-in controller to mouse and keyboard actions through
  InputPlumber.
- Provides a touchscreen keyboard using ROCKNIX's bundled `wvkbd`.
- Restores the normal ROCKNIX controller configuration when Firefox exits.
- Preserves the previous Firefox application during an update.

## Requirements

- A Retroid Pocket Flip 2 running a recent ARM64 ROCKNIX build.
- Network access on the handheld.
- SSH enabled in ROCKNIX.
- `curl` or `wget` available on the handheld.
- At least 750 MB of free space under `/storage` to allow installation and one
  retained update backup.

## Installation

### 1. Transfer the installer

Download `rocknix-firefox-clean-installer-v5.tar.gz` from the project's GitHub
release page.

When using the ROCKNIX SMB share, open `games-roms` and copy the archive into:

```text
_installers/firefox
```

This directory appears on the handheld as:

```text
/storage/roms/_installers/firefox
```

### 2. Run the installer

Connect to the handheld through SSH, then run:

```sh
cd /storage/roms/_installers/firefox
tar -xzf rocknix-firefox-clean-installer-v5.tar.gz
chmod +x *.sh
./install.sh
```

The installer downloads Firefox directly from Mozilla and installs it at:

```text
/storage/apps/firefox-rocknix
```

### 3. Launch Firefox

Refresh the EmulationStation game list:

```text
START → Game Settings → Update Gamelists
```

Then open:

```text
Ports → Firefox
```

Firefox can also be launched over SSH:

```sh
/storage/apps/firefox-rocknix/launch.sh
```

## Controls

| Control | Browser action |
|---|---|
| Right stick | Mouse pointer |
| A or R2 | Left-click |
| L2 | Right-click |
| B | Escape / close menu |
| X | Reload page |
| Y | Show or hide the onscreen keyboard |
| D-pad | Arrow keys |
| L1 / R1 | Scroll up / down |
| Left stick up / down | Page up / down |
| Start | Enter |
| Select | Tab |
| L1 + Select + Start | Exit Firefox |

To enter text, select a text field and press **Y**. Press **Y** again to hide
the keyboard.

## Updating Firefox

Run the installer again:

```sh
./install.sh
```

The installer downloads Mozilla's latest ARM64 release and retains the previous
application as `firefox.previous` until the next successful update.

## Clean reinstall

From the extracted installer directory, run:

```sh
./reset-firefox.sh
./install.sh
```

The reset removes the Firefox application and Ports launcher, then restores the
normal ROCKNIX input services. It deliberately preserves browser data at:

```text
/storage/.mozilla/firefox-rocknix
```

For a completely fresh profile, close Firefox and move the existing profile to
a backup location before reinstalling:

```sh
mv /storage/.mozilla/firefox-rocknix \
   /storage/.mozilla/firefox-rocknix.backup
```

## Troubleshooting

### Firefox does not launch

View the dependency report and application log:

```sh
cat /storage/apps/firefox-rocknix/diagnostics.txt
tail -n 150 /storage/apps/firefox-rocknix/logs/firefox.log
```

### Controller does not return after Firefox exits

Restart InputPlumber:

```sh
systemctl restart inputplumber.service
```

### Onscreen keyboard does not appear

Confirm that Firefox loaded its controller profile and that `wvkbd` is running:

```sh
inputplumber device 0 info
pidof wvkbd-mobintl
```

The profile name should be `Firefox Browser`. The current integration maps **Y**
to the keyboard toggle.

### Remove a stuck Firefox process

```sh
pkill -f '/storage/apps/firefox-rocknix/firefox'
systemctl restart inputplumber.service
```

## Persistent files

| Purpose | Device path |
|---|---|
| Firefox application | `/storage/apps/firefox-rocknix/firefox` |
| Controller integration and logs | `/storage/apps/firefox-rocknix` |
| Firefox profile | `/storage/.mozilla/firefox-rocknix` |
| EmulationStation launcher | `/storage/roms/ports/Firefox.sh` |

## Known limitations

- Only the Retroid Pocket Flip 2 SM8250 has been tested so far.
- The keyboard must be opened manually because `wvkbd` does not reliably receive
  Firefox text-field focus notifications.
- DRM streaming services such as Netflix, Prime Video, and Disney+ are not
  expected to work because Widevine is not officially available for Linux
  ARM64 Firefox.
- Hardware-accelerated video decoding on Qualcomm Venus may vary by ROCKNIX and
  Firefox version. YouTube can fall back to software decoding.
- Firefox may emit harmless GTK pixbuf and Freedreno shader warnings in its log.

## How it works

The installer downloads Firefox from Mozilla's official ARM64 redirect and
runs it natively through Sway/Wayland. A temporary InputPlumber profile provides
gamepad mouse and keyboard events. The launcher runs Firefox on a dedicated
Sway workspace so the `wvkbd` layer can reserve screen space, and restores the
standard controller profile when the browser closes.

The Firefox process sandbox remains enabled. The installer does not replace or
bundle glibc, Mesa, or ROCKNIX graphics drivers.

## Acknowledgements

- [Mozilla Firefox](https://www.firefox.com/)
- [ROCKNIX](https://rocknix.org/)
- [InputPlumber](https://github.com/ShadowBlip/InputPlumber)
- [wvkbd](https://github.com/jjsullivan5196/wvkbd)

## Contributing

Reports from other ARM64 ROCKNIX devices are welcome. Please include the device
model, ROCKNIX build, and the contents of `diagnostics.txt` when reporting a
launch or compatibility problem.

Developed with the help of [OpenAI Codex](https://openai.com/codex/).
