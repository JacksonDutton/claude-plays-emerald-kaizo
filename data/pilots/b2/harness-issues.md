# Harness issues

## 2026-10-17 ~11:20-11:40 UTC — status lines stale/lagging at boot; queue_len stuck at 1; "ERR busy" on first press
- After `start.sh` the first `g a` returned `ERR busy: previous PRESS still queued/draining`. `g s` showed `busy`, DIAG showed `queue_len:1`, `queue_head_mask:1`, `queue_head_hold:0`, `game_mode:"main_menu"`, `inputs_last_300f:0` for several minutes.
- I suspected the emulator had stopped advancing frames (ps CPU TIME stuck at 0:00:03, mgba.log empty). That was wrong: `/proc/<pid>/stat` utime was rising, `g raw MODE` showed `frame` going up ~60/s, and a screenshot showed the game had moved on to Birch's intro speech. `ps` TIME is just coarse for a frame-paced process.
- So the game was running and had progressed past the title menu without any press from me (A on NEW GAME was apparently applied by the stale queued press, then the intro auto-scrolled). The harness status (`game_mode:main_menu`, `busy`, queue_len 1) lagged the real game state by minutes. By the time I looked again `queue_len` was 0 and `g s` read `dec:naming_screen`.
- Consequence: the gender prompt was passed without my input and the default (boy) was selected. Not a choice I made. Logged in diary.
- I restarted the emulator once with `start.sh` (no save existed, so nothing lost) — the same stale state appeared after the restart, so the restart did not fix it; it just resolved by waiting.
- Worked around by checking `g shot` / `g raw MODE` (frame counter) instead of trusting `g s` right after boot. Sent `g raw CLEARQUEUE` once; it reported "cleared 0" (queue was already empty).
- Possible cause (inferred, not verified): the cloud pacing patch (59.7 fps real-time) vs. a harness tuned for the Mac's timing; a 1-entry press with hold+release of ~40 frames should drain in <1s but did not appear to.

## 2026-10-17 ~11:50 UTC — `g adv` pressed A up to 30 times on the clock-setting yes/no
- In the bedroom I used `g adv` after the "clock is stopped" text. It printed "(max 30 presses, still in same message)" and had pressed A repeatedly. The screenshot then showed "Is this the correct time?" with the cursor on NO (not YES). I don't know whether my presses moved it or the clock screen defaults that way. I moved it to YES myself and accepted a 10:00 AM game clock (not my real local time; it doesn't matter for this game).
- The status flag `yn?` was also unreliable at times: it showed on ordinary dialogue and was missing on at least one real prompt-ish screen. I fell back to `g shot` before every confirm.

## 2026-10-17 19:12 UTC — emulator down after pause
After the pause the bridge on :8888 refused connections (the VM had apparently been reset/idle). `bash start.sh resume` brought it back at (23,46) in Rustboro, which matches the 18:50 checkpoint (in-game save + savestate). Used only for crash recovery, not to undo anything. Note the `g` error message suggests `~/pokemon_bridge/relaunch.sh`; I used start.sh as CLAUDE.md says.
