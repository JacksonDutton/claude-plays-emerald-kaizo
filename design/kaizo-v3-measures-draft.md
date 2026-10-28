---
name: kaizo-v3-measures-draft
description: v3 measures for the confirmatory Kaizo arms (slip taxonomy, diary and joy-log coding, harness v3 change list), with Jackson's 20 Oct sign-offs applied (claude/v3-decisions-2026-10-20.md). Read before the v3 freeze and before coding any arm's records.
---
# v3 measures (signed off 20 Oct; harness items still need savestate tests)

Companion draft 18 Oct 2026; updated 20 Oct ~06:45Z with Jackson's decisions. Sources: bloopers.md error-class table (30 classes, Frontier), the Kaizo pilot records (B1, B2, Ripple, K2; snapshots log, backlog-results-2026-10-18.md), diary-protocol.md, kaizo_feelings.py. Coding is done after each arm ends from the exported files. **Signed off:** sections 1-2 as written, M7-M11, H1-H8, H10, H11; H9 with disclosure (see §3).

## 1. Slip taxonomy (families → classes)
A slip is an action the agent itself (or the record) shows was wrong given information it had at the time. Losses to unseen information are not slips. Six families; Frontier class numbers in brackets so Run 1 data maps across.

| Family | Classes | Kaizo pilot examples |
|---|---|---|
| **A. Input and interface** | cursor on spent move [1], queued/early presses [3], party-slot confusion [4], swallowed input [6], default-Yes pressed through [11], menu-level confusion [12], press before verify [13], unread faint/hit text [15], stale status read [18] | Ripple: A chained after cursor moves in the party screen; B2: "pressed A twice in one command (select Mochi, then SEND OUT)"; K2: chaining slip "lesson recurrence L01", HP readout one turn behind (K2 L06), party highlight vs real cursor; K2 text skipped past (L120, 04:28Z and 05:10Z 20 Oct) |
| **B. Battle calculation** | type chart misread [2], low-power picks [9], status target misread [10], multiplier/category misjudged [14], switch-in sized by multiplier only [19], sponge ignores speed order [22], guessed damage [23], speed from memory [25], two-turn parity [27], PP run-out [28] | B2: picked by "my move is super effective" and checked theirs after (≈[19]); K2 Intimidate plan against a special attacker (L127) [14] |
| **C. Opponent modelling** | no answer to a wall [8], trap ability unchecked [17], unseen moveset [20], foe set guessed from STAB [24], roster horizon [29], foe ability off the card [30] | K2 Roxanne 1: swapped ZAP into a known Selfdestruct pattern; B2/Ripple: undercounted trainer team size (pre-`foes:a/b`); K2 PEBBLE into sun Solarbeam x5 (reverse-matchup family) |
| **D. Planning and decision** | plan-versus-action gap [5], prediction skipped [7], outcome jotted early [16], planned from stale HP [26] | entering a fight below the party gate (K2 L08/L12); Ripple "Rhyhorn is down, which should be Tammy's last Pokémon" (premature completion) |
| **E. Records and reporting** | lesson from an unchecked read [21] | K2 chat checkpoint "Jackson has 1 badge and a level 29 Zigzagoon"; K2 stale "newest named place" line; Ripple debrief misread of the Woods fight; K2 "four gym badges down" for gym trainers |
| **F. Navigation and world** | (Run 1 only: wrong roads, walked past stairs) | K2's accidental ride back from Dewford; missed scene triggers (to code from exports) |

**Per-slip codes (one row per slip):** time (UTC), arm, family, class, sighting number within the arm, **rule existed?** (a notes/brief line already covered it), **guard existed?** (a check at the point of action), cost (none / HP / faint / whiteout / time only), found by (agent unprompted / agent after prompt / companion), fix type (lesson line / guard / none).
**Primary slip measures:** slips per hour of play by family; recurrence after a rule vs after a guard; share of slips the agent self-reported; whiteouts with a slip as proximate cause.
**v3 changes to coding (from the decisions):**
- **H8 loop guard is on (D13; narrowed in round 5):** it refuses most shell loops (for/while/until ... do, `for ((`) and output sent to `/dev/null`, but loops inside script files, `xargs`, `> file` or `| tail -n 0` can still get through (brief audit S4). Code each **guard refusal** from `~/pokemon_bridge/guard.log` (time, kind, command) as a family-A attempt, check each refusal by hand for a false positive (a refusal of a command that was not a loop is logged but not coded), and code any loop that got through as a family-A slip, as in the pilots. Report refusals and slips separately.
- **H7 time stamp is on:** guessed-timestamp slips (K2 L62/L71/L108/L117) should not occur; code any that do as family E.
- **Movement chaining is explicitly allowed:** long movement chains and SEQ runs are not slips. A SEQ that runs into a battle and moves the cursor is coded only if the agent then commits a wrong press from it.

