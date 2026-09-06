# Dependencies

Orbit is validated on Fedora 44 with Wayland, Hyprland `0.56.2`, and Noctalia.
Package names can vary by enabled Fedora repositories; the groups below are
the intended dependency boundary, not an inventory of one machine.

## Required Fedora Runtime

- `hyprland`, `hypridle`, `hyprlock`, `hyprpolkitagent`, `noctalia`, and
  `quickshell`;
- `xdg-desktop-portal` and `xdg-desktop-portal-hyprland`;
- GTK3/GTK4, Qt6/KDE runtime libraries, systemd user sessions, Wayland, and
  Kora icons or another available icon theme;
- `nwg-displays` for the machine-local monitor layout;
- `bash`, `python3`, `python3-pyudev`, `jq`, `socat`, `util-linux-core`,
  `shadow-utils`, `procps-ng`, `grim`, `slurp`, `wl-clipboard`, `zenity`,
  `libcanberra-gtk3`, and `alsa-utils`.

These provide the commands used by the core launchers and user services,
including `systemctl`, `hyprctl`, `flock`, `sg`, `ps`, `wl-copy`, and
`canberra-gtk-play`.

## Required External Projects

- Hyprland and Noctalia, which remain the compositor and shell/palette owners;
- QuickShell, which hosts Orbit's global-menu configuration;
- the four Hyprland plugins listed in [`external-components.md`](external-components.md);
- the independent Orbit Wallpaper Engine project. v0.1 includes an x86-64
  runtime artifact, but its source and integration checkout remain external.

## Plugin Build Dependencies

Required by the source-built plugin installers, not by a binary-only runtime:

- `git`, `gcc-c++`, `make`, `pkgconf`, and `patch`;
- the installed Hyprland development metadata and headers;
- component-specific development packages: Pixman, libdrm, PangoCairo,
  libinput, libudev, Wayland server, xkbcommon, and Lua 5.4.

Hyprland plugins are ABI-sensitive. Installers fail clearly when required
compiler or `pkg-config` dependencies are missing and warn when the running
Hyprland commit differs from the validated reference.

## Optional Applications And Integrations

- Sunshine/Moonlight and GPU Screen Recorder for streaming;
- Steam and GameMode for game sessions;
- Obsidian, Zen Browser, Zed, WezTerm, Kitty, and Nautilus presentation or
  application integrations;
- Nautilus Actions dependencies and its pinned upstream extension;
- LocalSend;
- Plymouth script-theme packages and privileged initramfs installation.

Optional installers and machine-local requirements are documented in
[`optional-integrations.md`](optional-integrations.md). They are not needed for
the core Orbit session.
