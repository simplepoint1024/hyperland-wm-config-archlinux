# Login manager: greetd + tuigreet + uwsm

For Hyprland on Arch Linux, this repository uses the recommended `greetd + tuigreet + uwsm` path instead of `SDDM`.

## Included helpers

- `scripts/login-manager/switch-to-greetd.sh`
  - installs `greetd`, `greetd-tuigreet`, `uwsm` unless `--skip-packages` is used
  - renders `scripts/login-manager/templates/greetd/config.toml.tmpl`
  - writes `/etc/greetd/config.toml`
  - enables `greetd.service`
  - disables `sddm.service`
- `scripts/login-manager/purge-sddm.sh`
  - removes `sddm` after `greetd` has been enabled successfully
- `scripts/login-manager/rollback-to-sddm.sh`
  - reinstalls `sddm`
  - re-enables `sddm.service`
  - disables `greetd.service`

## Recommended order

### One-shot from the repo root

```bash
cd /path/to/hyperland-wm-config-archlinux
./install.sh --enable-greetd
reboot
```

This installs the desktop packages/configs first, then deploys the repository-managed greetd config and enables `greetd.service`.

### Login manager only

```bash
cd /path/to/hyperland-wm-config-archlinux
sudo ./scripts/login-manager/switch-to-greetd.sh
reboot
```

After reboot, choose:

- `Hyprland (uwsm-managed)`

If everything works, you can remove `SDDM`:

```bash
sudo ./scripts/login-manager/purge-sddm.sh
```

If you need to roll back:

```bash
sudo ./scripts/login-manager/rollback-to-sddm.sh
```

## Notes

- These helpers are intentionally Arch-only.
- The scripts create a backup directory under `/var/backups/` before changing the login-manager configuration.
- The greetd template is versioned in `scripts/login-manager/templates/greetd/config.toml.tmpl`.
- `install.sh --enable-greetd` performs the full repo install and then switches the active login manager.
- For a safe preview, run:

```bash
./install.sh --dry-run --skip-packages --enable-greetd
sudo ./scripts/login-manager/switch-to-greetd.sh --dry-run
```

- You can override the generated greetd values when needed:

```bash
sudo GREETD_VT=1 \
  GREETD_USER=greeter \
  GREETD_COMMAND='tuigreet --time --remember --remember-session --user-menu --asterisks --sessions /usr/share/wayland-sessions --xsessions /usr/share/xsessions' \
  ./scripts/login-manager/switch-to-greetd.sh
```

