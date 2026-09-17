local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "rose-pine-moon"
config.colors = {
  selection_fg = "#191724",
  selection_bg = "#c4a7e7",
}

config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0

config.max_fps = 120

config.window_background_opacity = 0.88
config.macos_window_background_blur = 30

config.window_decorations = "RESIZE"

config.hide_tab_bar_if_only_one_tab = true

config.inactive_pane_hsb = {
  saturation = 0.8,
  brightness = 0.7,
}

config.scrollback_lines = 10000

config.keys = {
  {
    key = "d",
    mods = "CMD",
    action = wezterm.action.SplitHorizontal {
      domain = "CurrentPaneDomain",
    },
  },

  {
    key = "d",
    mods = "CMD|SHIFT",
    action = wezterm.action.SplitVertical {
      domain = "CurrentPaneDomain",
    },
  },

  {
    key = "w",
    mods = "CMD",
    action = wezterm.action.CloseCurrentPane {
      confirm = false,
    },
  },
}

config.mouse_bindings = {
  {
    event = {
      Up = {
        streak = 1,
        button = "Left",
      },
    },
    mods = "NONE",
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor(
      "Clipboard"
    ),
  },
}


return config