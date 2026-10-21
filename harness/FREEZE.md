# Harness freeze (16 Oct 2026)

This run uses these exact files.

| file | sha256 (first 16) | note |
|---|---|---|
| harness/director.lua | 1b4a4f00a6c00ae8 | |
| harness/bootstrap.lua | 17ad359a9a7c80ff | |
| harness/g | 98b9f7c216e5f653 | |
| harness/tc | d29e0d535b0d81e5 | |
| cloud/mgba-headless-pacing-and-video.patch | 6384b6955f246cc6 | |
| cloud/build_cloud_mgba.sh | 60a74d366cf7413c | |
| cloud/sips | 00fc40cd53e78245 | |
| setup.sh | 1be1804ea0888e90 | |
| start.sh | 80bb1795b2d99556 | |
| checkpoint.sh | 0da7fee79ae85663 | |
| CLAUDE.md | 3df36371b249186b | |
| package.sh | 6ae89d72c6168b0f | end-of-run export (K2) |
| .claude/settings.json | 18cb4850d570d68e | |

Notes:
- director.lua: VERSION `aba96c3c` (frozen since 9 Oct).
- bootstrap.lua: `__DIRECTOR_PATH__` is a placeholder; setup.sh writes the real path into the installed copy, and that is its only difference from the Mac copy.
- tc: version **v3.1k**, which is v3.1 (md5 feda7765…) plus one line: `ROM = os.environ.get("TC_ROM") or …`. setup.sh points the installed default at the Kaizo ROM. The Kaizo hack changes base stats (1,184 bytes), moves (449) and items (91) but keeps the type chart and every table address, so tc reads correct Kaizo numbers.
- ROM: Emerald Kaizo v2.1 (SinisterHoodedFigure, RHDN, 14 Mar 2020), patched with the IPS (sha1 07807df8…) onto the clean US ROM (sha1 f3ae0881…). Result sha1 `a7c4e34fafb53f2d5283eb6d43dad285c0dd40a8`. It lives only on the local branch `rom-local`, which is never pushed.
- Emulator: mGBA master 143adf5a, headless with Lua 5.4, plus a patch for 60 fps pacing and a video buffer. The Mac arm runs the mGBA Qt app instead. That environment difference goes in the paper.
- Screenshots: on the Mac, `g shot` upscales 2× with macOS sips; in the cloud, `cloud/sips` does a nearest-neighbour 2× resize. Both produce 480×320.
- Smoke test (companion's container, 16 Oct): booted, named the player, reached INSIDE OF TRUCK (25.40). `g s`, `g look`, MAPNAME, SAVE (ss1 written next to the ROM), `g shot` (480×320) and `tc mon` all worked.

- 16 Oct 7:55pm, before the third launch: CLAUDE.md gained a "How to play" section (no speed target; one `g` action per call; no loops or suppressed output; `g adv` for read text), the diary was made the main record, and the "screenshots are slowest" line was removed. start.sh now detaches the emulator (`setsid -f`), so the call returns at once. The harness files are unchanged.

- 18 Oct (K2 build): stuck rule changed from PAUSE-and-wait to a stuck review and carry on (aim: zero companion interventions); automatic tool reminders are named as not from the study; timestamps from `date -u`; checkpoint.sh no longer tries to push; new package.sh exports run files and a git bundle at the end. Harness files unchanged.
- 18 Oct (boot): start.sh now waits up to 60 s after a fresh boot for queued input to drain, clears the queue once if it is still busy (logged in run/harness-issues.md), and tells the player to take a `g shot` before the first press. The `g` no-reply message now points to `start.sh resume` instead of a Mac-only relaunch script. Pre-game and recovery only; game handling unchanged. Syntax-checked; not run against the emulator.
- 18 Oct (notes): four method-level additions to notes/K2.md from the previous notes run's exit interview (SUMMARY check after a forced switch, stale status/yn?, step the Center dialogue, write the opponent's team after a loss). No places, names or fights.
- 18 Oct (tc): a header comment naming an earlier agent was made anonymous; code unchanged.
- 18 Oct (foes): the status line shows `foes:a/b` in trainer battles (alive / team size, read from the foe party's level and HP fields), matching the party-ball row a human sees. Requested by a previous run's exit interview. Tested in the companion's cloud container on a mid-gym-battle savestate: `foes:2/6`, per-slot read 4 fainted, 2 full. start.sh tested there too: resume worked; a fresh boot showed `busy` for about 25 s with no input sent, then cleared on its own (no CLEARQUEUE needed).
- 18 Oct (review by the first notes author): notes header says the facility lessons assume equal levels (compare levels first) and to look lessons up by ID after one full read; T08 slot numbering made consistent (RAM from 0, screen from 1); B19 says the low-estimate figure is about mental arithmetic, not `tc`; B20 adds first-turn move order as speed evidence; T15 adds that seen moves are a minimum and to check both foe types on the chosen move; D14 tidied (one Why; warp-list clause moved to N02); duplicate 'trust the readout' trimmed. CLAUDE.md: look up notes by ID; log the time of each stuck review. `harness/turn.sh` removed from the repo and setup (an old Mac helper that discards `g` output and loops presses, which the brief forbids; no earlier Kaizo arm's records mention it). R01/R05 stay out on purpose.

## Note added 21 Oct 2026 (repository copy)

- **Settings hash.** The `.claude/settings.json` row above (`18cb4850d570d68e`) was not updated when the settings changed before K2's launch. The file K2 actually ran with, committed in its run repository and copied here as `harness/claude-settings.json`, hashes to `0b6d3aebf3d8f016`. Every other file in this repository matches its row above (checked 21 Oct with `sha256sum`). The row is left as written so the record stays as it was at the freeze.
- **Names and paths.** This table uses each file's path in a run repository. In this repository the emulator files live under `harness/emulator/`, the settings file is `harness/claude-settings.json`, and `CLAUDE.md` is `harness/briefs/K2-brief.md` (hash `3df36371b249186b`, matching the row). `harness/README.md` maps every path.
