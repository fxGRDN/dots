-- Hyprland Lua config. Translated from hyprland.conf.
-- Refer to the wiki for more information: https://wiki.hypr.land/Configuring/Start/

local hypr = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr"

-- Equivalent of `cp -L --no-preserve=mode --update=none scheme/default.lua scheme/current.lua`:
-- only create current.lua if it does not exist yet.
local function ensure_current_scheme()
    local current = hypr .. "/scheme/current.lua"
    local f = io.open(current, "r")
    if f then
        f:close()
        return
    end
    local src = io.open(hypr .. "/scheme/default.lua", "r")
    if not src then
        return
    end
    local data = src:read("a")
    src:close()
    local dst = io.open(current, "w")
    if dst then
        dst:write(data)
        dst:close()
    end
end
ensure_current_scheme()

-- Variables (colours + other vars)
local scheme = require("scheme/current")
local vars = require("variables")
local col = vars.colours(scheme)

local function rgb(hex)
    return "rgb(" .. hex .. ")"
end
local function rgba(hex, alpha)
    return "rgba(" .. hex .. (alpha or "") .. ")"
end

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({ output = "", mode = "1920x1080@60", position = "auto", scale = 1 })
hl.monitor({ output = "DP", mode = "1920x1080@60", position = "auto", scale = 1, mirror = "HDMI" })

---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "kitty"
local fileManager = "nautilus"
local browser = "zen-browser"
local launcher = "qs -c bar ipc call launcher toggle"
local uwsm = "uwsm app --"
-- Software rendering halves the bar's memory (no GL driver/context); it only repaints small areas.
local bar = "env QT_QUICK_BACKEND=software qs -n -c bar"
local restart_bar = "qs kill -c bar; " .. uwsm .. " " .. bar

local function app(cmd)
    return uwsm .. " " .. cmd
end

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- exec-once equivalents: run once when Hyprland starts.
hl.on("hyprland.start", function()
    hl.exec_cmd(app(bar))
    hl.exec_cmd(app("hyprsunset"))
    hl.exec_cmd(app("hypridle"))
    hl.exec_cmd(app("wl-paste --watch cliphist store")) -- clipboard history for the bar's picker
    hl.exec_cmd(app("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"))
    hl.exec_cmd(app("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"))
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- exec equivalents: run on every (re)load.
hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "Win12X-Fantasy-Yellow-Dark-Compact"') -- for GTK3 apps
hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')                     -- for GTK4 apps

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")                                                                 -- for Qt apps

---------------------
---- PERMISSIONS ----
---------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({ ecosystem = { enforce_permissions = true } })
-- hl.permission({ binary = "/usr/(bin|local/bin)/grim", type = "screencopy", mode = "allow" })
-- hl.permission({ binary = "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", type = "screencopy", mode = "allow" })
-- hl.permission({ binary = "/usr/(bin|local/bin)/hyprpm", type = "plugin", mode = "allow" })

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        layout = "dwindle",

        allow_tearing = false, -- Allows `immediate` window rule to work

        gaps_workspaces = vars.workspaceGaps,
        gaps_in = vars.windowGapsIn,
        gaps_out = vars.windowGapsOut,
        border_size = vars.windowBorderSize,

        col = {
            active_border = col.activeWindowBorderColour,
            inactive_border = col.inactiveWindowBorderColour,
        },
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
    dwindle = {
        -- pseudotile = true, -- Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true, -- You probably want this
        smart_split = false,
        smart_resizing = true,
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
    master = {
        new_status = "master",
    },

    decoration = {
        rounding = vars.windowRounding,

        blur = {
            enabled = vars.blurEnabled,
            xray = vars.blurXray,
            special = vars.blurSpecialWs,
            ignore_opacity = true, -- Allows opacity blurring
            new_optimizations = true,
            popups = vars.blurPopups,
            input_methods = vars.blurInputMethods,
            size = vars.blurSize,
            passes = vars.blurPasses,
        },

        shadow = {
            enabled = vars.shadowEnabled,
            range = vars.shadowRange,
            render_power = vars.shadowRenderPower,
            color = col.shadowColour,
        },
    },

    animations = {
        enabled = true,
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#misc
    misc = {
        -- Plain void colour until awww draws the wallpaper, matching the login fade-out
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = rgb(scheme.background),
        allow_session_lock_restore = true, -- lets SUPER+L relaunch the locker if it crashes
    },

    group = {
        col = {
            border_active = col.activeWindowBorderColour,
            border_inactive = col.inactiveWindowBorderColour,
            border_locked_active = col.activeWindowBorderColour,
            border_locked_inactive = col.inactiveWindowBorderColour,
        },

        groupbar = {
            font_family = "JetBrains Mono NF",
            font_size = 15,
            gradients = true,
            gradient_round_only_edges = false,
            gradient_rounding = 0,
            height = 25,
            indicator_height = 0,
            gaps_in = 3,
            gaps_out = 3,

            text_color = rgb(scheme.onPrimary),
            col = {
                active = rgba(scheme.primary, "d4"),
                inactive = rgba(scheme.outline, "d4"),
                locked_active = rgba(scheme.primary, "d4"),
                locked_inactive = rgba(scheme.secondary, "d4"),
            },
        },
    },
})

-- Default curves, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/#curves
--                       NAME             X0    Y0        X1    Y1
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- Default animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
-- 	name = "no-gaps-wtv1",
-- 	match = { float = false, workspace = "w[tv1]" },
-- 	border_size = 0,
-- 	rounding = 0,
-- })
-- hl.window_rule({
-- 	name = "no-gaps-f1",
-- 	match = { float = false, workspace = "f[1]" },
-- 	border_size = 0,
-- 	rounding = 0,
-- })

