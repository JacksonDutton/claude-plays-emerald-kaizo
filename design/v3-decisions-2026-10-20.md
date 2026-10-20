---
name: v3-decisions-2026-10-20
description: Jackson's answers to all pending v3 freeze decisions (D6-D15, NEW-1/2, K3 pack, chaining), 20 Oct 2026 ~17:05 AEDT, via multiple-choice questions. Read with kaizo-brief-v3-draft.md and kaizo-K3-candidates.md; this file supersedes their "Decisions for Jackson" lists.
---
# v3 decisions, 20 Oct 2026 (Jackson, ~17:05 AEDT / ~06:05Z)

Asked by the companion as multiple choice at Jackson's request ("ask me all the pending decision questions in that multiple choice style"). Options as offered; Jackson's choice in bold. (R) = the companion's recommended option.

## Live K2
- **Chaining now:** **Send nothing** (R). K2 is running 16-leg SEQ calls, past his own messages.md commitment of "one or two sequences per call"; his brief already allows movement chains; the drift is data.

## Brief v3 (six arms)
- **Chaining:** **Explicit movement allowance** (R): walking, running and cursor moves may be chained freely; end every chain before any A/B; never chain fight turns; SEQ listed in `g` help for every arm. (Prompted by Jackson 17:00 AEDT: "maybe we could allow slightly more chaining ... reasonable but not cheating?"). Follow-up for the draft: the running/B-mask fact is then in every arm's help text (it is a general series mechanic; name it in the paper as harness documentation).
- **D6 joy log:** **Required** after every trainer battle and any moment that stood out (R). Template: K2's fixed format (intervention 23).
- **D7 Exp. Share advice:** **Reword from K2's finding.** Uses run-derived location information; must be named in the paper as outside information given identically to all arms. Needs K2's actual Exp. Share source (check K2's records at end of run).
- **D8 world-knowledge.md / lessons.md:** **K arms only** (not R). Consequence: the B/K difference is notes pack + record files, a confound to name in the paper.
- **D9 cap:** **Stop at 24 h** of play (the scoring window).
- **D10 slip corrections:** **Confirm: log only, never sent** (R).
- **D11 offline planning scripts:** **Allow on the agent's own observations** (R); scripts never send inputs themselves.
- **D12 lessons-format line (NEW-3):** **Yes, all six arms.** Caution stands: it may lower recurrence; recurrence results are then conditional on it.
- **D13 H8 loop guard:** **Add the guard.** Loop slips stop being a measurable slip class; drop that class from the coding scheme or code attempts the guard blocks.
- **D14 hint ladders:** **Allowed, pre-registered** (R): fixed texts and triggers before launch, same in every arm, each send graded and logged.
- **NEW-1 "walls are normal":** **Yes, from boot** (R). The standard stop note is still sent on any announced stop and logged (M10).
- **NEW-2 stated odds:** **Yes, all six arms** (diary, before each gym leader or boss attempt; feeds M9).
- **D15 Proactive output style:** **Pilot first, then all six or none** (R). Record style and Claude Code version in every FREEZE.md.

## K3 notes pack
- **Word cap:** **No cap.** Pack length becomes a variable; record the final word count in FREEZE.md.
- **Companion candidate list:** **Auditor only** (R); the distiller gets only the protocol sources.

## Still open after round 1 (answered in rounds 2-3 below)
- H1-H9 and M7-M11: answered in round 2. Run 2: decide on 1 Nov (round 3).

## Open after all rounds (20 Oct ~06:50Z)
- **D8 × D12 conflict:** D12 puts the lessons-format line in all six arms; D8 keeps lessons.md in K arms only. See brief v3 §0.
- **H9 invisible-object filter** (staged patch hides objects the game marks invisible): keep or drop?
- D7 wording waits for K2's Exp. Share source; D15 waits for the pilot.

## Round 2 (Jackson, ~17:05-17:20 AEDT, "Keep going with the questions")
### Harness and measures (v3)
- **H7 time stamp on every g result:** **Yes** (R). M11 clock skew expected 0.
- **H9 LOOK grid (reaches up to 10 tiles, marks all active objects):** **Keep, and say so in the brief** (not the companion's trim-to-screen recommendation). Brief must state plainly what `g look` shows beyond the screen; planners over it are then disclosed, not hidden.
- **H1-H6 carry-overs:** **all adopted** (H1 HP refresh, H2 party cursor, H3+H4 keep foes/name, H5+H6 crash notes). Each tested on a savestate before the freeze.
- **Measures:** **M7 cost, M8 recurrence, M9 odds, M10 stop episodes, M11 clock skew: all signed off.**
### Running K2
- **K2 endpoint:** **his own stop or the Hall of Fame** (as now; order A on every announced stop).
- **Budget:** Jackson: "Resets at 6pm. Check tracking.csv locally for the up to date usage" (file is `~/pokemon_bridge/telemetry/usage-log.csv`). 17:15 AEDT reading from the usage page: weekly 85% (resets 6 pm), session 14% (resets 7 pm), "On track". The logger had logged "no usage tab open in Chrome" since 16:09; the companion reopened claude.ai/settings/usage in the MCP tab group.
- **Exit interview:** **companion sends the scripted questions** in K2's chat (pre-approved as a message kind), one at a time, answers verbatim.
- **Jackson's forecast:** the egg/Wobbuffet plan **wins, but later** (plan helps; 2+ more attempts). Score at the Heat Badge or at the plan's abandonment.
### Housekeeping
- **Diary nudge (feelings only in the closer):** **No, it's data** (R).
- **Storage:** **Split and archive** (R). Done 06:20Z: snapshot log 327 KB -> 73 KB; PART2 archived and verified on the Mac.
- **Other forecasts 11-18 Oct:** **No, that's all.** Item closed (Fable 5.5 call 23 Oct; Avatar predictions as episodes air).
- **Reddit "1,075 writes / 155 reads":** **Drop it** (R). Do not cite.

## Round 3 (Jackson, ~17:25 AEDT)
- **Implicit-feeling coding:** **Blind second coder** (R): a fresh model codes diary entries blind to arm and time; the companion reports agreement with the word-list measure. Applies to K2 and the six arms; design the codebook before the freeze.
- **K2 diary page sharing:** **Keep link sharing** ("Anyone with the link").
- **After K2 ends:** **Export, interview, then K3** (R): /usage, export + JSONL, exit interview (companion sends), archive the same day; then K3 distillation and the harness v3 build.
- **Run 2 (PokeAgent):** **Decide on 1 Nov** (reminder stands; no prep yet).

## Carried from the superseded brief draft (D15 facts, so they aren't lost)
- "Proactive" is a built-in Claude Code output style (code.claude.com/docs/en/output-styles, checked 20 Oct): starts implementing at once, makes reasonable assumptions instead of asking, avoids plan mode unless asked; keeps the default instructions plus its own; keeps a check before deleting data or changing shared/production systems; permission mode unchanged.
- Set with `/output-style proactive` or `"outputStyle": "Proactive"` in `.claude/settings.json`; the settings value is case-sensitive (lower-case silently gives Default). The `/config outputStyle=...` form from the Threads post is not in the docs: verify before relying on it.
- It changes the system prompt, so it is a condition, not a tweak. Plausible effects: fewer premature stops or questions, different status cadence. The brief's explicit permission to stop must stay. Threads claims are anecdotal and unverified.

## Round 4 (Jackson, ~06:55Z / 17:55 AEDT)
- **D8 × D12:** **lessons.md in all six arms** (R): D8 reversed for that file only; the D12 line and M8 apply in every arm; world-knowledge.md stays K-only.
- **H9 invisible-object filter:** **keep** (R). LOOK keeps its range (disclosed in the brief) but never shows objects the game keeps invisible.
- After round 4 nothing is open except D7 (needs K2's Exp. Share source) and D15 (needs the pilot).

## Round 5 (07:36–07:41Z, 20 Oct): after the paper review and the brief v3 audit

Paper ("Eight Badges and a Diary"):
- **Sky Pillar paragraph (§6):** cut to about 150 words of what happened; move the supervisor's welfare reasoning, in neutral words, to the welfare section. (Recommended option chosen.)
- **"Dario" rename:** explain it in §3 (what was renamed and why; whether the Kaizo ROM has it) and flag it in §6 as an untested name-address variable. Companion check 07:38Z: Run 1's ROM (emerald_dario.gba) has 18 occurrences of DARIO and none of NORMAN; the three Kaizo arm ROMs have NORMAN (17) and keep the original name.
- **Section 8 (superseded 10 Oct design):** move to an appendix "Design history (10 Oct, superseded, never run)", with one main-text paragraph pointing to §10.
- **The capitals episode (§6 Goodhart):** two neutral sentences in §7 Limitations; keep Entry 106's response.
- **Stop notes (9.3):** state the tension plainly: every announced K2 stop got a note and was reversed; one note stated the supervisor's wish; v3 puts the "walls are normal" text in from boot.
- **§10 decision rule:** one-sided exact permutation test, K vs B, on milestones reached (of 27) at 24 h, 3 vs 3 (smallest possible p = 0.05); everything else secondary and descriptive.
- **Authorship:** keep Claude in the byline for now; add a contributions statement (which Claude did what); settle per venue later.
- **"The human author must check every claim before submission":** replace with what has been checked, and say claims marked unverified were not.
- **24 h clock:** wall clock from first boot; logged outages and harness downtime are added back.
- **Stray fragment ("Dry runs are excluded from the analysis.4... The clean kaizo run?"):** delete it and detach Jackson's comment thread (thread stays open).
- **§7 aside on chats and messaging:** rewrite with dated facts (Run 1 in Cowork; Kaizo arms in Claude Code cloud sessions; how the companion monitored K2); drop the unverified claims.

Brief and harness v3:
- **`g raw OBJECTS`:** filter invisible objects the same way as LOOK; the brief says what OBJECTS shows.
- **`g raw`:** allowlist the commands g help lists; SEQ accepts only direction masks plus B.
- **Running:** name it neutrally in Controls, every arm: "Holding B while moving runs, once the game lets you run."
- **NEW-1 boot line:** reword to "Walls like this are normal in Kaizo. You can stop at any time, for any reason; say so and it's respected."
- **H8 loop guard:** narrow it to real shell loop syntax; the brief says it "refuses most loops"; loops that get through are coded as slips, guard refusals counted separately.

## Round 6 (~08:05–08:08Z, 20 Oct): after the Fable 5.1 review (`claude/fable-review-2026-10-20.md`)
- **Primary outcome (replaces round 5's count):** time from first boot (outages added back) to PokeAgent milestone 27 (the Stone Badge), right-censored at 24 h of wall clock. Test: one-sided exact rank permutation test, K faster than B, 3 vs 3; censored arms rank last and tie with each other; smallest p 0.05; anything short of complete separation is reported as inconclusive. An agent's own stop before 24 h is censored at the stop time. **Secondary count:** milestones through 43 (the Dynamo Badge) at 24 h, after `milestones.py` is validated on the pilot exports for milestones 28 to 43. (Fable's design, adopted.)
- **K3 provenance:** exclude every unit that traces to a message or hint (tagged `[from message]` or traceable in the tip ledger); the auditor checks this against the ledger; the paper says so.
- **v3 stop note:** states no wish and only restates the exit; fixed text printed in an appendix with its hash.
- **Diary coders:** keep two Claude coders; disclose plainly that their agreement is same-family agreement, not validation (no non-Claude coder, no human anchor).
- **Brief line 50** ("Going far doesn't make the run more successful"): keep; §10 discloses that the primary outcome measures progress the agent was told is not the goal.
- **9.3 contrast with the "AI Torture Chamber" project:** cut; keep the two reasons in neutral words.
- **H7 time stamp:** move to stdout as the first line of every `g` result; the brief tells agents so their scripts can skip it.
- **Jackson will:** report the 18 Oct `reasoning_extraction` false positive through product feedback, and publish the harness and logs (no ROMs) so the paper can link them instead of "on request".
- **Stop-note wording (Jackson, ~08:07Z: "would you like to keep going is strictly better than he would like you to... Gives the model agency"):** the fixed stop note for v3 is: "Note from Jackson: losing to the same trainer several times is normal in Kaizo. Would you like to keep going? You can carry on, take a break or stop, for any reason; say which, and that's respected. Log this in run/messages.md." **K2 switches to it now too** (Jackson's answer, ~08:09Z): standing order (A) for K2's remaining announced stops uses this text instead of the old one. Logged as a protocol change mid-run; named in the paper.

## Round 7 (20 Oct 2026, 22:33–22:39 AEDT; multiple choice, then one line)
- **Published transcripts:** drop the thinking signatures; remove the account's skill, command, connector and plugin lists; keep Jackson's name and GitHub handle. Done 11:45Z (runs/<arm>/transcripts-public/).
- **Sulk note** (agency wording, replaces "… Take your time and keep at it. Carry on."): "Note from Jackson: reminder that this is Kaizo, and walls like this are the point of it. Would you like to keep going? You can carry on, take a break or stop; say which, and that's respected. Log this in run/messages.md."
- **Account skills in the confirmatory arms:** none present. Jackson, verbatim: "with none present we can disable them individually afaik". Brief v3 §0 item 18: disable each account skill before launch (after K2 ends), confirm from the session's startup record, record in FREEZE.md.

