#!/usr/bin/env bash
# Copies custom system files (outside $HOME) into ~/.config/system/files/
# Stock files with small edits are documented in system-notes.md instead.
set -euo pipefail

DEST="$HOME/.config/system/files"

PATHS=(
  /etc/modprobe.d/nvidia-power.conf
  /etc/pacman.d/hooks
  /etc/systemd/logind.conf.d
  /etc/systemd/zram-generator.conf
  /etc/snapper/configs
  /etc/systemd/system/disable-bd-prochot.service
  /usr/local/bin/disable-bd-prochot.sh
  /usr/lib/systemd/system-sleep/disable-bd-prochot
)

existing=()
for p in "${PATHS[@]}"; do
  if [[ -e $p ]]; then existing+=("$p"); else echo "skip (missing): $p"; fi
done

sudo rm -rf "$DEST"
mkdir -p "$DEST"
sudo rsync -aR "${existing[@]}" "$DEST/"
sudo chown -R "$USER:$USER" "$DEST"

echo "Synced:"
find "$DEST" -type f | sed "s|^$DEST||" | sort
