#!/bin/bash
# Start (or restart) the headless emulator + harness in the background.
#   start.sh          boot (the in-game save loads normally from the title screen)
#   start.sh resume   boot, then load savestate slot 1 (crash/VM-reset recovery only)
REPO="$(cd "$(dirname "$0")" && pwd)"; PB="$HOME/pokemon_bridge"; ROM="$PB/rom/kaizo.gba"
pid=$(pgrep -x mgba-headless) && kill $pid && sleep 1
cd "$PB" || exit 1
setsid -f /opt/mgba-headless -l 0 --script "$PB/bootstrap.lua" "$ROM" < /dev/null > "$PB/mgba.log" 2>&1   # fully detached: this script returns at once
for i in $(seq 1 40); do sleep 0.5; (exec 3<>/dev/tcp/127.0.0.1/8888) 2>/dev/null && break; done
export PATH="$HOME/bin:$PB:$PATH" TC_ROM="$ROM"
g s || { echo "ERR emulator did not come up; see $PB/mgba.log"; exit 1; }
if [ "$1" = resume ]; then g raw LOAD 1; sleep 1; g s; exit 0; fi
# Fresh boot: the status line can lag the game for a while after boot (seen in earlier runs).
# Wait for any queued input to drain; if it hasn't after 60 s, clear it once and log that.
for i in $(seq 1 120); do s=$(g s 2>/dev/null); [[ $s == *busy* ]] || break; sleep 0.5; done
if [[ $s == *busy* ]]; then
  c=$(g raw CLEARQUEUE); mkdir -p "$REPO/run"
  echo "- $(date -u +%FT%TZ) start.sh: input queue still busy 60 s after boot; sent CLEARQUEUE ($c)." >> "$REPO/run/harness-issues.md"
fi
echo "Booted. Right after boot the status line can lag: take a g shot before your first press."
