# Internal microphone fix

Makes the internal microphone usable on the ASUS ProArt PX13 HN7306WU by
selecting the working Realtek ALC294 input.

## Why this is needed

On affected systems, PipeWire exposes an internal microphone but the default
ALSA mixer path selects `Internal Mic` (codec pin `0x12`). That input produces
little or no voice audio and may produce loud clicks when its gain is raised.
The laptop's working microphone is exposed as `Internal Mic 1` (codec pin
`0x13`).

This fix installs a user-level ALSA card profile that:

1. Selects `Internal Mic 1` and disables the incorrect input.
2. Keeps both dedicated microphone-boost controls at 0 dB.
3. Leaves normal PipeWire volume control, speakers, and headphones available.

It does not replace or patch the kernel.

## Requirements

- ASUS ProArt PX13 HN7306WU
- Realtek ALC294 codec with subsystem ID `1043:1ed3`
- PipeWire and WirePlumber
- ALSA card profiles installed under `/usr/share/alsa-card-profile`
- `systemd` user services

It was developed and tested on Omarchy/Arch Linux with kernel 7.2.3,
PipeWire 1.6.8, and WirePlumber 0.5.17.

## Install

Run the installer as your normal desktop user, without `sudo`:

```bash
cd asus-proart-px13-linux
./microphone-fix/install.sh
```

The installer restarts PipeWire and WirePlumber, briefly interrupting active
audio applications.

## Test

Speak throughout a five-second recording:

```bash
timeout 5 pw-record /tmp/px13-microphone-test.wav
pw-play /tmp/px13-microphone-test.wav
rm /tmp/px13-microphone-test.wav
```

The selected input can be confirmed with:

```bash
amixer -c 1 sget 'Internal Mic 1'
```

It should report `Capture [on]`. ALSA card numbers can vary; use `arecord -l`
to find the ALC294 card if it is not card 1.

## Input level

Set the input level through PipeWire. Start at 70% and increase it if needed:

```bash
wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 0.70
```

The custom profile disables the extra 30 dB microphone-boost control. A 100%
PipeWire level can still apply up to 30 dB of capture gain. Reduce the level if
speech clips or clicks return.

## Uninstall

Run the uninstaller as your normal desktop user:

```bash
./microphone-fix/uninstall.sh
```

This removes only the files installed by this tool and restarts the user audio
services.

## Files installed

| File | Purpose |
| --- | --- |
| `~/.config/alsa-card-profile/mixer/paths/analog-input-px13-mic.conf` | Selects `Internal Mic 1` and controls capture gain. |
| `~/.config/alsa-card-profile/mixer/profile-sets/px13.conf` | Adds the custom input path to the normal analog profiles. |
| `~/.config/wireplumber/wireplumber.conf.d/51-px13-microphone.conf` | Assigns the profile to the affected ALC294 codec. |

## Troubleshooting

Confirm that WirePlumber loaded the custom profile:

```bash
pactl list cards
```

The Ryzen HD Audio Controller should contain:

```text
device.profile-set = "px13.conf"
analog-input-px13-mic: Internal Microphone
```

If the installer rejects a machine that has the same codec and wiring, verify
the hardware first and then run:

```bash
./microphone-fix/install.sh --force
```

Do not use `--force` on unrelated hardware.
