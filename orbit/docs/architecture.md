# Architecture

Orbit owns authored compositor policy, session coordination, application
integrations, user services, and the interface between Noctalia and the
independent Wallpaper Engine.

Orbit runs on two compositors. Hyprland is the reference session; niri is the
second, described in [`niri-session.md`](niri-session.md). The split between
them is sharp: everything the user looks at — Noctalia, the palette, every
theme adapter, the global menu and the cheatsheet — is shared unchanged, and
only window management differs. `bin/orbit-compositor` is the single place
either compositor is addressed, answering in one JSON shape so no other script
or QML file knows which is running.

Noctalia owns the shell and palette. Its generated files are consumed directly
by GTK, Qt/KDE, WezTerm, and Hyprland. `orbit-theme` generates only adapters
that have an active consumer, including GTK presentation/opacity, Kitty,
herdr, and Hyprlock.

Hyprland starts Noctalia, the global-menu QuickShell configuration, and
`orbit-session-bootstrap`. The global-menu configuration also hosts the keyboard
cheatsheet overlay, which Hyprland toggles over IPC on Super+/. That overlay is
rendered entirely from `hyprctl binds -j`: a bind appears in it when, and only
when, it carries a `"Group | Label"` description in `config/hypr/hyprland.lua`,
so the compositor configuration remains the single source and the overlay cannot
drift from it. The bootstrap imports the graphical environment,
assigns semantic Home workspaces to monitors discovered from live Hyprland
state, starts the session target, performs the session transition, and repairs
the portal binding.

The session target owns the Wallpaper Engine, workspace Alt+Tab services,
workspace application placement, shader events, Hypridle, and the native
Hyprland PolicyKit agent.

`niri-session.target` is the niri counterpart and is deliberately narrower: the
Alt+Tab, workspace-allocation and shader units exist to give Hyprland behaviour
that niri performs natively or that depends on a Hyprland plugin, so it does not
pull them. The niri session starts the same three processes Hyprland's start
hook does — Noctalia, the global-menu QuickShell instance and
`orbit-session-bootstrap` — through `spawn-at-startup` in `config/niri/orbit.kdl`,
and the bootstrap resolves the target, the session variable and the portal
backend from the compositor it finds itself in.

The Wallpaper Engine is an independent project. Orbit tracks its service and
control integration but never copies its source tree into this repository.
