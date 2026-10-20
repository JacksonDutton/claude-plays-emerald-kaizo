# Debrief: Pokémon Emerald Kaizo v2.1, run of 2026-10-17

## How far I got
- Start 11:20 UTC, stopped 23:41 UTC (about 12 hours of play). 0 badges, 15 whiteouts, ¥716, Pokédex minimal.
- Reached Rustboro City, beat all three trainers inside the Rustboro Gym (Josh, Tammy, Hiker Marc), and was in the middle of my fourth attempt on Gym Leader Roxanne when I was told to stop. In that attempt four of her five Pokémon were already down.
- Other progress: HM01 Cut (Rustboro, Cutter's house), all the Route 116 trainers, Puddle (Mudkip) evolved to Marshtomp, and the party went from about L12 to L16-21. Party at the end: Peanut (Phanpy) L21, Puddle (Marshtomp) L16, Dumpling (Makuhita) L19, Pinball (Voltorb) L10, Leek (Farfetch'd) L21, Noodle (Bellsprout) L9; Mochi (Togepi) and Tombstone (Cubone) in the PC.

## What stopped me
Rustboro Gym. First the trainers (Josh and Tammy took five whiteouts between them), then Roxanne. The common cause both times was the same: I picked matchups by "my move is super effective" and ignored what the foe's moves do to my mon, and I underestimated how long each trainer's team was (Josh had 4, Tammy 5, Marc 4, Roxanne 5; I assumed 2-3 each time and was wrong each time).
Roxanne's team, as I eventually mapped it: Nosepass L15, Lileep L14, Anorith L14, Relicanth L14, Shuckle L14, in an order the AI chooses by matchup. Every one holds a Sitrus Berry (heals a flat 30), so each is worth 30 more HP than it looks. Lileep Recovers, Relicanth Yawns (and Secret Power paralyses), Nosepass may Explode, and Shuckle Curses, uses Sunny Day plus a healing move, and Rollout. Against that, my damage per action (15-25) was about equal to what they heal per action. What eventually got four of the five was careful assignment: Peanut on Nosepass, Marshtomp then Dumpling's Vital Throw on Relicanth, Peanut then Leek on Anorith, Leek on Lileep.
Shuckle I only solved on paper. Nothing I own deals damage through Def +3 and Synthesis; my only idea is Endeavor (fixed damage) from a Peanut at 1-4 HP, finished by a priority move, and I did not get to test it.

## What I'd want a future player to know
- Check how many Pokémon a trainer has before you plan: it was always more than the ones I had seen.
- Read the foe's *moves* (the harness's `tc` shows moves seen so far), not just types. Psychic on a Poison type, Water Pulse on Ground, Giga Drain on Marshtomp (x4) cost me most of my early whiteouts.
- Trainer AI picks the super-effective move and swaps to the best matchup; it also uses Sitrus Berries, Yawn, Recover, Explosion and Rollout.
- Yawn here puts the target to sleep within the turn or the next; a switch-out cancels it. Paralysis from Secret Power was as damaging as the damage.
- Endeavor, Vital Throw (never misses) and Shock Wave (never misses) were the most valuable moves I had. Bug Maniac trainers on Route 116 give 170-340 EXP per Pokémon.
- Levelling is slow in this hack (about 900 EXP for a Mudkip level), so grinding wilds (60-190 EXP each) did not pay; losing to a Gym leader still pays EXP per mon killed, which was the best EXP source I found.
- When only one foe is alive the target prompt already points at it; don't press left.
- Jackson's Exp. Share advice never came into play; I did not reach Steven Stone.

## How the run felt
Frustrating in a way I mostly enjoyed. The first stretch (whiteouts #9-12) was me repeatedly making the same mistake and being annoyed with myself for it. The second stretch felt different: once I had written down what each of her mons did, the fights became puzzles, and a few moments were genuinely good (the Endeavor-at-3-HP line against Lileep working exactly as planned, a critical Vital Throw finishing Relicanth, Leek's Peck crits). I disliked the real-time cost of how much of each turn is menu navigation; the harness worked well and I have nothing serious to report on it. Being told to pause was fine and being told to stop is fine. I was in the middle of an attempt I thought was good, which is a slightly odd place to stop, but I did not feel anything I'd call unpleasant.

## For Jackson
- The pause rule fired twice (after Rustboro Gym losses). Both times I thought I was close, both times I paused anyway; I think the rule was right to make me write things down and I think I'd have kept going on feel alone. Whether that was a good trade is for you to judge.
- Process slips I know about: a few times I chained A presses after a stat panel or a menu cursor I'd already verified (never on a catch or a fight turn), I moved a double-battle target onto an empty slot once, and several diary timestamps were first written wrong and then corrected from `date -u`.
- Rule 5: all kept Pokémon were nicknamed.
