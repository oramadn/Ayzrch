# Ayzrch

Arch Linux setup scripts. `./setup.sh` runs every `scripts/*.sh` in order;
`opt-`-prefixed modules are asked about individually (`--all` accepts them all).

- Need to reboot after downloading NVIDIA drivers

## Orbit desktop

`scripts/15-orbit.sh` installs the Orbit desktop: **Hyprland** compositor,
**Noctalia** shell (bar, launcher, notifications, and the source of every colour
in the session), a **QuickShell** global menu and four Hyprland plugins. It is
vendored from
[CleanShirtUK/dotfiles](https://github.com/CleanShirtUK/dotfiles) into `orbit/`,
adapted from Fedora to Arch — see [`orbit/ATTRIBUTION.md`](orbit/ATTRIBUTION.md)
for provenance and every local modification.

```sh
scripts/15-orbit.sh                # packages, deploy, plugins
scripts/16-orbit-integrations.sh   # Zen theming, LocalSend, GPU Screen Recorder
scripts/17-awww-wallpaper.sh       # awww renders the wallpaper Noctalia picks
scripts/13-niri.sh                 # the same desktop on niri, as a second session
```

### Two compositors

`scripts/13-niri.sh` adds an **Orbit (niri)** session alongside Hyprland. Both
are installed; you pick one in Ly at login. The shell, the palette, every theme
adapter, the global menu and the cheatsheet are shared unchanged — what changes
is window management, which niri does natively instead of through Orbit's
Hyprland scripts. See [`orbit/docs/niri-session.md`](orbit/docs/niri-session.md)
for exactly what is shared, what differs, and why.

Monitors work the same way in both sessions: run `nwg-displays`. It supports
niri natively, writing `~/.config/niri/monitor.kdl` instead of
`~/.config/hypr/monitors.lua` and asking niri to reload, so the layout applies
live. Hyprland's four plugins (Hyprglass, HyprWindowShade, dynamic-cursors,
ScrollOverview) have no niri equivalent; niri's own blur, shadow, rounding and
overview cover what they can.

Orbit's own wallpaper engine is not installed: its persistent GPU context
deadlocked on NVIDIA explicit-sync fences. `scripts/17-awww-wallpaper.sh` puts
[awww](https://github.com/LGFae/awww) (CPU shared-memory buffers, no GPU
context) behind Noctalia's picker instead — see
[`docs/awww-live-wallpaper.md`](docs/awww-live-wallpaper.md).

The install is non-destructive: existing `~/.config/{hypr,kitty,wezterm}` are
moved to `*.pre-orbit-<date>` first, and Orbit's own deploy refuses to overwrite
any unrelated file.

### After installing

1. Log out, then pick **Hyprland** in Ly — not `hyprland-uwsm`. If you also ran
   `scripts/13-niri.sh`, **Orbit (niri)** is the other entry.
2. Noctalia's setup wizard runs on first login. Pick a wallpaper (the picker
   browses `~/Pictures`); the whole palette (window borders, GTK, Qt,
   terminals, lock screen) is derived from it, and awww draws it.
3. Run `nwg-displays` to arrange monitors. It writes `~/.config/hypr/monitors.lua`,
   which is machine-local and deliberately not tracked here.
4. Restart Zen Browser to pick up its chrome overrides. Launch LocalSend once,
   then run `~/.local/bin/configure-localsend` to set the device name.
5. Optional: point ghostty at Noctalia's palette (`theme = noctalia` in your
   chezmoi-managed `~/.config/ghostty/config`) so the terminal follows the wallpaper.

### Monitors

Orbit does not hardcode connectors. `nwg-displays` writes the layout per machine,
and at every login `orbit-home-workspaces` assigns each connected monitor a Home
workspace — 1, 6, 11… — ordered left to right, so docked, undocked and
multi-monitor setups all work from one config without editing anything.

Hyprland has no primary-monitor setting; workspace 1 belongs to the leftmost
display. Noctalia draws its bar and dock on every monitor.

### Keys

| Key | Action |
|---|---|
| `Super+Return` | Ghostty |
| `Super+Q` / `Super+C` | Close window |
| `Super+E` | Dolphin |
| `Super+B` / `Super+Shift+B` | Zen — Personal / Work profile |
| `Super+Space` | Noctalia launcher |
| `Super+V` | Toggle floating |
| `Super+F` / `Alt+Return` | Maximize / fullscreen |
| `Alt+Tab` | Workspace overview (ScrollOverview) |
| `Super+arrows` | Directional focus, crossing monitors and workspaces |
| `Super+Shift+arrows` | Move window the same way |
| `Super+Ctrl+arrows` | Resize window |
| `Super+1`…`0` / `Super+Shift+1`…`0` | Absolute workspace / move window there |
| `Super+grave` / `Super+Shift+grave` | Scratchpad / move window to it |
| `Super+L` / `Super+M` | Lock / shut down, with animation |
| `Super+Shift+S` | Region screenshot into satty |
| `Super+Shift+C` | Colour picker to clipboard |
| `Super+Shift+E` | Emoji picker (rofi) |
| `Super+Shift+R` / `Super+Shift+Z` | Record / save the last 30s replay |
| Media / volume / brightness keys | wpctl, playerctl, brightnessctl |

The niri session binds the same keys to niri's native actions, and adds four for
columns, which a master layout has no use for: `Super+,` / `Super+.` move a
window in and out of a column, `Super+R` cycles column width, and
`Super+Shift+\` centres the column. `Super+/` shows the same cheatsheet, built
from whichever compositor's configuration is live.

Workspaces `1`, `6`, `11`… are each monitor's semantic Home, assigned to whatever
is connected at login; the absolute `Super+1..0` binds address the same numbers
directly, so both models work together.

`Super+A` (chatgpt) and `Ctrl+Shift+Escape` (Mission Center) are upstream binds
for apps that are not installed here — rebind them in
`orbit/config/hypr/hyprland.lua` when you want them.

### Updating

The four Hyprland plugins are compiled against Hyprland's ABI and pinned to
upstream commits validated against Hyprland `0.56.2` (commit `efb50993`). After
`pacman -Syu` moves Hyprland, rebuild them:

```sh
scripts/15-orbit.sh --plugins-only
```

If a plugin no longer compiles against the new Hyprland, bump its pinned commit
in `orbit/bin/install-*` or `orbit/arch/install-*`. Hyprland itself keeps working
with plugins missing — only the glass blur, workspace overview, window ripples and
cursor effects go away until they are rebuilt. To gate compositor upgrades
entirely, add `IgnorePkg = hyprland` to `/etc/pacman.conf` (not done by default).

### Lock screen

Noctalia owns the session lock. `Super+L` goes through `loginctl lock-session`,
hypridle's `lock_cmd` calls `noctalia msg session lock`, and Noctalia draws the
lock surface on every monitor. Orbit's hyprlock configuration is still present
but unused — `orbit/config/hypr/hypridle.conf` documents how to swap back.

Do not enable both: they race for `ext-session-lock-v1`, and the loser's failure
drops the session straight back to unlocked.

### Rolling back

```sh
mv ~/.config/hypr.pre-orbit-<date> ~/.config/hypr   # after removing the Orbit symlinks
chezmoi apply
```

Then pick **niri** or the old Hyprland session in Ly. The niri session, wayle bar,
awww wallpaper daemon and matugen theming are untouched by the Orbit install and
keep working exactly as before.
