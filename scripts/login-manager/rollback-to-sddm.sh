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

pacman -S --needed --noconfirm sddm
systemctl enable sddm.service
systemctl disable greetd.service || true

echo "Switched back to SDDM. Please reboot."

