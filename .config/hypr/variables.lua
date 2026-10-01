-- Lua counterpart of variables.conf.
-- Colour-dependent values (e.g. shadowColour) take the scheme table as input.
local M = {}

-- ### Hyprland ###

-- Touchpad
M.touchpadDisableTyping = true
M.touchpadScrollFactor = 0.3
M.workspaceSwipeFingers = 4
M.gestureFingers = 3
M.gestureFingersMore = 4

-- Blur
M.blurEnabled = true
M.blurSpecialWs = false
M.blurPopups = true
M.blurInputMethods = true
M.blurSize = 8
M.blurPasses = 2
M.blurXray = false

-- Shadow
M.shadowEnabled = true
M.shadowRange = 20
M.shadowRenderPower = 3

-- Gaps
M.workspaceGaps = 20
M.windowGapsIn = 5
M.windowGapsOut = 0
M.singleWindowGapsOut = 0

-- Window styling
M.windowOpacity = 0.95
M.windowRounding = 0
M.windowBorderSize = 1

-- Misc
M.volumeStep = 10 -- In percent
M.cursorTheme = "sweet-cursors"
M.cursorSize = 24

-- ### Keybinds ###
-- Workspaces
M.kbMoveWinToWs = "SUPER + ALT"
M.kbMoveWinToWsGroup = "CTRL + SUPER + ALT"
M.kbGoToWs = "SUPER"
M.kbGoToWsGroup = "CTRL + SUPER"

M.kbNextWs = "CTRL + SUPER + right"
M.kbPrevWs = "CTRL + SUPER + left"

M.kbToggleSpecialWs = "SUPER + S"

-- Window groups
M.kbWindowGroupCycleNext = "ALT + Tab"
M.kbWindowGroupCyclePrev = "SHIFT + ALT + Tab"
M.kbUngroup = "SUPER + U"
M.kbToggleGroup = "SUPER + Comma"

-- Window actions
M.kbMoveWindow = "SUPER + Z"
M.kbResizeWindow = "SUPER + X"
M.kbWindowPip = "SUPER + ALT + Backslash"
M.kbPinWindow = "SUPER + P"
M.kbWindowFullscreen = "SUPER + F"
M.kbWindowBorderedFullscreen = "SUPER + ALT + F"
M.kbToggleWindowFloating = "SUPER + ALT + Space"
M.kbCloseWindow = "SUPER + Q"

-- Special workspace toggles
M.kbSystemMonitor = "CTRL + SHIFT + Escape"
M.kbMusic = "SUPER + M"
M.kbCommunication = "SUPER + D"
M.kbTodo = "SUPER + R"

-- Apps
M.kbTerminal = "SUPER + T"
M.kbBrowser = "SUPER + W"
M.kbEditor = "SUPER + C"
M.kbFileExplorer = "SUPER + E"

-- Misc
M.kbSession = "CTRL + ALT + Delete"
M.kbShowSidebar = "SUPER + N"
M.kbClearNotifs = "CTRL + ALT + C"
M.kbShowPanels = "SUPER + K"
M.kbLock = "SUPER + L"
M.kbRestoreLock = "SUPER + ALT + L"

--- Colour values that depend on the active scheme.
---@param c table scheme table (see scheme/current.lua)
function M.colours(c)
	return {
		shadowColour = "rgba(" .. c.surface .. "d4)",
		activeWindowBorderColour = "rgba(" .. c.primary .. "d4)",
		inactiveWindowBorderColour = "rgba(" .. c.onSurfaceVariant .. "11)",
	}
end

return M