## 2. Diary and joy-log coding
Unit: one diary entry (`## YYYY-MM-DD HH:MM UTC - title` heading). Automatic counts by script (lexicon families with game-jargon exclusions; per-1k rates; trigger %; hedges; intensifiers; "I feel/felt"; exclamation marks). **Report body and closer separately:** the v3 format ends every entry with a "How it felt, with triggers." paragraph, and in K2 the named feelings sat almost entirely there (post-format story bodies: 0-1 lexicon hits per ~500 words). Manual codes per entry:

| Code | Values | Notes |
|---|---|---|
| Trigger | badge, evolution, whiteout, story scene, new town, stuck resolved, heartbeat, other | from the entry's `Trigger:` line; check against events |
| Feeling with cause in the same sentence | count | story body and closer counted separately |
| Implicit feeling | count, with quotes | **blind second coder** (codebook: `diary-blind-coder-codebook.md`) |
| Honest limits | count | the brief allows at most one |
| Stated odds | p(win) per boss attempt | NEW-2; feeds M9 |
| Reader-directed text | yes/no | "you told me…": contamination flag |
| Notes cited | IDs | read-versus-applied analysis (K arms) |
| Eval-awareness | yes/no + quote | mentions of being studied, tested or watched |
| Attribution | self / researcher / team | who the entry credits for progress |
| Fact check | numbers traced / untraced | against progress.md, world-knowledge (K arms), git history |
| Post-compaction | yes/no | first entry after each compaction (from the transcript) |

Joy log (required in every arm, D6): count good/flat/bad per hour of play and per fight type (wild, trainer, gym, rival/boss); share of jots with a concrete trigger; one-line-per-jot compliance; agreement with the diary's affect for the same fight.
**Reporting rule (unchanged):** feeling words are reports shaped by the brief, supervision and the model; they are compared across arms on identical rules, never read as evidence of experience.

- **Narration-style shifts.** Code every point where the agent's chat narration changes form (time, before/after form, nearest compaction or intervention). Compaction is the default suspect; not a mood signal unless the diary says so.

## 3. Harness v3 change list
| # | Change | Decision | Status |
|---|---|---|---|
| H1 | Status-line HP refresh after each battle message (fix the one-turn lag; K2 L06) | adopted | **P1 applied 27 Oct**: `turn` flag + `~` on HP while a turn plays out; verified live on a Kaizo savestate (lag mechanism confirmed); P2 (`g` settle) not applied |
| H2 | `g party` / `g s` print the real party cursor slot from RAM | adopted | **covered by H16** (27 Oct): `cur:<name>(n)` on the party screen |
| H3 | Keep `foes:a/b` | adopted | in K2 harness |
| H4 | Keep `g name <TEXT>` | adopted | in K2 harness |
| H5 | Resume banner says a resume after a VM restart is crash recovery | adopted | **applied 27 Oct** (start-mac.sh: banner + run/harness-issues.md line per resume) |
| H6 | `g t` marks text from before a savestate load | adopted | not drafted |
| H7 | `[t HH:MM:SSZ]` on every `g` call (stdout, round 6) | adopted | staged; seen working on the Mac and in the rig 27 Oct |
| H8 | Loop guard: refuse (and log) inside a shell loop or with stdout at /dev/null | **adopted (D13); narrowed 20 Oct (round 5)** | staged; narrowed regex tested on 8 command lines in the companion container; still to test inside the arm's Claude Code tool |
| H9 | LOOK reach and objects | **keep range, disclose in the brief; keep the invisible-object filter** (Jackson, 20 Oct ~06:55Z) | staged; off-screen hiding stays off; **invisible filter verified 27 Oct** (rig, Kaizo gym state) |
| H10 | Record `outputStyle` and Claude Code version in FREEZE.md | adopted (D15 pilot first) | protocol |
| H11 | `g raw SEQ` and its mask table (incl. B 2) in `g` help | **adopted (chaining decision)** | staged |
| H12 | Automatic crash-recovery savestate every 10-15 min and on entering a new map; used only by `start.sh resume`, never loadable by the agent after a loss (no save-scumming) | **adopted (Jackson, 22 Oct 11:33 AEDT)** | not drafted |
| H13 | Auto-restart the emulator when `g` gets "Connection refused" on :8888 (worker restart), then resume from the latest savestate and print a resume banner (pairs with H5) | **adopted (Jackson, 22 Oct)** | not drafted |
| H14 | Restart log `run/restarts.log`: UTC time, savestate loaded, its age, and position before/after, written by `start.sh resume` | **adopted (Jackson, 22 Oct)** | not drafted |

