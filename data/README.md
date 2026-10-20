# Data

## `pilots/`

The run records each finished Kaizo pilot wrote for itself, as exported at the end of the run (`run/` in its repository). Savestates and the in-game save are left out.

| File | What it is |
|---|---|
| `diary.md` | The agent's diary: entries it wrote after set triggers (badge, whiteout, major scene and so on), including how it felt and why. The main qualitative record. |
| `progress.md` | Running state the agent kept for itself: start and current time, location, badges, party, items, trainers beaten, current plan and route notes. |
| `debrief.md` | The agent's end-of-run debrief. |
| `harness-issues.md` | Harness problems the agent logged. |
| `messages.md` | The supervisor messages the agent received, as it logged them, with what it changed in response. |

- `b2/`: Kaizo pilot B2 (no notes, harness v2).
- `ripple-k1/`: Kaizo pilot Ripple (notes pack K1.1). Its sidecar file is held back with the quarantined material.
- B1's records are not exported as files; its diary and progress file can be read from its transcript.
- K2 is still running. Its records will be added when it ends.

The diaries are not strictly append-only: the agents sometimes edited earlier entries. The edits found are listed in `design/transcript-analyses-2026-10-20.md`, section 6.

## `analyses/`

Outputs of the 20 October transcript analyses (method and results: `design/transcript-analyses-2026-10-20.md`).

| File | What it is |
|---|---|
| `milestones-v3.1-{B1,B2,Ripple}.csv` | First-seen time of each PokeAgent first-gym milestone (1 to 27), scored from the transcripts by `tools/milestones.py` v3.1. |
| `habits_*.csv`, `habits_windows.csv` | Hourly tool-use habits per arm, and the same measures before and after each compaction and human message. |
| `narration_hourly.csv`, `narration_compaction.csv` | How often and how much the agent wrote between tool calls, per hour and around compactions. |
| `r1_reimpl.csv`, `r1_diary.md` | The supplementary milestone R1 ("Trainer Red" beaten) rescored from the transcripts, and an audit of every non-append edit each agent made to its diary. |
| `checkins.md` | Every non-tool message injected into each pilot, human-typed or harness-generated. |
| `scrub_report.md` | What `tools/scrub.py` found and replaced. The list of the account's connected services is removed from this public copy. |

## `transcripts/`

The pilot session transcripts (gzipped JSON Lines), with checksums. See `transcripts/README.md`.
