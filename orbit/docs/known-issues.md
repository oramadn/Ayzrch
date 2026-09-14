# Known Limitations

These are current, non-blocking v0.1 limitations rather than resolved defects.

- Orbit is validated against Fedora 44, Hyprland `0.56.2`, and commit
  `efb50993780079460b0cbed1363e2166a2de1d9f`. Hyprland plugins may need to be
  rebuilt after compositor or relevant dependency ABI changes.
- The v0.1 Wallpaper Engine deployment artifact is x86-64 Linux only.
- Monitor layout is generated per machine by `nwg-displays`; Sunshine also
  requires a machine-local display profile and has not been validated across
  multiple hardware profiles.
- Logout and lock currently have different visual choreography. Matching them
  exactly is a post-v0.1 fast follow and does not block the release.
- Plymouth is included as an optional source integration but is not part of
  standard deployment and requires privileged initramfs installation.
- Optional application integrations are only active when their applications
  and machine-specific configuration are present.
- The niri session has no equivalent for the four Hyprland plugins. Hyprglass
  refraction and chromatic aberration, HyprWindowShade ripples, dynamic-cursors
  tilt and ScrollOverview are absent; niri's native blur, shadow, rounding and
  overview are configured to cover what they can.
- Under niri, `orbit-compositor cursorpos` reports the focused output's centre
  and `layers` synthesises the Noctalia bar rectangle from `ORBIT_BAR_HEIGHT`.
  niri exposes neither the pointer position nor layer-shell geometry over IPC,
  so the global menu anchors less precisely there than under Hyprland.
- Disabling Noctalia's niri template deletes `~/.config/niri/noctalia.kdl`,
  which `config.kdl` includes. `orbit-niri-session` re-seeds it at start, so the
  breakage is limited to a live reload before the next login.
