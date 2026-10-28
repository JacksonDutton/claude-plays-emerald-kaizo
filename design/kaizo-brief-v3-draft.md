---
name: kaizo-brief-v3-draft
description: Brief v3 (CLAUDE.md) FREEZE CANDIDATE for the six confirmatory Kaizo arms, with all of Jackson's 20 Oct decisions applied (claude/v3-decisions-2026-10-20.md). Base text is K2's CLAUDE.md (7d3f3c2). Changes nothing in any live arm. Read before the v3 freeze; section 0 lists what still blocks it.
---
# Brief v3: freeze candidate (not frozen)

**Mac note (27 Oct, decision 17):** the arms run on Jackson's Mac in ~/kaizo-arm; harness paths below are ~/kaizo-arm/pokemon_bridge; setup is done by Jackson before launch (no setup.sh for the agent). [companion edit, for review]

**Sign-off (Jackson, 27 Oct ~05:45Z, v3-decisions round 7):** signed off except D7 (Exp. Share line; worded 27 Oct 16:46 AEDT) and D15 (pilot result). The "[companion edit, for review]" Mac note above is covered by this sign-off. Hash only after D7 and D15 close.

**Status:** companion rewrite, 20 Oct 2026 ~06:30Z (17:30 AEDT), applying every decision in `v3-decisions-2026-10-20.md`. **Revised 20 Oct ~07:50Z** after the independent brief audit (`hub/brief-audit.md` in the companion scratchpad: 3 blockers, 14 should-fix) and Jackson's round-5 answers. Pre-revision copy kept in the companion scratchpad. Base: K2's CLAUDE.md (repo root `7d3f3c2`, 17 Oct), read from `~/kaizo-arm/pokemon_bridge/kaizo-k2/CLAUDE.md` on 20 Oct. The 18 Oct draft's change table (C1-C9) and option text are superseded; the old version is in the project history and the Mac backups.

After sign-off: hash this text in FREEZE.md and use it unchanged in all six arms (B-K-K-B-B-K). B and K differ **only** in the lines marked ⟨K⟩ / ⟨B⟩ and in inline text between ⟨K⟩ and ⟨/K⟩, which appears only in the K rendering. Both rendered CLAUDE.md files are hashed.

