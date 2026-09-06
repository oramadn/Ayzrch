local home = os.getenv("HOME")
local config = dofile(home .. "/.config/wezterm/wezterm.lua")

config.window_close_confirmation = "NeverPrompt"

return config
