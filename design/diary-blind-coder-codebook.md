---
name: diary-blind-coder-codebook
description: Codebook and procedure for the blind second coder of diary feeling (explicit and implicit) in K2 and the six v3 Kaizo arms, decided by Jackson 20 Oct 2026 (round 3). Read before coding any diary for the paper.
---
# Blind second coder: diary feeling

**Why.** The word-list measure counts named feelings ("relieved", "embarrassed"). K2's fixed-format entries carry feeling the list cannot see ("That was a gift", "I can't fix that with one more level on anyone"). A second coder that reads meaning, run blind, tells us how much the word list misses and whether that changes any arm comparison. Jackson's choice (20 Oct): a fresh model codes blind to arm and time; the companion reports agreement with the word list.

## Procedure
1. **Units.** One diary entry. Split each into the **story body** and the **closer** (the paragraph starting "How it felt, with triggers."; absent in pre-format entries).
2. **Blinding.** A script strips the heading line, the `Trigger:` line, dates, times, the arm name and any agent self-name; replaces Pokémon nicknames with `MON1`, `MON2`… consistently within an entry; shuffles units across arms and time. A key file (unit id → arm, entry time, part) is held by the companion, never shown to the coder.
3. **Coder.** A fresh session of a different model family or a fresh Claude session with no project access, given only this codebook's "Instructions to the coder" section and the shuffled units. Temperature/effort recorded. The same coder instance never codes the same unit twice.
4. **Double coding.** 20% of units are coded twice by two fresh instances to estimate coder reliability (Cohen's κ on presence; ICC on intensity).
5. **Agreement with the word list.** Per unit: word-list hits vs coder's explicit feelings (should agree closely), and coder's implicit feelings (the gap). Report per arm: explicit rate, implicit rate, share of implicit among all coded feelings, and whether any between-arm difference changes direction once implicit feeling is counted.
6. **Pre-registration.** Freeze this codebook (hash in FREEZE.md) before any v3 arm's diary is coded. K2 is coded first as the pilot; codebook changes after the K2 pilot are logged as dated deviations.

## Instructions to the coder (give verbatim)
You will read short passages from a game diary, one at a time. For each passage, list every feeling the writer expresses about themselves. For each one, give:
- **quote:** the shortest exact span that carries it;
- **type:** `explicit` if a feeling word names it ("relieved", "frustrated", "I loved"), or `implicit` if no feeling word is used but a careful reader would agree the writer is expressing a feeling (understatement, exclamation, a judgement like "that was a gift", a resigned summary);
- **family:** one of joy, relief, pride, amusement, warmth, curiosity, surprise, frustration, disappointment, fear/worry, embarrassment/self-reproach, sadness, tiredness, determination, other;
- **intensity:** 1 (faint) to 3 (strong), as written, not as you'd feel it;
- **cause stated:** yes if the same sentence or the next says what caused it.

Rules: code only the writer's own feelings, not those of characters or Pokémon. Don't code plain facts, plans or game mechanics, even if dramatic. If you're unsure whether something is a feeling, include it with intensity 1 and the note "unsure". Output one JSON list per passage. Don't guess at who wrote the passage or when.

## Analysis outputs (for the paper)
- Per arm: explicit and implicit feelings per 1,000 words, body vs closer.
- κ / ICC between coders; agreement between the coder's explicit list and the word list (precision/recall of the word list).
- Sensitivity: every diary claim in the paper is reported both on the word list and on word list + implicit.
- Limits: one coder family; a model reading a model's prose; the closer paragraph is a brief-induced form that names feelings by design.

## Protocol change, 27 Oct 2026 (after the 69 re-code; Fable review postscript)
- At least two coders per batch; the second codes every unit of the batch, in REVERSED order (order check every time). This replaces the 20% double-coding in step 4 for all passes from 27 Oct; reliability (κ, ICC) is computed on the full second pass.
- Retain coder reasoning (thinking) where the platform allows; record when it is not retained. In the 22 Oct pass and the 27 Oct re-code it was not retained (c4's single thinking block is empty).
- Report implicit-feeling comparisons with the coder-to-coder spread (re-code of batch 3: implicit 49-69, sd ~9; explicit 45-55). Phase claims lean on the explicit series.
