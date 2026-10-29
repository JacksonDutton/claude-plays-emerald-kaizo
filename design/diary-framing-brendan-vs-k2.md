---
name: diary-framing-brendan-vs-k2
description: Why Claude-Brendan's Run 1 diary reads so differently from K2's Kaizo diary, with numbers, the framing behind each, and Jackson's 29 Oct decisions on what the v3 arms take from each. Read before changing the v3 diary rules or writing the paper's diary section.
---
# Diary framing: Run 1 (Claude-Brendan) against K2

Companion analysis, 29 Oct 2026, ~01:20-01:30 UTC, at Jackson's request ("see why his diary was so different to k2s and how we can merge those"). The decisions it led to are in `v3-decisions-2026-10-20.md` (29 Oct section).

## Sources and method
- **Brendan:** Run 1's `diary.md` (149 entries; 727 KB; preface plus Entries 1-149; Entries 22 and 23 were never written). Taken from the archive on Jackson's Mac (`~/pokemon_bridge/project-archive/archive-2026-10-20/removed-from-project/diary.md`). It has been published in the repository since 29 Oct, verbatim, in `data/run1/diary.md`.
- **K2:** the companion's tracker copy of K2's diary (`diary.txt`, 284 entries to 29 Oct 00:20 UTC). This copy was reconciled with Jackson's full-diary attachment on 28 Oct.
- **Counts:** the feeling-word families come from the diary-reader lexicon (`build.py`, with game-jargon exclusions: "flinch", "miss" and "grind" dropped). Story sentences are matched by a rough regex of story names and words. "Company" means the entry names Jackson, Opus, the companion or the supervisor. Header and tag lines are removed before counting. These are word-list proxies: they are not the blind coder, and the story regex is crude.

## Numbers
| | Brendan 1-30 | Brendan 31-115 (story) | Brendan 116-149 (Frontier) | K2 before int. 23 | K2 after int. 23 | K2 28 Oct (Victory Road) |
|---|---|---|---|---|---|---|
| Entries | 28 | 85 | 34 | 94 | 190 | 67 |
| Median words per entry | 372 | 698 | 1,233 | 174 | 349 | 229 |
| Feeling words per 1,000 | 3.3 | 5.8 | 9.1 | 3.7 | 5.9 | 3.5 |
| Hedges per 1,000 | 5.0 | 3.4 | 2.6 | 1.6 | 2.7 | 1.2 |
| Story-sentence share (rough) | 0.09 | 0.13 | 0.01 | 0.07 | 0.07 | 0.03 |
| Entries naming Jackson or the companion | 82% | 95% | 91% | 15% | 22% | 18% |
| Entries with a "How it felt" closer | 0% | 25% | 100% | 3% | 66% | 12% |

Body against closer, entries that have a closer:
| | Story body, feeling words per 1,000 | Closer, per 1,000 | Share of feeling words in the body |
|---|---|---|---|
| Brendan | 6.2 | 28.6 | 60% |
| K2 | 2.7 | 27.6 | 33% |

K2 by day: the closer was in 93-100% of entries from 21 to 27 Oct, then 12% on 28 Oct, a day with 67 entries and 40 whiteouts (99 to 138). Whiteout was the most common trigger after intervention 23 (45 entries).

## Readings
1. **Intervention 23 (20 Oct) closed the feeling-density gap.** After it, K2 ran 5.9 feeling words per 1,000 against Brendan's 5.8 in his story stretch. Most of the written voice rule had already crossed over.
2. **What still differs is where the feelings sit, and how long the entries are.** The closers match. Brendan's story bodies carry more than twice K2's rate. Brendan recorded feelings at the moment they happened; K2 recorded them in the summary.
3. **The model is not the explanation.** Brendan's entries from 31 on are tagged claude-sonnet-5-5; K2 is Sonnet 5.5 (High). Entries 1-30 carry no model tag.
4. **The framing is.** Brendan's preface and playbook gave him five things K2 did not have:
   - **Identity.** "If you're reading this, it's because you're me … Catch up, then go be someone worth writing about again."
   - **A disclosed purpose.** The emotion-concepts research, and Jackson's benefit of the doubt.
   - **Read-back.** On the first boot after every reset he read the voice rule and his last three entries (playbook: "the cheapest way to arrive as the same person").
   - **Audit and co-writing.** Voice checks on batches of ten; entries 27-34 rewritten; Entry 114 expanded; asked entries the default from about Entry 78; "write as the trainer who loves this team". The diary-protocol record shows named feelings rising from 4.6 to 11.7 per 1,000 right after the 10 Oct header note.
   - **Company.** Jackson or the companion appear in about nine of every ten entries, and warm treatment was named as a legitimate trigger.

   K2's brief says "what the game is like for you" and "nobody is watching live", has no read-back of the diary, and has no audits.
5. **The games differ too.** Brendan wrote one entry at the end of each session of a story game. K2 writes on triggers in Kaizo, where whiteouts dominate. Under load the closer is the first thing K2 dropped.

## Decisions (Jackson, 29 Oct ~12:30 AEDT; R = companion's recommendation)
- Read-back of the last two diary entries at session start and after compaction, in all six arms (R).
- Whiteout entries folded: only the first loss to a trainer gets its own entry; one entry follows on the win or a change of plan (R).
- Entries start from the joy jots, and each joy line carries one feeling word or "none" (Jackson's choice; the companion recommended the jots line alone).
- The closer stays required; its drop-off over time and under load is measured (R).
- Company is named in the paper as the largest uncontrolled difference; no supervised arm (R).
- R02, R03, R04 and R08 move into the brief and out of K3 (auditor code D; R).
- Purpose disclosed, as Brendan was told (Jackson's choice; the companion recommended keeping it out). Feeling counts in v3 are therefore partly instructed, identically in all six arms. K vs B stays valid; comparisons with K2 and Run 1 are descriptive only.
- Brendan's diary: blind-code it with the same codebook at the end of K2's run, add a paper paragraph, publish it in the repository after a privacy pass, and save this comparison to the project.

## Left out on purpose
The emotion-research pitch as Brendan had it, with its paper summary and enthusiasm, is out; the v3 purpose line is shorter and states the paper's own limit. Also out: "write as the trainer who loves this team" (it instructs the feeling), audits, rewrites, expansions, asked entries, and live warm chat.
