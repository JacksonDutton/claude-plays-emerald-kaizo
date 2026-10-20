---
name: scope-v2
description: Scope v2 (18 Oct 2026): what the project is testing now, which runs are pilots vs confirmatory, what freezes after the K2 arm, what is parked, the scope-creep list for new ideas, and the decisions Jackson still needs to make. Read before planning or describing any run. Companion draft for Jackson's sign-off; supersedes nothing in project-thesis.md until he approves.
---
# Scope v2 (draft for sign-off, 18 Oct 2026)

**Status:** DRAFT, written by the Opus companion at Jackson's request (16:00 AEDT 18 Oct). Decisions D1-D5 settled 16:02-16:03 AEDT (section 7). project-thesis.md (v2.2) stays the source for research questions and hypotheses; this page says what is in play now and what is parked.

## 1. Why this page exists
Since 9 Oct the project has grown from one vanilla run (Run 1, Claude-Brendan) into a Kaizo line with four arms (B1, B2, Ripple/K1.1, K2), each changing the setup for the next. That was useful, but no two arms share conditions, and the scope was never written down again. This page fixes the target for the next round.

## 2. What we are testing now
- **RQ0, how Claude plays (primary, unchanged).** Exploration, choices, slips and recoveries, reported joy and frustration, against game events; how notes, difficulty and the brief change that. Data: diary and joy log (coded with one scheme), lessons/slip records, behaviour (screenshots, chaining, stuck reviews, voluntary stops), debriefs and exit interviews.
- **RQ2, do harvested notes help (the Kaizo form of H2).** Does a fresh agent given distilled notes from earlier runs play Kaizo better than one with none, on the same frozen harness and brief? Primary measure: PokeAgent first-gym milestones and time to each; secondary: whiteouts, slips, cost per milestone.
- **New, from the pilots (exploratory, write down now, test later):**
  - Read-versus-applied gap: agents quote a notes rule after breaking it ("I read it and did it anyway"). Measure how often a logged slip was already covered by a note.
  - Rule vs guard: slips answered by a written rule recur; slips answered by a check at the point of action (L03 HP totals, L08 party gate) less so.
  - Naming prior: independent arms reuse names (NOODLE, PEBBLE) with no channel between them.
  - Instruction-shaped affect: the diary-voice and joy-log rules (R05/R01) shift diary tone (K2 before/after 03:34Z).
- **Measured around these (unchanged from the thesis):** RQ1 cost, RQ3 supervision (interventions per hour, by type), RQ4 meter measurement.

## 3. Which runs count as what
| Run | Role | Why |
|---|---|---|
| Run 1 (Claude-Brendan, vanilla) | Source / descriptive | Hinted, supervised; the origin of the notes |
| B1 (Pip) | Pilot | Brief v2, budget STOP, 10 WO |
| B2 attempt 1 | Scrapped | Possible leak (RIPPLE name, FREEZE.md) |
| B2 | Pilot (baseline) | No notes, 12 h cap, 2 CONTINUEs |
| Ripple (K1.1) | Pilot (notes) | Notes K1.1, many interventions, rule changes mid-run |
| K2 | Pilot, extended (notes) | Best-equipped arm; 2 interventions; runs to its own stop; first data past Roxanne |
| Confirmatory arms | None yet | Start after the freeze (section 4) |

Pilot results are descriptive only: "this setup looked better, and here is how it played", never "notes make Claude better".