---------------
---- INPUT ----
---------------

-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
    input = {
        kb_layout = "pl",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.config({
    gestures = {
        workspace_swipe_use_r = true, -- swipe to the numerically previous/next workspace, even if empty
    },
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more
-- Descriptions feed the bar's keybind cheatsheet: "Group | Action", optionally
-- "| Keys" to override the displayed keys (used for ranges like 1-0).
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(app(terminal)), { description = "Apps | Terminal" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(app(browser)), { description = "Apps | Browser" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(app(fileManager)), { description = "Apps | File manager" })
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(launcher), { description = "Apps | Launcher" })
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(launcher), { description = "Apps | Launcher" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(app("hyprpicker -a")), { description = "Apps | Color picker" })
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("qs -c bar ipc call clipboard toggle"), { description = "Apps | Clipboard history" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Windows | Close" })
hl.bind(
    mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"),
    { description = "System | Log out" }
)
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Windows | Toggle floating" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Windows | Pseudo-tile" }) -- dwindle
-- hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(hypr .. "/scripts/lock.sh"), { locked = true, description = "System | Lock" })
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd(restart_bar), { description = "System | Restart bar" })

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "Windows | Move focus | SUPER ARROWS" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Screenshots
local screenshotDir = "~/Pictures/Screenshots"
-- screenshot of a region
hl.bind(
    "Print",
    hl.dsp.exec_cmd(
        [[grim -g "$(slurp)" - | wl-copy && wl-paste > ]]
        .. screenshotDir
        .. [[/Screenshot-$(date +%F_%T).png && notify-send -t 1500 -a Screenshot "Region captured"]]
    ),
    { description = "System | Screenshot region" }
)
-- screenshot of the whole screen
hl.bind(
    "SHIFT + Print",
    hl.dsp.exec_cmd(
        [[grim - | wl-copy && wl-paste > ]]
        .. screenshotDir
        .. [[/Screenshot-$(date +%F_%T).png && notify-send -t 1500 -a Screenshot "Screen captured"]]
    ),
    { description = "System | Screenshot screen" }
)

-- Switch to next/previous workspace
hl.bind(mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "r-1" }), { description = "Workspaces | Previous / next | SUPER CTRL ARROWS" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }),
        i == 1 and { description = "Workspaces | Go to workspace | SUPER 1-0" } or nil)
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),
        i == 1 and { description = "Workspaces | Move window there | SUPER SHIFT 1-0" } or nil)
end

-- Swap windows with mainMod + SHIFT + HJKL
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "l" }), { description = "Windows | Swap | SUPER SHIFT HJKL" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "d" }))

-- App scratchpads: started on first press, then shown/hidden; they keep running while hidden
local scratchpad = hypr .. "/scripts/scratchpad.sh "
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(scratchpad .. "music"), { description = "Scratchpads | Music (spotatui)" }) -- also bar player right click
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(scratchpad .. "chat"), { description = "Scratchpads | Chat (concord)" })
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(scratchpad .. "notes"), { description = "Scratchpads | Notes (Notion)" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(scratchpad .. "rss"), { description = "Scratchpads | RSS (eilmeldung)" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(scratchpad .. "mail"), { description = "Scratchpads | Mail (meli)" })

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Scratchpads | Magic workspace" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Scratchpads | Move window to magic" })

-- Scroll to the previous/next workspace with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }), { description = "Workspaces | Cycle | SUPER SCROLL" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "r-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Windows | Drag to move" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Windows | Drag to resize" })

-- Laptop multimedia keys for volume and LCD brightness (bindel = locked + repeating)
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true }
)
-- The bar's OSD can't see brightness changes by itself, so tell it after each one
local osd_brightness = " && qs -c bar ipc call osd brightness"
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+" .. osd_brightness), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-" .. osd_brightness), { locked = true, repeating = true })

-- Media keys go through the bar, so they control the same player it shows
local media = "qs -c bar ipc call media "
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(media .. "next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(media .. "toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(media .. "toggle"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(media .. "previous"), { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/ for workspace rules

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },

    no_focus = true,
})

hl.window_rule({
    name = "float-volume-control",
    match = { class = "^(org\\.pulseaudio\\.pavucontrol|pavucontrol|com\\.saivert\\.pwvucontrol)$" },

    float = true,
    center = true,
    size = "900 600",
})

hl.window_rule({
    name = "music-scratchpad",
    match = { initial_class = "^spotatui$" },

    workspace = "special:music",
})

hl.window_rule({
    name = "chat-scratchpad",
    match = { initial_class = "^concord$" },

    workspace = "special:chat",
})

hl.window_rule({
    name = "notes-scratchpad",
    match = { initial_class = "^[Nn]otion$" },

    workspace = "special:notes",
})

hl.window_rule({
    name = "rss-scratchpad",
    match = { initial_class = "^eilmeldung$" },

    workspace = "special:rss",
})

hl.window_rule({
    name = "mail-scratchpad",
    match = { initial_class = "^meli$" },

    workspace = "special:mail",
})

-- Hyprland-run windowrule
hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move = "20 monitor_h-120",
    float = true,
})
