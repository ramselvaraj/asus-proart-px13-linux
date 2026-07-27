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

if [[ "$EUID" -ne 0 ]]; then
    printf 'Run this installer as root, for example: sudo %s\n' "$0" >&2
    exit 1
fi

vendor="$(sed -n '1p' /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
model="$(sed -n '1p' /sys/class/dmi/id/product_name 2>/dev/null || true)"

if [[ "$force" -ne 1 ]]; then
    if [[ "$vendor" != "ASUSTeK COMPUTER INC." ]] ||
        [[ "$model" != *"ProArt PX13"* && "$model" != *"HN7306"* ]]; then
        printf 'Unsupported system: vendor=%q model=%q\n' "$vendor" "$model" >&2
        printf 'Use --force only after confirming compatible hardware.\n' >&2
        exit 1
    fi
fi

if [[ ! -e /sys/module/asus_nb_wmi ]] &&
    ! modinfo asus_nb_wmi >/dev/null 2>&1; then
    printf 'The asus_nb_wmi kernel module is not available.\n' >&2
    exit 1
fi

if [[ ! -e /sys/class/leds/asus::kbd_backlight ]]; then
    printf 'The ASUS keyboard-backlight interface was not found.\n' >&2
    exit 1
fi

install -D -o root -g root -m 0755 \
    "$script_dir/asus-tablet-backlight" \
    /usr/local/libexec/asus-tablet-backlight
install -D -o root -g root -m 0644 \
    "$script_dir/asus-tablet-backlight.service" \
    /etc/systemd/system/asus-tablet-backlight.service
install -D -o root -g root -m 0644 \
    "$script_dir/asus-proart-px13-tablet-mode.conf" \
    /etc/modprobe.d/asus-proart-px13-tablet-mode.conf

systemctl daemon-reload
systemctl enable --now asus-tablet-backlight.service

printf '\nInstallation complete.\n'
printf 'Reboot once to load the ASUS driver with tablet-mode detection enabled.\n'
