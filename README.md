# Hyprland WM Config for Arch Linux
Personal Hyprland desktop setup for Arch Linux, including:
- `Hyprland`
- `uwsm`
- `Waybar`
- `Wofi`
- `Tilda`
- `greetd + tuigreet` helper scripts
- helper scripts under `~/.local/bin`
- `hypridle`, `hyprlock`, `hyprpaper`
## Repository layout
- `templates/.config/...` — config files installed into `~/.config`
- `templates/.local/bin/...` — helper scripts installed into `~/.local/bin`
- `scripts/login-manager/...` — greetd / SDDM switch and rollback helpers
- `packages/arch.txt` — package list for Arch Linux
- `install.sh` — one-click installer
## Quick install
```bash
git clone git@github.com:simplepoint1024/hyperland-wm-config-archlinux.git
cd hyperland-wm-config-archlinux
chmod +x install.sh
./install.sh
```
## Useful install options
```bash
./install.sh --dry-run
./install.sh --skip-packages
./install.sh --force
```
## What the installer does
- installs Arch packages from `packages/arch.txt` unless `--skip-packages` is used
- backs up existing target files into `~/.cache/hyperland-wm-config-archlinux/backups/<timestamp>/`
- renders template files by replacing `__HOME__` with your real home directory
- installs configs into `~/.config/...`
- installs helper scripts into `~/.local/bin/...`
- makes installed scripts executable
## Login manager
This repo now tracks the recommended Hyprland login-manager path on Arch:
- `greetd`
- `tuigreet`
- `uwsm`

The switch / purge / rollback helpers live under `scripts/login-manager/`:
- `switch-to-greetd.sh`
- `purge-sddm.sh`
- `rollback-to-sddm.sh`

Detailed notes and example commands are in `docs/login-manager.md`.
## Notes
### Wallpapers
This repo keeps the current wallpaper paths from the original machine, but they are rewritten to your home directory at install time.
If those images do not exist on the target machine, Hyprland will still install, but you should edit:
- `~/.config/hypr/hyprpaper.conf`
- `~/.config/hypr/hyprlock.conf`
- `~/.local/bin/hypr-startup`
### Monitor layout
The current `hyprland.conf` contains a machine-specific monitor layout.
If your monitor names or positions differ, edit `~/.config/hypr/hyprland.conf` after install.
## Dry-run example
```bash
./install.sh --dry-run --skip-packages
```
