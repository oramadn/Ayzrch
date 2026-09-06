local wezterm = require 'wezterm'
local config = {}

-- Noctalia owns the terminal color output; Orbit does not generate a second scheme.
config.color_scheme = "Noctalia"
-- UI configuration: tab bar disabled; Orbit updates the canonical monospace font.
config.enable_tab_bar = false
config.font = wezterm.font("JetBrains Mono")
config.font_size = 10

-- Window appearance: frameless (no decorations), 30px padding, 40% opacity for transparency
-- Padding provides breathing room around terminal content; opacity works with compositor
-- (e.g., Hyprland's blur effects) to create glass-like transparency.
config.window_decorations = 'NONE'
config.window_padding = {
  left = 30,
  right = 30,
  top = 30,
  bottom = 30,
}
config.window_background_opacity = 0.4
-- Keybindings: custom Alt+C for copy-to-clipboard, Ctrl+C/V for standard clipboard operations
config.keys = {
  {
    key = 'c',
    mods = 'ALT',
    -- Alt+C sends Ctrl+C to application (useful for some terminal programs expecting Alt+C)
    action = wezterm.action.SendKey { key = 'c', mods = 'CTRL' },
  },
  {
    key = 'c',
    mods = 'CTRL',
    -- Ctrl+C copies selected text to system clipboard (overrides normal Ctrl+C signal)
    action = wezterm.action.CopyTo 'Clipboard',
  },
  {
    key = 'v',
    mods = 'CTRL',
    -- Ctrl+V pastes from system clipboard
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

return config
