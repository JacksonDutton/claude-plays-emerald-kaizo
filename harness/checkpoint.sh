#!/bin/bash
# Checkpoint: savestate slot 1 + copy in-game save/states into run/saves, then commit locally.
#   checkpoint.sh "short message"
REPO="$(cd "$(dirname "$0")" && pwd)"; PB="$HOME/pokemon_bridge"
export PATH="$HOME/bin:$PB:$PATH"
g raw SAVE 1 >/dev/null; sleep 1
cp "$PB"/rom/kaizo.sav "$PB"/rom/kaizo.ss1 "$PB"/rom/kaizo.ss2 "$REPO/run/saves/" 2>/dev/null
cd "$REPO" && git add run && git commit -q -m "checkpoint: ${1:-progress}" && echo "committed"
echo "(commits are local; package.sh exports them at the end)"
