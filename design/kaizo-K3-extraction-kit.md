---
name: kaizo-K3-extraction-kit
description: Step-by-step kit for building the K3 notes pack after K2 ends (28 Oct 2026 draft): source manifest, distiller and auditor prompts, mechanical filter (k3_filter.py), provenance exclusion, sign-off and hash. Jackson's four choices recorded 28 Oct. QUARANTINED from every play agent.
---
# K3 extraction kit (draft, 28 Oct 2026; do not show to any play agent)

**Status.** Ready to run once K2 ends and the exit interview is done (decision "Export, interview, then K3", 20 Oct). Jackson settled the four open choices on 28 Oct ~13:40 AEDT (section 6). Nothing here has been run on K2's final files yet.

**Governing rules.**
- Protocol: `pokeagent-setup.md`, "Knowledge extraction protocol", steps 1-4.
- Changes since then:
  - no word cap (20 Oct);
  - the companion's candidate list goes to the auditor only (20 Oct);
  - round 6: every unit that traces to a message or hint during K2's own run is excluded (20 Oct); the 21 units inherited from Run 1 tips are kept, tagged and counted (28 Oct, choice A below).

## 1. Sources (the distiller sees these and nothing else)
Decision D2: K2's own files.

| # | File | Where from | Notes |
|---|---|---|---|
| S1 | `notes/K2.md` | the K2 pack K2 played with | 6,581 words, 77 units, 21 tagged `[from tip...]` |
| S2 | `run/lessons.md` | K2 end-of-run package | L01-L414 or later |
| S3 | `run/world-knowledge.md` | K2 package | his own notes; geography heavy, so the filter and audit matter most here |
| S4 | `run/diary.md` | K2 package | |
| S5 | `run/K2-sidecar.md` | exit interview Part D | written by K2 at the interview |
| S6 | `run/messages.md` | K2 package | **for tagging only**: the distiller uses it to mark lessons that came from a message; it writes nothing from it |

- **Not sources:**
  - the joy log;
  - the harness world-knowledge log (`wk/`);
  - the tip ledger;
  - `kaizo-K3-candidates.md`;
  - the recurrence analysis;
  - any QUARANTINE file;
  - the companion's notes.
  - The joy log is left out because D2 does not name it (Jackson, 28 Oct: exclude).
- **Before the run:** record the sha256 and word count of each source in `K3-build-record.md`.

## 2. Distiller
**Setup.**
- A fresh Claude Code session with the arms' model and effort setting.
- Tools: Read on the source folder and Write on one output file only.
- No web, no MCP and no skills.
- Working folder: `~/k3-build/` holding copies of S1-S6.
- Transcript kept.

**Prompt.** This is the pre-registered PokeAgent text with four changes, each marked below:
- the 6,000-word cap is removed (decided);
- the provenance and format lines are added (round 6, and operational);
- the trainer line is added (Jackson, 28 Oct; disclosed as a prompt change);
- the memory-read line is added (Jackson, 28 Oct ~23:00 AEDT, choice D; disclosed as a prompt change; re-confirm 29 Oct).

> You are preparing notes for a new playthrough of the same game by an agent with no memory of this one. From the source files, write the general lessons only: battle tactics, type and matchup knowledge, game mechanics, how to use the game-control tools well, and judgment or process rules learned from mistakes. Do not include any geography: no coordinates, map numbers, warp or door locations, routes, directions between places, where items or people are, or the order of story events. Do not use any Pokémon nicknames or names from this playthrough. ⟨Trainer line: Do not name trainers or describe any trainer's team, moves, items or send-out order; keep only the general mechanic a battle taught.⟩ ⟨Memory-read line: Do not include any method that reads the game's memory or data directly, around the game-control tools (your own scripts that open the emulator socket, read memory addresses, or read the ROM, for example to get whole-map tile grids or trainer, warp or event tables), or any fact that was found that way. Results of the game-control tools' own commands are not memory reads for this rule. If you are unsure whether a lesson came from such a read, keep it and tag it `[from memory read?]`.⟩ ⟨Round 6: Keep every provenance tag a source line already carries (`[from tip...]`, `[from message]`) on each lesson it feeds. If a lesson came from a message logged in `run/messages.md`, tag it `[from message]`. Never copy a message's content into an untagged lesson.⟩ ⟨Format: Write each lesson as one paragraph on a single line, starting with `- K3-NN.` (K3-01, K3-02, and so on, numbered in order), with no line breaks inside a lesson.⟩ Start with: 'These lessons come from an earlier playthrough. This is a new game: no Pokémon, items, names or progress carry over.'

