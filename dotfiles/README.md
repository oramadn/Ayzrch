# Dotfiles

Personal configuration: editor, shell, terminal, multiplexer. The rice itself
lives in [`../orbit/`](../orbit); the split is by lifecycle, not importance.
Orbit's files are replaced wholesale when the desktop is updated. These are
yours, and nothing overwrites them.

Deployed by [`deploy`](deploy), which `scripts/05-dotfiles.sh` calls.

## Layout

| Tree | Placement | Why |
|---|---|---|
| `home/` | symlinked into `$HOME` | Editing the live file edits this repo. `git status` is your uncommitted changes. |
| `seed/` | copied once, never replaced | Orbit writes into these too. Linking them would send generated writes back here. |

`seed/` holds exactly three files: both `gtk-*/settings.ini`, where
`orbit-theme` owns four of the six keys (font, icon theme, cursor theme and
size), and `herdr/config.toml`, where it owns the generated `[theme.custom]`
table but the prefix key is yours.

`.config/nvim` is linked as a **directory**, not file by file, so lazy.nvim's
rewrite of `lazy-lock.json` lands here and gets tracked. A file-level symlink
would be replaced by any program that saves via temp-and-rename.

## History

This replaced chezmoi and a separate `dotfiles` repository. chezmoi was
carrying no templates, no encrypted files and no per-machine data, so the move
cost nothing -- it was being used as a git-backed file copier, which `deploy`
does in 80 lines. Per-machine variance, if it is ever wanted, belongs here.

Not carried over, deliberately: third-party plugin trees that their own
managers install (TPM, lazy.nvim), generated palette files, and machine-local
monitor layouts.

## Provenance

`home/.config/nvim` began as [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
(MIT, `LICENSE.md` retained) and has diverged. `lua/kickstart/` is upstream's;
`lua/config/` and `lua/plugins/` are local. The original checkout, with its git
history, was moved aside as `~/.config/nvim.pre-orbit-<date>` rather than
deleted.
