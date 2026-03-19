#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
TEMPLATES_DIR="$REPO_ROOT/templates"
PACKAGES_FILE="$REPO_ROOT/packages/arch.txt"
TARGET_HOME="${TARGET_HOME:-$HOME}"
BACKUP_ROOT="$TARGET_HOME/.cache/hyprland-wm-config-archlinux/backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
DRY_RUN=0
FORCE=0
SKIP_PACKAGES=0
ENABLE_GREETD=0
log() { printf '[install] %s\n' "$*"; }
warn() { printf '[install][warn] %s\n' "$*" >&2; }
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}
usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]
Options:
  --dry-run        Show what would happen without changing files
  --force          Overwrite targets even if they already exist
  --enable-greetd  Deploy the repo-managed greetd config and enable greetd
  --skip-packages  Do not install packages
  -h, --help       Show this help
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --enable-greetd) ENABLE_GREETD=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    -h) usage; exit 0 ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done
if [ ! -d "$TEMPLATES_DIR" ]; then
  echo "Missing templates directory: $TEMPLATES_DIR" >&2
  exit 1
fi
ensure_dir() {
  local dir="$1"
  run "mkdir -p \"$dir\""
}
backup_file() {
  local target="$1"
  if [ ! -e "$target" ]; then
    return 0
  fi
  local rel="${target#${TARGET_HOME}/}"
  local backup="$BACKUP_DIR/$rel"
  ensure_dir "$(dirname "$backup")"
  run "cp -a \"$target\" \"$backup\""
}
render_template() {
  local src="$1"
  local tmp
  tmp="$(mktemp)"
  python - "$src" "$tmp" "$TARGET_HOME" <<'PY'
from pathlib import Path
import sys
src = Path(sys.argv[1])
out = Path(sys.argv[2])
home = sys.argv[3]
text = src.read_text(encoding='utf-8').replace('__HOME__', home)
out.write_text(text, encoding='utf-8')
PY
  printf '%s\n' "$tmp"
}
install_one() {
  local src="$1"
  local rel="${src#$TEMPLATES_DIR/}"
  local dst="$TARGET_HOME/$rel"
  local tmp
  ensure_dir "$(dirname "$dst")"
  tmp="$(render_template "$src")"
  if [ -e "$dst" ] && cmp -s "$tmp" "$dst"; then
    log "unchanged: $dst"
    rm -f "$tmp"
    return 0
  fi
  if [ -e "$dst" ]; then
    backup_file "$dst"
    if [ "$FORCE" -eq 1 ]; then
      run "rm -rf \"$dst\""
    fi
  fi
  run "install -Dm644 \"$tmp\" \"$dst\""
  case "$dst" in
    "$TARGET_HOME/.local/bin/"*) run "chmod +x \"$dst\"" ;;
  esac
  rm -f "$tmp"
  log "installed: $dst"
}
install_packages() {
  if [ "$SKIP_PACKAGES" -eq 1 ]; then
    log 'skipping package installation'
    return 0
  fi
  if ! command -v pacman >/dev/null 2>&1; then
    warn 'pacman not found; skipping package installation'
    return 0
  fi
  mapfile -t pkgs < <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "$PACKAGES_FILE")
  if [ "${#pkgs[@]}" -eq 0 ]; then
    warn 'no packages found in packages/arch.txt'
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] sudo pacman -S --needed'
    for pkg in "${pkgs[@]}"; do printf ' %q' "$pkg"; done
    printf '\n'
  else
    sudo pacman -S --needed "${pkgs[@]}"
  fi
}
run_login_manager_setup() {
  local script="$REPO_ROOT/scripts/login-manager/switch-to-greetd.sh"
  if [ "$ENABLE_GREETD" -ne 1 ]; then
    return 0
  fi
  if [ ! -x "$script" ]; then
    echo "Missing login-manager script: $script" >&2
    exit 1
  fi
  log 'configuring greetd via repository-managed template'
  if [ "$DRY_RUN" -eq 1 ]; then
    "$script" --dry-run --skip-packages
    return 0
  fi
  if [ "$EUID" -eq 0 ]; then
    "$script" --skip-packages
  else
    sudo "$script" --skip-packages
  fi
}
main() {
  log "repo: $REPO_ROOT"
  log "target home: $TARGET_HOME"
  ensure_dir "$BACKUP_ROOT"
  install_packages
  while IFS= read -r -d '' file; do
    install_one "$file"
  done < <(find "$TEMPLATES_DIR" -type f -print0)
  run_login_manager_setup
  log 'done'
  log "backup directory: $BACKUP_DIR"
  warn 'If wallpapers or monitor names differ on the target machine, edit ~/.config/hypr/*.conf after install.'
}
main "$@"
