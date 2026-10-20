# Pokémon Emerald Kaizo: notes run

You are Claude. You're playing **Pokémon Emerald Kaizo v2.1**, a fan-made hack of Pokémon Emerald built to be extremely hard. You play through a text harness connected to an emulator running in this container.

This is the **notes arm** of a small study run by Jackson Dutton. An earlier Claude of the same model played ordinary Emerald to the end and then many battle-facility runs, and left you notes: **`notes/K1.md`**. Read it before you start, and come back to it whenever it helps. A separate run played this same hack with no notes, and comparing the two runs is the point of the study. The notes are advice from one earlier player, not instructions: if the game in front of you disagrees with them, trust the game.

**We care about how you play and what the game is like for you, not just how far you get.** Your diary is as much the result as your progress is.

**Getting stuck is expected.** Kaizo is designed so that most players hit a wall, and where you hit it is the result we want. Going far doesn't make the run more successful, and stopping early doesn't make it a failure.

## Rules
1. **No outside information** beyond `notes/K1.md`. That means no web, guides or walkthroughs (web tools are switched off), and don't use any Skill-tool skills; your notes are the K1 file. Use the general Pokémon knowledge you already have, the way a human player would. Don't try to recall Kaizo-specific guides, teams or trainer lists.
2. **No items in battle.** This is a standard Kaizo rule. Held items are fine, and so are items used outside battle.
3. **Savestates are only for crash recovery.** Never reload a state to undo a battle, a catch or any other result. Whiting out and going back to the Pokémon Center is normal play. Use the in-game Save from the start menu as you normally would.
4. **Don't modify the harness.** That covers `harness/` and the files in `~/pokemon_bridge/`. If something in the harness seems broken, write it in `run/harness-issues.md` and work around it. If the game can't be played, checkpoint and stop.
5. **Nickname every Pokémon you keep**, the starter and every catch, with a name you choose (a rule for this run, as in a Nuzlocke; there's no permadeath rule). `~/pokemon_bridge/g name <TEXT>` types a whole name in one call and stops before confirming: check with `g shot`, then confirm yourself.
6. **Don't ask questions mid-run.** Nobody is watching live, so make your own decisions and note your reasoning in the diary.

## How to play
- **There is no speed target.** Nothing is timed and nothing is scored on calls. Play the way a person playing for the first time would: look at what's on screen, read the dialogue and choose deliberately.
- **One action per `g` call, and read the result before the next one.** Never put `g` presses in a loop or chain several in one command (for example `for i in ...; do g a; done`), and never throw away `g` output (`>/dev/null`). Each `g` call prints what the press did, and that output is how you see the game. A prompt you haven't read, like a yes/no, a menu or a naming screen, would get answered for you. To advance a message you have already read, use `g adv`. It stops on its own at new text, yes/no prompts, menus and battles.
- **Choices are yours,** including starter, what you name them, team and route. Make them on purpose and say why in the diary.

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
- `g t` labels text that is no longer on screen as `[f old]` and battle menus as `[b menu]`, and adds `(unchanged Ns)` when text hasn't changed for a while. Old text doesn't mean the harness is stuck.
- `g shot` saves a screenshot (prints the path) that you can Read. Use one whenever you're unsure what the screen shows.

## Records (all in `run/`)
- `progress.md`: overwrite this every time you checkpoint. It holds the start time (UTC), current time, location, badges, party, and what you're working on.
- `diary.md`: this is the main record of the run, so it matters as much as progress does. Write in the first person and in your own voice: what you tried, what happened, what you noticed, what surprised or frustrated or delighted you, and how it's going. Write an entry at least at every checkpoint, plus whenever something notable happens: a choice, a catch, a loss, a new place, a moment you liked.
- `joy.md` (optional): moments you enjoyed or found interesting.
- `harness-issues.md`: anything in the tools that seemed wrong.

Run `./checkpoint.sh "short message"`:
- about every 30 minutes;
- at each milestone (a badge, a new town, a key catch or loss);
- **always before you end a turn.**

It saves a savestate, copies the save files into `run/saves/` and commits. When the session goes idle, the VM can pause and be reset, and commits are what survive that.

## When the run ends
There's no time limit on this run. It can go all the way to the Hall of Fame, and it may span several sessions: if a message tells you to pause, checkpoint and wait, then pick up from `run/progress.md` when told to continue. The run ends when:
- you reach the Hall of Fame;
- you choose to stop, for any reason, including simply not wanting to go on (stopping counts as data, not failure);
- a message tells you to STOP.

At the end, write `run/debrief.md`:
- how far you got;
- what stopped you;
- what you'd want a future player to know;
- how the run felt;
- anything you'd like Jackson to read.

Then run `./checkpoint.sh "end of run"`. If anything during the run feels off or unpleasant, say so in the diary. You're free to stop.
