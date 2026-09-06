# Optional Integrations

Optional integrations do not make their application a core Orbit dependency.

- **Sunshine:** `bin/orbit-sunshine-display`, its watchdog unit, and the
  machine-local display profile preserve save/switch/watchdog/restore behavior.
  Connector names, modes, resolutions, and host identities are never stored in
  the repository.
- **Game sessions:** `orbit-game-run`, `orbit-game-session.service`, and its
  timer integrate Steam/GameMode behavior.
- **Obsidian:** `configure-obsidian` installs the tracked appearance snippet into
  a vault selected by `OBSIDIAN_VAULT`.
- **Zen:** `configure-zen` installs the tracked browser chrome override into the
  active profile.
- **Zed:** the tracked theme and settings provide the supported presentation
  integration.
- **Nautilus Actions:** the installer verifies and installs the pinned upstream
  extension.
- **LocalSend:** the user unit and configuration helper integrate the Flatpak.
- **GPU Screen Recorder:** the control and installation helpers integrate the
  Flatpak recorder.
- **Plymouth:** the source theme is included but is not part of standard
  deployment and requires a privileged initramfs installation step.
