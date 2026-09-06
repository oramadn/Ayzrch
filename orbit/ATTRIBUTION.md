# Attribution

Everything in this directory except `arch/` and this file is vendored from an
upstream project by **CleanShirtUK**:

- Upstream: <https://github.com/CleanShirtUK/dotfiles> ("Orbit")
- Vendored commit: `10ae4745a00230e458b6667d71b7b76eee90ce5f` (2026-08-30)
- Upstream release: Orbit v0.1, validated on Fedora 44 + Hyprland 0.56.2

Upstream publishes no LICENSE file. The code is vendored here unmodified except
for the changes listed below, with full credit to the original author. If you
are the author and would prefer this copy removed or handled differently, open
an issue on <https://github.com/oramadn/Ayzrch>.

Orbit is configuration and glue. The components it configures are separate
projects with their own licenses, installed from packages or built from pinned
upstream commits — never vendored here:

| Component | Upstream | License |
|---|---|---|
| Hyprland | hyprwm/Hyprland | BSD-3-Clause |
| Noctalia | noctalia-dev/noctalia | see upstream |
| QuickShell | quickshell.outfoxxed.me | see upstream |
| Hyprglass | hyprnux/hyprglass | BSD-3-Clause |
| ScrollOverview | yayuuu/hyprland-scroll-overview | BSD-3-Clause |
| HyprWindowShade | ManofJELLO/HyprWindowShade | MIT |
| Dynamic Cursors | virtcode/hypr-dynamic-cursors | MIT |
| Oblique Cursor | kayxean/oblique-cursor | no license stated |
| Orbit Wallpaper Engine | CleanShirtUK/orbit-wallpaper-engine | GPL-3.0 |

## Local modifications

### Removed (Fedora-only, or not wanted on this setup)

- `plymouth/`, `diagnostics/`, `docs/` retained upstream but Fedora-specific
  claims in them are superseded by `Ayzrch/README.md`.
- Obsidian: `config/obsidian/`, `bin/configure-obsidian`, `bin/orbit-daily-note`,
  `bin/orbit-scratchpad` — Obsidian appearance is managed separately.
- Nautilus: `config/actions-for-nautilus/`, `config/gtk-4.0/nautilus-overrides.css`,
  `bin/install-actions-for-nautilus`, `bin/nautilus-copy-path`,
  `bin/nautilus-open-as-admin` — Dolphin is the file manager here.
- Sunshine / game sessions: `config/orbit/machine/`, `bin/orbit-sunshine-display`,
  `bin/orbit-game-run`, `systemd/user/orbit-game-session.*`,
  `systemd/user/orbit-sunshine-display-watchdog.service`,
  `systemd/user/app-dev.lizardbyte.app.Sunshine.service.d/`.
- Fedora installers replaced by `arch/` equivalents:
  `bin/install-hyprwindowshade` (hyprpm headers), `bin/install-gpu-screen-recorder`
  (Flatpak/Flathub), `bin/configure-localsend-firewall` (`firewall-cmd`).
- `bootstrap/{deploy,verify,migrate}` had the corresponding entries removed from
  their file lists and exclusion sets.

### Changed for Arch

1. `systemd/user/hyprpolkitagent.service` — `ExecStart` is
   `/usr/lib/hyprpolkitagent/hyprpolkitagent`; Fedora's path is `/usr/libexec/hyprpolkitagent`.
2. `systemd/user/localsend.service`, `bin/show-localsend`, `bin/configure-localsend` —
   use the native `localsend` binary and `$XDG_DATA_HOME` settings path instead of
   `flatpak run org.localsend.localsend_app` and `~/.var/app/...`.
3. `bin/gpu-screen-recorder-control` — calls `gsr-cli` / `gpu-screen-recorder`
   from `extra/gpu-screen-recorder` instead of the Flatpak. Recording, replay and
   the Resolve conversion logic are unchanged.
4. `config/gtk-4.0/{gtk.css,gtk-dark.css}` — dropped the `nautilus-overrides.css`
   import alongside the removed file.
5. `bin/configure-zen` — resolves the Zen profile root as `~/.zen` or, as the Arch
   package uses, `$XDG_CONFIG_HOME/zen`. Upstream hardcodes `~/.zen`.

### Fixed while deploying

6. `bootstrap/deploy` — the `hypr/{scripts,shaders,patches}/*` and
   `quickshell/global-menu/*` loops globbed against `$PWD` instead of the
   repository, so running deploy from anywhere but the checkout linked a literal
   `*` and silently skipped 20 files. They now glob against `$repo_dir`.
7. `bin/dotfiles-install-wallpaper` — upstream installs
   `bin/orbit-wallpaper-launcher` and the desktop entry from the *external*
   Wallpaper Engine checkout, where neither exists (they are Orbit's own files,
   already deployed by `bootstrap/deploy`), so the installer always failed at
   that line. Those two installs are removed. It now also installs the renderer
   it just built, plus `wave.frag`, the settings QML and the default config,
   which upstream leaves to `make install` — and `make install` cannot be used
   because it would write through the Orbit-owned service symlink into this
   repository. `enable --now` became `enable`: the renderer needs a Wayland
   session, so it starts with `hyprland-session.target`.
8. Removed the vendored prebuilt `bin/orbit-wallpaper-engine` ELF. The renderer
   is built from the pinned `v0.2.0` external checkout during install instead of
   shipping an opaque binary in this repository.
