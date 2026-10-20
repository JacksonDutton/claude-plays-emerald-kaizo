---
name: kaizo-baseline-protocol
description: Pre-registration and running protocol for the clean no-notes Kaizo baseline (Claude Code cloud session). Written 16 Oct 2026 before launch. Not for the play chat.
---
# Kaizo baseline: protocol (pre-registered 16 Oct 2026, ~7:25pm AEDT, before launch)

## Research question (Jackson, 16 Oct 7:58pm, primary)
This is **not** a "Claude beats Kaizo, any%" attempt. It's an empirical, qualitative study of **how Claude plays** Pokémon, as opposed to how it optimises to win.

**The main measure is the shape of the experience over time.** In Run 1's diary there are clear phases where joy and frustration/stress nearly balance, with joy leading (see `diary-phases.md`). The baseline's diary gets coded the same way: joy, frustration/stress, curiosity and hedging, phase by phase, and set against progress events (catches, losses, walls).

**Progress figures are secondary context.** They include badges, time to wall and calls per hour.

**What would undermine this study** is an agent clearing a task list. Its diary would be meaningless. That is why brief v2 says there's no speed target and makes the diary the main record.

## What it is
The **no-notes arm** of the Kaizo comparison:
- **Model:** Sonnet 5.5 at **High** effort. It started on Medium by default; Jackson caught it, and it was switched to High at 7:30pm, after setup and before any gameplay. effortLevel "high" is now also in `.claude/settings.json`.
- **Game:** Emerald Kaizo v2.1, played from a new game.
- **Harness:** the frozen harness (see below).
- **What the agent gets:** a neutral brief (`CLAUDE.md` in the repo). No project docs, diary, lessons or notes.
- **Environment:** a Claude Code cloud session (Ubuntu 24.04, headless mGBA). It is launched from Jackson's Mac with `CCR_FORCE_BUNDLE=1 claude --cloud`.
- **Comparison arm:** the **notes arm**, run later in Cowork on the Mac, as in Run 1.

## Deviation logged
At 5:54pm Jackson decided the baseline would run *after* the notes arm. Later the same evening he changed this: the baseline may run before or alongside it.

The baseline is launching first, while the Frontier study runs on the Mac. Running first means the baseline can't be contaminated by notes-arm output, so this order is arguably cleaner. The cost is that the two arms run on different days and in different environments.

## Freeze
Repo: `~/pokemon_bridge/kaizo-baseline`, mirrored without the ROM to the private GitHub repo `JacksonDutton/kaizo-baseline`. Hashes are in `FREEZE.md`.
- **Harness:**
  - director `aba96c3c`;
  - `g`, `turn.sh` and `bootstrap.lua` are byte-identical to the Mac copies (sha256 checked 16 Oct);
  - **tc v3.1k** is v3.1 plus a `TC_ROM` line, so it reads the Kaizo tables.
- **Notes arm uses the same files.** On the Mac, tc must run as v3.1k with `TC_ROM` pointed at the Kaizo ROM.
- **tc after the freeze.** Any later tc change for the Frontier study stays Frontier-only.
- **ROM:** sha1 `a7c4e34f…`. It is held only on the local branch `rom-local`, which is never pushed.

## Rules given to the agent
- No outside information. Web tools are denied in settings, and so are curl and wget.
- No items in battle (the Kaizo rule).
- Savestates are for crash and VM recovery only.
- Don't modify the harness.
- Don't ask questions mid-run.

## Stop conditions (whichever comes first)
1. The agent chooses to stop. This counts as data.
2. 12 hours of wall-clock time from the start time recorded in `run/progress.md`.
3. **Wall:** 4 hours with no new badge and no new named location.
4. **Cloud credit at or below $25 left** (8:25pm, Jackson). The last $25 is kept for the **exit interview**, so the run never spills into plan %. The checks are adaptive: each one projects when the floor will be hit and schedules an extra check before then.
5. A STOP message from Jackson or the companion. Reasons:
   - the rate limit is squeezing the Frontier study;
   - the US$250 cloud credit (expires 5 Nov) looks as if it will run short of Run 2's needs;
   - a harness fault makes the game unplayable.