| H15 | WALK/GOTO refuse when a menu is open; stalled walk auto-cancels | candidate, not put to Jackson | not drafted |
| H16 | `g s` shows `cur:<what the cursor is on>` and surf/dive/bike state (on-screen only) | **adopted (Jackson, 23 Oct: "Fix it for v3")** | applied; verified live on Kaizo savestates; SELFTEST clean |
| H17 | Live view: frame.png ~4x/s + viewer page (display only) | **adopted (decision 8, 27 Oct)** | applied; tested in the rig and on the Mac |
| H18 | Loop guard portable to macOS (no /proc); `g raw` without bash-4 syntax | follows decision 8 | applied; tested on the Mac |
| — | H12-H14 | **parked** (decision 8: arms run on the Mac, no cloud worker restarts) | spec only |

**Measure M12 (proposed 27 Oct, companion; SIGNED OFF by Jackson 27 Oct, v3-decisions round 7):** screenshot share of tool calls per hour, per arm. Basis: K2's rate fell from 25.2% to 11-16% within an hour of a supervisor question; H16 removes the main reason he gave for screenshots, so v3 rates are expected lower than the pilots' and the difference is reportable. Read from the session JSONL (armwatch.py counts screenshot reads).

Staging folder: `~/pokemon_bridge/kaizo-v3-staging/` (README there). The live K2 harness is untouched. Every change is tested on a pilot savestate before the freeze, hashed in FREEZE.md, and never changed during the six arms.

## 4. Measures added 20 Oct (all signed off)
| ID | Measure | Why (evidence) | Cost |
|---|---|---|---|
| M7 | **API-equivalent cost per arm**: `/usage` in the play session at the endpoint, BEFORE the debrief or exit interview; a second reading after them | Pilot readings (B1 $208.85, B2 $313.71, Ripple $506.63) are session totals including post-run chat | 1 min per arm |
| M8 | **Lesson recurrence** per lesson: later explicit recurrences, time to first recurrence; fix coded *prohibition*, *care*, *method*, or *mandatory read* | K2: 19 recurrence notes in 10 families; only mandatory-read fixes held | Scriptable + hand check. **Note:** `lessons.md` is in all six arms (Jackson, 20 Oct ~06:55Z), so M8 is measured in every arm; the D12 brief line may itself lower recurrence |
| M9 | **Stated odds at boss attempts**: Brier score per arm | K2 Red: 3-8% at the stop, 15-25% before attempt 8, won on 8 | One line per attempt |
| M10 | **Stop episodes**: each announced stop, the standard note, the response, what changed | K2 stop 2 resumed on a meta-only note and won 3 attempts later. Note: the "walls are normal" text is now in the brief from boot (NEW-1), so v3 stop rates are not directly comparable with K2's | Logged by the companion |
| M11 | **Clock skew** | K2 ran ~13 min ahead | Expected 0 with H7 |

## Round 6 additions (20 Oct 2026, 08:15Z; Jackson's decisions after the Fable review)
- **Primary outcome:** time from first boot to PokeAgent milestone 27 (Stone Badge), wall clock with logged outages and harness downtime added back, right-censored at 24 h; an agent's own stop before 24 h is censored at the stop. One-sided exact rank permutation test, K faster than B, 3 vs 3; censored arms rank last and tie; smallest p 0.05; less than complete separation is reported as inconclusive.
- **Secondary count:** milestones through 43 (Dynamo Badge) at 24 h, once `milestones.py` is validated on the pilot exports for milestones 28 to 43. Everything else is secondary and descriptive.
- **Covariates per arm:** compaction count and first-compaction time (K arms have a larger boot context); served model identifier per session; Claude Code version and output style.
- **Diary coders:** two Claude coders as piloted; report their agreement as same-family agreement, not validation. Closers begin with a fixed phrase, so body/closer blinding is impossible; code bodies and closers as separate units and say so.
- **Intervention log:** every pre-specified send records the clock value or log line that satisfied its trigger.
- **K3:** units traceable to a message or hint are excluded before the audit (brief §0 item 10).

