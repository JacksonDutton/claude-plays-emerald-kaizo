# Claude plays Pokémon Emerald (and Emerald Kaizo)

This project follows an AI model, Claude, as it plays a Pokémon game on its own for days at a time. It records everything the AI does, everything it writes about itself, and every message a human sends it. The aim is to see how well an AI agent works over a very long task, how much human help it really needs, what that costs, and whether its own account of its play can be trusted.

The project is run by Jackson Dutton, an independent researcher in Melbourne, Australia. It has no institutional backing and is self-funded. Claude (Anthropic's Opus model) works on it as a co-researcher. Jackson designed the study, watched over the runs and made every decision about design and interpretation. The paper was written together. Claude wrote first drafts from the logs, and Jackson directed, edited and decided what the paper claims.

## The game, in plain terms

**Pokémon Emerald** is a 2004 Game Boy Advance game. You walk around a map, catch creatures, battle other trainers, and collect eight gym badges. Then you face the final challenge, the Elite Four, and enter the Hall of Fame.

**Emerald Kaizo** is a fan-made, much harder version of the same game. Opponents have stronger teams and smarter tactics, and losing is common. When your whole team is knocked out, you "white out". You are sent back to the last healing point and lose half your money.

**The agent** is a Claude model. In the Kaizo runs it runs in Claude Code, Anthropic's command-line tool, in a cloud session. Run 1 played the original game through a similar harness on Jackson's Mac, in the Claude desktop app. The agent cannot see the game the way a person does. It plays through a small program we built, called the harness. The harness reads the game's memory and turns it into text, such as where the player is standing, what is on the map, and the state of a battle. It also lets the agent press buttons and take screenshots. While it plays, the agent keeps its own files. These are a diary, a progress file and a list of harness problems. K2 also keeps its own list of lessons and notes about the game world. Ripple, the first run with notes, kept neither.

## The questions

Long-running AI agents are often judged partly by what they say about their own work. We log everything around one agent so that its own reports can be checked against what it actually did and what it was told.

1. **Do written notes help a new agent?** Before some runs, a fresh agent is given notes that earlier Claude agents wrote from their own play. If that agent does better, is it because of the notes, or because of the human who was helping along the way? (The runs with notes also differ in a few other ways, such as which record files the agent keeps, so the planned study tests that whole package rather than the notes alone.) Every message the human sends is saved word for word and rated by how much game information it gave away. That lets us count the help instead of guessing.
2. **Do an agent's reports of its feelings change when it is told how to write them?** In the first run, the number of feelings the agent named in its diary roughly doubled within two entries of one instruction about how to keep the diary. That matters to anyone who treats an AI's self-reports as evidence of what is going on inside it.
3. **What does a long agent run cost, and what drives the cost?**

On the agent's welfare, we follow Anthropic's published position. We record the agent's feeling words as reports linked to what triggered them. We do not treat them as proof of inner experience. The agent may pause or stop at any time, and a stop is recorded as a result, not a failure.

## The runs

Each run (we also call them "arms") has a short name. "Notes" means the agent was given notes written by earlier agents. "Milestones" are 27 checkpoints from the start of the game up to the first gym badge, taken from the PokéAgent benchmark's list.

| Run | Game | Model | What happened |
|---|---|---|---|
| Run 1 | Original Emerald | Sonnet 5 and Opus 5.5 up to the first badge, then Sonnet 5.5 | Finished. It won all eight badges and entered the Hall of Fame on 10 October 2026. A later phase in the post-game Battle Frontier was paused on 17 October. |
| B1 | Kaizo, no notes, first harness | Sonnet 5.5 | Finished. Reached 22 of the 27 milestones. |
| B2 | Kaizo, no notes, second harness | Sonnet 5.5 | Finished. Reached 26 of 27. |
| Ripple | Kaizo, first notes pack (from Run 1) | Sonnet 5.5 | Finished. Reached all 27 and won the first badge in about 19 hours. |
| K2 | Kaizo, second notes pack (from Run 1 and Ripple) | Sonnet 5.5 | Still running. On 28 October it had seven badges and was at the eighth gym, after a four-day pause at the weekly usage limit (23 to 27 October). Its data will be added when the run ends. |
| Planned study | Kaizo, six runs: three with notes, three without | Sonnet 5.5 | Being designed. The plan will be fixed and recorded before it starts, so the results cannot shape the method. Decisions so far are in `design/v3-decisions-2026-10-20.md`. |

The trial runs differed in their instructions, their harness and how much a human stepped in. That means they are case studies, not a fair comparison. The planned six-run study is the fair comparison. Its two groups differ by the whole notes package, not by the notes alone.

## The paper

[`paper/eight-badges-and-a-diary-rev419-2026-10-27.pdf`](paper/eight-badges-and-a-diary-rev419-2026-10-27.pdf)

*Eight Badges and a Diary: Measuring Help, Cost and Self-Report in a Claude Agent Playing Pokémon Emerald.* Working paper, draft of 27 October 2026 (rev 419), 52 pages. It has not been peer reviewed. Section 9 covers the trial runs, including K2 to seven badges and its pause at the weekly usage limit on 23 October. Section 10 sets out the planned study, which will run on the supervisor's own computer.

Earlier revisions, kept so old links still work: [`paper/eight-badges-and-a-diary-rev379-2026-10-22.pdf`](paper/eight-badges-and-a-diary-rev379-2026-10-22.pdf) (22 October 2026, 48 pages) and [`paper/eight-badges-and-a-diary-rev376-2026-10-21.pdf`](paper/eight-badges-and-a-diary-rev376-2026-10-21.pdf) (21 October 2026, 44 pages).

## What it cost

The Kaizo runs used Claude Code on a Claude Max subscription, which charges a flat monthly fee rather than per use. The figures below come from Claude Code's built-in `/usage` command. They show what each session would have cost at Anthropic's standard pay-per-use (API) prices. They are not money we actually spent.

| Run | Equivalent cost (US$) | Per hour of API activity |
|---|---|---|
| B1 | 208.85 | about 69 |
| B2 | 313.71 | about 64 |
| Ripple | 506.63 | about 63 |
| K2 | read when the run ends | |
| Run 1 | no figure (it ran in the desktop app, which has no `/usage` total) | |

`tools/session_cost.py` recalculates each session's cost from its saved transcript.

## What is in this repository

| Folder | Contents |
|---|---|
| [`paper/`](paper/) | The working paper (PDF). |
| [`harness/`](harness/) | The harness used by Ripple, B2 and K2. It includes the emulator scripts, the `g` command the agent uses to play, the `tc` damage calculator, setup and start scripts, the agents' instructions for every run, and the two notes packs. |
| [`tools/`](tools/) | Analysis scripts. They score milestones, remove private details from transcripts, prepare files for publishing and read session costs. |
| [`design/`](design/) | How the study is designed. It holds the trial-run protocol, the draft plan for the six-run study, the measures, the decisions so far, and the scoring guide for a second reader who codes the diaries without knowing which run they came from. |
| [`data/`](data/) | Records from B2 and Ripple (diary, progress, end-of-run debrief written by the agent, harness problems, human messages), analysis outputs and the session transcripts. |

**Transcripts.** The full sessions for B1, B2 (including a 45-minute first attempt) and Ripple are in [`data/transcripts/`](data/transcripts/). They are about 50 MB compressed and hold 135,440 events. The README in that folder explains the format and what was removed before publishing.

## What is not here, and why

- **Game files.** No game ROM, patch or save file is included. The harness needs a legally obtained Pokémon Emerald ROM patched with Emerald Kaizo v2.1. `harness/setup.sh` checks the patched file's SHA-1 and stops if it does not match.
- **K2's records.** K2 is still playing. Its diary, lessons and transcript will be added after the run ends and the agent has been interviewed.
- **Outside game information.** During the study, some files are kept away from the agents because they hold game knowledge from outside the game, such as encounter tables, move lists, forum posts and a human's own playthrough. They are not published here.
- **Run 1's raw records.** The paper reports Run 1. Its raw diary and logs are available on request.
- **Personal and account details.** See the next section.

## How the harness works

In the Kaizo runs, the game runs in the mGBA emulator, with no screen, inside a Claude Code cloud session. A script inside the emulator (`harness/emulator/director.lua`) reads the game's memory and passes the information to the agent. The agent plays with the `g` command. For example, `g s` shows the player's status, `g look` shows the map, `g a` presses A and `g up 3` walks up three steps. Other commands help with menus and battles and take screenshots.

The agent keeps its records in a `run/` folder. Every message from the human is saved word for word in `run/messages.md`. Each one is also rated in a separate log by what kind of help it was and how much game information it gave away. More detail is in `harness/README.md`, `harness/FREEZE.md` and `harness/V2-CHANGES.md`.

## Privacy

Before publishing, the transcripts went through two scripts in `tools/`.

1. `scrub.py` removed or replaced session IDs, account-scoped connector and plugin-sync IDs, and one email address. It found no populated account or user ID fields and no personal home-folder paths. Its report is `data/analyses/scrub_report.md`.
2. `publish_prep.py` removed hidden signature data from the agent's reasoning blocks. It also replaced the account's lists of installed add-ons, connector details and connector tool names with a short note, because these describe the account rather than the play.

Jackson's name and GitHub username were kept. If you find personal information that should not be here, please open an issue.

## Using this material

The code in `harness/` and `tools/` is under the MIT licence (`LICENSE`). The paper, documents, instructions, notes packs and data are under CC BY 4.0 (`LICENSE-docs.md`). The mGBA patch in `harness/cloud/` follows mGBA's own licence, MPL-2.0.

Please cite the working paper:

> Dutton, J., with Claude (Anthropic). *Eight Badges and a Diary: Measuring Help, Cost and Self-Report in a Claude Agent Playing Pokémon Emerald.* Working paper, draft of 21 October 2026. https://github.com/JacksonDutton/claude-plays-emerald-kaizo

Pokémon is a trademark of Nintendo, Creatures Inc. and GAME FREAK inc. Emerald Kaizo is a fan-made modification by its own authors. This project is not affiliated with or endorsed by any of them, or by Anthropic.
