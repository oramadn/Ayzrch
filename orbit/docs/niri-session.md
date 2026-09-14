# The niri Session

Orbit runs on two compositors. The Hyprland session is the original and remains
the reference; the niri session is the same desktop with niri doing the window
management. Both are installed side by side and chosen at the login screen.

## What is shared and what is not

Almost everything a user looks at is compositor-independent and is reused
byte for byte:

- Noctalia — the bar, launcher, notifications, OSD, lock screen and the source
  of every colour in the session. Noctalia has a native niri backend, so it
  behaves identically;
- the palette adapters: GTK 3/4, Qt/KDE, Kitty, WezTerm, Ghostty, Zed, Zen;
- the QuickShell global menu, its application-actions popup, and the keyboard
  cheatsheet;
- `orbit-theme`, `orbit-update-all-colors`, the sound theme, hypridle, and the
  session transition choreography.

What is not shared is window management. Orbit's Hyprland policy spends most of
its scripts reproducing behaviour niri has built in — directional focus that
escalates across monitors, a vertical workspace hierarchy per monitor, and a
workspace overview. Under niri the compositor does that work directly, so:

| Hyprland | niri |
|---|---|
| `focus-directional`, `move-window-workspace`, `focus-workspace` | `focus-column-or-monitor-*`, `focus-window-or-workspace-*`, `move-*` |
| `workspace-alt-tab` + ScrollOverview plugin | `toggle-overview` |
| `orbit-home-workspaces` Home blocks (1, 6, 11…) | niri workspaces, which are already per-monitor and vertical |
| `orbit-transition-workspace`, `orbit-session-workspaces` | absent; the transition keeps its sound, chrome and wallpaper phases |
| Hyprglass, HyprWindowShade, dynamic-cursors | no equivalent; niri's own blur, shadow and rounding are configured to match what they can |

## The compositor shim

`bin/orbit-compositor` is the one place either compositor is addressed. It
answers the queries Orbit's shell integrations were written against — `monitors`,
`clients`, `activewindow`, `activeworkspace`, `workspaces`, `layers`,
`cursorpos`, `binds` — in Hyprland's JSON shapes regardless of which compositor
is running, plus a small `dispatch` verb set. Callers therefore carry no
compositor knowledge at all.

Three niri answers are approximations rather than readings, because niri does
not expose the underlying state over IPC:

- `cursorpos` reports the focused output's centre. niri has no pointer-position
  request. The global menu uses this only when it is opened without coordinates.
- `layers` reports a top-anchored Noctalia bar as a full-width strip of
  `ORBIT_BAR_HEIGHT` pixels (default 48) and every other surface as a zero
  rectangle. niri lists layer-shell surfaces but not their geometry.
- window `address` is niri's integer window id rendered as a string. Every
  dispatch verb accepts it with or without an `address:` prefix.

## Configuration layout

`~/.config/niri/config.kdl` is an include list, seeded rather than linked
because Noctalia's niri template appends its own include to it:

```
include "orbit.kdl"            # Orbit's session — linked from config/niri/
include "noctalia.kdl"         # Noctalia's palette, after Orbit so colours win
include "orbit-overrides.kdl"  # structural fields that must survive the palette
include "monitor.kdl"          # this machine's outputs, written by nwg-displays
include "local.kdl"            # anything else of yours: workspaces, binds
```

niri treats a missing include as a fatal parse error, and `noctalia.kdl`,
`monitor.kdl` and `local.kdl` can all legitimately be absent, so
`orbit-niri-session` re-seeds any include whose target has gone missing before
it execs the compositor.

## Monitors

The same as under Hyprland: run `nwg-displays`, drag the monitors, apply.
nwg-displays supports niri natively — it writes `~/.config/niri/monitor.kdl`,
which is its own default path for niri, then asks niri to reload, so the layout
applies live with the usual revert-on-timeout prompt. Adaptive sync and 10-bit
are available there; only workspace assignment is greyed out, because niri's
workspaces are dynamic.

`monitor.kdl` is created as a writable regular file, never an Orbit symlink:
nwg-displays replaces a read-only symlink it finds at that path.

`orbit-overrides.kdl` exists for one reason: Noctalia's template writes a
`layout` block carrying focus-ring colours, and Orbit draws window state with
the border alone. Turning the ring off after the palette is more robust than
relying on niri's include-merge rules.

## The cheatsheet

Orbit's rule is that the compositor configuration is the only source of the
keyboard cheatsheet, and it holds under niri. Every bind in `orbit.kdl` carries
`hotkey-overlay-title="Group | Label"` — which is niri's own hotkey-overlay
field, so one line feeds both niri's built-in overlay and Orbit's QuickShell
one. `orbit-compositor binds` parses those titles out of the live config
(following `include`s) and emits them in the shape the overlay already reads. A
bind without a title is deliberately absent from both overlays.

## Deliberate differences from the Hyprland session

These are choices, not gaps:

- **Windows tile by default.** Orbit's Hyprland configuration floats every
  window by default and tiles a named list. That policy exists because Hyprland's
  master layout is a poor fit for the way Orbit is used; it is actively harmful
  under a scrollable compositor, where it would disable the layout entirely.
- **No automatic new-workspace routing.** Hyprland allocates a fresh workspace
  for Zen and Zed through `new-workspace-apps`. niri's scroll makes that
  unnecessary: a new window extends the strip rather than crowding the screen.
- **Four binds have no Hyprland counterpart.** A scrollable compositor needs a
  way to put two windows in one column, which a master layout does not have:
  `Super+comma`, `Super+period`, `Super+R` and `Super+Shift+backslash`. They
  appear in the cheatsheet under "Columns".
- **Two cheatsheet rows are missing.** `Super`+left-drag moves a window and
  `Super`+right-drag resizes it under both compositors, but niri implements them
  natively rather than as binds, so they carry no `hotkey-overlay-title` and the
  cheatsheet — which shows binds and only binds — cannot list them. Every other
  row is identical between the two sessions, key for key and label for label.

Beyond those three, `orbit-compositor binds` produces the same cheatsheet under
either compositor; the diff is worth re-running after a keymap change.

## Session units

`niri-session.target` is deliberately narrower than `hyprland-session.target`.
It omits `workspace-alt-tab-input`, `workspace-alt-tab-release` and
`new-workspace-apps`, all of which exist to give Hyprland behaviour niri has
natively. `window-shader-events` is Hyprland-only as well: it drives a
per-window shader through a Hyprland plugin.

## Portals

niri ships its own `portals.conf` preferring the GNOME backend with a GTK
fallback. `xdg-desktop-portal-gnome` is the only backend implementing ScreenCast
for niri, so screen sharing and the recorder need it installed.
`orbit-session-bootstrap` restarts whichever of the two is present after the
compositor is ready, exactly as it rebinds the Hyprland backend.
