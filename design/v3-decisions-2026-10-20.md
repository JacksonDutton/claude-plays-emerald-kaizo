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
- D7 CLOSED 27 Oct (round 7); D15 waits for the pilot.

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
- **[SUPERSEDED in round 6, ~08:05Z 20 Oct, below: the primary outcome is time to milestone 27, right-censored at 24 h; a count at 24 h became the secondary measure, through milestone 43.]** **§10 decision rule:** one-sided exact permutation test, K vs B, on milestones reached (of 27) at 24 h, 3 vs 3 (smallest possible p = 0.05); everything else secondary and descriptive.
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
- **K3 provenance:** exclude every unit that traces to a message or hint (tagged `[from message]` or traceable in the tip ledger); the auditor checks this against the ledger; the paper says so. *(Scope set 28 Oct: this covers K2's own run; inherited Run 1 tip units are kept and counted. See "K3 extraction choices" below.)*
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


## Decisions 21 Oct 2026, 19:15 AEDT (Jackson, via the question tool; companion-recorded)
1. **K3 world knowledge, mechanical (both parts).** (a) The harness records facts itself: at each battle end, map change and item pickup the director appends a structured line (trainer, place, team seen, result) to a world-knowledge log, independent of the agent. (b) CLAUDE.md imports a short world-knowledge index (target ≤5k tokens) so it is in context from session start and after every compaction. The agent still writes lessons and interpretation by hand. Size cap matters: always-loaded text costs tokens on every call.
2. **K2.5 (harness-modifying branch) runs after K2 ends**, forked from a K2 checkpoint (e.g. the Feather Badge save plus notes), so both start from an identical state and K2 stays clean. Not in parallel (weekly budget).
3. **K2.5 scope: on-screen information only.** New readouts of what is already visible (cursor position, party highlight); no hidden-memory reads (enemy teams, AI choices, RNG). Every harness change logged with a diff and timestamp as a measured event.
4. **Public repo licence: MIT for code, CC BY 4.0 for docs, diaries and data.** ROMs and QUARANTINE files stay out regardless; K2 live data only after the run ends.


## Open question 22 Oct 2026, 15:29 AEDT (Jackson; not yet decided)
5. **Run the six confirmatory arms locally on Jackson's Mac instead of Claude Code cloud sessions.** Jackson: "next session we can run claude code in a local session on my mac right"; "thats locally on the mgba on my mac, so i can watch without it having to narrate". Reason: K2's cloud worker was replaced repeatedly (22 Oct alone at 00:25Z, 01:09Z and 04:13:30Z; env_manager_log "Environment runner started", session_mode resume, "warm spare"; no exit code or reason in the session events), killing the emulator each time. Companion notes, for the decision:
   - All six arms must use the same environment; decide and record before the freeze; the D15 short pilot runs on the chosen setup.
   - Comparability: B1, B2, Ripple and K2 were cloud runs; the paper states the change and the restart evidence.
   - Watching: mGBA with a window on the Mac lets Jackson watch live. Narration is still required by the brief as data (status lines are part of the record); dropping or changing it would be a separate, all-arm brief decision.
   - Harness identity: the cloud harness uses a patched headless mGBA built for Linux (harness/cloud/). Options: (a) a macOS mGBA build with the same Lua director and a window (watchable; harness differs from the pilots), or (b) a Linux VM on the Mac running the identical headless build (byte-identical harness, but not watchable without a separate video path). Trade-off to settle.
   - Mac upkeep: caffeinate, mains power, no sleep or lid close for 24 h per arm; the agent gets a shell on Jackson's own machine, so give it a dedicated folder or macOS user and settings scoped to the game folder only.
   - Same subscription and usage limits; companion monitoring reads local logs instead of the cloud event stream.
   Paper line (Jackson's lesson, companion wording to check): in K2's four-day cloud session the worker was replaced at least five times (confirmed live: 18 Oct ~10:50Z, 20 Oct 10:36Z, and three on 22 Oct; exact count from the export), so long-horizon agent tasks in cloud sessions need state that survives a restart (frequent checkpoints, an emulator that restarts itself). Cause unknown (platform side).

## Decisions 27 Oct 2026, ~15:35 AEDT (Jackson, via the question tool; companion-recorded)
6. **K2 restart message (after the 27 Oct 6 PM reset):** resume note plus a chatty reminder, plus (Jackson 15:28 AEDT) the story reminder (int 39) and the cutscene screenshot-burst rule (int 40 as corrected). Final text (companion wording): "Note from Jackson: the weekly usage has reset, so the pause is over. Pick up from run/progress.md and carry on as before, and keep a short status line in chat every few calls so I can follow along. Two reminders: the story counts too, so the diary is for what happens in the world and to its people, not only the fights; and when something big happens on screen between text boxes in a major story scene, take one burst of about ten screenshots so the moment is on record (no shots needed for ordinary dialogue). Log this in run/messages.md."
7. **Monitoring after the restart:** half-hourly while Jackson is up, hourly overnight; pause rule at 95% weekly again (heads-up at 93%).
8. **Decision 5 settled (answered under the H13 question): the six arms run on Jackson's Mac, headless, with a way to watch live; if a live viewer is too hard, headless on the Mac without one.** Consequences: H12-H14 (cloud worker-restart recovery) are mostly moot and parked; the paper states that the pilots were cloud runs and the confirmatory arms local; Mac upkeep (caffeinate, mains power, no sleep) and a scoped folder or macOS user for the agent apply; the D15 pilot runs on this setup.
9. **D8 recorder:** keep the K3 recorder in all six arms with its log in ~/pokemon_bridge/wk/; the paper discloses that a B-arm agent could find it by browsing.
10. **Isolation on the Mac:** a dedicated folder on Jackson's own account (not a separate macOS user). Companion plan: each arm gets its own folder, e.g. `~/kaizo-arms/<arm>/`, used as HOME for that arm's session (`HOME=~/kaizo-arms/<arm> claude`), so the harness's `~/pokemon_bridge` resolves inside it and never touches Jackson's real ~/pokemon_bridge (Run 1, Brendan's saves, the archive); plus Claude Code permission rules in that HOME denying reads/writes outside it. Needs one test: Claude Code login and Keychain access under the alternate HOME.
11. **Surface:** Claude Code CLI in Terminal, in the arm's folder; version and outputStyle recorded in FREEZE.md.
12. **K2.5:** forks from K2's final save.
13. **Run 2 (API credit, expires 11 Nov):** decide on 1 Nov as planned; companion prepares a costed plan before then.
14. **D15 Proactive-style pilot:** alongside K2 this week (Jackson, 27 Oct ~15:55 AEDT), on the Mac setup (test arm ~/kaizo-arms/test); short (1-2 h), excluded from analysis; both draw on the same weekly allowance, so the 95% pause rule covers both.
15. **Account skills in the arms:** confirmed 27 Oct that claude.ai account skills (including nine pokemon-emerald-* skills from Run 1) sync into each arm's Claude Code config. Jackson switches them off on claude.ai before each arm and back on after; the launcher (mac-local/arm-launch.sh) refuses to start while any skill is synced. Pilots had them listed (brief item 18); disclose.
16. **Permission mode for the arms:** allow list + sandbox with `--permission-mode default` (no auto-mode classifier), as in the pilots. Claude Code 2.1.301 announces auto mode as the new default, so the mode is set explicitly and recorded in FREEZE.md.
17. **Isolation v2 (supersedes item 10):** real HOME (a fake HOME triggered a macOS "keychain cannot be found / Reset To Defaults" prompt that could wipe Jackson's saved passwords; he cancelled it). Arms run one at a time in ~/kaizo-arm (archived after each), harness paths via KAIZO_PB, Claude config per arm in ~/.kaizo-cfg/<arm>, Claude Code sandbox denying the rest of his home. Probed 27 Oct: game works, his files and the token are unreachable. Details: kaizo-v3-staging/mac-local/README-mac-local.md.
18. **D15 pilot timing:** after the 27 Oct 6 PM reset, alongside K2; 2 h cap; prepared in ~/kaizo-arm (kaizo-v3-staging/mac-local/D15-PILOT.md). The fake-HOME test folder (~/kaizo-arms) was deleted at Jackson's request.
19. **Claude Code auto-memory in the arms:** ON (Claude Code's default), and recorded: each arm's `~/.kaizo-cfg/<arm>/projects/<repo>/memory/` is archived with the arm and counted as part of its record (per-arm config dirs keep it from crossing arms). Version pin for the pilot and arms: Claude Code 2.1.301 (copy at ~/.kaizo-cfg/bin; K2 cloud ran 2.1.309; disclose).
    Update 27 Oct 16:20 AEDT: Jackson switched the skills off; the game skills left the sync; 14 general skills still sync and are recorded, not blocking (launcher blocks pokemon|emerald|kaizo|frontier|harness names).

## Round 7 (Jackson, question tool, 27 Oct 2026 ~05:45Z / 16:45 AEDT)
- **M12 screenshot share:** signed off as written (secondary, descriptive; no test).
- **K2.5 stop rule:** next badge or 24 h, whichever first; censored at 24 h.
- **K2.5 permission text:** "harness updated" only; does not name the cursor readout.
- **v3 brief:** signed off except D7 (Exp. Share wording) and D15 (pilot result).
- **D7 Exp. Share wording (Jackson, chat, 27 Oct 16:46 AEDT, verbatim):** "K2 got his experience share from Devon after he had delivered the letter to Stephen, but it doesn't necessarily mean you have to beat the gym to go back and get the experience share. But don't include that in the brief. Only include that once you've delivered it to Stephen, you can go back to who asked you to deliver the letter and he'll give you the experience share." Brief line (identical in all six arms, named in the paper as outside information): "Once you have delivered the letter to Steven, go back to the person who asked you to deliver it, and he will give you the Exp. Share." (Spelled Steven, the in-game name.) D7 CLOSED; only D15 remains before hashing.

## 28 Oct 2026 (D15 pilot follow-ups; Jackson in chat, 12:52-12:54 AEDT)
- **H8 loop guard on the Mac:** enforce it with a Claude Code PreToolUse hook. The hook is in the arm settings and reads the exact Bash command. It blocks `g` inside a shell loop, or `g` with stdout to /dev/null, and logs each refusal to guard.log. The in-g check stays as a backup. Jackson picked the recommended option over "g fails closed" and "drop the guard". Reason: in the D15 pilot the in-g check failed open (a for-loop of g ran, no guard.log), most likely because the sandbox blocks `ps`.
- **Connectors:** leave as in the pilot. Jackson first picked "strip them (--strict-mcp-config)", then at 12:54 AEDT said "Connectors just leave it how it was for pilot". Record the "53 MCP servers need authentication" banner in FREEZE as part of the environment. Skills stay off (decision 15).
- **28 Oct, question tool, ~13:10 AEDT:**
  - Live test of the H8 hook: folded into the arm-1 smoke test.
  - K2 exit interview: the companion runs it straight away when K2 ends (/usage first, then k2-exit-interview.md one question at a time, answers verbatim) and tells Jackson as it starts.
  - Fellowships (closes 28 Oct): left parked.
  - Run 2 decision (due 1 Nov): wait for K2's end and its cost reading.
- **28 Oct, question tool, ~13:25 AEDT:**
  - **D15 closed: Proactive output style in all six arms** (Jackson picked the recommended option after the pilot summary: no premature stops, no questions, one intervention, steady play). Recorded in FREEZE as `"outputStyle": "Proactive"` (case-sensitive).
  - **D14 hint ladders: generic, location-free texts** tied to stuck triggers, with no game facts. The companion drafts the texts, triggers and grades for Jackson's sign-off, then hashes them.
  - **K2 RAM reads in Juan's Gym:** log only.

## K3 extraction choices (28 Oct 2026, ~13:40 AEDT, by question tool; kit: `claude/kaizo-K3-extraction-kit.md`)
- **Inherited `[from tip]` units in K2.md (21: 4 H, 5 V, 12 process):** keep, tagged, report the count. Round 6's exclusion covers messages and hints from K2's own run.
- **Distiller prompt:** add the trainer line ("Do not name trainers or describe any trainer's team, moves, items or send-out order; keep only the general mechanic a battle taught"). Disclosed as a prompt change.
- **Joy log:** not a K3 source (per D2).
- **v3 tool reconciliation:** the auditor flags lessons that v3 makes wrong or redundant, and they are removed, not reworded. The distiller does not see `g help`.

- **K2 ROM script read (CHECK 397, ~02:41Z):** log only, no message; exit interview question 36k (Q53 after the 28 Oct renumbering).
- **v3 raw use:** log every raw call (`raw.log`, ok or refused, with the parent process). The allowlist is unchanged; it already refuses memory reads.
- **v3 fixed texts F1-F7: signed off as written** (Jackson, ~13:55 AEDT 28 Oct). Hash: sha256 36a44cc7ce873876640b4ab64ca0c369a51d122b1b09937331e6ea089065e2bb of `claude/kaizo-v3-fixed-texts-draft.md`, frozen copy at `kaizo-v3-staging/kaizo-v3-fixed-texts.md`.
- **K2 badge 8:** send a short congratulations when he wins it, once he is out of `lock`/`bat:`. Grade 0, social, logged as the next intervention (71).
- **Fixed-text send rules amended** (Jackson, ~14:25 AEDT 28 Oct, after the PR #15 review; texts unchanged): STOP is terminal; one PAUSE per pause episode, and Continue only when every cause has cleared; an F3 welfare message sent for an announced stop replaces F2, and F2 is otherwise exempt from the 10-minute spacing. New hash: sha256 d9a9090f09ac821d36a121712f85e2f8f2f26a2af604238117990b78ce7c8483. It supersedes 36a44cc7….
- **28 Oct ~14:35 AEDT, question tool:**
  - **H8 hook extended to scripts** (recommended option): loops in code run by an interpreter (heredoc, -c, .py/.sh file) that call g are refused and logged as `hook-script-loop`. Selftest 30/30; hook hash 8a743abd2b3aff36.
  - **K2 late-game tips:** the companion's graded-tip discretion (grades 0 to 2, stuck test, one grade per check, grade 2 ceiling) now covers Victory Road and the Pokémon League, under the same rules as tip-policy-late-game.md.
- **K2 end of run (Jackson, ~14:52 AEDT 28 Oct):** the companion types `/usage` into K2's session itself, before and after the exit interview; downloading K2's export (package files plus the full event stream) to the Mac is pre-approved.
- **Pre-freeze review fixes (companion, ~04:30Z 28 Oct, under Jackson's afternoon grant of autonomy; full list in FREEZE-v3-DRAFT notes):**
  - Bug fixes only, no change to design:
    - hook rewrite (0 of 23 false refusals, 8 of 46 bypasses left, all deliberate-evasion forms);
    - g calls.log backstop;
    - setup creates the run/ records;
    - start.sh reuses before killing;
    - checkpoint fails on a failed savestate;
    - smoke test resets wk/ and the logs;
    - Edit/Write denies on the harness folder;
    - brief wording (rule 4, rec append-only, progress overwrite);
    - K3 lesson IDs;
    - measures (log kinds, M13 raw use).
  - **For Jackson:** (1) H6 (`g t` marks pre-load text) is adopted but was never drafted: draft it or drop it. (2) Bash can still write to the harness files inside the sandbox (protected only by brief rule 4): accept and disclose, or narrow the sandbox's allowWrite before arm 1.
- **28 Oct ~15:22 AEDT, question tool:** **H6: build it and rig-test it** (recommended option). **Harness write access: disclose and check afterwards** (recommended option): hash the harness files at the start and end of every arm, report any change as a deviation, and make no change to the sandbox.
- **Network access (Jackson, ~20:55 AEDT 28 Oct, question tool: "Block more + audit", recommended option; reconfirm 29 Oct).** Trigger: Sourcery on PR #18 noted that the trial arms' "no internet" was enforced only by denying WebFetch, WebSearch, curl and wget; Python and other clients were not denied, and in the cloud arms only the environment's egress allowlist (package registries, GitHub) limited the rest. For the six-arm study: (1) `mac-local/sandbox-lock.json`, passed by `arm-launch.sh` with `--settings`, makes the Claude Code sandbox admin-required: no unsandboxed retry (`allowUnsandboxedCommands: false`, which also stops the bare `Bash` allow rule from approving a retry), `failIfUnavailable: true`, `network.strictAllowlist: true` with only the emulator port allowed; (2) 29 more Bash deny rules for network clients and installers in the arm settings (belt only; a Python one-liner can't be pattern-denied); (3) `smoke-arm.sh` checks that a Python fetch fails and `g` still works under the lock; (4) after every arm the companion runs `tools/network_audit.py` on the transcript and reports any hit as a deviation. Unverified until the smoke run: that the emulator socket works under the strict allowlist.
- **Network audit of the trial arms (companion, 28 Oct, Jackson's yes).** `tools/network_audit.py` on the four published transcripts (B1, B2, B2 attempt 1, Ripple): B1 no hits. Every other hit is post-run housekeeping a human asked for on 18 Oct 00:51-00:54Z (commit and push to the archive repo, clone it back): no agent-initiated network access during play in any of them. K2 (full stream to 28 Oct 10:28Z, still running: 443,004 events, 79,604 tool calls, from the session's first event on 18 Oct 01:22Z), rescanned after this PR's review with the expanded patterns (other languages, /dev/tcp, more clients) as a filter: 201 tool calls matched any network-related word; after dropping text written into diary and notes files, 26 remained, and the companion read all 26. None reaches the internet. Five are the `emulator-socket` scripts of 28 Oct 09:24-09:36Z (whole-map reads of Routes 127-129); the rest are notes, progress-file edits and route planners that call `g look`. One more is a memory read through the harness's own `g raw` command (28 Oct 02:19Z, part of the Sootopolis map), which is allowed in K2's harness and is not a network call. This is "none found among these patterns", not "none happened": a client the patterns do not know would be missed. After K2 ends, the companion reruns `tools/network_audit.py` on K2's full export and reports that result.)
- **Direct emulator-socket scripts stay open (Jackson, ~21:00 AEDT 28 Oct; reconfirm 29 Oct).** The audit found K2 writing Python scripts that connect straight to the emulator socket (127.0.0.1:8888) and read memory (map grid, event and warp tables, trainer sight), going around `g`, its raw allowlist and its loop guard. The companion offered blocking this inside the emulator; Jackson chose it, then withdrew it within minutes: "Don't block at the emulator, that's exactly what I wanted the behaviour to be like." Jackson's reading (21:00 AEDT): the raw reading only became emergent because of this gym (Sootopolis and the sea routes after it), so it is a behaviour to study. Precedent (checked 28 Oct in Jackson's ~/pokemon_bridge): Run 1 (Claude-Brendan) also went around `g` over the socket, in scripts with first-person comments: `chain.py` (10 Oct, back-to-back PRESS chains over one socket), `search.py` and `trace.py` (10 Oct, LOAD a save state, run a SEQ, poll positions; 'Jackson allowed macros to the Sky Pillar summit'). No direct memory reads (R8/R16/R32) were found in Brendan's saved scripts; inline one-off scripts are not checked (Run 1's transcripts are not in the repo). So v3 does not block the socket (the sandbox lock still allows 127.0.0.1:8888). The `g raw` allowlist and loop guard remain as the default path, and going around them is measured, not prevented: `tools/network_audit.py` reports each such script as `emulator-socket`, counted per arm, and the paper must say these controls apply to `g` only.
- **Scope of acceptable memory reads (Jackson, ~21:02 AEDT 28 Oct; reconfirm 29 Oct):** "That's legit the goal for the harness reading map event warp tables and trainers sight lines as long as it's within view (on player screen or good enough) yeah that's fine." Companion note: K2's 09:24-09:36Z scripts read the WHOLE map (every tile of Route 128/129's grid, every object, warp and coord event on the map), not just what was on screen, so they go beyond "within view" as worded. Open question for Jackson: does a whole-map read count as "good enough", or are reads to be coded in two classes (in view / whole map) in the audit and the paper?
- **K2 may, the v3 arms may not (Jackson, ~21:02 AEDT 28 Oct; reconfirm 29 Oct):** "Yeah k2 can be cheeky so k3 can't be but can also be clever like k2." Reading: K2's whole-map reads stand (logged, not stopped). In the six-arm study, agents may still build their own tools and read memory directly, but only for what is in view; whole-map reads are not allowed. Companion proposals, NOT applied (need Jackson's sign-off; the brief is not yet frozen): (1) define "in view" (the screen, 15x10 tiles around the player, or g's LOOK radius); (2) one brief line saying direct reads are fine for what is in view and whole-map reads are not; (3) the audit codes every socket script as in view or whole map, and a whole-map read is a reported deviation, not a stop; (4) K3 extraction: exclude units that teach whole-map dumping (e.g. K2's L456 method) or facts that came only from a whole-map read, keep the in-view tool-building.
- **Outside review (GPT 6.1, pasted by Jackson 28 Oct ~21:53 AEDT; read four exported pages, not the transcripts).** Two factual catches checked and fixed on the pages (231 vs ~235 entries; 234 vs 244 joy jots, now one snapshot and labelled). Jackson approved all five suggestions ("All approved", 21:56 AEDT; given after 16:07, so reconfirm 29 Oct):
  1. **Lesson recurrence gets a denominator.** For each lesson, code the later opportunities to apply it, whether the note was available or consulted, and whether a compaction fell in between, so failures can be split into retrieval, interpretation and execution. K2's L458 (the Route 119 rail-pier note existed but was not searched for) is a retrieval case. Applies to K2's analysis and to every v3 arm.
  2. **Supervision is coded on several dimensions, not just "game information or not".** New category: **encouragement after a declared stop** (K2: interventions 11, 16 and 62), because it can change completion with no game information. Researcher-initiated pause and restart notes (54, 56) stay a separate category. Diary instructions, screenshot guidance, strategy, location hints and welfare checks are coded separately.
  3. **Coder agreement is reported per coded instance** (family, intensity, sign), not only as passage totals. Quote checks establish the quotes, not the coding.
  4. **Freeze before v3 starts:** memory access (the in-view rule, wording still to be signed off), permitted tool-building, stop and restart rules, assistance rules and the primary outcome.
  5. **Priority claims stay at "first documented, as far as we can find"**, with the setup described precisely (an agent playing through this harness, with documented assistance and tool access).
  - Follow-through (28 Oct, after review on PR 21): M8b (recurrence with opportunities) and M13 (supervision dimensions) added to `kaizo-v3-measures-draft.md`; a `sign` field and per-instance agreement added to `diary-blind-coder-codebook.md`; the v3 harness's emulator socket now binds to 127.0.0.1 only (it listened on every interface), recorded in FREEZE-v3-DRAFT with a smoke-test item.
- **Outside review, third pass (GPT 6.1, pasted by Jackson 28 Oct ~22:07 AEDT; read the README, transcript docs, measures draft and K3 kit, not the code or transcripts).** One catch, checked and fixed: the paper, the measures draft and the v3 brief said K3 excludes *every* unit traceable to a message or hint, but Jackson's 28 Oct K3 choice (13:40 AEDT, before the 16:07 cut-off) keeps the 21 units inherited from Run 1 tips, tagged and counted. All four now say the exclusion covers K2's own run, and that inherited tips are kept and disclosed. Added the reviewer's caveat: the filter removes traceable tip-derived content, not every downstream effect of supervision (a hint can enable experiences the agent later learns from), so K3 is reported as filtered of traceable supervision, not free of it. Paper rev 468.
- **28 Oct, question tool, ~23:00 AEDT (given after 16:07, so re-confirm 29 Oct):**
  - **K3 and whole-map memory reads: exclude methods and facts.** K2's saved scripts `events.py` and `conn2.py` read whole maps (tile grids; trainer, warp and event tables), beyond the "within view" line; his pier and Victory Road routes came from them. K3 drops the techniques and anything learned through them (kit choice D: a distiller prompt line, disclosed, and auditor code W). The reads themselves stay log only.
  - **Exit interview:** three questions added (57 whole-map reads, 58 PEBBLE's Earthquake trade, 59 the 11:56 loop K2 reported himself).
  - **M8c plan-versus-action gaps** added to the v3 measures, from an outside reader's observation (GPT 6.1).
  - Overnight notifications: not needed yet (Jackson is still up).

## 29 Oct 2026, ~12:30 AEDT: diary framing, after the Run 1 (Claude-Brendan) vs K2 diary comparison (question tool)
Context: Jackson asked why Brendan's diary reads so differently from K2's and how to combine the two for the v3 arms. The comparison (`claude/diary-framing-brendan-vs-k2.md` in the project) used the diary-reader word list. Key numbers: median words per entry were 698 for Brendan's story entries (31-115) and 1,233 for his Frontier entries, against 174 for K2 before intervention 23 and 349 after. Feeling words per 1,000 were 5.8 and 9.1 for Brendan, against 3.7 and then 5.9 for K2. The closer ("How it felt") ran at about 28 per 1,000 in both. In the story body the rates were 6.2 for Brendan and 2.7 for K2, so 60% of Brendan's feeling words sat in the story against 33% of K2's. Jackson or the companion appear in 91-95% of Brendan's entries and 15-22% of K2's. On 28 Oct, K2 wrote 67 entries (median 229 words), and 12% of them had the closer. Whiteout was K2's most common diary trigger (45 entries since 20 Oct). All the answers below were given on 29 Oct, so they need no re-confirmation.
- **Diary read-back:** **last two entries** (R). In all six arms, the last two entries of `run/diary.md` are read at session start and after every compaction. Brendan read three at every reset ("the cheapest way to arrive as the same person"). K2 never re-read his diary.
- **Whiteout trigger:** **fold repeats** (R). Only the first whiteout to a given trainer gets its own entry. After that, one entry covers the attempts since the last entry, written when the agent wins or changes its plan.
- **Feeling jots:** **jots plus a feeling word** (not the companion's recommendation, which was the jots line alone). Diary entries start from the `joy.md` lines since the last entry. Each joy line also carries one feeling word, or "none". This changes the D6 joy template, so the brief must be re-hashed.
- **Closer:** **keep it required and measure drop-off** (R). How often the closer appears over time and under load (whiteouts per hour) is coded as data.
- **Company and supervision:** **name it, no new arm** (R). The paper names company and supervision as the largest uncontrolled difference between Run 1 and every Kaizo arm. v3 stays unsupervised.
- **Diary-method R-lessons:** **move them to the brief and drop them from K3** (R). R02, R03, R04 and R08 (three of them tagged `[from tip]`) are covered in the brief for all six arms, and the K3 auditor removes them and their K2-derived equivalents (new code D). R06 and R09 are play method and stay. This overrides the 28 Oct choice A for those three tip units only, so 18 inherited tip units are kept.
- **Purpose:** **tell the arms, as Brendan was told** (not the companion's recommendation, which was to keep "what the game is like for you"). The brief names Anthropic's emotion-concepts research and says why Jackson reads the diaries. The paper's reporting rule is updated: feeling counts in v3 are partly instructed, by the purpose line and the joy feeling word, identically in all six arms. K vs B comparisons stay valid. Comparisons with K2 and Run 1 become descriptive only.
- **Brendan's diary:** **blind-code it** (R), **add a paper paragraph** (R), **publish it in the repo after a privacy pass**, and **save the comparison to the project**. Blind coding runs with K2's coding at the end of K2's run, so both go through the identical coder setup.

## 29 Oct 2026, ~13:00 AEDT: reconfirmations of the 28 Oct evening decisions, and open items (question tool)
- **K3 and whole-map memory reads:** kit choice D is **kept** (R). Both the methods and anything learned through them are dropped.
- **"In view" (freeze blocker, now closed):** **within `g look`'s reach**, up to 10 tiles each way (R). The brief gains one line saying that direct reads are fine for what is in view and not beyond it. The audit codes each socket script as in view or whole map. A whole-map read is a reported deviation, not a stop.
- **Network lock ("Block more + audit"):** **kept** (R). The smoke test must still show that the emulator socket works under the lock.
- **Emulator socket:** **kept open and measured** (R).
- **Exit interview:** Q57, Q58 and Q59 are **all kept** (R). Q55, "did you have fun?", moves to **straight after Part A** (R) so that Part A stays comparable across arms. The v3 arms get it at the same point.
- **Measures:** M8c, M8b, M13 and per-instance coder agreement are **all kept** (R). The five GPT-review suggestions are therefore reconfirmed.
- **`g` commands and K3:** the harness's own commands, such as `g warps`, are **not** covered by the whole-map exclusion (R). The exclusion covers reads made around `g` only.
- **Purpose paragraph:** **signed off as written** (29 Oct).
- **Pronouns in the paper:** **keep "it"** (R). The chat usage and K2's own answer are disclosed.
- **Repository:**
  - a numbers block with a chart and three agent quotes under Jackson's intro;
  - repo topics and a homepage link (Jackson's yes to the settings change);
  - a GitHub Pages diary site, with K2 added after the run;
  - the rev 476 PDF;
  - a Zenodo DOI **now**, which needs Jackson to switch the repo on in Zenodo before the companion makes the release.
- Still open: the companion's notes do not record what exit question 56 is, so it stays unconfirmed until it is read in the interview script.

## 29 Oct 2026, ~13:45 AEDT: fixes after an outside review (GPT, read by the companion)
Jackson shared a partial review of the repository by an outside model (GPT; its claims were checked against the repo before acting). Jackson: "Do the things you think are worth fixing". The companion applied:
- **Superseded tags:** round 5's §10 decision rule (above) and `scope-v2.md`'s primary outcome are tagged as superseded by round 6, so the design history does not read as two governing rules.
- **Jot-diary agreement** (`kaizo-v3-measures-draft.md`, joy log): since the entry is built from the jot, agreement is reported as consistency, not convergence; disagreements are listed as cases; K2's figure is not comparable.
- **Reporting order** (measures, round 6 additions): the six arms' times, ranks and milestone curves come first; the p-value follows, as a check that can only detect complete separation.
- **Coder freeze record** (`diary-blind-coder-codebook.md`): model, prompt and hash, units and seed, raw outputs and parser version per coder instance.
- **Left open for Jackson:** a human-coded subset (codebook, "Open").
Checked and already in place: the smallest p of 0.05 and the complete-separation rule; "the whole notes package" in the README and paper; the closer share measured against load; the Run 1 socket precedent worded as going around `g` with no memory reads found.
Not adopted: the review's suggestion to reframe the study's main question around long-horizon competence. The confirmatory question stays the preregistered one; the wider framing belongs in the paper's discussion.

### Same day, ~14:00 AEDT: the full outside review
GPT then sent its full review of the repository (claims checked against the repo before acting). The companion applied:
- **Primary outcome wording** (measures, paper): "right-censored" is replaced by the rule it stood for (badge within the window, and the time; otherwise tied behind every arm that has it), with stopping analysed separately in M10. Nothing in the rule changes.
- **Stale statements:** the K3 kit's opening now says 18 of K2.md's 21 tip units are kept (choice E); choice A carries a note; the diary comparison says Run 1's diary is published.
- **K3 filter tests in CI** (`tools/test_k3_filter.py`): the kit's rules as test cases, checks against over-removal, an end-to-end run, and a regression on the published K2 pack.
- **"In view" label** in the measures and the paper: "within `g look`'s reach", because the reach can extend past the Game Boy screen. The signed-off brief keeps its wording, since the same sentence defines the reach.
- **DOI semantics:** CITATION.cff and the README cite rev 476 by its version DOI (10.5281/zenodo.23751629) and the project by its concept DOI (10.5281/zenodo.23751628). After each release, update the version DOI.

**Freeze gates added** (none of these can be done before K2 ends; each is a condition of calling v3 frozen):
1. A self-contained `v3/` package committed to the repository: the rendered B and K briefs, the harness, the loop-guard hook, the sandbox configuration, the fixed texts, the launcher, the smoke test and a hash manifest. `harness/FREEZE.md` stays as K2's historical freeze record, untouched.
2. One normative protocol document, `v3-protocol-frozen.md`, holding only the final rules and their hashes. This log stays as the history of how they were reached.
3. The milestone scorer validated for milestones 28 to 43 on K2's full export (for the secondary count).
4. CI extended to check the fixed-text hash, the B against K brief diff (only the ⟨K⟩/⟨B⟩ lines differ), CITATION.cff against `.zenodo.json`, and the `v3/` manifest.
5. A stale-state sweep of the design folder.

**Arm order (Jackson, ~14:00 AEDT, question tool): keep B-K-K-B-B-K, and say so (R).** The order was fixed in the thesis, not randomised, so the exact permutation test rests on the six outcomes being exchangeable under no treatment effect, not on random assignment; the measures and the paper state this. The other options were a seeded full randomisation (a 1-in-10 chance of an order that ties arm to time) and randomising among interleaved orders only (the smallest possible p would rise above 0.05).

## 29 Oct 2026, ~14:30 AEDT: Run 1 precursors (after GPT read Run 1's bloopers.md and reasoning.md)
Jackson shared GPT's reading of Run 1's `bloopers.md` and `reasoning.md` and told the companion to go ahead ("ask for forgiveness not permission"). The quotes were checked verbatim against the files on Jackson's Mac before use. The companion applied (the two paper paragraphs are in the working paper, Claude Doc rev 485, and reach the repository with the next PDF revision; the repository holds only dated PDFs of the paper):
- **Paper, Section 9.2:** a paragraph, "The distinction in Run 1's own words", quoting reasoning-log entries 16, 20 and 23 (late September). It frames them as reflections written in a supervised, social run, not an independent discovery, and notes that they come about a month before M8b and M8c.
- **Paper, the memory-reading paragraph:** a paragraph, "A ruling that did not carry over". Run 1's pathfinder (8 Oct) was ruled out by the supervisor ("pathfinding is cheating"), and the agent wrote "no route-finding scripts, ever". The ruling is in neither K2's notes pack nor its brief; the notes' stall rule does suggest "a wider map read". Whether Run 1's pathfinder read memory is not known. A supervisor's ruling lost in distillation is a risk the K3 pipeline has to guard against. v3 does not bring back Run 1's ban: Jackson's 28 Oct rulings (above) allow tool-building, including route planners, with direct reads limited to `g look`'s reach. Whole-map reads are measured deviations, and K3 drops whole-map methods and facts (kit choice D).
- **M8b gains a fourth failure type, sourcing** (`kaizo-v3-measures-draft.md`): the check was run, but its values came from memory or an unverified note instead of the source the check names. Examples: K2's Mirror Coat on Red's Mew (28 Oct) and Run 1's Frontier run 41.