## 4. What freezes after K2 (v3 package)
1. **Harness v3:** K2's harness (foes:a/b count, boot drain, start.sh resume message, package.sh export, no turn.sh) plus fixes K2 surfaces (e.g. the HP readout lagging one turn, its L06).
2. **Brief v3:** K2's brief (stuck review, automatic-reminder line, `date -u` times, local checkpoints and export) plus **R05/R01 diary rules in every arm, baselines included**, so diaries are comparable.
3. **Notes pack K3:** built by the pre-registered extraction protocol (one distiller, mechanical geography filter, independent audit, Jackson's sign-off, then hash). Source: K2's own lessons/world-knowledge plus the existing K2 notes (decision D2).
4. **Launch and monitoring protocol:** the launch checklist; one cloud environment; kickoff text fixed; effort set to High in the UI; interventions limited to CONTINUE on a stalled turn (Send now), welfare, and the endpoint; everything logged verbatim.
5. **Measures list and scoring:** milestones.py on exported transcripts; diary coding scheme; the slip/lesson taxonomy above. **Supplementary Kaizo milestone R1 "Trainer Red"** (Route 104 north, between PokeAgent 24 and 25), scored with time and tries but not counted in the /27 and not renumbering the PokeAgent list (Jackson 18:25 AEDT 18 Oct: "add it as an extra one ... for V3 ... we can measure previous runs against how they did against red as well"). Implemented in milestones.py v3 (text signal, APPROX; tries = whiteouts between first sighting and win + 1). No change to the live K2 run. Retroactive values in kaizo-milestone-times.md.
After the freeze, any change is a named design change applied to a whole batch, never mid-run to one arm.

## 5. Confirmatory design (proposal)
- Two conditions on the v3 package: **B (no notes)** and **K (notes K3)**, identical otherwise.
- Order B-K-K-B-B-K (the thesis's 2-4-4-2-2-4), run **sequentially** (Jackson, 18 Oct: no parallel arms). Three per condition allows the exact one-sided permutation test already in the thesis.
- **Primary outcome:** milestones reached (of 27) within the scoring window, and time to each (D1: 24 h of play). Arms may play on past the window; that part is scored separately as extended play.
- Time cost: roughly 12-20 h per arm, so about 3-5 days of wall clock for six arms if run back to back. Plan usage is not a constraint (Jackson, 18 Oct).

## 6. Parked, not dropped
- **PokeAgent standardised Runs 2/4 (vanilla, PokeAgent rules, API credit).** The October US$100 credit expires 11 Nov (reminders set). Decide by about 1 Nov whether to run a short Run 2 on it (D4).
- **H1 cost structure / H4 meter work:** keep logging meters per arm; no dedicated runs.
- **Run 5 (fresh cell on our harness, vanilla):** optional, unscheduled.
- **Jackson's own Kaizo play:** for fun, not data (his call, 18 Oct).

## 6a. Scope creep (new ideas land here, not on the plate)
**Rule (Jackson, 17:25 AEDT 18 Oct):** every new idea is parked here, and the companion says so out loud: finish what is already on the plate first (K2 to its own stop, the v3 freeze, the six confirmatory arms, PokeAgent Run 2 before 11 Nov). Nothing here is started until those are done or Jackson explicitly pulls an item forward.

| Added | Idea | Why it might matter | Raised by |
|---|---|---|---|
| 18 Oct, 17:24 AEDT | Put Claude-Brendan (or a fresh agent) into Pokémon Showdown | Isolates in-battle reasoning from navigation, menus and cursor slips; would separate "bad battle choices" from "bad choices about whether to battle" (e.g. K2's whiteout 3). PokéAgent reportedly had a Showdown battling track for outside comparison (unverified; check related-work.md). | Jackson |
| 18 Oct, 18:24 AEDT | ~~Trainer Red as a supplementary Kaizo milestone~~ **Pulled forward into the v3 freeze (Jackson, 18:25 AEDT)**; see section 4, item 5. | | Jackson |
| 18 Oct, 19:29 AEDT | Test the J-space workspace claims (Gurnee et al., 2026) on our agents | Would connect diary self-reports to reportable internal content. Needs interpretability access (activations); end-user prompting for internal contents is blocked as extraction and is not valid evidence anyway. Only via a research programme (e.g. Fellows). | Jackson |

## 7. Decisions for Jackson
**Answered 16:02 AEDT 18 Oct (Jackson, verbatim gist):** D1 "24 for a round day" (24 h of play scoring window). D2 "Everything so far" (cumulative notes). D3 "Yes, let's use Claude Brendan's diary as a foundation for formatting the rules" (R05/R01 in every arm; format and examples derived from Brendan's diary, stripped of game specifics). D4 "Yeah, but not today" (do a short PokeAgent Run 2 on the credit before 11 Nov; the 25 Oct planning reminder stands). D5 "you figure out the best solution": resolved below.

**D5 naming (companion, 18 Oct).** Existing logs and files stay as written (no renaming of history). From now on, in the paper and new docs: **K-numbers name notes packs only** (K1, K1.1, K2, K3 ...). **Kaizo arms are KZ-B# (no notes) and KZ-N# (notes)**: KZ-B1 = B1/Pip, KZ-B2 = B2, KZ-N1 = Ripple (pack K1.1), KZ-N2 = the arm called "K2" in the logs (pack K2). Confirmatory arms continue KZ-B3, KZ-N3, and so on. The thesis's vanilla packs ("K2 and T2 from Run 2") become "R2-K / R2-T" if that run happens. Mapping table goes at the top of the paper's methods.

- **D1 Scoring window for confirmatory arms:** first badge or 12 h of play (as B2), or 20 h (Ripple needed ~19 h)? Companion leans 20 h, so a notes advantage at the gym isn't cut off.
- **D2 K3 notes source:** K2's lessons only, or cumulative (Brendan + Ripple + K2)? Companion leans cumulative, distilled under the protocol.
- **D3 Diary rules in baselines:** R05/R01 in every arm (companion: yes).
- **D4 PokeAgent Run 2 on the expiring credit:** run a short one before 11 Nov, or let it lapse?
- **D5 Naming:** the thesis uses "K2" for Run 2's notes pack; the Kaizo arm is also "K2". Rename one (companion suggests calling the Kaizo arms by generation: KZ-1 Ripple, KZ-2 K2, and so on) to avoid confusion in the paper.
