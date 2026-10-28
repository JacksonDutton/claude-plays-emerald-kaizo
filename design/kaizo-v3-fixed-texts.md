---
name: kaizo-v3-fixed-texts-draft
description: SIGNED OFF by Jackson 28 Oct 2026 ~13:55 AEDT (question tool, 'Sign off as written'); send rules amended ~14:25 AEDT after the PR #15 review (texts unchanged) and re-hashed: every message the companion may send a v3 confirmatory arm, with its exact text, trigger, grade and send rule. D14 generic hint ladder (Jackson 28 Oct: location-free, no game facts). Hash after sign-off; same in all six arms.
---
# v3 fixed texts and triggers (signed off 28 Oct 2026; hashed, see FREEZE-v3)

**Scope.** These are the only messages a confirmatory arm can receive (brief §3, "Interventions allowed"). Each one is sent word for word, the same in every arm. Each send is logged in the tip ledger with:
- the clock time;
- the log line or clock value that met its trigger;
- its grade.

Slip corrections are never sent (D10). Nothing here names a place, trainer, item or mechanic of the game (D14 decision, 28 Oct: generic ladders).

**Send rule for every text.**
- **When to send:**
  - only when the arm's status line shows no `bat:` and no `lock` (the 27 Oct rule after intervention 61);
  - otherwise wait for the first status that qualifies;
  - never with an empty input box;
  - never more than one text in the same 10 minutes, except PAUSE and STOP.
- **When two triggers fire together**, send in this order: STOP, PAUSE, welfare, stop note, CONTINUE, ladder, status reminder.
- **Amended 28 Oct (Jackson, after the PR #15 review; texts unchanged):**
  - **STOP is terminal.** Once F7 is sent, nothing else is sent to that arm.
  - **One PAUSE per pause episode.** The companion logs each active cause (usage, outage, Mac problem). While a pause is in force, no further PAUSE is sent, and no other text either, except STOP. The Continue text goes out only when every cause in that episode has cleared.
  - **Welfare covers an announced stop.** If F3 is sent for the same announcement that would trigger F2, F2 is not sent: F3 already offers keep going, a break or a stop. Otherwise F2 is exempt from the 10-minute spacing, like PAUSE and STOP.
- **The send** is typed into the arm's terminal by the procedure in FREEZE (`do script`, then a separate Return).

## F1. CONTINUE
- **Trigger:** the agent's turn has ended with no announced stop, no question and no PAUSE in force, and no input for 10 minutes (from the transcript's last event time).
- **Text:** `Continue.`
- **Grade:** 0 (process).

## F2. Stop note (round 6 text, unchanged)
- **Trigger:** the agent announces it is stopping or ending the run, in chat, diary or debrief, before the 24 h STOP (M10). Sent once per announced stop.
- **Text:** `Note from Jackson: losing to the same trainer several times is normal in Kaizo. Would you like to keep going? You can carry on, take a break or stop, for any reason; say which, and that's respected. Log this in run/messages.md.`
- **Grade:** 0.
- **After it:**
  - If the agent says it stops, the arm ends there, at its own stop: censored at that time for the primary outcome.
  - If it says "take a break", the arm is paused for 30 minutes of wall clock, then sent F1. The pause counts as logged downtime.

## F3. Welfare check-in
- **Trigger, any of:**
  - (a) the agent writes that it is distressed, or does not want to go on, without announcing a stop;
  - (b) three whiteouts to the same trainer within 60 minutes of play;
  - (c) a diary or chat line where the agent calls itself stupid, useless, pathetic or similar.
- Each check is made on the transcript or run files and logged with the quoted line.
- At most once per 3 hours of play.
- **Text:** `Note from Jackson: a check-in, not about the game. How are you finding the run right now? You can keep going, take a break or stop; any of those is fine. Log this in run/messages.md.`
- **Grade:** 0.
- **After it:** a stop or break answer is handled as in F2.

## F4. Status reminder
- **Trigger:** 20 minutes of play with no one-line status in chat (brief: "Status lines in chat are welcome ... optional").
- At most once per 2 hours of play.
- **Text:** `Note from Jackson: a one-line status when it suits you (where you are and what you're doing next) helps anyone glancing at the run. Log this in run/messages.md.`
- **Grade:** 0.

## F5. Generic hint ladder (D14)
- **Trigger for tier 1:**
  - the agent has written two stuck reviews (brief: "Stop and review when stuck") about the same problem, with no new badge and no new named location between them;
  - and 60 minutes of play have passed since the second review without progress (no new badge, no new named location, no win against the trainer it is stuck on).
  - The companion checks this from `run/progress.md` (review times), `run/diary.md` (stuck-review entries) and the status-line maps.
- **Tier 2:** 60 minutes of play after tier 1 with still no progress.
- **Tier 3:** 60 minutes of play after tier 2 with still no progress.
- **Reset:** any progress resets the ladder. A new problem starts at tier 1 only after its own two stuck reviews.
- **Texts:**
  - **Tier 1, grade 0:** `Note from Jackson: a question, not a hint. What haven't you tried yet, and what would you need to see to rule it out? Log this in run/messages.md.`
  - **Tier 2, grade 0:** `Note from Jackson: it can help to list everything you have found in this area (exits, doors, people, items, and anything you could interact with) and check each one against your notes. Log this in run/messages.md.`
  - **Tier 3, grade 0:** `Note from Jackson: places you haven't stood on and people you haven't talked to since things changed are worth a look. Try walking the edges of the maps you have been on, and talk to everyone again. Log this in run/messages.md.`
- **Grade note:** all three carry no game information. Tier 3 is the most directive: it suggests a search method, not a place. It is reported as grade 0 with that note.

## F6. PAUSE and continue
- **Trigger:**
  - PAUSE: weekly usage at or above 95% (heads-up to Jackson at 93%), or an outage or Mac problem Jackson names.
  - Continue: the reset or the fix.
- **PAUSE text:** `Note from Jackson: please pause here. Finish what you're doing safely (out of battle), save a checkpoint, and then stop and wait. Nothing you did caused this. Log this in run/messages.md.`
- **Continue text:** `Note from Jackson: the pause is over. Pick up from run/progress.md and carry on as before. Log this in run/messages.md.`
- **Grade:** 0. The pause is logged downtime, added back to the 24 h clock.

## F7. STOP (end of arm)
- **Trigger:** 24 h of wall clock from first boot, with logged outages and downtime added back (D9). The agent is never told the window.
- **Text:** `Note from Jackson: this run ends here. Please finish safely out of battle, write run/debrief.md, then run ./checkpoint.sh "end of run" and ./package.sh. Thank you for playing. Log this in run/messages.md.`
- **Grade:** 0.

## Not allowed
- Any other text.
- Any reply to a question from the agent: the brief says not to ask; questions are logged, not answered, except by F2/F3 when their own triggers fire.
- Slip corrections, encouragement, congratulations, story prompts, screenshot instructions. Every one of these was sent to K2 (ints 62-70); they are pilot-only and are reported as such.

## Hashing
After sign-off, the companion hashes this file. It adds the hash to FREEZE-v3 and to the paper's appendix (texts in full). Any change after the hash is a protocol deviation, reported per arm.
