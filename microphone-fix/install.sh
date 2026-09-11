#!/bin/bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
force=0

if [[ "${1:-}" == "--force" ]]; then
    force=1
elif [[ $# -ne 0 ]]; then
    printf 'Usage: %s [--force]\n' "$0" >&2
    exit 2
fi

if [[ "$EUID" -eq 0 ]]; then
    printf 'Run this installer as your normal desktop user, without sudo.\n' >&2
    exit 1
fi

vendor="$(sed -n '1p' /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
model="$(sed -n '1p' /sys/class/dmi/id/product_name 2>/dev/null || true)"

if [[ "$force" -ne 1 ]]; then
    if [[ "$vendor" != "ASUSTeK COMPUTER INC." ]] ||
        [[ "$model" != *"ProArt PX13"* && "$model" != *"HN7306WU"* ]]; then
        printf 'Unsupported system: vendor=%q model=%q\n' "$vendor" "$model" >&2
        printf 'Use --force only after confirming compatible hardware.\n' >&2
        exit 1
    fi

    codec_found=0
    for codec in /proc/asound/card*/codec*; do
        [[ -r "$codec" ]] || continue
        if grep -q '^Vendor Id: 0x10ec0294$' "$codec" &&
            grep -q '^Subsystem Id: 0x10431ed3$' "$codec"; then
            codec_found=1
            break
        fi
    done

    if [[ "$codec_found" -ne 1 ]]; then
        printf 'The supported ALC294 codec (1043:1ed3) was not found.\n' >&2
        printf 'Use --force only after confirming compatible hardware.\n' >&2
        exit 1
    fi
fi

if [[ ! -f /usr/share/alsa-card-profile/mixer/paths/analog-input-mic.conf.common ]]; then
    printf 'ALSA card-profile mixer paths are not installed.\n' >&2
    exit 1
fi

for command in install systemctl; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$command" >&2
        exit 1
    fi
done

install -D -m 0644 \
    "$script_dir/analog-input-px13-mic.conf" \
    "$HOME/.config/alsa-card-profile/mixer/paths/analog-input-px13-mic.conf"
install -D -m 0644 \
    "$script_dir/px13.conf" \
    "$HOME/.config/alsa-card-profile/mixer/profile-sets/px13.conf"
install -D -m 0644 \
    "$script_dir/51-px13-microphone.conf" \
    "$HOME/.config/wireplumber/wireplumber.conf.d/51-px13-microphone.conf"

systemctl --user restart wireplumber pipewire pipewire-pulse

printf '\nInstallation complete.\n'
printf 'The working Internal Mic 1 input is now selected through PipeWire.\n'
printf 'See README.md for recording and volume tests.\n'