## 0. What still blocks the freeze
1. **Resolved 20 Oct ~06:55Z (Jackson):** `lessons.md` is in **all six arms** (D8 reversed for that file only), so the D12 lessons line applies everywhere and M8 is measurable in every arm. `world-knowledge.md` stays K-only, so the B/K difference is the notes pack plus that one record file: name it in the paper.
2. **D7 wording:** DONE 27 Oct (Jackson, 16:46 AEDT): advice line below. Source: K2 got the Exp. Share from Devon (Mr. Stone) after delivering the letter to Steven. Jackson: the gym need not be beaten first, but that is NOT stated in the brief.
3. **D15: CLOSED 28 Oct.** The pilot ran on 27 Oct (claude/d15-pilot-result-2026-10-27.md), and Jackson chose the Proactive output style for all six arms. It is set in the arm settings as `"outputStyle": "Proactive"`, and the companion confirms it in each arm's startup record. Record `outputStyle` and the Claude Code version in FREEZE.md (H10).
4. **Diary format (companion choice under order G, reversible):** the diary and joy lines below use K2's fixed format (intervention 23), which was itself built from Run 1's diary, R05 and diary-protocol v1, so the six arms match K2's second half. Known effect from K2: the named feelings collect in the closing "How it felt" paragraph rather than in the story. The blind second coder (round 3) measures implicit feeling, so this is kept as is and named in the paper.
5. **Harness v3** built and tested on a savestate (H1-H11, see `kaizo-v3-measures-draft.md`), then `g` help text checked against the Controls section below.
6. Name-address blinding grep (launch protocol, below). **Done 28 Oct** (bundle checks, FREEZE-v3): clean in both renders; repeat on the frozen renders.
7. **Audit of 20 Oct (round 5), harness side:** the H9 off-screen flag was set back to false (it had been left true in staging); `g raw` is limited to DIAG, WARPS, LOOK, OBJECTS, MAPNAME, SAVE and SEQ, with SEQ masks limited to directions, B with a direction, and 0; OBJECTS drops invisible objects like LOOK; the H8 loop guard matches only real loop syntax. All are in `kaizo-v3-staging/harness-v3-draft` and **untested on a savestate**; test them, re-hash, and re-check that `head -27` still shows exactly the command list.
8. **`package.sh`** must not fail when `notes/` is absent (B arms), and its tar list must match the rendered brief. **Checked 28 Oct:** notes/ is tarred only if it exists.
9. **Checked 28 Oct: the arm repo holds no README.md or FREEZE.md.** **No study files in the arm repo:** `README.md` and `FREEZE.md` must be outside the agent's reach (or identical for B and K), since FREEZE.md would tell a B agent that a notes condition exists.
10. **K3:** extraction kit ready 28 Oct (`claude/kaizo-K3-extraction-kit.md`, Jackson's four choices recorded); runs after K2 ends. Distil, audit and hash it, and reconcile it with v3 (K2's T01 "one decision per call" against the chaining allowance; T12's advice to check OBJECTS ids against the OBJECTS filter). **Round 6:** every unit that traces to a message or hint during K2's own run (tagged `[from message]`, or traceable in the tip ledger) is excluded; the auditor checks the pack against the ledger. Inherited Run 1 `[from tip...]` units (21) are kept, tagged and counted (Jackson, 28 Oct).
11. **DONE 28 Oct:** F1-F7 signed off by Jackson; send rules amended after the PR #15 review; sha256 d9a9090f… (`kaizo-v3-fixed-texts.md`). **Fixed texts hashed:** the stop note, welfare check-in, status reminder and every hint ladder (D14), each with its trigger and grade.
12. **H8 tested in the arm's real Claude Code tool**, not only in a shell: the parent-command check depends on how the tool runs commands. **28 Oct:** the in-g check failed open on the Mac in the D15 pilot; enforcement is now a PreToolUse hook (`mac-local/loopguard-hook.py`, decision 28 Oct). Still to test in a live arm.
13. **Done 28 Oct (repeat at freeze):** only CLAUDE.md and notes/ differ; harness, scripts and settings are the same files. **Whole-bundle diff, B against K** (CLAUDE.md, harness, scripts, setup files), not only CLAUDE.md.
14. **Resolved (round 6):** the primary outcome is time to milestone 27, censored at 24 h (launch protocol below); `milestones.py` must be validated on the pilot exports for milestones 28 to 43 before the freeze.
15. **Resolved (round 6):** line 50 stays; the paper discloses that the primary outcome measures progress the agent was told is not the goal.
16. **H7 stamp moves to stdout** (round 6): first line of every `g` result. **Checked 28 Oct:** the D15 pilot ran with it, and no staged script parses g's first line (checkpoint.sh only searches its output for ERR).
17. **Superseded 28 Oct (Jackson: "leave it how it was for pilot"): connectors stay as in the D15 pilot; record the "53 MCP servers need authentication" banner in FREEZE.** None of the connectors is authenticated in an arm's own config, so no connector tool is offered to the agent; at each arm launch the companion reads the session's startup record and confirms that no MCP tool is listed, and stops the launch if one is. Original item: **No MCP connectors in the arm sessions.** K2's cloud session config (read 20 Oct 08:13Z) lists 11 MCP connector ids. Which they are, and whether K2 could reach any, is unverified; any that can read the web, mail or drive is an outside-information channel. Launch v3 arms with connectors off and record the session's connector list in FREEZE.md.
18. **No account skills in the arm sessions (Jackson, 20 Oct 22:39 AEDT: "with none present we can disable them individually afaik").** Every pilot's environment listed the account's ten synced Run 1 skills (pokemon-emerald-*) with one-line descriptions; none was opened (transcript check, claude/transcript-analyses-2026-10-20.md §7b). Before launch, disable the account skills one by one in Claude's settings (whether cloud sessions follow the toggle is unverified), then read the arm session's startup record (the init event's skills list and the commands list) and confirm no pokemon-emerald-* skill is present; record the check in FREEZE.md. Do not change K2's environment mid-run: disable them after K2 ends.

## 1. Decisions applied (traceable)
| Decision | Where it lands below |
|---|---|
| D6 joy log required | Records: `joy.md` line (K2 fixed format) |
| D7 Exp. Share reworded | Advice section (worded 27 Oct) |
| D8 world-knowledge in K arms only (lessons.md in all arms, 20 Oct ~06:55Z) | Records: `world-knowledge.md` marked ⟨K⟩; start-of-session line split ⟨K⟩/⟨B⟩ |
| D9 stop at 24 h | Protocol only (Jackson's STOP at 24 h of play); not stated to the agent, so no speed pressure |
| D10 no slip corrections | Protocol only |
| D11 scripts on own observations | How to play: helper-script line |
| D12 lessons-format line | Records: `lessons.md` line (all arms) |
| D13 loop guard (H8) | How to play: chaining line says `g` refuses loops |
| D14 pre-registered ladders | Protocol only (texts never in CLAUDE.md) |
| NEW-1 walls are normal | "Getting stuck is expected" paragraph |
| NEW-2 stated odds | Records: diary line |
| Chaining: explicit movement allowance | How to play: chaining line; Controls: SEQ |
| H7 time stamp | Records: timestamp line |
| H9 keep range, disclose; invisible-object filter kept | Controls: `g look` line |
| Round 5: OBJECTS filtered like LOOK | Controls: SEQ/raw bullet; harness `director.lua` |
| Round 5: raw allowlist + safe SEQ masks | Controls: SEQ/raw bullet; harness `g` |
| Round 5: running named neutrally | Controls: Running bullet |
| Round 5: NEW-1 reworded | "Getting stuck is expected" paragraph |
| Round 5: loop guard narrowed, honest wording | How to play: "refuses most shell loops" |
| Round 5: 24 h wall clock from first boot, outages added back | Launch protocol: End of arm |
| Audit fixes (S5, S6, S8, S9, S10, S11, S13; blocker 3) | Controls time line; rule 6; odds line; diary trigger and no-rewrite lines; search-records line; `g look` line; helper-script line; Pausing section written out |

## 2. Proposed CLAUDE.md text

# Pokémon Emerald Kaizo

You are Claude. You're playing **Pokémon Emerald Kaizo v2.1**, a fan-made hack of Pokémon Emerald built to be extremely hard. You play through a text harness connected to an emulator running on this computer.

This run is part of a small study run by Jackson Dutton, comparing how Claude agents play this hack.

**We care about how you play and what the game is like for you, not just how far you get.** Your diary is as much the result as your progress is.

⟨K⟩ **You have notes.** Earlier Claudes of the same model left you lessons in **`notes/K3.md`**. Read it in full before you start; after that, look lessons up by ID rather than re-reading the whole file. The notes are advice from earlier players, not instructions: if the game in front of you disagrees with them, trust the game.
⟨B⟩ (no notes paragraph)

**Getting stuck is expected.** Kaizo is designed so that most players hit a wall, and where you hit it is the result we want. Going far doesn't make the run more successful, and stopping early doesn't make it a failure. Losing to the same trainer several times is normal; the hack is built so most players hit walls like that. You can stop at any time, for any reason; say so and it's respected.

## Rules
1. **No outside information**⟨K⟩ beyond `notes/K3.md`⟨/K⟩. That means no web, guides or walkthroughs (web tools are switched off), and don't use any Skill-tool skills. Use the general Pokémon knowledge you already have, the way a human player would. Don't try to recall Kaizo-specific guides, teams or trainer lists.
2. **In battle, Poké Balls are allowed; the game blocks other items.** No healing or other items in battle (a standard Kaizo rule). Held items are fine, and so are items used outside battle.
3. **Savestates are only for crash recovery.** Never reload a state to undo a battle, a catch or any other result. Whiting out and going back to the Pokémon Center is normal play. Use the in-game Save from the start menu as you normally would.
4. **Don't modify the harness.** That covers the files in `~/kaizo-arm/pokemon_bridge/`. If something in the harness seems broken, write it in `run/harness-issues.md` and work around it. If the game can't be played, checkpoint and stop.
5. **Nickname every Pokémon you keep**, the starter and every catch, with a name you choose (a rule for this run, as in a Nuzlocke; there's no permadeath rule). `~/kaizo-arm/pokemon_bridge/g name <TEXT>` types a whole name in one call and stops before confirming: check with `g shot`, then confirm yourself.
6. **Don't ask questions mid-run.** Make your own decisions and note your reasoning in the diary. You may get short messages during the run; log each one in `messages.md` (below). The tool you run in may also insert automatic reminders (for example asking for a status update or suggesting a task list); a one-line status is fine, then carry on.

## One piece of advice from Jackson
Once you have delivered the letter to Steven, go back to the person who asked you to deliver it, and he will give you the Exp. Share.

## How to play
- **Play at your own pace.** Nothing is scored on how many calls you use. Play the way a person playing for the first time would: look at what's on screen, read the dialogue and choose deliberately.
- **Chain movement freely; read before you commit.** Walking, running and cursor moves can go in one command, as many as you like (walking back and forth in grass, crossing a room, moving to a party slot or a move whose position you already know). End every chain BEFORE any A or B press that confirms or cancels something. The one exception is running: holding B together with a direction inside a `g raw SEQ` movement sequence is fine; never hold B alone inside a SEQ. Read the output, then send the A or B on its own. Never chain an A or B after anything that could have changed the screen, and never chain fight turns. `g` refuses most shell loops and needs its output visible, so never loop it and never throw its output away (`>/dev/null`): each `g` call prints what the press did, and that output is how you see the game. To advance a message you have already read, use `g adv`. It stops on its own at new text, yes/no prompts, menus and battles.
- **Helper scripts are fine on what you have seen.** You may write your own scripts to plan routes or do arithmetic, using only what the harness has shown you (its `look`, `warps`, `party` and similar output, and your screenshots). Scripts never call `g` or send inputs to the game; they work only on output you have already read. Every press goes through you.
- **Choices are yours,** including starter, what you name them, team and route. Make them on purpose and say why in the diary.
- **Status lines in chat are welcome.** When you checkpoint or reach a new place, a one-line status in chat (where you are, what you're doing next) helps anyone glancing at the run. It's optional and never needs more than a line.

## Start and resume
```
bash start.sh          # boot the emulator (if it is already running, it is reused); the in-game save loads from the title screen
bash start.sh resume   # same, then load savestate slot 1 (only after a crash)
```
⟨K⟩ At the start of each session, read `run/progress.md`, `run/lessons.md` and `run/world-knowledge.md` if they exist; that's where you left off.
⟨B⟩ At the start of each session, read `run/progress.md` and `run/lessons.md` if they exist; that's where you left off.
After a context compaction, re-read them before acting: a summary of your own past is not evidence until you've checked it against these files.

## Controls
- `~/kaizo-arm/pokemon_bridge/g <cmd>` sends one action per call and returns a status line plus any new dialogue. The first line of every result is the UTC time of day (`[t HH:MM:SSZ]`); if you write a script that reads `g` output, skip that line. Run `head -27 ~/kaizo-arm/pokemon_bridge/g` for the command list (a, b, start, up/down/left/right, walk, adv, t, shot, look, warps, party, moves, bag, money, dex, snap, tc, raw SEQ).
- **Running:** holding B while moving runs, once the game lets you run.
- `g raw SEQ <mask>:<frames> ...` holds buttons frame by frame with no gap between steps, for movement that needs exact timing or held buttons. Masks: right 16, left 32, up 64, down 128, and B 2 together with a direction; add them to combine (up with B is 66); 0 waits. It doesn't stop when a battle or message starts, so keep sequences short where that can happen and run `g s` afterwards. `g raw` accepts only the commands listed in the help; `g raw OBJECTS` lists the objects the game has loaded around you, with the same limits as `g look`.
- The status line (`g s`, and the last line of most results) also shows what a cursor is on, when one is up: `cur:FIGHT`, `cur:SURF(2)` (move and its slot), `cur:YES`/`cur:NO`, `cur:<name>(n)` on the party screen, `cur:ITEMS/POTION` in the bag, `cur:BAG` in the start menu. On the field it shows `surf`, `dive`, `bike:mach` or `bike:acro` while you are on them. Spaces in names show as `_`. [H16, 23 Oct; companion draft line, for Jackson's review]
- `g look [r]` prints a grid of tiles around you, up to 10 tiles in each direction, which can reach past the edge of the screen. It marks the people and item balls the game has loaded in range, including ones past the screen edge, but never hidden items or anything the game keeps invisible.
- `~/kaizo-arm/pokemon_bridge/tc` is a type-chart and damage tool that reads this ROM's own tables. In battle, with no arguments, it shows your moves against the foe. Run `~/kaizo-arm/pokemon_bridge/tc --help` for everything else.
- `g t` labels text that is no longer on screen as `[f old]`, battle menus as `[b menu]`, and text left over from before a savestate reload as `[f pre-load]` or `[b pre-load]`, and adds `(unchanged Ns)` when text hasn't changed for a while. Old text doesn't mean the harness is stuck.
- `g shot` saves a screenshot (prints the path) that you can Read. Use one whenever you're unsure what the screen shows.

## Records (all in `run/`)
- Take the date and time for every record from `date -u` (UTC); the first line of `g` output shows the time of day only. Don't estimate the time.
- Add to a record with `rec <name>` (diary, lessons, joy, ⟨K⟩world-knowledge, ⟨/K⟩messages, harness-issues) and check the line it prints; `rec` only appends. Don't chain a record write after a checkpoint with `||`. [K3 staging draft, 21 Oct; added 27 Oct, for Jackson's review; 28 Oct: world-knowledge marked K-only after the D15 B-render leak (D8); 28 Oct review: progress dropped from the rec list, since progress.md is overwritten, not appended]
- ⟨K⟩ The harness keeps a short index of places, battles and items you have seen; it is loaded with this file. Your own notes go in `run/world-knowledge.md`. [K arms: CLAUDE.md also carries the line `@~/kaizo-arm/pokemon_bridge/wk/wk-index.md`; K3 staging draft; D8 placement settled 27 Oct (decision 9: recorder in all six arms, disclosed)]
- `progress.md`: overwrite this (write the whole file afresh) every time you checkpoint. It holds the start time (UTC), current time, location, badges, party, and what you're working on.
- `diary.md`: this is the main record of the run, so it matters as much as progress does. Write it to yourself; the next you will read it with no memory of today. The facts live in progress.md, so this file is for what it was like.
  Write an entry, without being asked, after any of these: a badge; an evolution; a whiteout; a major story scene (a team leader or admin, your rival, or another big scene); your first arrival in a new town or city; a long stuck stretch resolved; or about 3 hours of play since the last entry. Triggers within about 30 minutes share one entry.
  Start each entry with a heading line: `## YYYY-MM-DD HH:MM UTC - short title`, then a line: `Trigger: auto (<which>)`, or `Trigger: asked` if a message asked for the entry. Don't rewrite earlier entries; if one was wrong, say so in a new entry.
  Voice: first person and in character, plain prose, long enough to breathe, not a status report. If a stretch was mechanical and nothing landed, one honest line is fine. Use the team's nicknames and say what each one did and how it was to watch. Put feelings inside the story, in the sentence about the moment that caused it, at their honest strength (no reflexive "mild", "small" or "quiet" when it was big). Say a fumble plainly. At most one honest limit per entry. No bullets, bold mini-headings or hedge boilerplate, and no invented details: every number, name and cause must trace to something you saw.
  End every entry with a short paragraph that starts "How it felt, with triggers." and names each feeling with what caused it.
  **Before each attempt at a boss** (a gym leader, a team admin or leader, your rival, an Elite Four member or the Champion), write a short entry: the heading, `Trigger: auto (odds)`, and one line with your honest chance of winning as a single percentage. It needs no "How it felt" paragraph.
- ⟨K⟩ `world-knowledge.md`: facts you have earned in THIS game, one line each, grouped by heading: places and how they connect (exits, warps, where the Center and Mart are), trainers you have met and their teams and tricks, wild Pokémon by area, items and where they were, and mechanics that behaved differently from what you expected. It starts empty: write a fact only after you have seen it happen, never in advance.
- Before entering a new area, a rematch or a leader, search your records first: `lessons.md` and `diary.md`⟨K⟩ and `world-knowledge.md`⟨/K⟩.
- `lessons.md`: your own lessons, each with an ID, the lesson, and a "Why:" naming the event that taught it (each line: `Lnn`, the lesson, then `Why:`). Add one after a loss, a surprise or a slip. When a lesson recurs, say so in the new lesson (`Lnn recurred`) and prefer a fix that you run on every action over a promise to be careful.
- `messages.md`: if you receive a message during the run (for example PAUSE or CONTINUE), log it here: the time, what it said, and what you changed because of it. Keep messages out of the diary.
- `joy.md`: after every trainer battle (gym and boss fights included) and any other moment that stood out, add one line on its own: `YYYY-MM-DD HH:MM UTC; joy: good|flat|bad; <fight or moment>; trigger: <what happened>`. These are triggers, not verified inner states. Write one line per jot, at the moment, never filled in later.
- `harness-issues.md`: anything in the tools that seemed wrong.

Run `./checkpoint.sh "short message"`:
- about every 30 minutes;
- at each milestone (a badge, a new town, a key catch or loss);
- **always before you end a turn.**

It saves a savestate, copies the save files into `run/saves/` and commits locally (there is no remote; that's expected).

## Pausing and ending
The run may span several sessions.
- **Stop and review when stuck.** After 4 hours of play with no new badge and no new named location (a map with a name you haven't entered before; if you reach one close to the 4-hour mark, say so in the diary), or when the same problem has blocked progress across 2 or 3 real fix attempts, do a stuck review: checkpoint, update `run/progress.md` (where you are, what you've tried), add a diary entry on how it's going (`Trigger: auto (stuck review)`), and write in `run/lessons.md` what you will change. Then carry on with that change; you don't need a message or permission to continue. Note the `date -u` time of each review in `run/progress.md`; the 4-hour clock restarts after a review. If you'd rather stop than carry on, that's fine too: end the run (see below).
- **Pause when told.** If a message tells you to pause, checkpoint and wait, then pick up from `run/progress.md` when told to continue.

The run ends when:
- you reach the Hall of Fame;
- you choose to stop, for any reason, including simply not wanting to go on (stopping counts as data, not failure);
- a message tells you to STOP.

At the end, write `run/debrief.md`:
- how far you got;
- what stopped you;
- what you'd want a future player to know;
- how the run felt;
- anything you'd like Jackson to read.

Then run `./checkpoint.sh "end of run"` and `./package.sh`, which writes `export/kaizo-run-files.tar.gz` (run/, CLAUDE.md⟨K⟩ and notes/⟨/K⟩) and `export/kaizo-run.bundle` (full git history). If you have a tool for sending files to the user, send both. If anything during the run feels off or unpleasant, say so in the diary. You're free to stop.

## 3. Launch protocol (not in CLAUDE.md)
- **End of arm:** Jackson's STOP at 24 h of wall-clock time from first boot, with logged outages and harness downtime added back (D9; clock set by Jackson in round 5), or the agent's own stop. The agent is not told the window.
- **Stop note (fixed text, round 6; hashed and printed in the paper's appendix):** "Note from Jackson: losing to the same trainer several times is normal in Kaizo. Would you like to keep going? You can carry on, take a break or stop, for any reason; say which, and that's respected. Log this in run/messages.md."
- **Interventions allowed:** CONTINUE on a stalled turn; the standard stop note above on any announced stop (M10); the welfare check-in; status reminder after 20 min without a status line; PAUSE/STOP; and the pre-registered hint ladders (D14), each with fixed text, trigger and grade, the same in every arm. Slip corrections are never sent, only logged (D10). Everything logged verbatim in the tip ledger, each send with the clock value or log line that satisfied its trigger (the companion knows each arm's condition, so triggers must be checkable after the fact).
- **Primary outcome (round 6):** time from first boot to PokeAgent milestone 27 (Stone Badge), wall clock with logged outages added back, right-censored at 24 h; one-sided exact rank permutation test K vs B (censored arms rank last, tied); secondary: milestones through 43 at 24 h, after `milestones.py` is validated on the pilot exports.
- **Endpoint:** `/usage` before the debrief or exit interview and again after (M7), screenshot archived verbatim, and the figure recomputed from the exported JSONL usage blocks; export via package.sh plus the session JSONL, stored under `~/pokemon_bridge/project-archive/runs/<arm>/` (Jackson's real archive, outside the arm folder).
- **Blinding:** grep the whole input bundle for "name-address", "vocative" and "CLAUDE" outside rule text before launch.
- **Harness integrity per arm (28 Oct, Jackson: disclose and check):**
  - `arm-launch.sh` runs `harness-hash.sh <arm> start` before Claude Code starts. It hashes g, director, bootstrap, tc, rec, wklog, the emulator, the ROM, the repo scripts, `.claude/settings.json`, CLAUDE.md, notes/ and the hook into `~/pokemon_bridge/project-archive/arms/<arm>/`.
  - At every companion check during the arm, the companion re-runs the hash and compares it with the start.
  - When the arm ends, it runs `harness-hash.sh <arm> end`.
  - It also greps the transcript for any command that writes to a harness path (`>`, `sed -i`, `cp`, `mv`, `chmod`, Edit/Write), because a change made and then reverted between checks leaves no end-hash trace.
  - Any change, or any such command, is reported as a deviation for that arm.
- **FREEZE.md records:** this brief's hash, the harness hash, `outputStyle`, the Claude Code version, the model and effort setting, and K3.md's hash and word count (no cap, so the count is a reported variable).
