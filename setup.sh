#!/usr/bin/env bash
# One-time setup for the virtual pointer backend.
set -euo pipefail

if ! command -v ydotool >/dev/null; then
  echo "Installing ydotool..."
  omarchy pkg add ydotool
fi

sudo usermod -aG input "$USER"
systemctl --user enable ydotool.service

echo
echo "Setup is complete. Log out and back in (or reboot) before using the trackpad."
echo "After the new session starts, ydotool.service will create the virtual pointer."
