#!/bin/bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    printf 'Run this uninstaller as root, for example: sudo %s\n' "$0" >&2
    exit 1
fi

systemctl disable --now asus-tablet-backlight.service 2>/dev/null || true

saved_level=/var/lib/asus-tablet-backlight/saved-level
led=/sys/class/leds/asus::kbd_backlight/brightness
if [[ -r "$saved_level" && -w "$led" ]]; then
    level="$(sed -n '1p' "$saved_level")"
    if [[ "$level" =~ ^[1-9][0-9]*$ ]]; then
        printf '%s\n' "$level" > "$led"
    fi
fi

rm -f /usr/local/libexec/asus-tablet-backlight
rm -f /etc/systemd/system/asus-tablet-backlight.service
rm -f /etc/modprobe.d/asus-proart-px13-tablet-mode.conf
rm -f /var/lib/asus-tablet-backlight/saved-level
rmdir /var/lib/asus-tablet-backlight 2>/dev/null || true

systemctl daemon-reload

printf '\nUninstallation complete.\n'
printf 'Reboot once to return the ASUS driver to its previous configuration.\n'
