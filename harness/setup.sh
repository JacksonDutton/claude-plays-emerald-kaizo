#!/bin/bash
# One-time (and after any VM reset) setup for the Kaizo run. Idempotent.
set -e
REPO="$(cd "$(dirname "$0")" && pwd)"; PB="$HOME/pokemon_bridge"
bash "$REPO/cloud/build_cloud_mgba.sh"
python3 -c 'import PIL' 2>/dev/null || pip install -q --break-system-packages pillow
mkdir -p "$PB/rom" "$PB/shots" "$HOME/bin"
for f in director.lua g; do cp "$REPO/harness/$f" "$PB/$f"; done
# tc reads type/move/stat tables from the ROM: point its default at the Kaizo ROM
sed "s#~/pokemon_bridge/emerald_orig_copy.gba#~/pokemon_bridge/rom/kaizo.gba#" "$REPO/harness/tc" > "$PB/tc"
sed "s#__DIRECTOR_PATH__#$PB/director.lua#" "$REPO/harness/bootstrap.lua" > "$PB/bootstrap.lua"
chmod +x "$PB/g" "$PB/tc"
install -m 755 "$REPO/cloud/sips" "$HOME/bin/sips"
ROM="$PB/rom/kaizo.gba"
if [ ! -s "$ROM" ]; then
  if [ -s "$REPO/rom/kaizo.gba" ]; then cp "$REPO/rom/kaizo.gba" "$ROM"
  else git -C "$REPO" show rom-local:kaizo.gba > "$ROM.tmp" 2>/dev/null && mv "$ROM.tmp" "$ROM" || { rm -f "$ROM.tmp"; echo "ERR: ROM not found (rom/kaizo.gba or branch rom-local)"; exit 1; }; fi
fi
echo "a7c4e34fafb53f2d5283eb6d43dad285c0dd40a8  $ROM" | sha1sum -c --quiet || { echo "ERR: ROM hash mismatch"; exit 1; }
# restore latest checkpoint (in-game save + savestates) if the run has one
for f in "$REPO"/run/saves/kaizo.*; do [ -e "$f" ] && cp -n "$f" "$PB/rom/"; done
grep -q 'pokemon_bridge' "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" <<B
export PATH="\$HOME/bin:\$HOME/pokemon_bridge:\$PATH"
export TC_ROM="\$HOME/pokemon_bridge/rom/kaizo.gba"
B
echo "setup OK. Start the emulator with: bash $REPO/start.sh"
