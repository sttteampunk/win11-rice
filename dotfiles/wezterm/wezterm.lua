-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Core Settings
config.front_end = "OpenGL"
config.max_fps = 120
config.default_cursor_style = "BlinkingBar"
config.animation_fps = 120
config.cursor_blink_rate = 500
config.term = "xterm-256color"

-- Font Settings (Matched to WT)
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 13.0 -- Adjust to your preference, WT usually defaults around here
config.cell_width = 1.0 -- Normal width for monospaced fonts

-- Window Styling (Matched to WT)
config.window_background_opacity = 0.95
config.prefer_egl = true
config.window_decorations = "NONE | RESIZE"
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

-- Tab Bar Settings
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- Keymaps
config.keys = {
	{ key = "v", mods = "CTRL|SHIFT|ALT", action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },
	{ key = "h", mods = "CTRL|SHIFT|ALT", action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },
	{ key = "U", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "I", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "O", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "P", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
	{ key = "9", mods = "CTRL", action = act.PaneSelect },
	{ key = "L", mods = "CTRL", action = act.ShowDebugOverlay },
	{
		key = "O",
		mods = "CTRL|ALT",
		-- Toggling opacity
		action = wezterm.action_callback(function(window, _)
			local overrides = window:get_config_overrides() or {}
			if overrides.window_background_opacity == 1.0 then
				overrides.window_background_opacity = 0.95
			else
				overrides.window_background_opacity = 1.0
			end
			window:set_config_overrides(overrides)
		end),
	},
}

-- Custom Monochrome Theme (Translated from WT settings.json)
config.colors = {
	background = "#18181B",
	foreground = "#E5E7EB",

	cursor_bg = "#E5E7EB",
	cursor_border = "#e5e7eb",
	cursor_fg = "#18181B",

	selection_bg = "#2C2C32",
	selection_fg = "#E5E7EB",

	-- The standard 8 ANSI colors
	ansi = {
		"#18181B", -- black
		"#E5E7EB", -- red
		"#A0A1A4", -- green
		"#E5E7EB", -- yellow
		"#4B565C", -- blue
		"#E5E7EB", -- purple
		"#E5E7EB", -- cyan
		"#E5E7EB", -- white
	},
	-- The bright 8 ANSI colors
	brights = {
		"#A0A1A4", -- bright black
		"#A0A1A4", -- bright red
		"#E5E7EB", -- bright green
		"#E5E7EB", -- bright yellow
		"#E5E7EB", -- bright blue
		"#E5E7EB", -- bright purple
		"#E5E7EB", -- bright cyan
		"#E5E7EB", -- bright white
	},

	tab_bar = {
		background = "#18181B",
		active_tab = {
			bg_color = "#18181B",
			fg_color = "#E5E7EB",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = "#18181B",
			fg_color = "#E5E7EB",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		new_tab = {
			bg_color = "#18181B",
			fg_color = "#E5E7EB",
		},
	},
}

config.window_frame = {
	font = wezterm.font({ family = "JetBrainsMono Nerd Font", weight = "Regular" }),
	active_titlebar_bg = "#18181B",
}

config.default_prog = { "pwsh.exe", "-NoLogo", "-NoProfileLoadTime" }
config.initial_cols = 80

return config
