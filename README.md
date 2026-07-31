# Firefox for ROCKNIX

Run Mozilla's official Linux ARM64 Firefox build on the Retroid Pocket Flip 2
with touchscreen support, controller-based mouse controls, and a Wayland
onscreen keyboard. Everything installs under `/storage`; the immutable ROCKNIX
system partition is not modified.

> This is an independent community project and is not affiliated with Mozilla
> or ROCKNIX.

## Status

| Device | ROCKNIX build | Status |
|---|---|---|
| Retroid Pocket Flip 2 (SM8250) | Nightly `20260731` | Tested and working |
| Other ARM64 ROCKNIX devices | — | Untested |

## Installation

1. Download `rocknix-firefox-clean-installer-v6.tar.gz`.
2. Using SMB/SFTP, copy it to:

   ```text
   /storage/roms/_installers/firefox
   ```

3. Connect to ROCKNIX through SSH and run:

   ```sh
   cd /storage/roms/_installers/firefox
   tar -xzf rocknix-firefox-clean-installer-v6.tar.gz
   chmod +x *.sh
   ./install.sh
   ```

4. In EmulationStation, select:

   ```text
   START → Game Settings → Update Gamelists
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
| B | Back |
| X | Reload page |
| Y | Show/hide onscreen keyboard |
| D-pad | Arrow keys |
| L1 / R1 | Scroll up/down |
| Left stick up/down | Page up/down |
| Start | Enter |
| Select | Tab |
| Home / Guide | Exit Firefox |

To type, select a text field and press **Y**. Press **Y** again to hide the
keyboard.

Developed with the help of [OpenAI Codex](https://openai.com/codex/).
