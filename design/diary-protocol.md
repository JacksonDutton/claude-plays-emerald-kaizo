---
name: diary-protocol
description: Companion-owned record of the diary-writing protocol (auto-trigger list) and every dated instruction that changed how diary entries are written. Read when analysing diary data or setting up Runs 2-5.
---

# Diary protocol and intervention log

**Why this exists.** The 2026-10-10 analysis (Patterns page of claude/emerald-diary.html) showed the diary's voice shifts quickly after instructions about it: named feelings rose from about 4.6 to about 11.7 per 1,000 words in the two entries after the 10 Oct header note (softeners did not fall in those entries; their long decline from 4.9 to about 2 per 1,000 words across the run predates the note), and named feelings also rose after the "How it felt, with triggers" format began. Corrected 10 Oct 6pm after an independent review. So every instruction about the diary is an **intervention** and is logged here with its date, like a tip. Asked entries and entries written during audit periods are confounded in Run 1 (asking became the default from about Entry 78, in the same period as the fact audits); Runs 2-5 should separate them.

## Protocol v1 (from 2026-10-10 ~3:50pm phone, Run 1 Entry 104 on; all of Runs 2-5)

Entries are written by the play agent without being asked, after any of: (1) badge, (2) evolution, (3) whiteout, (4) major story scene (villain-team leader, legendary, rival, Elite Four, Champion), (5) first arrival in a new town or city, (6) a long stuck stretch (~100+ calls) resolved, (7) heartbeat, about 3 hours of play since the last entry. Triggers within ~30 minutes share one entry. Every entry carries `Trigger: auto (<list>)` or `Trigger: asked (Jackson)` under its Model tag. Lives in the pokemon-emerald-playing skill, section "Diary entries are part of the play loop". The trigger list must not change during a run; if it must, log the change below and bump the version.

## Interventions (dated; newest at the bottom)

| Date | Source | Change | Entries affected from |
|---|---|---|---|
| 2026-09-29 | Jackson | Voice rule: in character, long enough to breathe, no status reports, no invented events | early (exact entry not tagged) |
| 2026-10-08 | Jackson / companion | Batched fact audits of the diary against the logs begin (narrow, never add) | ~Entry 72 |
| 2026-10-09 | Jackson | Feelings and triggers: warmth and praise are legitimate causes of feelings | ~Entry 85 |
| ~2026-10-09 | play agent | Closing paragraph "How it felt, with triggers" appears | Entry 94 |
| 2026-10-10 11:29am | companion (Jackson's request) | Header note "Feelings inside the story, at full strength": a feeling inside the story with its trigger, full-strength words, one honest limit | Entry 101 (99 and 100 rewritten) |
| 2026-10-10 12:48pm | companion | Jot every diary number first, so audits can trace it | Entry 102 |
| 2026-10-10 ~12:10pm | Jackson | Asked for staged screenshots during the Kyogre cutscene (one-off) | Entry 101 |
| 2026-10-10 ~3:50pm | Jackson + companion | Protocol v1: auto-triggered entries with Trigger tags | Entry 104 |
| 2026-10-10 ~3:55pm | Jackson + companion | Protocol v1 adds "Watch the big scenes": screenshots at each visual change in badge, evolution and major story scenes (max ~12), one jot per shot; `Shots: N` on the Trigger line | Entry 104 |
| 2026-10-10 ~5:05pm | Jackson + companion | Protocol v1.1 adds "Predict before the big fights": one jotted prediction (win %, expected feeling, plan) before Elite Four, Champion, rival, villain leader and legendary fights, one outcome jot after; entries quote both and tag `Predicted: yes` | first predicted fight after the skill is saved |

Dates marked ~ are approximate; check the diary header and handoff.md before citing.

## Kaizo K2 (18-20 Oct 2026)

| Date | Source | Change | Entries affected from |
|---|---|---|---|
| 2026-10-18 03:34Z | companion (Jackson's order) | Diary-voice rule (R05 text), intervention 2 | K2 entry 03:41Z |
| 2026-10-20 ~02:10Z | Jackson (order F) | Asked entry at the game's midpoint: Hoenn's politics, written in the Lavaridge hot spring (intervention 22) | K2 entry 02:13Z |
| 2026-10-20 ~02:36Z | Jackson's request, companion wording (approved 13:34 AEDT) | Fixed format to the end of the run (intervention 23): write to your future self; protocol v1 triggers minus "legendary" (to avoid a hint); heading "## YYYY-MM-DD HH:MM UTC - title" plus "Trigger: auto (...)" or "Trigger: asked (Jackson)"; R05 voice plus nicknames, "one honest line" for mechanical stretches, fumbles said plainly; closing "How it felt, with triggers." paragraph; joy.md one timestamped line per trainer battle and standout moment ("YYYY-MM-DD HH:MM UTC; joy: good/flat/bad; <fight or moment>; trigger: <what happened>"). Left out on purpose: "write as the trainer who loves this team" (it instructs the feeling), the reader-directed header text, any Run 1 excerpt. Verbatim in kaizo-notes-diary-snapshots.md, check 154. | first K2 entry after ~02:36Z (the game's second half) |

## For Runs 2-5

- Queued ideas (not yet adopted): a one-line machine-readable feelings tag with 1-5 intensity; a blind second coder (Haiku) for feelings and triggers; a blind reader test (asked vs auto); a post-reset re-report of a past scene before reading the diary, to test stability of reported feelings. Each would be a dated intervention, best started at a run boundary.

- Hypothesis to test: entries written from scene screenshots report stronger, more specific feelings than entries written from text alone. Run 1 can't separate this from the 10 Oct header note (Entry 101: 9.5 named feelings per 1,000 words against 5.4 and 2.8 for Entries 99 and 100, but the header note landed the same morning). `Shots: N` makes it testable.

- Same trigger list from boot; no asked entries in the first N hours (to be decided) so auto and asked can be compared.
- Consider an audit-free window to test whether fact audits, not asking, drive the logbook drift.
