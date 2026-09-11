# Architecture

Orbit owns authored Hyprland policy, session coordination, application
integrations, user services, and the interface between Noctalia and the
independent Wallpaper Engine.

Noctalia owns the shell and palette. Its generated files are consumed directly
by GTK, Qt/KDE, WezTerm, and Hyprland. `orbit-theme` generates only adapters
that have an active consumer, including GTK presentation/opacity, Kitty, and
Hyprlock.

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

The Wallpaper Engine is an independent project. Orbit tracks its service and
control integration but never copies its source tree into this repository.
