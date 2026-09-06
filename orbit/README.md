# Orbit

Orbit is an early-release (`v0.1`) Fedora + Hyprland desktop configuration.
It provides authored Hyprland policy, session services, application routing,
workspace behavior, a QuickShell global menu, and integration with Noctalia and
the independent Orbit Wallpaper Engine.

Orbit does not replace Hyprland or Noctalia. Hyprland remains the compositor;
Noctalia remains the shell and color-palette authority. Orbit owns the glue
between them and its own user services. External plugin source and compiled
plugins are installed outside this repository.

## Validated Platform

The supported reference is Fedora 44 with Wayland and:

- Hyprland `0.56.2-1.fc44`, commit `efb50993780079460b0cbed1363e2166a2de1d9f`;
- Noctalia `5.0.0~beta.9-1.fc44`;
- an x86-64 system for the v0.1 Wallpaper Engine artifact.

Compatibility beyond this reference is not promised. Hyprland plugins use
private compositor APIs and may need rebuilding after Hyprland or ABI-related
dependency updates.

## Features

- Noctalia-driven colors with Orbit adapters for GTK, Qt/KDE, Kitty, WezTerm,
  Hyprland, and Hyprlock;
- Hyprland workspace policy, application placement, Alt+Tab, transitions, and
  lock/session services;
- QuickShell global menu and Orbit-routed Wallpaper Engine settings;
- Hyprglass, ScrollOverview, HyprWindowShade, and Dynamic Cursors integration;
- optional Sunshine, game-session, Nautilus, LocalSend, recorder, browser,
  editor, and Plymouth integrations.

## Install

Use the canonical, multi-step guide in [`docs/install.md`](docs/install.md).
In brief, install Fedora dependencies, clone this repository, review any
existing-file adoption with `bootstrap/migrate`, run `bootstrap/deploy`, build
the pinned plugins with their dedicated installers, install the pinned
Wallpaper Engine integration, and configure monitors with `nwg-displays`.

Deployment is refusal-oriented: it will not overwrite unrelated files. It
creates Orbit-owned symlinks, seeds selected files only when absent, enables
core user units, and refreshes Noctalia templates. It does not install Fedora
packages or perform privileged operations.

## Architecture

```text
Hyprland -> Noctalia + QuickShell global menu
         -> hyprland-session.target
              -> Wallpaper Engine, workspace, shader, idle, and policy services

Noctalia palette/templates -> Orbit semantic and presentation adapters
Orbit configuration       -> Hyprland policy, routing, and machine-independent services
Machine-local setup       -> nwg-displays monitor layout and optional Sunshine profile
```

See [`docs/architecture.md`](docs/architecture.md) and
[`docs/file-map.md`](docs/file-map.md) for ownership boundaries.

## Dependencies

Required packages, external projects, build requirements, and optional
integrations are separated in [`docs/dependencies.md`](docs/dependencies.md).
The plugin and Wallpaper Engine provenance is recorded in
[`docs/external-components.md`](docs/external-components.md).

## Verify, Recover, Update

After installation:

```sh
./bootstrap/verify
./tests/orbit/run-all
```

Live tests require an active non-root Hyprland session. Back up existing user
configuration before adoption. `bootstrap/migrate --dry-run` previews adoption;
`bootstrap/migrate --adopt` records a manifest and snapshots replaced files,
and `bootstrap/migrate --rollback PATH/TO/manifest.json` restores that snapshot.
See [`docs/deployment.md`](docs/deployment.md) for recovery and update details.

## Limitations

See [`docs/known-issues.md`](docs/known-issues.md) for the short v0.1 list.
The most important limitations are the validated Hyprland ABI boundary, the
x86-64 Wallpaper Engine artifact, machine-local monitor/Sunshine setup, and
known logout visual-parity follow-up work.

## Project Status

Orbit v0.1 is an early release. Updates should first be validated against the
reference platform and documented external revisions. Contributions and issue
reports should include the Hyprland version/commit, relevant plugin revisions,
and whether the issue reproduces without optional integrations.
