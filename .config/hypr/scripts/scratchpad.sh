#!/bin/sh
# Usage: scratchpad.sh <music|chat|notes|rss>
# Shows/hides an app on its own special workspace, starting it on first use.
# Apps keep running while hidden. Window rules in hyprland.lua send each
# class to its workspace.

case "$1" in
    music) class=spotatui; cmd="kitty --class spotatui -e spotatui" ;;
    chat)  class=concord;  cmd="kitty --class concord -e $HOME/.cargo/bin/concord" ;;
    notes) class=notion;   cmd="notion-app" ;;
    rss)   class=eilmeldung; cmd="kitty --class eilmeldung -e eilmeldung" ;;
    *) echo "usage: $0 <music|chat|notes|rss>" >&2; exit 1 ;;
esac

if ! hyprctl clients | grep -qix "[[:space:]]*initialClass: $class"; then
    uwsm app -- $cmd >/dev/null 2>&1 &
    exit 0
fi

hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$1\")" >/dev/null
