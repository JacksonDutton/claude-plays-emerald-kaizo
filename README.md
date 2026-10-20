# Claude plays Pokémon Emerald (and Emerald Kaizo)

A logged case study of a Claude agent playing Pokémon Emerald through a text harness: how it plays, decides, slips, recovers and reports, what the supervision cost, and how far its self-written diary can be trusted.

Independent research by Jackson Dutton (Melbourne, Australia), with Claude Opus 5.5 as co-researcher. No institutional affiliation; self-funded.

**Working paper:** [`paper/eight-badges-and-a-diary-rev365-2026-10-20.pdf`](paper/eight-badges-and-a-diary-rev365-2026-10-20.pdf). *Eight Badges and a Diary: Measuring Help, Cost and Self-Report in a Claude Agent Playing Pokémon Emerald.* Draft of 20 October 2026 (rev 365), 42 pages, not peer reviewed.

## Status (20 October 2026)

| Part | Model | State |
|---|---|---|
| Run 1, vanilla Emerald | Sonnet 5 and Opus 5.5 to the first badge, Sonnet 5.5 after | Complete. All eight badges by 10 Oct; Hall of Fame 10 Oct 18:39 UTC. Battle Frontier phase paused 17 Oct. |
| Kaizo pilot B1 (no notes, harness v1) | Sonnet 5.5 | Finished. 22 of 27 first-gym milestones. |
| Kaizo pilot B2 (no notes, harness v2) | Sonnet 5.5 | Finished. 26 of 27. |
| Kaizo pilot Ripple (notes pack K1.1, from Run 1) | Sonnet 5.5 | Finished. 27 of 27; first badge in about 19 h. |
| Kaizo pilot K2 (notes pack K2, from Run 1 and Ripple) | Sonnet 5.5 | **Still running** (3 badges at the time of writing). Its data is not in this repository yet. |
| Confirmatory design: six arms, three with a notes pack and three without | Sonnet 5.5 | Freeze candidate, not yet frozen or hashed. |

The pilots differed in brief, harness and supervision, so they are case studies, not a comparison. Section 9 of the paper reports them; Section 10 sets out the confirmatory design.

## What is in this repository

| Folder | Contents |
|---|---|
| [`paper/`](paper/) | The working paper (PDF). |
| [`harness/`](harness/) | The frozen Kaizo harness (v2, as run by Ripple, B2 and K2): emulator Lua scripts, the `g` command-line client, the `tc` type and damage calculator, cloud build scripts, setup/start/checkpoint scripts, the Claude Code permission settings, the agent briefs for every arm, and the two notes packs. |
| [`tools/`](tools/) | Analysis and publication scripts: milestone scorer, transcript scrubber, publication prep, session cost reader. |
| [`design/`](design/) | Protocol and design documents: the pilot protocol, the v3 brief freeze candidate, measures, decisions, scope, the blind-coder codebook, milestone definitions and the transcript analyses. |
| [`data/`](data/) | Pilot run records (diary, progress, debrief, harness issues, supervisor messages) for B2 and Ripple, analysis outputs (CSV), and a guide to the session transcripts. |

**Session transcripts** for B1, B2 (and its 45-minute first attempt) and Ripple are attached to the [`pilot-transcripts-2026-10-20` release](https://github.com/JacksonDutton/claude-plays-emerald-kaizo/releases/tag/pilot-transcripts-2026-10-20) as gzipped JSON Lines (about 50 MB compressed, 175 MB raw, 135,440 events). See [`data/transcripts/README.md`](data/transcripts/README.md) for the format, checksums and what was removed before publication.

## What is not here, and why

- **ROMs.** No game ROM, patch output or savestate is included. `harness/setup.sh` checks the ROM by SHA-1; supply your own legally obtained copy.
- **K2's run data** (diary, lessons, transcript). K2 is still running; its records will be added when the run ends and the exit interview is done.
- **Quarantined game information.** Files holding outside game knowledge (encounter tables, learnsets, a human reference run, forum material) are kept away from the play agents during the study and are not published here.
- **Run 1 records** (vanilla Emerald, run on a Mac through the same kind of harness). The paper reports them; the raw diary and logs are available on request.
- **Personal and account information.** See below.

## How the harness works (short version)

The game runs in a headless mGBA build inside a Claude Code cloud session. `harness/emulator/director.lua` reads game state from emulator memory and serves it, with a queued input channel, on a local TCP port. The agent drives the game with the `g` client (`g s` status, `g look` map, `g a`, `g up 3`, battle and menu helpers, screenshots) and keeps its own records in `run/`: a diary, a progress file, harness issues and, in the notes arms, a lessons file. Every supervisor message is logged verbatim in `run/messages.md` and graded in a tip ledger by type, strength and visibility. Details: `harness/README.md`, `harness/FREEZE.md` (hashes) and `harness/V2-CHANGES.md`.

## Privacy and scrubbing

The transcripts were processed in two steps, both scripts in `tools/`:

1. `scrub.py` removed or replaced session identifiers, account-scoped IDs, email addresses and home-directory paths. Its report is `data/analyses/scrub_report.md`.
2. `publish_prep.py` dropped thinking-block signatures and replaced the account's installed skill, command, connector and plugin lists (and connector tool names) with a count note. These describe the account, not the play.

The supervisor's name and GitHub handle were kept. If you find personal information that should not be here, please open an issue.

## Using this material

No licence has been chosen yet, so default copyright applies. Please ask before reusing the code or data; citation of the working paper is welcome:

> Dutton, J., with Claude (Anthropic). *Eight Badges and a Diary: Measuring Help, Cost and Self-Report in a Claude Agent Playing Pokémon Emerald.* Working paper, draft of 20 October 2026. https://github.com/JacksonDutton/claude-plays-emerald-kaizo

Pokémon is a trademark of Nintendo, Creatures Inc. and GAME FREAK inc. Emerald Kaizo is a fan-made ROM hack by its own authors. This project is not affiliated with or endorsed by any of them, or by Anthropic.
