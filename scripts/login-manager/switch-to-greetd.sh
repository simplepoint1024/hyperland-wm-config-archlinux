#!/usr/bin/env bash
set -euo pipefail

if (( EUID != 0 )); then
  echo "Please run with sudo: sudo $0" >&2
  exit 1
fi

if ! grep -q '^ID=arch$' /etc/os-release; then
  echo "This script currently supports Arch Linux only." >&2
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
backup_dir="/var/backups/hyprland-dm-switch-$(date +%Y%m%d-%H%M%S)"
install -d -m 755 "$backup_dir"

if [[ -f /etc/greetd/config.toml ]]; then
  cp -a /etc/greetd/config.toml "$backup_dir/greetd-config.toml.bak"
fi

if [[ -e /etc/systemd/system/display-manager.service ]]; then
  cp -a /etc/systemd/system/display-manager.service "$backup_dir/display-manager.service.bak"
fi

pacman -S --needed --noconfirm greetd greetd-tuigreet uwsm

install -d -m 755 /etc/greetd
cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --user-menu --asterisks --sessions /usr/share/wayland-sessions --xsessions /usr/share/xsessions"
user = "greeter"
EOF

systemctl enable greetd.service
systemctl disable sddm.service || true

cat <<EOF

Prepared the switch from SDDM to greetd + tuigreet + uwsm.

After reboot, choose:
  Hyprland (uwsm-managed)

Next steps:
  1) reboot
  2) verify greetd can log into Hyprland normally
  3) if everything is fine, run:
     sudo ${script_dir}/purge-sddm.sh

Rollback:
  sudo ${script_dir}/rollback-to-sddm.sh

Backup directory:
  ${backup_dir}
EOF