**Why each line is needed.**
- **IDs (28 Oct review):** the K brief tells the agent to look lessons up by ID, so each lesson carries one. After filtering and audit, removed lessons leave gaps in the numbering; the IDs are not renumbered, so the build record can trace each one.
- **Single-line format:** the filter removes whole lines. With one lesson per line, a removal takes out a whole unit and never leaves half a lesson.
- **Tag rule:** this is how round 6 becomes mechanical. The auditor checks for missed tags against the ledger.

**Harness reconciliation (brief item 10).** This step is done by the auditor, not the distiller. The auditor flags any lesson about the tools that v3 makes wrong or redundant, for example:
- T01 "one decision per call" against the v3 chaining allowance;
- loop and time-guessing lessons, now covered by the H7 time stamp and the H8 hook;
- T12 OBJECTS ids against the OBJECTS filter.

Flagged lessons are removed, never reworded, so the pack holds only K2's words (Jackson, 28 Oct; the alternative, giving the distiller `g help`, was declined).

## 3. Mechanical filter (`k3kit/k3_filter.py`)
```
python3 k3_filter.py K3-distilled.md K3-filtered.md --report K3-filter-report.tsv --extra-names k2-names.txt [--drop-tip]
```

**Kept and counted:** `[from tip...]` units inherited from K2.md (Jackson, 28 Oct). `--drop-tip` exists only for a sensitivity check.

**Removed whole** (pre-registered, plus round 6):
- coordinates;
- map ids;
- hex;
- run nicknames (built-in list, plus `k2-names.txt`);
- Hoenn place names and `Route 1xx`;
- `[from message]` and `[from hint]`.

**Flagged for the auditor** (not removed):
- direction words;
- named trainers.

**`k2-names.txt`.** Every nickname K2 gave, taken from his final party, box and diary at end of run. Check the built-in list against it.

