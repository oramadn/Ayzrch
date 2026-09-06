# Installation

This is the canonical Orbit v0.1 installation path. It assumes a Fedora 44
Wayland system with Hyprland installed or ready to install. Commands below are
run from the Orbit checkout unless stated otherwise.

## 1. Install Dependencies

Install the required Fedora packages from [`dependencies.md`](dependencies.md).
The exact package names can vary with Fedora repositories, but the base set is:

```sh
sudo dnf install \
  hyprland hypridle hyprlock noctalia hyprpolkitagent \
  quickshell nwg-displays \
  xdg-desktop-portal xdg-desktop-portal-hyprland \
  python3 python3-pyudev jq socat util-linux shadow-utils procps-ng \
  grim slurp wl-clipboard zenity libcanberra-gtk3 alsa-utils \
  git gcc-c++ make pkgconf patch
```

The source-built plugins also require the development packages listed in
`dependencies.md`. If a plugin installer reports a missing `pkg-config`
dependency, install that dependency's Fedora `-devel` package and rerun it.

## 2. Clone And Review

```sh
git clone <orbit-repository-url> ~/src/orbit-dotfiles
cd ~/src/orbit-dotfiles
```

Do not delete an existing dotfiles repository or home-directory configuration.
Back up important files first. Orbit deployment refuses to overwrite unrelated
regular files and symlinks.

For an existing configuration, preview the bounded adoption process:

```sh
./bootstrap/migrate --dry-run
```

If the report is acceptable, `./bootstrap/migrate --adopt` creates a manifest
and snapshots files it replaces under `${XDG_STATE_HOME:-$HOME/.local/state}/orbit/migrations/`.
It does not replace directories and blocks unexpected content.

## 3. Deploy Orbit

```sh
./bootstrap/deploy
```

This creates Orbit-owned symlinks under `~/.config`, `~/.local/bin`,
`~/.local/lib`, and `~/.config/systemd/user`; seeds copy-once files such as
Qt6 configuration and the desktop entry; enables core user units; and asks
Noctalia to apply templates. It does not install packages, compile plugins,
modify monitor layout, or perform privileged operations.

`./bootstrap/deploy --optional` additionally enables the optional game-session
and LocalSend user services. It does not install their applications.

## 4. Install External Components

The plugin installers use pinned upstream commits and build outside the Orbit
checkout. They do not enable, reload, or replace a plugin in the running
compositor:

```sh
./bin/install-hyprglass
./bin/install-scrolloverview
./bin/install-hyprwindowshade
```

Dynamic Cursors is also ABI-sensitive. Its pinned source revision and upstream
build path are documented in [`external-components.md`](external-components.md);
build it outside the checkout and install `out/dynamic-cursors.so` to
`~/.local/share/hyprland/plugins/dynamic-cursors.so`.

The accepted reference for all four plugins is Hyprland `0.56.2` at commit
`efb50993780079460b0cbed1363e2166a2de1d9f`. Rebuild them after a material
Hyprland ABI update. Do not substitute an upstream moving `main` build.

Wallpaper Engine is a separate project. Its v0.1 deployment includes a
tracked x86-64 runtime artifact and a pinned external checkout. Use an HTTPS
remote when the GitHub SSH remote is not configured:

```sh
ORBIT_WALLPAPER_REPO_URL=https://github.com/CleanShirtUK/orbit-wallpaper-engine.git \
  ./bin/dotfiles-install-wallpaper
```

This builds the external project, installs its Noctalia integration, installs
Orbit's launcher entry, and enables/starts its user service. Its source remains
outside this repository. Details and the artifact limitation are in
[`external-components.md`](external-components.md).

## 5. Configure This Machine

Monitor layout is intentionally machine-local. Run:

```sh
nwg-displays
```

The generated `~/.config/hypr/monitors.lua` is not shipped or committed.
Orbit discovers connected monitors at runtime for semantic workspace behavior.
Noctalia is the source of truth for colors and palette templates; do not edit
generated color outputs as if they were Orbit inputs.

Sunshine requires an additional machine-local profile copied from
`config/orbit/machine/sunshine-display.conf.example`. Optional Plymouth setup
requires privileged initramfs work and is not part of standard deployment.

## 6. Verify And Start Using Orbit

```sh
./bootstrap/verify
./tests/orbit/run-all
```

Log out and start a new Hyprland session after deployment so the authored
configuration and newly installed plugins are loaded. No reboot is normally
required. Live tests require an active non-root Hyprland session.

## Rollback

For an adoption manifest, use the exact manifest path printed by `--adopt`:

```sh
./bootstrap/migrate --rollback \
  "$HOME/.local/state/orbit/migrations/<timestamp>/manifest.json"
```

Rollback refuses to remove a destination that has changed since adoption. To
remove Orbit deployment links without deleting source or history, stop using
the checkout, remove only symlinks that resolve into it, and restore any
backups. Do not delete unrelated home-directory files. Reverting the Orbit Git
checkout is separate from restoring machine-local state and generated outputs.
