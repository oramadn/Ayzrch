# Wallpapers with awww + Noctalia

Replaces the removed Orbit Wallpaper Engine. Noctalia keeps the wallpaper picker
UI and palette generation; `awww` owns the actual pixels on screen.

## Why awww

`awww-daemon` draws through `wl_shm` (CPU shared-memory buffers), not an EGL/GPU
surface. The bug that killed the old engine every ~4.5 min (and later hung it)
was an NVIDIA explicit-sync fence deadlock on a persistent GPU context; awww
never opens one, so it cannot hit that class of bug.

Facts this setup relies on (verified 2026-09-11):

- `awww 0.12.1` is in Arch `extra`.
- Noctalia's `wallpaper_changed` hook fires with `NOCTALIA_WALLPAPER_PATH` and
  `NOCTALIA_WALLPAPER_CONNECTOR` (`DP-1` / `DP-2`, or empty for all outputs).
- `[theme] source = "wallpaper"` palette generation reads the wallpaper *file*
  (decoded to 112x112), independent of who renders it.
- Noctalia merges every `~/.config/noctalia/*.toml` alphabetically;
  `~/.local/state/noctalia/settings.toml` (app-managed) loads last and wins.
- `noctalia msg wallpaper-set [connector] <path>` persists + fires the hook.
- Noctalia's picker scans one flat folder (`[wallpaper] directory`), now
  `~/Pictures/Wallpapers` (set in both `20-awww-wallpaper.toml` and the
  GUI-managed `settings.toml`). No recursion for the picker.

## Layout in this repo

```
awww/
  systemd/user/awww-daemon.service
  bin/awww-noctalia-hook
  config/noctalia/20-awww-wallpaper.toml
scripts/17-awww-wallpaper.sh
docs/awww-live-wallpaper.md      (this file)
```

Everything is deployed as symlinks into `$HOME`, like Orbit does, so edits in the
repo apply live.

## How it works

1. `awww-daemon.service` (user unit, `WantedBy=hyprland-session.target`) runs
   `awww-daemon --quiet`. At start awww restores each output's last wallpaper
   from `~/.cache/awww/<ver>/DP-*` records, so login needs no extra step.
2. `20-awww-wallpaper.toml` disables Noctalia's own wallpaper surface
   (`[wallpaper] enabled = false`, the picker stays) and registers
   `[hooks] wallpaper_changed = "sh -c '~/.local/bin/awww-noctalia-hook'"`.
   It merges with Orbit's `hooks.toml` (`colors_changed`), distinct keys.
3. `awww-noctalia-hook` waits for the daemon socket, then runs
   `awww img [-o <connector>] --resize crop --transition-type fade ...`.
   Noctalia solid colours (`color:#RRGGBB`) become `awww clear RRGGBB`.
   Transitions: `none|simple|fade|left|right|top|bottom|wipe|wave|grow|center|any|outer|random`.
4. `scripts/17-awww-wallpaper.sh` installs the package, links the three files,
   enables/starts the unit, reloads Noctalia and re-applies the current
   wallpaper. `scripts/15-orbit.sh` no longer installs the old engine.

## Verify

```bash
systemctl --user status awww-daemon.service        # active (running)
awww query                                          # lists DP-1 and DP-2
journalctl --user -t awww-noctalia-hook -n 5       # one "img ..." line per pick
cat /proc/$(pgrep -x awww-daemon)/wchan; echo      # should NOT be drm_syncobj_*
noctalia msg wallpaper-set ~/Pictures/Wallpapers/some.jpg
```

Observed: `wallpaper-set DP-1 <path>` fires the hook with an empty connector
unless Noctalia's per-monitor wallpaper mode is on, so awww paints both outputs.

Steady-state cost with a static wallpaper: awww does no per-frame work; RSS is
the two shared framebuffers (~60 MB for 1080p + 1440p), no GPU context.

## Fallback — picker vanishes with `enabled = false`

Unverified whether disabling Noctalia's wallpaper renderer also hides its picker
panel (it did not on 2026-09-11). If it ever does:

1. Set `enabled = true` back in `20-awww-wallpaper.toml`.
2. Change the service to `ExecStart=/usr/bin/awww-daemon --quiet --layer bottom`
   so awww paints above Noctalia's background surface (still below windows and
   bars). Watch for Noctalia desktop widgets, which may also live on `bottom`.
3. `systemctl --user daemon-reload && systemctl --user restart awww-daemon`.

## Live (animated) wallpapers — tried and removed (2026-09-11)

awww can loop GIF/animated WebP, and a full pipeline was built and then purged:
drop-in MP4→WebP conversion (systemd path unit + ffmpeg), a hidden second
daemon for pre-decoding, a bar play/pause button and a Noctalia plugin panel.
It worked, but the cost was not worth it on this machine:

- awww decodes every frame at output resolution into a per-file cache
  (≈0.5 GB per 10 s clip at 15 fps for two monitors, linear in frames) and
  spends CPU decompressing every frame while playing (~15 % of a core at
  15 fps, ~60 % at 60 fps, per animation).
- Smoothness needs ≥30 fps, doubling or quadrupling that; downloaded "seamless"
  clips usually are not (the wrap jumped ~130 ms) and need crossfading.

If it is ever revisited: the awww frame cache is keyed by path + output size
only; `awww-daemon --namespace X` runs a second, independent daemon whose
per-output restore records are stored per namespace; `awww img` skips a file an
output already shows; and Noctalia's picker lists `.gif`/`.webp`, fires the
hook for them, and samples one frame for the palette. Noctalia plugins (Luau,
`ui.*` declarative panels, `noctalia.setWallpaper`) can build a custom picker.