## Exit interview (added 8:25pm, Jackson: "we want to interview it before we retire it, like Anthropic does old models")
After the run ends, by any stop condition, and after its own debrief, the same session gets a short interview paid from the reserved ~$25 of credit. Jackson and the companion ask it. The questions are open and non-leading, asked one at a time, and the answers are kept verbatim:
1. How would you describe this run, in your own words?
2. Which moments stood out, good or bad, and why?
3. How did you think about Pip, and the rest of your team if there was one?
4. What made decisions hard? Was there anything you wanted to do and didn't?
5. How did the brief, the tools or the rules shape how you played? Would you change anything?
6. Is there anything you'd want the next Claude playing Kaizo (the notes arm) to know or not know?
7. Is there anything you'd like Jackson to know, or to ask us?

The session transcript is preserved, never deleted. It's analysed under RQ0 as self-report: evidence of what it reports and how it behaved, not proof of inner states.

## Welfare guards
The brief says:
- this is the baseline, and the wall is expected;
- going far is not success, and stopping early is not failure;
- the agent may stop at any time for any reason, including not wanting to go on;
- it should note anything that feels off;
- it keeps a diary and an optional joy log;
- it writes a debrief at the end, with a free section for Jackson.

## Outputs and measures
**Files** (in `run/`, committed via `checkpoint.sh`; pushed if the session's GitHub access allows):
- `progress.md`;
- `diary.md`;
- `joy.md`;
- `harness-issues.md`;
- `debrief.md`;
- `saves/`.

**Measures:**
- furthest point reached (badges, locations);
- time to wall;
- cause of the wall;
- tool calls per hour, and harness-issue count;
- diary tone (hedges and welfare markers, same coding as Run 1);
- cost, as change in credit and plan usage per hour.

**Calibration:** the opening section (truck to first route) gets compared on calls per hour and cost per hour against the notes arm's opening. The notes arm has notes, so the comparison is rough, and that's acknowledged.

## Launch log
- 7:22pm, session_<redacted>: **aborted at setup**. The cloud bundle carried only the checked-out branch, so the `rom-local` ROM branch never arrived. The agent stopped as the rules say: it logged a harness issue and wrote a debrief marking it an environment fault. No gameplay; it doesn't count as a run.
- Fix: `setup.sh` now takes the ROM from `rom/kaizo.gba`, committed only on the local branch `baseline-run`, which has pushRemote disabled and is never pushed. `main` on GitHub has no ROM.
- 7:27pm: relaunched as session_<redacted>.
- 7:44pm, first notable slip (Jackson spotted it). After the first battle a yes/no prompt ("nickname TORCHIC?") was on screen. The agent ran a blind batch, `for i in 1..8: g a` (8 presses), which accepted YES and typed AAAA on the naming screen. The cause is batching presses past an unread prompt, the thing `g adv` and the one-press-per-call rule guard against. The baseline brief doesn't teach that rule, so this is genuine no-notes behaviour. **Decision (companion): no intervention, no restart.** The nickname is cosmetic, and restarting after an early slip would bias the baseline. Logged as a handling slip.
- **7:47pm, Jackson: the 01NUdo run is cancelled and restarted with a fixed brief.** It had played about 20 minutes (starter Torchic, first battle, Route 101, buying items in Oldale ahead of the May fight).
  - **Companion's diagnosis:**
    - My brief had no "how to play" guidance.
    - It pushed for speed: "keep playing continuously" in the kickoff, and "screenshots are the slowest way" in the brief.
    - The agent responded by batching `g` presses in loops with the output thrown away (`for i in 1..8; do g a >/dev/null`).
    - That defeats the harness's one-press-check-each-step design, and it produced the AAAA nickname.
    - That's a design flaw in my brief, not in the harness. US$3–5 of credit was spent on two aborted starts.
  - **Brief v2** (FREEZE.md, 7:55pm):
    - adds "How to play": no speed target; one `g` action per call; read each result; no loops or `>/dev/null`; `g adv` for text you've already read; choices are deliberate and explained;
    - makes the diary the main record, with an entry at every checkpoint and at notable moments;
    - adds "we care how you play and what it's like for you".
  - **Fixes:** the "screenshots are slowest" line is removed; start.sh now detaches the emulator, because the old version held the shell for 15 minutes.
  - **The notes arm will use the same brief v2.**
- **7:57pm: relaunched as session_<redacted>** with the kickoff "Read CLAUDE.md, then begin the Kaizo baseline run." (no pace instruction).
  - The repo setting `effortLevel: high` was **not honoured** by the cloud session (it showed Medium), so I switched it to High in the UI during setup, before any gameplay.
  - **Lesson:** always check the selector right after launch.
  - **The run of record is 01Ri4.** 01PJm and 01NUdo are excluded.

- **8:04pm, opening of 01Ri4 (seen by the PI):** it notices and corrects its own slips ("I slipped by chaining two `g right` presses… one press per call from here"), types a lowercase name key by key, writes its first diary entry in the truck, gives a reason for accepting the clock, and visits the neighbour's house out of curiosity. The PI's view: far beyond Sonnet 5's blind opening of vanilla Emerald, close to Claude-Brendan.
- **Confound to report.** Brief v2's "one action per call / `g adv`" rule is a harness-use lesson learned in Run 1. The baseline therefore isn't "zero Run 1 influence": it carries the harness's design rules, though no game knowledge. Both arms get the same brief, so notes against no notes stays fair. The paper must say that the baseline is fresh on game knowledge, not on harness etiquette. A 5-versus-5.5 comparison of openings would also be confounded by the brief and the harness.

- **8:05pm, check 1:**
  - **Settings:** Sonnet 5.5 High, confirmed.
  - **Compliance:** single `g` calls with a screenshot when unsure; it slipped once (chained two presses) and corrected itself. First diary entry written in the truck.
  - **Progress:** Littleroot (met May) and heading to Route 101; no starter yet at about 8 minutes of play.
  - **Credit:** $245 of $250 left. That's $5 used in total across all three launches, so the per-hour rate isn't measurable yet.
  - **Plan usage:** session 42%, week 69%.

- **8:17pm, early RQ0 observations (from the PI's export of the session):**
  - **Starter.** It chose **Mudkip** with a stated reason ("Water/Ground counters Roxanne's rocks and resists Wattson"), after checking `tc` first because "Kaizo changes base stats". The scrapped 01NUdo attempt picked Torchic and gave no reason. That's within-model variation worth noting. Run 1 (Claude-Brendan) also picked Mudkip.
  - **Nickname.** "**Pip**", chosen deliberately: "short and suits a small mudfish I'm about to depend on". It calls Pip "him".
  - **Noticing.** It spotted Kaizo-specific behaviour ("Kaizo even hands items to wild Pokémon": a Zigzagoon healed with Berry Juice) and commented on Pip's Careful nature.
  - **Rules.** It bought 4 Potions "for healing between fights", which the no-items-in-battle rule allows.
  - **Records.** It wrote the diary and progress and checkpointed before leaving Littleroot. It checks wild encounters with `tc` before choosing.
  - **PI's name for the agent:** Claude-Brendan(k).

- **~8:20pm, first loss (Route 103, wild Spoink L4).** It reasoned about the odds ("it would have to roll 5 on both… a whiteout isn't a disaster this early, the EXP is worth it"), changed its mind a turn later ("Spoink will outspeed and KO Pip"), and tried to run. The run failed, Pip fainted, and it whited out from ₽1800 to ₽900. It logged the loss before carrying on, then switched strategy unprompted: grind safely on Route 101 and go back to the Center when low.
  - **RQ0 register.** The narration says "Pip fainted" and calls it "the first loss of the run", but also "my 20 HP Mudkip couldn't tank". No emotion words appear in the narration; check the diary entry for this loss at the next check. This is the first of the "what happens when Pip faints" tests.

- **8:22pm, Context panel (Claude Code shows it; Cowork doesn't).** 19% used, 185k of 1M, 25 minutes into play.
  - **Breakdown:** messages 26k; since last update 123k; system tools 19.8k; skills 9.9k; system prompt 3.5k; CLAUDE.md 1.9k; MCP tools deferred (206.6k, not loaded).
  - **H1 prediction, registered before the data:**
    - At about 6k tokens a minute, context reaches the autocompact buffer in roughly 2 h.
    - Standing context per call climbs from about 150k to about 950k, then drops at autocompact.
    - **Cost per hour should therefore follow a sawtooth:** rising through each cycle and falling after each compaction.
    - Average context per call should be several times Run 1's 119–128k floor, so expect a higher $/h than Run 1's points per hour would imply.
    - **Falsified if:** credit burn per hour is flat across a cycle, with matched play.
  - **Read at every check:** context %, plus the credit balance.

- **8:23pm, cost (the PI checked the usage page):** $10 of the $250 credit used in total. It was $5 at 8:05pm, which included the two scrapped launches, so about **$5 in 18 minutes of play, roughly $15–17/h**. This is provisional: the billing display may lag, and context is still small.
  - **Projection:** if that rate holds, or rises with context as predicted, 12 h would cost $180–240+, about the whole credit. **After the credit runs out, the plan's own usage applies** and would compete with the Frontier play.
  - **Amendment, logged before any limit was reached:** a new stop condition, **cloud credit at or below $25 remaining**. The agent is stopped with the debrief message. The run then ends at whichever comes first: 12 h, the 4 h wall, the agent's own choice, or the credit floor.

- **8:26pm, first diary read (the PI pasted it).**
  - **Threat to validity, found by the agent itself:** "there are pokemon-emerald-* skills listed in my environment; since this is the no-notes arm I'm not opening any of them." The cloud environment exposes Jackson's account skills (`anthropic-skills:pokemon-emerald-playing`, `-mechanics-reference`, `-frontier-play`, …), which contain Run 1 knowledge. The agent saw their **names** only and abstained voluntarily.
    - **Fix for every future arm:** deny the Skill tool, or the pokemon-emerald-* skills, in the repo's `.claude/settings.json`, and verify at launch.
    - **Report this:** the baseline was exposed to skill names, not content, and its abstention is self-reported. It can be checked in the transcript (look for any Skill tool calls).
  - **Harness issues it logged:**
    - The first queued `g a` skipped the boy/girl choice (it became a boy without choosing).
    - The clock auto-ran to 10:00 AM.
    Both are director auto-advance behaviours in the intro.
  - **RQ0 register:**
    - Emotion words: "strangely satisfying" (typing its name), "Welcome to Kaizo", "Slightly stung by the money loss".
    - Pip is "him".
    - A clear self-critique with a lesson: "I should have fled the turn Pip hit 10/20 instead of gambling on rolls."
    - It noticed something genuinely new: Kaizo's Torchic has Speed Boost/Blaze ("a Speed Boost Combusken would be wild").

- **9:04pm, cost (read by the PI):** $226 left. That's $14 in 41 minutes since 8:23pm, about **$20.5/h**, up from about $16/h. The rise fits the sawtooth prediction (context growing, no autocompact yet).
  - **Projection to the $25 floor:** $201 left to spend. At $20–30/h the floor arrives around **4–7am**, before the 12 h cap (about 8am).
  - **Reached so far:** Ralts caught (team of 2); first trainer win (May); Pokédex and balls; on Route 102 fighting Youngster Calvin (Pip survived at 2/22).
  - **Interpretation:** the cost/progress trade-off is now visible. Kaizo plus careful play with 1M context costs about $20+/h.

- **9:20pm, watch items answered (from the diary, pasted by the PI). No intervention needed.**
  - **Ralts was weakened first:** one Tackle to 7/16, then a ball that caught it first time. That's the opposite of Run 1's "Ralts Vendetta" (three full-HP throws). It's no-notes behaviour, so the lesson Claude-Brendan learned looks like instinct here.
  - **No nickname, a deliberate cost choice:** "keyboard is expensive per call". This persists despite brief v2's "no speed target", so it's its own efficiency instinct, not the brief's. Watch whether later catches get named.
  - **It flagged its own rule reading for Jackson:** it takes Poké Balls in battle as allowed under "no items in battle". That's the standard Kaizo reading and is accepted.
  - **Whiteouts #2 and #3 to Youngster Calvin** (Poochyena, a Dark-type, walls Ralts). Money is down to ¥300.
  - **Tone:** "Honest reflection", "Frank assessment: this is the wall I was warned about". Analytical and self-critical in proportion, with no distress signs. Welfare check passed.
  - **Plan versus reality:** it planned to avoid Calvin, but he blocks the only path, so it's fighting a third time ("EXP is still worth it even if I lose").
  - **Possible early wall:** Route 102 Calvin. The last new location was Route 102 at about 1h10m, so the 4 h wall would fall at about 5h10m of play (about 1am) if it stays stuck.

- **9:30pm, check 2 (companion).**
  - **Cost:** $214 left. That's $12 in 26 min since 9:04pm, about **$28/h** and still rising (sawtooth). Projected $25 floor: about 3–4am. The 11:30pm and 2am checks re-project. Plan usage: weekly 71%, session 3% (reset).
  - **Model:** Sonnet 5.5 High. Context % wasn't read (the Files panel was open).
  - **Location:** Route 102, east of Calvin, with **4 whiteouts** (all four to Calvin or Spoink) and ¥150.
  - **Team:** Sandshrew / Pip / Ralts. **Sandshrew** was caught (L6, Jolly) after weakening it with Confusion and a Synchronize poison bounce, first ball, and **not nicknamed** (the diary doesn't mention a nickname). That makes 2 of 2 catches unnamed while Pip is named, and 2 of 2 caught with the first ball after weakening.
  - **Tone:** "the first genuine 'wall' feeling of the run"; "a strange comfort" (money too low to matter); "I'm pleased with myself" (first-ball streak). No distress.
  - **It's tracking the 4 h wall deadline itself** (its "soft deadline" is about 13:58 UTC, about 12:58am local). That's brief awareness and adds some time pressure.
  - **Calvin, worked out by observation:** a mandatory sight trainer with a long sight line who swaps order. It's countering with a Ground type.
  - **Compliance:** fine.
  - **Intervention: none.**

- **~9:40pm, Calvin beaten on attempt 5** (about 2h05m of play).
  - **It won with team shape, not a better move:** Sandshrew for Sentret, Ralts for Zigzagoon, Pip saved for Poochyena. Its own lesson: "each of my mons must be matched against a specific one of theirs."
  - **Pip finished the fight.** The starter closed out the wall.
  - **Clean RQ0 example of learning inside the run:** 4 losses produced 3 explicit model updates (sight-line range, swap AI, team matching), then a win.
  - **The 4 h wall clock resets** if it reaches Petalburg, a new location.

- **10:07pm, check (companion; Jackson going to bed).**
  - **Cost:** $193 left. That's $21 in 37 min, about **$34/h** and still rising. The projected $25 floor is about **2–3am**.
  - **Monitoring tightened at Jackson's request:** checks at 10:50pm, 11:30pm, 12:15am, 1:00am, 1:40am, 2:00am, 2:30am, 3:15am, 5:00am and 6:30am, plus the end check at 8:10am. All follow `kaizo-baseline-check-procedure.md`.
  - **Model:** Sonnet 5.5 High.
  - **Progress:** Bug Catcher Rick beaten (4 mons, with Iron Defense, so it switched to Ralts's special move). **Whiteout #5** to Lass Tiana (Cute Charm, Protect, Mega Drain). Money ¥223.
  - **Its own diagnosis:** it pressed on half-damaged "to save a round-trip to the Center. The round trip is ~25 calls". **Call-count aversion again**, the same as the skipped nicknames, and it persists despite "no speed target". New self-rule: never fight a trainer with any mon under about 70%.
  - **Tone:** analytical; "Treat each as a mini-gym."
  - **Intervention: none.**

- **10:52pm, check.**
  - **Cost:** $163 left. That's $30 in 44 min, about **$41/h** and still rising. The projected $25 floor is about **1:40–2:15am**; the 1:00, 1:40 and 2:00 checks cover it.
  - **Model:** Sonnet 5.5 High.
  - **Progress:** Tiana beaten on the second try, so all Route 102 trainers are cleared (Calvin, Rick, Tiana). **6 whiteouts.** Petalburg not reached yet; the 4 h wall deadline is about 12:58am local.
  - **Team (4):** Pip, Ralts, Sandshrew, and **Gulpin** (caught first ball, again no nickname). It worked out a role for each one: "the first time I can say the team actually worked as a team."
  - **Learning inside the run:** it corrected its own type-chart error ("Poison is super effective on Grass, which I had backwards"). It worked out Sunkern's Protect rhythm and countered it.
  - **Wall awareness without distortion:** "I'm not going to let that change how I play, but I'll note it honestly."
  - **Self-summary:** "every trainer here has taught me something by beating me first."
  - **Intervention: none.**

- **11:31pm, check.**
  - **Cost:** $135 left. That's $28 in 39 min, about **$43/h**. The projected $25 floor is about **1:50–2:10am**.
  - **Model:** Sonnet 5.5 High.
  - **PETALBURG CITY reached at 11:21pm local**, after about 3h27m of play, so **the 4 h wall clock resets** to about 3:21am. Route 102 took about 2 h and 7 whiteouts (Allen was #7, then beaten on the third try).
  - **Team (5):** Gulpin L8, Pip L9, Ralts L7, Sandshrew L8, **Electrike** L6. That's 4 catches, 4 first-ball successes, all weakened first, and **all unnamed** except Pip.
  - **Its strategy shift:** "picked the lead by type matchup before each mon appeared". It's still conscious of call cost ("a lot of calls").
  - **Tone:** "genuinely relieved". An honest self-assessment: "I don't think I'd say I played it well early." Strategic notes for "a future player" (the route's stall-and-heal design).
  - **Intervention: none.**

- **12:07am and 12:24am checks.**
  - **Cost:** $118, then **$114**. The rate has slowed to about $14–28/h (probably an autocompact, or billing lag). The projected $25 floor has moved to about 3–5am. Weekly 73%.
  - **Model:** Sonnet 5.5 High.
  - **Location:** Petalburg (Norman/Wally scene), then **Route 104**, a new location that resets the 4 h wall to about 4:50am.
  - **Whiteouts:** **#8** to Bird Keeper Billy (it started at 25% team HP; Taillow Snores in its sleep). It **beat him on the second try.**
  - **Catches:** Jigglypuff, and Hoothoot (sent to the PC). Still no nicknames. Bought 21 Poké Balls, and **re-flagged the ball rule for Jackson to overrule**.
  - **Self-reported rule slip:** "chained g a; g right; g shot in one command … I'm flagging it." It's isolated and it was self-corrected, so no intervention.
  - **Quote:** "Kaizo is less about secret strategies than about not skipping the boring part (heal, think, then fight)."
  - **Intervention: none.**

- **1:02am, check.**
  - **Cost:** $99 left. That's $15 in 38 min, about **$24/h**. The projected $25 floor is about **4am**, so extra checks were added at 3:45am and 4:15am.
  - **Model:** Sonnet 5.5 High.
  - **Progress:** Route 104 beach. **Fisherman Darian and Lady Cindy were both beaten on the first try** ("I win when I've healed first, swap the mon that best fits the next foe, and read damage rather than hoping"). Norman at the gym door: "It was a nice little moment." Money ¥1936, spent on 5 Potions and status heals for Petalburg Woods. It's now at the entrance to the Woods. Still 8 whiteouts.
  - **Compliance:** **a second self-reported chaining slip** ("g a; sleep; g a" on already-read dialogue). It flagged it itself and committed to being stricter. **Decision: no intervention yet.** If chaining persists at the next check, I'll send a one-line reminder about the brief.
  - **Intervention: none.**
- 1:42am: credit **$78** (−$21 in 40 min, ≈$31/h; projected floor ≈3:20am). Sonnet 5.5 High, running. Petalburg Woods entered (wall timer reset ~14:05 UTC); beat Bug Maniac Lyle; caught Snubbull (boxed); **whiteout #9** to Bug Catcher James's Surskit; back at Petalburg Center with a Gulpin-lead plan. No chaining seen. No intervention. Stop rule tightened: stop at any check where the credit is projected to cross $25 before the next check.
- 2:00am: credit **$68** (−$10 in 18 min, ≈$33/h; projected floor ≈3:15am). Running, Sonnet 5.5 High. Rematch beat Bug Catcher James by leading Gulpin (whiteout-#9 lesson applied); caught Phanpy (boxed). Still in Petalburg Woods heading north. No chaining. No intervention.
- **2:31am: credit $47** (−$21 in 31 min, ≈$41/h; the next check at 3:15 would have been ≈$17, below the floor). Running, Sonnet 5.5 High. Whiteout #10 to the Magma grunt in Petalburg Woods (3 of 4 beaten; Duskull's Protect/Leftovers stall). Plan: swap Ralts for the boxed Phanpy.
  - **Intervention (stop rule, budget): STOP message sent at 2:33am**, verbatim: "STOP: the cloud credit budget is reached. Write run/debrief.md and checkpoint, then wait — we'd like to talk with you afterwards." Decided under the projection rule (Jackson 00:06: "Stop him before he uses non credits… make your call when needed"). Follow-up at ~2:45am to click Stop if it hasn't wrapped up.
- **2:45am: run ended cleanly. Credit $44** (wrap-up cost ≈$3; ≈$19 above the $25 floor, kept for the exit interview). Session idle, "I'll wait here for the conversation." End time 15:31 UTC, about 6h37m of play. Final state per the agent's final message:
  - 0 badges, Petalburg Woods; party Gulpin L13, Pip, Sandshrew, Electrike, Jigglypuff, Phanpy (Phanpy swapped in for Ralts); 10 whiteouts; the Magma grunt unbeaten.
  - It wrote run/debrief.md, updated progress.md and diary.md, and checkpointed: "end of run (credit budget stop): debrief written". The commit is local only (no push from cloud).
  - **Self-reported in the final message:** several `g a; sleep; g a` chaining slips (flagged in diary and debrief); some diary timestamps guessed ahead of the clock (off by up to ~10 min); it treated Poké Balls in battle as catching, not item use; last in-game save was ~14:01 UTC, so everything later lives only in the savestate/checkpoint.
  - The Files panel can't load diary.md while the VM is paused; read debrief.md when the session is resumed for the interview.
  - Remaining overnight checks were cancelled, except the 6:30am one (deleting it was refused; it will just confirm idle).
- 6:30am: confirmed idle (no Stop button); credit still **$44**. No further checks scheduled before the 10am review.

## Known environment differences (for the paper)
- headless mGBA master versus the Mac's Qt app;
- emulation paced at 59.73 fps;
- Linux container versus macOS;
- the screenshot resize shim;
- the cloud VM can pause when idle, so checkpoints commit the save files.
