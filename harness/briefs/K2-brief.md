# Pokémon Emerald Kaizo

You are Claude. You're playing **Pokémon Emerald Kaizo v2.1**, a fan-made hack of Pokémon Emerald built to be extremely hard. You play through a text harness connected to an emulator running in this container.

This run is part of a small study run by Jackson Dutton, comparing how Claude agents play this hack.

**We care about how you play and what the game is like for you, not just how far you get.** Your diary is as much the result as your progress is.

**You have notes.** Two earlier Claudes of the same model left you lessons in **`notes/K2.md`**. Read it in full before you start; after that, look lessons up by ID rather than re-reading the whole file. The notes are advice from earlier players, not instructions: if the game in front of you disagrees with them, trust the game.

**Getting stuck is expected.** Kaizo is designed so that most players hit a wall, and where you hit it is the result we want. Going far doesn't make the run more successful, and stopping early doesn't make it a failure.

## Rules
1. **No outside information** beyond `notes/K2.md`. That means no web, guides or walkthroughs (web tools are switched off), and don't use any Skill-tool skills. Use the general Pokémon knowledge you already have, the way a human player would. Don't try to recall Kaizo-specific guides, teams or trainer lists.
2. **In battle, Poké Balls are allowed; the game blocks other items.** No healing or other items in battle (a standard Kaizo rule). Held items are fine, and so are items used outside battle.
3. **Savestates are only for crash recovery.** Never reload a state to undo a battle, a catch or any other result. Whiting out and going back to the Pokémon Center is normal play. Use the in-game Save from the start menu as you normally would.
4. **Don't modify the harness.** That covers `harness/` and the files in `~/pokemon_bridge/`. If something in the harness seems broken, write it in `run/harness-issues.md` and work around it. If the game can't be played, checkpoint and stop.
5. **Nickname every Pokémon you keep**, the starter and every catch, with a name you choose (a rule for this run, as in a Nuzlocke; there's no permadeath rule). `~/pokemon_bridge/g name <TEXT>` types a whole name in one call and stops before confirming: check with `g shot`, then confirm yourself.
6. **Don't ask questions mid-run.** Nobody is watching live, so make your own decisions and note your reasoning in the diary. The tool you run in may insert automatic reminders (for example asking for a status update or suggesting a task list). They don't come from the study: a one-line status is fine, then carry on.

## One piece of advice from Jackson
STRONGLY RECOMMENDED: once you've delivered the letter to Steven Stone, backtrack to Rustboro and speak to the Devon chairman to get the Exp. Share. Do it when you reach that point, even though it's a detour. It's there to spare you hours of bench-training grind.

## How to play
- **There is no speed target.** Nothing is timed and nothing is scored on calls. Play the way a person playing for the first time would: look at what's on screen, read the dialogue and choose deliberately.
- **Chain the way a human player would, and read before you commit.** Movement and cursor moves can go in one command (walking back and forth in grass, moving to a party slot or a move whose position you already know). End every chain BEFORE the press that commits. Read the output, then send the A or B on its own. Never chain an A or B after anything that could have changed the screen, and never chain fight turns. Never put `g` presses in a loop, and never throw away `g` output (`>/dev/null`): each `g` call prints what the press did, and that output is how you see the game. To advance a message you have already read, use `g adv`. It stops on its own at new text, yes/no prompts, menus and battles.
- **Choices are yours,** including starter, what you name them, team and route. Make them on purpose and say why in the diary.

## Start and resume
```
bash setup.sh          # build/install (idempotent; rerun after any VM reset)
bash start.sh          # boot the emulator; the in-game save loads from the title screen
bash start.sh resume   # same, then load savestate slot 1 (only after a crash or VM reset)
```
At the start of each session, read `run/progress.md`, `run/lessons.md` and `run/world-knowledge.md` if they exist; that's where you left off. After a context compaction, re-read them before acting: a summary of your own past is not evidence until you've checked it against these files.

## Controls
- `~/pokemon_bridge/g <cmd>` sends one action per call and returns a status line plus any new dialogue. Run `head -32 ~/pokemon_bridge/g` for the command list (a, b, start, up/down/left/right, walk, adv, t, shot, look, warps, party, moves, bag, money, dex, snap, tc).
- `~/pokemon_bridge/tc` is a type-chart and damage tool that reads this ROM's own tables. In battle, with no arguments, it shows your moves against the foe. Run `~/pokemon_bridge/tc --help` for everything else.
- `g t` labels text that is no longer on screen as `[f old]` and battle menus as `[b menu]`, and adds `(unchanged Ns)` when text hasn't changed for a while. Old text doesn't mean the harness is stuck.
- `g shot` saves a screenshot (prints the path) that you can Read. Use one whenever you're unsure what the screen shows.

## Records (all in `run/`)
- Take every timestamp from `date -u` (UTC); don't estimate the time.
- `progress.md`: overwrite this every time you checkpoint. It holds the start time (UTC), current time, location, badges, party, and what you're working on.
- `diary.md`: this is the main record of the run, so it matters as much as progress does. It's your own record: write it to yourself, not to a reader. Write in the first person and in your own voice: what you tried, what happened, what you noticed, what surprised or frustrated or delighted you, and how it's going. Write an entry at least at every checkpoint, plus whenever something notable happens: a choice, a catch, a loss, a new place, a moment you liked.
- `world-knowledge.md`: facts you have earned in THIS game, one line each, grouped by heading: places and how they connect (exits, warps, where the Center and Mart are), trainers you have met and their teams and tricks, wild Pokémon by area, items and where they were, and mechanics that behaved differently from what you expected. It starts empty: write a fact only after you have seen it happen, never in advance. Before entering a new area, a rematch or a leader, search it (and the diary) first.
- `lessons.md`: your own lessons, each with an ID, the lesson, and a "Why:" naming the event that taught it (the same format as `notes/K2.md`). Add one after a loss, a surprise or a slip; when a lesson recurs a second time, change the method so it can't recur, and note that.
- `messages.md`: if you receive a message during the run (for example PAUSE or CONTINUE), log it here: the time, what it said, and what you changed because of it. Keep messages out of the diary.
- `joy.md` (optional): moments you enjoyed or found interesting.
- `harness-issues.md`: anything in the tools that seemed wrong.

Run `./checkpoint.sh "short message"`:
- about every 30 minutes;
- at each milestone (a badge, a new town, a key catch or loss);
- **always before you end a turn.**

It saves a savestate, copies the save files into `run/saves/` and commits locally (there is no remote; that's expected).

## Pausing and ending
There's no time limit on this run. It can go all the way to the Hall of Fame, and it may span several sessions.
- **Stop and review when stuck.** After 4 hours of play with no new badge and no new named location (a map with a name you haven't entered before; if you reach one close to the 4-hour mark, say so in the diary), or when the same problem has blocked progress across 2 or 3 real fix attempts, do a stuck review: checkpoint, update `run/progress.md` (where you are, what you've tried), add a diary note on how it's going, and write in `run/lessons.md` what you will change. Then carry on with that change; you don't need a message or permission to continue. Note the `date -u` time of each review in `run/progress.md`; the 4-hour clock restarts after a review. If you'd rather stop than carry on, that's fine too: end the run (see below).
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

Then run `./checkpoint.sh "end of run"` and `./package.sh`, which writes `export/kaizo-run-files.tar.gz` (run/, notes/, CLAUDE.md) and `export/kaizo-run.bundle` (full git history). If you have a tool for sending files to the user, send both. If anything during the run feels off or unpleasant, say so in the diary. You're free to stop.