9. `config/hypr/hyprland.lua` — `require("monitors")` and `require("noctalia")`
   load files that only exist *after* a first login: `monitors.lua` comes from
   `nwg-displays`, `noctalia.lua` from Noctalia's Hyprland template. On a fresh
   install either one raises a Lua error that aborts the whole config, so the
   first Hyprland session comes up as stock Hyprland with no Orbit binds. Both
   are now `pcall`-guarded, with a `preferred/auto` monitor fallback. A fallback
   `monitors.lua` is also seeded from `arch/monitors.lua.default` at install.

### Changed for this setup

10. `config/hypr/hyprland.lua`:
   - `local terminal = "ghostty"` (was `wezterm`), `local fileManager = "dolphin"` (was `nautilus`).
   - `kb_layout = "us,ara"` with `kb_options = "grp:alt_shift_toggle"` (was `us` only).
   - Removed the Super+S (OpenCode), Super+D and Super+Shift+D (Obsidian) binds and
     their helper path locals.
   - Added an NVIDIA environment block guarded on `/proc/driver/nvidia/version`,
     replacing what `scripts/06-hyprland.sh` used to append to `hyprland.conf`.
   - Merged the pre-Orbit Ayzrch keybinds. `Super+Return` opens the terminal and
     `Super+Q` closes the window (upstream has terminal on `Super+Q`, close on
     `Super+C`; `Super+C` still closes). `Super+Shift+S` pipes the screenshot to
     `satty` rather than straight to the clipboard. Added, none of which upstream
     binds at all: `Super+1..0` / `Super+Shift+1..0` absolute workspaces, the
     `Super+grave` scratchpad, `Super+F` maximize, `Super+Shift+E` emoji picker,
     `Super+Shift+C` colour picker, and the audio, media and brightness keys.
     Upstream's directional focus and workspace navigation are kept as they are.
     `Super+B` / `Super+Shift+B` open Zen's Personal / Work profiles; these were
     commented out in the pre-Orbit config and are restored here.

Two upstream binds are intentionally left as-is and are dead until the apps exist:
Super+A (`chatgpt`) and Ctrl+Shift+Escape (`flatpak run io.missioncenter.MissionCenter`).

### Found on the first Hyprland session

11. `config/hypr/hyprland.lua` — sets `QT_QPA_PLATFORMTHEME=hyprqt6engine`.
    `bin/orbit-session-bootstrap` refuses to import the session environment
    unless all nine listed variables are non-empty, and nothing on Arch sets this
    one (Fedora does so globally). Without it the bootstrap exits immediately,
    `hyprland-session.target` never starts, and the whole service stack — wallpaper
    engine, polkit agent, shader events, Alt+Tab, colour adapters, portal
    rebinding — silently stays down while the compositor itself looks fine.
12. `systemd/user/workspace-alt-tab-input.service` — upstream runs
    `/usr/bin/sg input -c …`. Arch's `shadow` package ships `newgrp` but not `sg`,
    so the unit dies with status 203/EXEC. It now execs `orbit-input-state`
    directly and `scripts/15-orbit.sh` adds the user to the `input` group.
13. `bin/orbit-theme` — required exactly 8 colour roles from Noctalia's Hyprland
    template, including `shadow`. Noctalia dropped `shadow` from that template
    after 5.0.0-beta.9 (the validated release), so every colour adapter aborted
    against current Noctalia. The 7 core roles are now required and `shadow`
    falls back to `surface`, which is the only value it fed.

14. `config/hypr/hypridle.conf` — `lock_cmd` calls `noctalia msg session lock`
    instead of Orbit's `start-hyprlock`. Noctalia 5.x ships a session lock that
    is enabled by default and claims `ext-session-lock-v1` on the logind lock
    signal; upstream Orbit locks with hyprlock, so both raced. hyprlock lost
    ("Seems we got yeeten"), the failed lock dropped the session back to
    unlocked, and the wallpaper renderer's surfaces were destroyed with it.
    Noctalia was validated at 5.0.0-beta.9, before it had a lock screen.
    Orbit's `hyprlock.conf`, `generate-hyprlock-colors` and the wallpaper's
    lock background are left in place but unused; the conf documents how to
    hand locking back to hyprlock.
15. `systemd/user/orbit-wallpaper-engine.service` — `Restart=always` instead of
    `Restart=on-failure`. The renderer exits 0 when its Wayland connection
    drops, so `on-failure` never fired and any compositor-side disruption left
    the desktop with no wallpaper until it was started by hand.
    `RestartPreventExitStatus=78` still covers deliberate exits.

### Dependency gap

`bin/orbit-input-state` imports `evdev` and exits without it, taking
`workspace-alt-tab-input.service` (Alt+Tab hold-to-cycle) with it, but upstream's
`docs/dependencies.md` lists only `python3-pyudev`. `scripts/15-orbit.sh`
installs `python-evdev` as well.

## `arch/` (Ayzrch-owned, not upstream)

- `install-hyprwindowshade` — builds against Arch's `/usr/include/hyprland` via
  pkg-config instead of hyprpm's compiled headers; applies Orbit's tracked patch.
- `install-dynamic-cursors` — pinned-commit installer in the shape of Orbit's others.
- `install-oblique-cursor` — installs the hyprcursor theme from its GitHub release.
- `noctalia-templates.toml` — enables the Noctalia built-in templates whose output
  Orbit's adapters read.
