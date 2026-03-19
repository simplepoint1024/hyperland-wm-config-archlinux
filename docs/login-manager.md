# Login manager: greetd + tuigreet + uwsm

For Hyprland on Arch Linux, this repository uses the recommended `greetd + tuigreet + uwsm` path instead of `SDDM`.

## Included helpers

- `scripts/login-manager/switch-to-greetd.sh`
  - installs `greetd`, `greetd-tuigreet`, `uwsm`
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
- `install.sh` installs the packages, but it does **not** automatically switch the active display manager.

