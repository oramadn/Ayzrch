# Deployment

`bootstrap/deploy` is intentionally small and idempotent.

It:

- creates required destination directories;
- symlinks authored Orbit configuration, scripts, libraries, QuickShell files,
  and user units from this repository;
- seeds mutable Qt configuration only when the destination is absent;
- seeds the authored Wallpaper Engine desktop launcher only when the destination
  is absent;
- seeds the Orbit freedesktop sound theme only when its files are absent;
- enables core user services without starting or restarting the desktop;
- asks Noctalia to apply templates and runs the canonical Orbit appearance
  adapter path;
- refuses to replace an existing regular file or unrelated symlink.

The command does not install packages, compile external plugins, modify monitor
configuration, or perform privileged operations. Use the dedicated documented
install steps for those tasks.

Before adoption, run `bootstrap/migrate --dry-run`. Its `--adopt` mode is the
explicit exception to deploy's refusal-only behavior: it adopts approved
identical or known-portable files, snapshots replaced files, and writes a
manifest below `${XDG_STATE_HOME:-$HOME/.local/state}/orbit/migrations/`.
Rollback uses the printed manifest:

```sh
./bootstrap/migrate --rollback \
  "$HOME/.local/state/orbit/migrations/<timestamp>/manifest.json"
```

Rollback refuses to remove a destination that changed after adoption. Normal
deployment creates links and enables user units, but does not start or restart
the desktop. Start a fresh Hyprland session after deployment to load the
configuration and plugins; a reboot is normally unnecessary.

Plymouth installation and Noctalia greeter synchronization require privilege
and are separate operations.

To deploy optional user services:

```sh
./bootstrap/deploy --optional
```

Sunshine display recovery additionally requires a machine-local file at
`~/.config/orbit/machine/sunshine-display.conf`, based on
`config/orbit/machine/sunshine-display.conf.example`.
