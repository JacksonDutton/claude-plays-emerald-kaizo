# Harness

The Kaizo harness exactly as frozen for the K2 arm (18 October 2026). The file hashes are in `FREEZE.md`; every file here matches its row there, with one exception noted below. `FREEZE.md` and `V2-CHANGES.md` give paths as they were in the run repository, so `harness/director.lua` there is `emulator/director.lua` here (the run-repository layout is under "Running it").

`FREEZE.md` has no rows for the briefs or the notes packs. Checked on 29 October against K2's launch commit (`7d3f3c2`, on the supervisor's Mac): `notes-packs/K2.md` (sha256 `5b83ceb6e0a05379…`), `briefs/K2-brief.md` (`3df36371b249186b…`, the `CLAUDE.md` row) and `claude-settings.json` (`0b6d3aebf3d8f016…`) are byte-identical to the files K2 started with. `briefs/B2-brief.md` (`cbde5a6f79c8afcd…`) matches B2's launch commit (`590b431`).

## Layout

| Path | What it is | Installed as (in a run) |
|---|---|---|
| `emulator/director.lua` | mGBA Lua script: reads game state from emulator memory, queues inputs, serves both on 127.0.0.1:8888. RAM addresses come from the pret decompilation and symbol file, not from walkthroughs. | `~/pokemon_bridge/director.lua` |
| `emulator/bootstrap.lua` | Loads and hot-reloads `director.lua` inside mGBA. `__DIRECTOR_PATH__` is filled in by `setup.sh`. | `~/pokemon_bridge/bootstrap.lua` |
| `emulator/g` | The agent's command-line client (`g s`, `g look`, `g a`, `g up 3`, `g t`, `g adv`, `g shot`, `g name`, battle and menu helpers). | `~/pokemon_bridge/g` |
| `emulator/tc` | Type, stat and damage calculator. Reads its tables from the ROM, so it gives the hack's numbers. | `~/pokemon_bridge/tc` |
| `cloud/` | Builds headless mGBA in a Claude Code cloud container (with a 60 fps pacing and video-buffer patch) and a Linux stand-in for macOS `sips`. | `/opt/mgba-headless`, `~/bin/sips` |
| `setup.sh`, `start.sh`, `checkpoint.sh`, `package.sh` | One-time setup (checks the ROM's SHA-1), emulator start and resume, savestate checkpoint plus local commit, end-of-run export. | repository root |
| `claude-settings.json` | The arm's Claude Code settings: model, effort, and the permission list (no web, no skills, no pushing the ROM branch). | `.claude/settings.json` |
| `briefs/` | The agent brief each arm read at start (`CLAUDE.md` in its run repository). Renamed here so Claude Code does not load them as instructions when this repository is opened. | `CLAUDE.md` |
| `notes-packs/` | The two notes packs given to the notes arms: `K1.md` (K1.1, distilled from Run 1; used by Ripple) and `K2.md` (from Run 1 and Ripple; used by K2). | `notes/K1.md`, `notes/K2.md` |
| `FREEZE.md`, `V2-CHANGES.md`, `harness-v2.diff` | Freeze record and change log; the v1 to v2 diff of `director.lua` and `g`. | |

## Which arm ran what

| Arm | Harness | Brief | Notes pack |
|---|---|---|---|
| B1 | v1 (this folder minus `harness-v2.diff` and the 18 Oct changes listed in `FREEZE.md`) | `briefs/B1-brief.md` | none |
| B2 | v2 | `briefs/B2-brief.md` | none |
| Ripple | v2 | `briefs/Ripple-brief.md` | `notes-packs/K1.md` |
| K2 | v2 plus the 18 Oct changes (foe team-size readout on the status line, boot wait in `start.sh`, `package.sh`) | `briefs/K2-brief.md` | `notes-packs/K2.md` |

## Known discrepancy

`FREEZE.md` lists `.claude/settings.json` as `18cb4850d570d68e`. The file committed in K2's run repository, and copied here, hashes to `0b6d3aebf3d8f016`. The table row appears not to have been updated when the settings changed (unverified). The file here is the one K2 ran with.

## Running it

You need your own legally obtained ROM: Pokémon Emerald (US), patched with Emerald Kaizo v2.1, SHA-1 `a7c4e34fafb53f2d5283eb6d43dad285c0dd40a8`. No ROM is distributed here.

1. Make a run repository laid out as `setup.sh` expects. The paths are not the ones in this folder, and the "Installed as" column above is where `setup.sh` then copies them:

   ```
   CLAUDE.md                 one of briefs/*.md
   .claude/settings.json     claude-settings.json
   notes/K2.md               notes arms only (notes-packs/)
   harness/director.lua      emulator/director.lua
   harness/bootstrap.lua     emulator/bootstrap.lua
   harness/g, harness/tc     emulator/g, emulator/tc
   cloud/                    cloud/
   setup.sh start.sh checkpoint.sh package.sh
   rom/kaizo.gba             your patched ROM
   ```
2. In a Claude Code cloud session: `bash setup.sh`, then `bash start.sh`.
3. The agent reads `CLAUDE.md` and plays with `g`. `checkpoint.sh "message"` saves; `package.sh` exports the run at the end.

The Run 1 (vanilla) harness ran on a Mac with the mGBA Qt app and is not included.
