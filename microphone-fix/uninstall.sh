#!/bin/bash
set -euo pipefail

if [[ "$EUID" -eq 0 ]]; then
    printf 'Run this uninstaller as your normal desktop user, without sudo.\n' >&2
    exit 1
fi

rm -f "$HOME/.config/alsa-card-profile/mixer/paths/analog-input-px13-mic.conf"
rm -f "$HOME/.config/alsa-card-profile/mixer/profile-sets/px13.conf"
rm -f "$HOME/.config/wireplumber/wireplumber.conf.d/51-px13-microphone.conf"

rmdir "$HOME/.config/alsa-card-profile/mixer/paths" 2>/dev/null || true
rmdir "$HOME/.config/alsa-card-profile/mixer/profile-sets" 2>/dev/null || true
rmdir "$HOME/.config/alsa-card-profile/mixer" 2>/dev/null || true
rmdir "$HOME/.config/alsa-card-profile" 2>/dev/null || true

systemctl --user restart wireplumber pipewire pipewire-pulse

printf '\nUninstallation complete.\n'
printf 'The default ALSA microphone path has been restored.\n'
