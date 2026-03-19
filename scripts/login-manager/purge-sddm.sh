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

if ! systemctl is-enabled --quiet greetd.service; then
  echo "greetd is not enabled yet; aborting to avoid removing the only login manager." >&2
  exit 1
fi

pacman -Rns --noconfirm sddm

echo "SDDM has been removed. Current login manager: greetd."

