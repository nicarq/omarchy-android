-- The PRoot session is nested in a Weston surface whose dimensions follow
-- the current Termux:X11 display. A wildcard keeps this correct across fold,
-- unfold, and rotation instead of retaining the old QEMU Virtual-1 mode.
-- Keep Omarchy's conventional variable names: its Display panel updates
-- these declarations in place, which lets scale changes survive a restart.
local omarchy_monitor_scale = tonumber(os.getenv("OMARCHY_SCALE")) or 2
local omarchy_gdk_scale = math.floor(omarchy_monitor_scale + 0.5)

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Android surfaces can have odd pixel dimensions. Keep the selected UI scale
-- and let logical dimensions round when a fold or rotation changes the size.
hl.config({ debug = { disable_scale_checks = true } })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale, transform = 0 })
