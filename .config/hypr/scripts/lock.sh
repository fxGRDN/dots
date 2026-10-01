#!/bin/sh
# Lock with the Quickshell lockscreen, showing the current awww wallpaper.
wall=$(awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -n 1)
if [ -z "$wall" ] || [ ! -e "$wall" ]; then
	wall="${HOME}/.local/share/wallpapers/pixelhole.gif"
fi

LOCK_BG="$wall" exec qs --no-duplicate -p "${HOME}/.config/quickshell/lock"
