# Swayidle configuration script
# ~/.config/swayidle/config.sh

#!/usr/bin/env bash

swayidle -w \
    timeout 300 'swaylock -f' \
    timeout 600 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' \
    before-sleep 'swaylock -f' \
    lock 'swaylock -f'
