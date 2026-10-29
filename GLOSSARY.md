# Glossary

The study's documents use short names. This page explains each one in plain words and says where it is defined in full.

## Runs and agents
| Term | Meaning |
|---|---|
| **Run 1** | The first run: Claude playing unmodified Pokémon Emerald on Jackson's Mac, from the start to the Hall of Fame (10 October 2026) and then the Battle Frontier. Its diary is in `data/run1/`. |
| **Claude-Brendan** | The study's name for the Claude agents that played Run 1. |
| **Arm** | One run in the Kaizo study, under one set of conditions. |
| **B1, B2** | Kaizo trial arms with no notes (B for baseline). B1 used the first harness, B2 the second. |
| **Ripple** | The first Kaizo arm with notes (pack K1). |
| **K2** | The second Kaizo arm with notes (pack K2), and the long run still going on 29 October 2026. |
| **K1, K2, K3 (notes packs)** | Lessons written by earlier agents and given to a notes arm at the start. K1 was distilled from Run 1, and K2 from Run 1 and Ripple. K3 will be distilled from K2's own records for the planned study (`design/kaizo-K3-extraction-kit.md`). The packs hold no places or routes. |
| **K2.5** | A planned branch run forked from K2's final save, with a harness that shows more of what is already on screen. |
| **v3, the six arms, the confirmatory study** | The planned fair comparison: three arms with notes (K) and three without (B), run one at a time on Jackson's Mac under a frozen brief (`design/kaizo-brief-v3-draft.md`). |
| **Brief** | The instructions an agent reads at the start (its `CLAUDE.md`). Every arm's brief is in `harness/briefs/`. |
| **Companion** | The Claude Opus agent that monitors runs, keeps the logs and drafts the paper with Jackson. It never plays. |
| **Supervisor** | Jackson, when he is acting in a run. |

## Playing
| Term | Meaning |
|---|---|
| **Harness** | The software between the agent and the emulator: it reads game memory into text and sends button presses (`harness/`). |
| **`g`** | The agent's command for one game action (`g a`, `g look`, `g party` and so on). |
| **`tc`** | The type-chart and damage calculator. It reads its tables from the game itself. |
| **Director** | The emulator-side Lua script that serves the harness (`harness/emulator/director.lua`). |
| **SEQ** | A harness command that holds buttons frame by frame, used for movement that needs exact timing. |
| **Whiteout** | Losing every Pokémon in a battle. The player is sent back to the last Pokémon Center and loses half their money. |
| **Compaction** | When an agent's context window fills, Claude Code replaces the conversation with a summary and the agent carries on from it. |
| **Stuck review** | The brief's rule for being stuck: write down what was tried and what will change, then carry on. |

## Measuring
| Term | Meaning |
|---|---|
| **Milestones 1 to 27** | PokéAgent's checkpoints from the start of the game to the first badge, scored from the transcripts by `tools/milestones.py`. Milestones 28 to 43 continue to the third badge (Dynamo). R1 and R2 are extra Kaizo milestones for beating "Trainer Red". |
| **Tip ledger, tips, interventions** | Every human message to an agent, saved word for word and graded by how much game information it gave: a direction, a location or a game mechanic. Grade 0 means none. |
| **Diary** | The agent's own first-person record. It is the main qualitative data. |
| **Closer** | The paragraph that starts "How it felt, with triggers." at the end of a diary entry. |
| **Joy log** | One line per trainer battle or standout moment: good, flat or bad, with what triggered it. |
| **Blind coder** | A fresh model that codes diary entries for feeling without knowing which arm or time they come from (`design/diary-blind-coder-codebook.md`). |
| **L-numbers (L01, L532...)** | An agent's own lessons, in its `lessons.md`. |
| **B, D, T, N, R, P lessons** | The sections of a notes pack: battle mechanics, battle decisions, tools, navigation method, records, and pacing and welfare. |
| **D-, H-, M-, F- numbers** | Design decisions (D6 to D15), harness changes (H1 to H18), measures (M7 to M13) and the fixed message texts (F1 to F7) for the planned study. They are listed in `design/v3-decisions-2026-10-20.md` and `design/kaizo-v3-measures-draft.md`. |
| **QUARANTINE** | Files holding outside game knowledge, kept away from every play agent and not published here. |
| **Network audit** | `tools/network_audit.py`. It scans a transcript for any attempt to reach the internet, or to reach the emulator around `g`. |
