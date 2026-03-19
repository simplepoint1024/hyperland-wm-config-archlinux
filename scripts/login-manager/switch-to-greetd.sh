#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
SKIP_PACKAGES=0
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="${GREETD_CONFIG_TEMPLATE:-$SCRIPT_DIR/templates/greetd/config.toml.tmpl}"
BACKUP_DIR="/var/backups/hyprland-dm-switch-$(date +%Y%m%d-%H%M%S)"
GREETD_VT="${GREETD_VT:-1}"
GREETD_USER="${GREETD_USER:-greeter}"
GREETD_COMMAND="${GREETD_COMMAND:-tuigreet --time --remember --remember-session --user-menu --asterisks --sessions /usr/share/wayland-sessions --xsessions /usr/share/xsessions}"

usage() {
  cat <<'USAGE'
Usage: ./scripts/login-manager/switch-to-greetd.sh [options]
Options:
  --dry-run        Show the planned changes without writing files
  --skip-packages  Do not install greetd/tuigreet/uwsm
  -h, --help       Show this help
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}

require_root() {
  if [ "$DRY_RUN" -eq 0 ] && (( EUID != 0 )); then
    echo "Please run with sudo: sudo $0" >&2
    exit 1
  fi
}

require_arch() {
  if ! grep -q '^ID=arch$' /etc/os-release; then
    echo "This script currently supports Arch Linux only." >&2
    exit 1
  fi
}

ensure_template() {
  if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Missing greetd template: $TEMPLATE_PATH" >&2
    exit 1
  fi
}

render_template() {
  local tmp
  tmp="$(mktemp)"
  python - "$TEMPLATE_PATH" "$tmp" "$GREETD_VT" "$GREETD_USER" "$GREETD_COMMAND" <<'PY'
from pathlib import Path
import sys

def toml_escape(value: str) -> str:
    return value.replace('\\', '\\\\').replace('"', '\\"')

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
vt = sys.argv[3]
user = toml_escape(sys.argv[4])
command = toml_escape(sys.argv[5])
text = src.read_text(encoding='utf-8')
text = text.replace('__GREETD_VT__', vt)
text = text.replace('__GREETD_USER__', user)
text = text.replace('__GREETD_COMMAND__', command)
dst.write_text(text, encoding='utf-8')
PY
  printf '%s\n' "$tmp"
}

backup_if_exists() {
  local path="$1"
  local backup_name="$2"
  if [ -e "$path" ]; then
    run "cp -a '$path' '$BACKUP_DIR/$backup_name'"
  fi
}

install_packages() {
  if [ "$SKIP_PACKAGES" -eq 1 ]; then
    return 0
  fi
  run "pacman -S --needed --noconfirm greetd greetd-tuigreet uwsm"
}

deploy_config() {
  local rendered
  rendered="$(render_template)"
  run "install -d -m 755 '$BACKUP_DIR'"
  run "install -d -m 755 /etc/greetd"
  if [ -e /etc/greetd/config.toml ] && cmp -s "$rendered" /etc/greetd/config.toml; then
    echo "greetd config is already up to date: /etc/greetd/config.toml"
    rm -f "$rendered"
    return 0
  fi
  backup_if_exists /etc/greetd/config.toml greetd-config.toml.bak
  backup_if_exists /etc/systemd/system/display-manager.service display-manager.service.bak
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] install -Dm644 %q /etc/greetd/config.toml\n' "$rendered"
    printf '[dry-run] rendered config preview:\n'
    sed 's/^/  /' "$rendered"
  else
    install -Dm644 "$rendered" /etc/greetd/config.toml
  fi
  rm -f "$rendered"
}

enable_services() {
  run "systemctl enable greetd.service"
  run "systemctl disable sddm.service || true"
}

main() {
  require_root
  require_arch
  ensure_template
  install_packages
  deploy_config
  enable_services
  cat <<EOF

Prepared the switch from SDDM to greetd + tuigreet + uwsm.
Template source:
  ${TEMPLATE_PATH}

After reboot, choose:
  Hyprland (uwsm-managed)

Next steps:
  1) reboot
  2) verify greetd can log into Hyprland normally
  3) if everything is fine, run:
     sudo ${SCRIPT_DIR}/purge-sddm.sh

Rollback:
  sudo ${SCRIPT_DIR}/rollback-to-sddm.sh

Backup directory:
  ${BACKUP_DIR}
EOF
}

main "$@"

