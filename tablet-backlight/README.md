# Tablet-mode keyboard backlight

Turns the keyboard backlight off when an ASUS ProArt PX13 enters tablet mode,
then restores its previous brightness when the laptop is unfolded.

## Why this is needed

The PX13 firmware already detects when the display is folded and disables the
physical keyboard. On some Linux installations, however, the firmware's
lid-flip state is not exposed as a standard tablet-mode switch, and the
keyboard light stays on.

This tool:

1. Configures the `asus_nb_wmi` driver to expose the ASUS lid-flip state as
   Linux `SW_TABLET_MODE`.
2. Runs a small service that listens for that switch.
3. Saves the current keyboard brightness, turns it off in tablet mode, and
   restores the saved level in laptop mode.

It does not modify the laptop firmware.

## Requirements

- ASUS ProArt PX13 from the HN7306 family
- Linux with `systemd`
- Python 3
- The `asus_nb_wmi` kernel module
- `/sys/class/leds/asus::kbd_backlight`

It was developed on an HN7306WU running Fedora Linux. The installer refuses
unknown models unless explicitly run with `--force`.

## Install

Clone the repository and run:

```bash
cd asus-proart-px13-linux
sudo ./tablet-backlight/install.sh
sudo systemctl reboot
```

The reboot is required because the ASUS kernel driver reads its tablet-mode
option when the module loads.

After reboot, fold and unfold the display. The light should switch off and
return to its previous level.

## Check its status

```bash
systemctl status asus-tablet-backlight.service
journalctl -u asus-tablet-backlight.service -b
```

A working setup will log messages similar to:

```text
following /dev/input/event15; initial mode=laptop
mode changed to tablet
tablet mode: keyboard backlight off
mode changed to laptop
laptop mode: restored backlight level 1
```

Input event numbers are assigned dynamically, so yours may not be `event15`.

## Uninstall

```bash
sudo ./tablet-backlight/uninstall.sh
sudo systemctl reboot
```

The uninstaller removes only files installed by this tool. The reboot returns
the ASUS driver to its previous configuration.

## Files installed

| File | Purpose |
| --- | --- |
| `/usr/local/libexec/asus-tablet-backlight` | Watches the tablet-mode switch and controls the light. |
| `/etc/systemd/system/asus-tablet-backlight.service` | Starts the watcher automatically. |
| `/etc/modprobe.d/asus-proart-px13-tablet-mode.conf` | Enables ASUS lid-flip tablet detection. |
| `/var/lib/asus-tablet-backlight/saved-level` | Temporarily remembers the previous brightness. |

## Troubleshooting

Confirm that the driver option took effect:

```bash
cat /sys/module/asus_nb_wmi/parameters/tablet_mode_sw
```

After reboot, it should print `2`.

Confirm that Linux exposes a tablet switch:

```bash
grep -H . /sys/class/input/input*/capabilities/sw
```

If installation is blocked because your PX13 reports an unexpected model
name, first verify that it is an ASUS HN7306-family convertible. You may then
override the model check:

```bash
sudo ./tablet-backlight/install.sh --force
```

Do not use `--force` on an unrelated laptop.
