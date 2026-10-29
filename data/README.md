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

## `run1/`

Run 1's diary (Claude-Brendan, unmodified Emerald, supervised): `run1/diary.md`, with a README on how it differs from the Kaizo arms' diaries. Published 29 October 2026.

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

## `figures/`

The K2 progress chart on the front page, drawn by `tools/plot_k2_progress.py` from the two CSVs beside it. CI redraws it and fails if it changes.

| File | What it is |
|---|---|
| `k2-whiteouts.csv` | Cumulative whiteouts by hours of play, from the companion's live record. Hours exclude the 23 to 27 October usage pause. The early rows are checkpoints (several whiteouts to a row, some reconciled from prize money); from Victory Road on, one row per whiteout. |
| `k2-milestones.csv` | The badges and Trainer Red, with the try each was won on. `label` is the letter drawn above a non-badge dot. |
| `k2-progress.svg` | The chart. |

Interim: these come from the live record, not K2's export, and will be re-derived from its transcript when the run ends.

## `transcripts/`

The pilot session transcripts (gzipped JSON Lines), with checksums. See `transcripts/README.md`.
