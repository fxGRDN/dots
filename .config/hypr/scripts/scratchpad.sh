#!/bin/sh
# Usage: scratchpad.sh <music|chat|notes|rss|mail>
# Shows/hides an app on its own special workspace, starting it on first use.
# Apps keep running while hidden. Window rules in hyprland.lua send each
# class to its workspace.
#
# Terminal apps run in footclient windows of one shared foot server
# (foot-server.socket), so each one costs ~2 MB instead of a whole terminal.

case "$1" in
    music) class=spotatui;   cmd="footclient --no-wait --app-id=spotatui spotatui" ;;
    chat)  class=concord;    cmd="footclient --no-wait --app-id=concord $HOME/.cargo/bin/concord" ;;
    notes) class=notion;     cmd="uwsm app -- notion-app" ;;
    rss)   class=eilmeldung; cmd="footclient --no-wait --app-id=eilmeldung eilmeldung" ;;
    mail)  class=meli;       cmd="footclient --no-wait --app-id=meli meli" ;;
    *) echo "usage: $0 <music|chat|notes|rss|mail>" >&2; exit 1 ;;
esac

if ! hyprctl clients | grep -qix "[[:space:]]*initialClass: $class"; then
    $cmd >/dev/null 2>&1 &
    exit 0
fi

hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$1\")" >/dev/null