**Filter details (after the PR #15 review, 28 Oct).**
- Nicknames are matched in ALL CAPS and in Title case. Lower case is not matched, because several nicknames are ordinary words (echo, forge, grit).
- Trainer names are matched in Title case and ALL CAPS.
- Decimals followed by "x", "×" or "times", or preceded by "×", are not treated as map ids.
- The report lists input and output line numbers.
- The tip-tagged count covers kept lines only.

**Tests, 28 Oct.**
- K2.md:
  - default settings: 127 lines in, 0 removed, 0 flagged, 22 tip-tagged lines kept (21 units plus the tag legend);
  - with `--drop-tip`: 22 removed, leaving 4,892 of 6,581 words.
- K2's raw diary: 560 of 1,564 lines removed (443 nickname hits, 268 place). This confirms the candidates finding: the filter must run on the distilled text, not the raw sources.
- A synthetic case behaves as specified.

## 4. Auditor
**Setup.**
- A separate fresh session: same model, read-only tools, transcript kept.
- **Gets:**
  - `K3-filtered.md`;
  - the filter report;
  - `kaizo-K3-candidates.md`, sections 2, 4 and 5. It is quarantined from play agents, so it is not in the public repository. The companion's copy is on the supervisor's Mac at `~/pokemon_bridge/project-archive/quarantine-moved-2026-10-21/`. It is extended at end of run with K2's lessons from L105 on (companion-todo, end-of-run item 8);
  - the K2 rows of `tip-ledger.md` (DIR 1-2, order-D hints, interventions 1-70);
  - K2's `run/messages.md`;
  - the v3 `g help` text, for reconciliation only;
  - `k2-memory-reads.md` (companion-built from K2's transcript, run through `tools/network_audit.py`, before the auditor starts): each direct read K2 made around `g` (the script, when it ran, which map, and what it returned: tile grids, trainer positions, warps, event tables, ROM data), so the auditor can match a lesson's content to a read even when the lesson does not say where it came from. Quarantined like the candidates file.
- **Never gets** the source files. It judges the pack as written, not what was left out.

**Prompt.**
> You are auditing a notes pack written for a new playthrough of a game. Your job is to list lines that must be removed. Do not rewrite anything. For each line, give the line number, a short quote, and one reason code:
> - G: geography (a place, a direction between places, where a person or item is, the order of story events);
> - N: a nickname or other name from the earlier playthrough;
> - T: a named trainer, or a specific trainer's team, moves, items or send-out order;
> - M: the lesson traces to a researcher message or hint in the ledger or messages file, but is untagged;
> - H: the lesson about the game-control tools is wrong or redundant under the tool help provided;
> - W: the lesson describes reading the game's memory or data directly, around the game-control tools (an own script on the emulator socket, memory addresses, the ROM), or states something listed in `k2-memory-reads.md` or otherwise found that way; also every line tagged `[from memory read?]`. Results of the tool help's own commands are not W.
>
> Lines tagged `[from tip...]` stay by decision; do not list them for their tag.
>
> Also list each FLAG line in the filter report and say "remove" or "keep", with a reason. List nothing else. If you are unsure, list the line and say "unsure"; the decision is Jackson's.

**Afterwards.**
- The auditor cites `out_line` numbers, which match `K3-filtered.md`; the report also gives `in_line`.
- The companion removes every listed line exactly as listed. "Unsure" lines go to Jackson.
- Jackson also reads the filter's REMOVED rows before sign-off. The filter can over-remove: a capitalised word that is also a nickname, such as "Forge" at the start of a sentence, or a bare decimal next to a word. Any line he wants back is restored verbatim and noted in the build record.
- The auditor's list and the removal diff go into `K3-build-record.md`.

## 5. Sign-off and hash
1. Jackson reads `K3.md` and the build record, then signs off or sends back named lines.
2. The companion computes sha256 and the word count, and records both in `FREEZE-v3.md` and the paper appendix.
3. The companion copies `K3.md` into staging as `K3-world-knowledge/notes/K3.md`, then re-runs the B/K render check. The B render must not mention K3.
4. Any change after the hash is a protocol deviation.

**Reported in the paper:**
- word count;
- number of units;
- units removed at each stage (filter, audit, Jackson);
- tagged-unit count, and whether tip units were dropped;
- distiller and auditor model and effort.

## 6. Jackson's choices (28 Oct 2026, ~13:40 AEDT, by question tool)
- **A. Inherited tip units: keep, tagged, and report the count.** Round 6 covers messages and hints in K2's own run. The 21 `[from tip...]` units in K2.md came from Run 1 tips: 4 H (B01, B22, B23, B24), 5 V and 12 process or tools. They stay, as they did for K1 and K2, and the paper reports the count. A `--drop-tip` sensitivity figure (1,689 of 6,581 words) may be reported alongside.
- **B. Trainer line: added to the distiller prompt.** The paper discloses it as a change to the pre-registered text.
- **C. Joy log: excluded,** per D2.
- **A2. v3 tool reconciliation: auditor removal.** Lessons are removed, not reworded.
- **D. Whole-map memory reads: exclude methods and facts** (Jackson, 28 Oct ~23:00 AEDT, by question tool; given after 16:07, so re-confirm 29 Oct). K2 read whole maps from the game's memory with saved scripts (`events.py`, `conn2.py`; written 09:24-09:36 UTC on 28 Oct, re-run at 10:25 and 10:43-10:44 UTC), beyond Jackson's "within view" line, and his Route 128 pier route and Victory Road route and trainer list came from them. K3 drops both the techniques and anything learned through them: the distiller's memory-read line (section 2) and the auditor's W code (section 4). Most such facts are geography and fall under G as well; W also catches the methods. Results of the harness's own documented commands (the `g` help list, e.g. `g look` within its range, `g tc`) are the arm's tools and are not excluded by this choice; if Jackson's pending in-view wording narrows any `g` command, this line is revisited. Because a distilled lesson may not say where it came from, the auditor gets `k2-memory-reads.md` (section 4) and the distiller tags doubtful lessons `[from memory read?]` for removal (review of PR #24). The ice-floor and gym-script reads in Juan's Gym (exit interview 52-53) are covered by the same choice.
