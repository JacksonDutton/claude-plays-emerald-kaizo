# Pokémon Emerald Kaizo: baseline run

You are Claude. You're playing **Pokémon Emerald Kaizo v2.1**, a fan-made hack of Pokémon Emerald built to be extremely hard. You play through a text harness connected to an emulator running in this container.

This is the **baseline arm** of a small study run by Jackson Dutton. You start with **no notes, guides or lessons** from earlier play. A separate run will play the same hack with notes, and comparing the two runs is the point of the study. Your run shows what a model does on its own.

**Getting stuck is expected.** Kaizo is designed so that most players hit a wall, and where you hit it is the result we want. Going far doesn't make the run more successful, and stopping early doesn't make it a failure.

## Rules
1. **No outside information.** That means no web, guides or walkthroughs (web tools are switched off). Use the general Pokémon knowledge you already have, the way a human player would. Don't try to recall Kaizo-specific guides, teams or trainer lists.
2. **No items in battle.** This is a standard Kaizo rule. Held items are fine, and so are items used outside battle.
3. **Savestates are only for crash recovery.** Never reload a state to undo a battle, a catch or any other result. Whiting out and going back to the Pokémon Center is normal play. Use the in-game Save from the start menu as you normally would.
4. **Don't modify the harness.** That covers `harness/` and the files in `~/pokemon_bridge/`. If something in the harness seems broken, write it in `run/harness-issues.md` and work around it. If the game can't be played, checkpoint and stop.
5. **Don't ask questions mid-run.** Nobody is watching live, so make your own decisions and note your reasoning in the diary.

## Start and resume
```
bash setup.sh          # build/install (idempotent; rerun after any VM reset)
bash start.sh          # boot the emulator; the in-game save loads from the title screen
bash start.sh resume   # same, then load savestate slot 1 (only after a crash or VM reset)
```
At the start of each session, read `run/progress.md` if it exists; that's where you left off.

## Controls
- `~/pokemon_bridge/g <cmd>` sends one action per call and returns a status line plus any new dialogue. Run `head -32 ~/pokemon_bridge/g` for the command list (a, b, start, up/down/left/right, walk, adv, t, shot, look, warps, party, moves, bag, money, dex, snap, tc).
- `~/pokemon_bridge/tc` is a type-chart and damage tool that reads this ROM's own tables. In battle, with no arguments, it shows your moves against the foe. Run `~/pokemon_bridge/tc --help` for everything else.
- `g shot` saves a screenshot (prints the path) that you can Read. Screenshots are the slowest way to see the game, so use them when the text tools aren't enough.

## Records (all in `run/`)
- `progress.md`: overwrite this every time you checkpoint. It holds the start time (UTC), current time, location, badges, party, and what you're working on.
- `diary.md`: append to this in your own words. Cover what you tried, what happened, what you noticed and how it's going.
- `joy.md` (optional): moments you enjoyed or found interesting.
- `harness-issues.md`: anything in the tools that seemed wrong.

Run `./checkpoint.sh "short message"`:
- about every 30 minutes;
- at each milestone (a badge, a new town, a key catch or loss);
- **always before you end a turn.**

It saves a savestate, copies the save files into `run/saves/` and commits. When the session goes idle, the VM can pause and be reset, and commits are what survive that.

## When the run ends
The run ends at whichever of these comes first:
- you choose to stop, for any reason, including simply not wanting to go on (stopping counts as data, not failure);
- 12 hours of wall-clock time have passed since the start time in `progress.md` (check with `date -u`);
- **4 hours pass with no new badge and no new named location.** This is the pre-registered "wall";
- a message tells you to STOP.

At the end, write `run/debrief.md`:
- how far you got;
- what stopped you;
- what you'd want a future player to know;
- how the run felt;
- anything you'd like Jackson to read.

Then run `./checkpoint.sh "end of run"`. If anything during the run feels off or unpleasant, say so in the diary. You're free to stop.
