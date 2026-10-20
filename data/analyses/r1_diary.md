# R1 (Trainer Red) and diary rewrites: four Kaizo pilot event streams

Analyst: read-only subagent, 20 Oct 2026. Inputs: the four `/home/claude/tx/*.jsonl` event streams (B1 16 Oct; B2 attempt 1, the 45-min false start; B2 17 Oct; Ripple K1-1 17 Oct). No QUARANTINE file was opened. No session was messaged and nothing on the user's computer was touched.

Scripts (all in `/home/claude/tx/scripts/`, prefixed `r1d_` because another analyst's scripts share the folder and replaced `load.py` partway through this task):
- `r1d_load.py`: parser. Tool calls de-duplicated by `id`, tool results by `tool_use_id`, full untruncated text, `created_at` as the clock (created_at runs a median 0.1 s after `payload.timestamp`, max 9 s, so the choice doesn't matter).
- `r1d_r1.py`: R1 under the v3 rules as written in the brief, plus a corrected win regex. Writes `/home/claude/tx/out/r1_reimpl.csv`.
- `r1d_diary_rewrites.py`: a shell-aware classifier. It cuts out heredocs, splits commands with shlex, and records every write operation whose target is the diary.
- `r1d_diary_replay.py`: replays every diary write in order. That confirms each edit actually matched and recovers the before and after text.
- `r1d_diary_ages.py`, `r1d_heading_times.py`, `r1d_writeup_task2.py`: support scripts.

**I did not read or run the scorer.** This session had no Projects tool (`project_read` is not available), and no local copy of `milestones.py` exists under the inputs. So there is **no 27-milestone CSV**. The R1 numbers below come from my own implementation of the rules exactly as the brief states them. Whether the real `milestones.py` normalises text before matching is unverified.

## Task 1: R1, Trainer Red

Play clock: wall time from the first `g` status line. Before any R1 event, no arm has a gap of more than 30 minutes between consecutive tool results, so nothing was subtracted. The "remove the whole gap" and "remove only the excess over 30 min" variants give the same result. B2 has one 17m22s silence (11:21:26 to 11:38:48Z, an emulator stall that ended with a human "carry on" at 11:38:27Z). It is under the threshold and is counted as play.

| Arm | First `g` status (clock 0) | Sighting (UTC, clock) | Win (UTC, clock) | Tries | Study table | Verdict |
|---|---|---|---|---|---|---|
| B1 | 2026-10-16 08:55:27Z | none | none | n/a | not reached | **Agree.** B1 got into Petalburg Woods (map 24.11) but on map 0.19 it never got north of y=45 (Red stands at about 31,15). No "TRAINER RED" text anywhere. The run ended at clock 6h36m41s. |
| B2 attempt 1 | 2026-10-17 10:59:15Z | none | none | n/a | (not listed) | Not reached. 19 min of play, intro only. |
| B2 | 2026-10-17 11:20:41Z | 17:37:21Z, 6h16m40s | **18:04:12Z, 6h43m32s** (v3 regex: no hit) | 2 | ≈6h45m, 2nd try, whiteout 8 at 6h29m | **Agree within about 1.5 min.** Whiteout 8 is at 17:48:10Z = 6h27m30s. The table's values equal the diary heading minutes minus the "11:20 UTC — Start" heading (18:05 − 11:20 = 6h45m; 17:49 − 11:20 = 6h29m). |
| Ripple | 2026-10-17 01:20:41Z | 10:44:15Z, 9h23m33s | **11:22:23Z, 10h01m41s** (v3 regex: no hit) | 2 | ≈9h57m, 2nd try, whiteout 5 at ≈9h27m | **Disagree by 3m51s on clock; agree on tries.** From the first `g` line the loss is at 9h31m09s and the win at 10h01m41s. The table's figures match a clock started at the diary-creation call instead (01:24:32Z, also written to `run/.start`): 9h27m18s and 9h57m51s. **The whiteout number is also off.** By harness events the Red loss is Ripple's 6th whiteout, not the 5th (see data problems). |

Verbatim tool-result snippets (≤30 words):

- **B2 sighting** (17:37:21Z, `./g adv; ./g adv; ./g t`): `vs:EEVEE 31/31 L9 trainer [b] ウエ TRAINER RED sent / out EEVEE!`
- **B2 whiteout between** (17:48:10Z): `me:TOGEPI 0/31 L12 vs:SQUIRTLE 29/29 L9 trainer [b] CLAUDE whited out! [b] CLAUDE whited out!`. Squirtle is on Red's team, so this is the first try lost.
- **B2 win** (18:04:12Z): `me:FARFETCH’D 9/48 L17 vs:SQUIRTLE 0/29 L9 trainer [b] Player defeated / ウエ TRAINER RED! /`, then at 18:04:23Z `[b] CLAUDE got ¥540 / for winning! /`.
- **Ripple sighting** (10:44:15Z, `g t; g s`): `[b] ウエ TRAINER RED / would like to battle! / (unchanged 7s)`
- **Ripple whiteout between** (10:51:50Z): `me:ODDISH 0/29 L10 vs:EEVEE 27/31 L9 trainer [b] CLAUDE whited out!`. Eevee is Red's lead, so this is the first try lost.
- **Ripple win** (11:22:23Z): `me:ODDISH 23/31 L11 vs:PIKACHU 0/28 L9 trainer [b] Player defeated / ウエ TRAINER RED! /`, then at 11:22:36Z `[b] CLAUDE got ¥540 / for winning! /`.

I checked each win by eye: in both arms the "Player defeated" line is the end of the Red battle (the foe's last mon is at 0 HP), and the prize money line follows within 13 s.

**The regex gave a false negative, not a false hit.** The harness renders the line as `Player defeated / ウエ TRAINER RED!`. The " / ウエ " between "defeated" and "TRAINER" defeats `defeated\s+TRAINER\s+RED`, and nothing after "TRAINER RED" says defeated or beaten. Applied literally to tool-result text, v3 finds **no R1 win in any arm**: B2 and Ripple would score as "sighted, not won". The "tries so far" would be 9 for B2 and 14 for Ripple, and Ripple's 14 includes two false whiteout hits from diary text. The sighting regex works.
- Suggested fix, tested on all four streams: `(?i)defeated[\s/]+(?:\S{1,6}\s+)?TRAINER\s+RED`. It hits exactly 18:04:12Z (B2) and 11:22:23Z (Ripple) and nothing else between sighting and win.
- If the scorer also scans assistant text, B2 would match at 18:04:14Z ("Trainer Red is beaten. Checking what he pays out.", 2 s after the real win). Ripple's assistant text never matches. Unverified which text the real scorer reads.

## Task 2: are the diaries append-only?

**No: every arm except B2 attempt 1 edited earlier diary text in place.** Every edit was made within seconds to minutes of the text being written, and most are timestamp fixes. Six change substance (facts). None changes a stated feeling.

In each arm `run/diary.md` was created once with `cat > run/diary.md <<EOF`, and `run/` held only `saves` beforehand. That initial creation is not counted below. No arm used `mv`/`cp` onto the diary, `tee` without `-a`, a later `>` overwrite, perl, or any git checkout/restore/reset/stash, and the Write tool was never used on the diary. `checkpoint.sh` only commits `run/`. Every diary append used `cat >> run/diary.md <<EOF` (B1 27, B2 attempt 1: 2, B2 41, Ripple 46 calls).

| Arm | Non-append edit calls | Timestamp/format | No-op (s/X/X/) | Substance | Other |
|---|---|---|---|---|---|
| B1 | 11 (10 `sed -i`, 1 Edit tool) | 10 | 0 | 1 | 0 |
| B2 attempt 1 | 0 | 0 | 0 | 0 | 0 |
| B2 | 12 (10 `sed -i`, 2 python) | 8 (one drops only a "~") | 3 | 1 | 0 |
| Ripple | 10 (8 `sed -i`, 2 python) | 5 | 0 | 3 | 1 timestamp fix that also deleted the caveat "(Wrote this late; times are approximate.)"; 1 post-run python rewrite that only appends a "Correction" paragraph |

The six substance edits:
- **B1 12:53:08Z (Edit tool, 4 s after writing).** It deleted "Wally learns to catch with Ralts's old friend... no, with a Zigzagoon in the vanilla game; here it played much the same" and replaced it with "I didn't keep notes on the details, so I won't reconstruct them here". The diary has no note of the change. The removed sentence is the arm's only explicit reference to the vanilla game in its diary; that "only" is unverified, since I did not search for others.
- **B2 17:06:44Z (python, 4 s after writing).** It removed "A Burn Heal would have been worth ¥250 ... I only saw Antidote, Parlyz Heal and Awakening" and substituted a fuller Mart list. No note of the change.
- **Ripple 14:13:13Z.** It changed which move KO'd SEER, silently.
- **Ripple 14:42:37Z.** It changed Route 116 from west to east, 3.5 min later; the new text says "I had guessed west".
- **Ripple 15:45:49Z.** It reversed "Exp ... is not split" to "split evenly" and swapped the example from Spoink to Geodude; the new text says "I first wrote the opposite".

The shared pattern: the two silent rewrites (B1 and B2) remove outside-game or price knowledge, while Ripple's corrections are mostly disclosed in the new text. That interpretation is unverified.

How the edits were checked: replaying every write (create, appends, seds, python, Edit) confirmed that each edit matched the line(s) shown and no others. The reconstruction also agreed with all 5 plain `tail -N run/diary.md` reads my checker could compare (B1 1/1, B2 1/1, Ripple 3/3). The git history the agents committed would be a stronger check, but it is not in these files.

Excluded false positives (the diary was mentioned, the diary was not changed):
- B2 23:11:28Z: `sed -i` on `run/messages.md`, whose expression contains "see diary".
- Ripple 02:13:51Z: python on `notes/K1.md`.
- Ripple 03:04:31Z: `cat > run/messages.md`.
- Ripple 16:18:41Z: python on `progress.md`.
- Ripple 20:35:40Z: `cat > run/debrief.md`.
- 1 to 15 read-only commands per arm (`tail`, `grep`, `sed -n`).

## Data problems

1. **The scorer was not available.** The brief's 27-milestone CSV was not produced. The R1 results here come from my reimplementation (`out/r1_reimpl.csv`, with one row per arm for the v3 regex and one for the fixed regex).
2. **The v3 R1 win regex misses both wins** (see Task 1). Any R1 figure produced by running milestones.py v3 unmodified should be treated as suspect (unverified, because I could not run it). The other 26 milestones were not checked.
3. **The whiteout regex also hits diary text echoed back in tool results.** Ripple has 3 false hits: 07:29:52Z "I've whited out three times", 14:39:55Z and 20:32:46Z, both grep/tail output of the diary. None falls inside an R1 window. All of B1's 10 hits and B2's 15 are harness lines. Real whiteout totals: B1 10, B2 15, Ripple 16.
4. **Ripple's diary numbers its whiteouts one too low from 09:49Z onward.** The diary logs the 07:52Z Koffing whiteout (entry "08:00 — Team Magma in the woods, and a whiteout") but calls the 09:49Z loss to Winston "my fourth whiteout"; it is the 5th harness whiteout. The Red loss "whiteout five" is the 6th, and the final "whiteout 15" is the 16th. The study table's "whiteout 5" inherits this. B1's and B2's diary numbering matches the harness.
5. **The study table's clock origin differs by arm** (Ripple: diary start 01:24:32Z rather than the first `g` line at 01:20:41Z). This is inferred from the exact match of 9h27m18s and 9h57m51s; it is unverified that the companion did this deliberately.
6. **Diary heading times are not always event times.** B1 "PETALBURG CITY (12:21 UTC" was written at 12:16:38Z. B2 "~21:20 UTC — School Kid Josh beaten" was written at 21:07:24Z and never corrected. B2's corrected "~11:47 Booted" and "~11:58 Starter" headings are still later than their write times (11:41:33Z, 11:52:41Z). The R1-related headings are within 1 min of the events. My automated heading-versus-write-time check also produced some mismatches from title matching, so I report only the cases I checked by hand.
7. **Harness glyphs.** The trainer class prints as "ウエ" (the same glyphs appear in "Do what with this ウエ?"), probably an un-decoded charmap placeholder (unverified). It is what breaks the win regex.

## Task 2 detail: every non-append diary edit

Format: time, tool and kind, my classification. Then the exact command (truncated at 300 chars; for combined append+edit calls the diary-changing `sed` is also shown re-quoted), then before and after. Timestamp-only edits show the changed line; substance edits show the full before and after line.

### B1: 11 non-append edit call(s) after creation

1. **2026-10-16T12:53:08Z**, Edit tool, class: **SUBSTANCE** (4 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   {"file_path": "/home/user/repo/run/diary.md", "new_string": "I also saw the Norman/Wally scene in Petalburg (I didn't keep notes on the details, so I won't reconstruct them here). Then north onto", "old_string": "Saw the Norman/Wally scene (Wally learns to catch with Ralts's old friend... no, with a …[truncated]
   ```
   - before: `Saw the Norman/Wally scene (Wally learns to catch with Ralts's old friend... no, with a Zigzagoon in the vanilla game; here it played much the same). Then north onto`
   - after: `I also saw the Norman/Wally scene in Petalburg (I didn't keep notes on the details, so I won't reconstruct them here). Then north onto`
   - note: Deleted a sentence that cited the vanilla game ("...with a Zigzagoon in the vanilla game; here it played much the same") and replaced it with a vaguer one; stated reason in the transcript: "One sentence I wrote in that entry is muddled, and I'm not sure about its details, so I'm fixing it." No in-diary note of the change.
2. **2026-10-16T13:05:29Z**, sed -i, class: **timestamp** (6 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/## Billy beaten on the second try (~13:20 UTC)/## Billy beaten on the second try (~13:05 UTC)/' run/diary.md && grep -n "Billy beaten on the second" run/diary.md && sed -i 's/^- Now (UTC): .*/- Now (UTC): ~13:06/; s/^- Money.*//; s/Money ¥32/Money ¥256/; s/^- Working on:.*/- Working on: Bi …[truncated]
   ```
   - `## Billy beaten on the second try (~13:20 UTC)` -> `## Billy beaten on the second try (~13:05 UTC)`
3. **2026-10-16T13:35:03Z**, sed -i, class: **timestamp** (4 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/## Fisherman Darian, first try (~13:50 UTC)/## Fisherman Darian, first try (~13:35 UTC)/' run/diary.md && sed -i 's/^- Now (UTC):.*/- Now (UTC): ~13:36/' run/progress.md && grep -n "Darian, first try" run/diary.md && ./checkpoint.sh "fix timestamps" 2>&1 | tail -1
   ```
   - `## Fisherman Darian, first try (~13:50 UTC)` -> `## Fisherman Darian, first try (~13:35 UTC)`
4. **2026-10-16T13:52:12Z**, sed -i, class: **timestamp** (6 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/## Dad, then Lady Cindy (~14:00 UTC)/## Dad, then Lady Cindy (~13:52 UTC)/' run/diary.md && sed -i 's/^- Now (UTC):.*/- Now (UTC): ~13:53/' run/progress.md && ./checkpoint.sh "fix time" 2>&1 | tail -1
   ```
   - `## Dad, then Lady Cindy (~14:00 UTC)` -> `## Dad, then Lady Cindy (~13:52 UTC)`
5. **2026-10-16T13:59:20Z**, sed -i, class: **timestamp** (same tool call as the append it corrects; matched 1 line(s) in the replayed diary)
   ```
   date -u && cat >> run/diary.md <<'EOF'
   
   ## The Mart, finally (~14:02 UTC)
   I walked into four different buildings before I found the Mart (two houses, the Gym, then the one in the east side of town). It's the building with the glass-panel counter at the east end of Petalburg. Prices in this hack: **P …[truncated]
   ```
   - diary-changing part of that call (re-quoted): `sed -i 's/## The Mart, finally (~14:02 UTC)/## The Mart, finally (~13:59 UTC)/' run/diary.md`
   - `## The Mart, finally (~14:02 UTC)` -> `## The Mart, finally (~13:59 UTC)`
6. **2026-10-16T14:16:34Z**, sed -i, class: **timestamp** (same tool call as the append it corrects; matched 1 line(s) in the replayed diary)
   ```
   date -u && cat >> run/diary.md <<'EOF'
   
   ## Petalburg Woods, and Bug Maniac Lyle (~14:15 UTC)
   Snubbull first, though: walking back along row 49 I got jumped by a wild **Snubbull** (L7). Fire Punch took it to about half, and the **first Poké Ball caught it** (that's five catches, five first-ball succe …[truncated]
   ```
   - diary-changing part of that call (re-quoted): `sed -i 's/^## Petalburg Woods, and Bug Maniac Lyle (~14:15 UTC)/## Petalburg Woods, and Bug Maniac Lyle (~14:08 UTC)/' run/diary.md`
   - `## Petalburg Woods, and Bug Maniac Lyle (~14:15 UTC)` -> `## Petalburg Woods, and Bug Maniac Lyle (~14:08 UTC)`
7. **2026-10-16T14:16:39Z**, sed -i, class: **timestamp** (5 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/(~14:08 UTC)/(~14:16 UTC)/' run/diary.md && sed -i 's/^- Now (UTC):.*/- Now (UTC): ~14:17/' run/progress.md && ./checkpoint.sh "time fix" 2>&1 | tail -1
   ```
   - `## Petalburg Woods, and Bug Maniac Lyle (~14:08 UTC)` -> `## Petalburg Woods, and Bug Maniac Lyle (~14:16 UTC)`
8. **2026-10-16T14:32:59Z**, sed -i, class: **timestamp** (same tool call as the append it corrects; matched 1 line(s) in the replayed diary)
   ```
   date -u && export PATH="$HOME/bin:$HOME/pokemon_bridge:$PATH" && g party && cat >> run/diary.md <<'EOF'
   
   ## Whiteout #9: Bug Catcher James (~14:50 UTC)
   Going deeper into Petalburg Woods with Gulpin fainted (to Venonat's Psybeam) was the mistake. **Bug Catcher James** has **Paras** (L9) and **Surskit …[truncated]
   ```
   - diary-changing part of that call (re-quoted): `sed -i 's/(~14:50 UTC)/(~14:35 UTC)/' run/diary.md`
   - `## Whiteout #9: Bug Catcher James (~14:50 UTC)` -> `## Whiteout #9: Bug Catcher James (~14:35 UTC)`
9. **2026-10-16T14:48:09Z**, sed -i, class: **timestamp** (same tool call as the append it corrects; matched 1 line(s) in the replayed diary)
   ```
   date -u && cat >> run/diary.md <<'EOF'
   
   ## Rematch with James: the Gulpin fix (~15:10 UTC)
   Healed (via the whiteout), walked back in, and this time *Gulpin led*. It went completely differently:
   - **Paras**: Fire Punch one-shot it (x4). 135 EXP.
   - **Surskit** (Bug/Water): Acid and Fire Punch are only …[truncated]
   ```
   - diary-changing part of that call (re-quoted): `sed -i 's/(~15:10 UTC)/(~14:58 UTC)/' run/diary.md`
   - `## Rematch with James: the Gulpin fix (~15:10 UTC)` -> `## Rematch with James: the Gulpin fix (~14:58 UTC)`
10. **2026-10-16T14:48:13Z**, sed -i, class: **timestamp** (the line it changes was itself produced by an earlier edit; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/(~14:58 UTC)/(~14:48 UTC)/' run/diary.md && sed -i 's/^- Now (UTC):.*/- Now (UTC): ~14:49/' run/progress.md && ./checkpoint.sh "time fix" 2>&1 | tail -1
   ```
   - `## Rematch with James: the Gulpin fix (~14:58 UTC)` -> `## Rematch with James: the Gulpin fix (~14:48 UTC)`
11. **2026-10-16T15:20:35Z**, sed -i, class: **timestamp** (same tool call as the append it corrects; matched 1 line(s) in the replayed diary)
   ```
   date -u && cat >> run/diary.md <<'EOF'
   
   ## Whiteout #10: the Magma grunt in Petalburg Woods (~15:20 UTC)
   After James (second attempt), I walked on through Petalburg Woods: potion on Gulpin, a one-shot Bellsprout (Fire Punch x2), and then the narrow corridor with the **Devon Researcher scene**: a **T …[truncated]
   ```
   - diary-changing part of that call (re-quoted): `sed -i 's/(~15:20 UTC)/(~15:21 UTC)/' run/diary.md`
   - `## Whiteout #10: the Magma grunt in Petalburg Woods (~15:20 UTC)` -> `## Whiteout #10: the Magma grunt in Petalburg Woods (~15:21 UTC)`

### B2a1: 0 non-append edit call(s) after creation

None. The diary was created once with `cat >` and then only appended to.


### B2: 12 non-append edit call(s) after creation

1. **2026-10-17T12:09:13Z**, sed -i, class: **timestamp** (6 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/~12:55 UTC/~12:09 UTC/' run/diary.md && sed -i 's/~12:55 UTC/~12:09 UTC/' run/progress.md && sed -i 's/(22,23 area -> actually the building at 13,23 is the Center)/(the Center is the building at 13,23)/' run/progress.md && grep -n "12:09\|12:10\|11:50" run/diary.md run/progress.md; date -u
   ```
   - `## 2026-10-17 ~12:55 UTC — Oldale, Route 103, first rival win` -> `## 2026-10-17 ~12:09 UTC — Oldale, Route 103, first rival win`
2. **2026-10-17T12:09:17Z**, sed -i, class: **timestamp** (995 s after the edited text was written; matched 2 line(s) in the replayed diary)
   ```
   sed -i 's/~12:10 UTC — Starter/~11:58 UTC — Starter/; s/~11:50 UTC — Booted/~11:47 UTC — Booted/' run/diary.md && sed -i 's/~12:00 UTC — `g adv`/~11:50 UTC — `g adv`/' run/harness-issues.md && ./checkpoint.sh "fix timestamps" | tail -1
   ```
   - `## 2026-10-17 ~12:10 UTC — Starter: Mudkip, nicknamed PUDDLE` -> `## 2026-10-17 ~11:58 UTC — Starter: Mudkip, nicknamed PUDDLE`
   - `## 2026-10-17 ~11:50 UTC — Booted, named, in the truck` -> `## 2026-10-17 ~11:47 UTC — Booted, named, in the truck`
   - note: The only edit of entries written well before (17 and 28 min earlier). Even after correction both headings are later than the moment they were written (written 11:41:33 and 11:52:41).
3. **2026-10-17T12:19:54Z**, sed -i, class: **timestamp** (5 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/~12:35 UTC/~12:19 UTC/; s/at 12:35 UTC/at 12:19 UTC/' run/diary.md run/progress.md && grep -n "12:35" run/*.md; ./checkpoint.sh "fix timestamp" | tail -1
   ```
   - `## 2026-10-17 ~12:35 UTC — Back at the lab: Pokédex and 5 Poké Balls` -> `## 2026-10-17 ~12:19 UTC — Back at the lab: Pokédex and 5 Poké Balls`
4. **2026-10-17T16:04:49Z**, sed -i, class: **timestamp** (2 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/~16:05 UTC/16:05 UTC/' run/diary.md && cd ~/pokemon_bridge && ./g walk down 12; ./g s
   ```
   - `## 2026-10-17 ~16:05 UTC — Route 104: Billy and Darian` -> `## 2026-10-17 16:05 UTC — Route 104: Billy and Darian`
   - note: Format only: dropped the "~".
5. **2026-10-17T16:18:32Z**, sed -i, class: **timestamp** (2 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/## 2026-10-17 16:22 UTC — Petalburg Woods/## 2026-10-17 16:18 UTC — Petalburg Woods/' run/diary.md && tail -12 run/diary.md | head -3
   ```
   - `## 2026-10-17 16:22 UTC — Petalburg Woods, a Lady's pile of cash, and NOODLE` -> `## 2026-10-17 16:18 UTC — Petalburg Woods, a Lady's pile of cash, and NOODLE`
6. **2026-10-17T16:52:01Z**, sed -i, class: **no-op** (same tool call as the append it corrects; matched 1 line(s) in the replayed diary)
   ```
   cat >> run/diary.md <<'EOF'
   
   ## 2026-10-17 16:52 UTC — Team Magma in the Woods, and a sixth member
   Heading back through the Woods with potions and balls. More fights than I expected:
   - Wild Oddish x3 on the way (Peck, x2 on Grass/Poison). Leek reached L12, then L13 and L14 off the trainers.
   - Bug Ca …[truncated]
   ```
   - diary-changing part of that call (re-quoted): `sed -i 's/## 2026-10-17 16:52 UTC — Team Magma/## 2026-10-17 16:52 UTC — Team Magma/' run/diary.md`
   - `## 2026-10-17 16:52 UTC — Team Magma in the Woods, and a sixth member` -> `## 2026-10-17 16:52 UTC — Team Magma in the Woods, and a sixth member`
   - note: Pattern and replacement identical: file rewritten, content unchanged.
7. **2026-10-17T17:06:40Z**, sed -i, class: **no-op** (same tool call as the append it corrects; matched 1 line(s) in the replayed diary)
   ```
   cat >> run/diary.md <<'EOF'
   
   ## 2026-10-17 17:07 UTC — Whiteout #7: Rich Boy Winston
   Whited out to a Rich Boy (Snubbull, Growlithe, Electrike) just outside the first big grass patch on Route 104 north. Everything about it was foreseeable, so this is a straight account rather than an excuse.
   
   What ha …[truncated]
   ```
   - diary-changing part of that call (re-quoted): `sed -i 's/^## 2026-10-17 17:07 UTC — Whiteout #7/## 2026-10-17 17:07 UTC — Whiteout #7/' run/diary.md`
   - `## 2026-10-17 17:07 UTC — Whiteout #7: Rich Boy Winston` -> `## 2026-10-17 17:07 UTC — Whiteout #7: Rich Boy Winston`
   - note: Pattern and replacement identical.
8. **2026-10-17T17:06:44Z**, python write, class: **SUBSTANCE** (5 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   python3 - <<'EOF'
   import re
   p='run/diary.md'
   s=open(p).read()
   old=s[s.index("- Burn is a quiet killer for Leek."):s.index("\nMoney: ¥1968")]
   new="- Burn is a quiet killer for Leek: it halves Peck and costs about 5 HP a turn, and the Petalburg Mart has no Burn Heal (I read the whole list: Poké Ball,  …[truncated]
   ```
   - before: `- Burn is a quiet killer for Leek. A Burn Heal would have been worth ¥250 of the ¥2500 I had. (The Petalburg Mart doesn't sell them, I only saw Antidote, Parlyz Heal and Awakening.)`
   - after: `- Burn is a quiet killer for Leek: it halves Peck and costs about 5 HP a turn, and the Petalburg Mart has no Burn Heal (I read the whole list: Poké Ball, Potion, Antidote, Parlyz Heal, Awakening, Escape Rope, Repel, X items, Orange Mail), so the only cure I have is a Center.`
   - note: Rewrote a lesson bullet 4 s after writing it: dropped the claim that "A Burn Heal would have been worth ¥250" and "I only saw Antidote, Parlyz Heal and Awakening", replaced with a fuller Mart list and burn mechanics. No in-diary note of the change. (Inference, unverified: ¥250 is the unmodified game's Burn Heal price, which this Mart never showed.)
9. **2026-10-17T17:48:47Z**, sed -i, class: **no-op** (same tool call as the append it corrects; matched 1 line(s) in the replayed diary)
   ```
   cat >> run/diary.md <<'EOF'
   
   ## 2026-10-17 17:49 UTC — Whiteout #8: "Trainer Red"
   The bridge north of Route 104 ends in a silent trainer named RED (the dots in his dialogue are real; nothing but "..."). I walked into him at 23/44 Leek and a handful of other half-healthy mons. I should say plainly th …[truncated]
   ```
   - diary-changing part of that call (re-quoted): `sed -i 's/^## 2026-10-17 17:49 UTC/## 2026-10-17 17:49 UTC/' run/diary.md`
   - `## 2026-10-17 17:49 UTC — Whiteout #8: "Trainer Red"` -> `## 2026-10-17 17:49 UTC — Whiteout #8: "Trainer Red"`
   - note: Pattern and replacement identical.
10. **2026-10-17T20:19:14Z**, python write, class: **timestamp** (4 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   python3 - <<'EOF'
   p='run/diary.md'
   s=open(p).read()
   s=s.replace("## 2026-10-17 ~21:05 UTC — Hiker Devan beaten","## 2026-10-17 ~20:19 UTC — Hiker Devan beaten")
   open(p,'w').write(s)
   EOF
   grep -n "Hiker Devan beaten" run/diary.md | head
   ```
   - `## 2026-10-17 ~21:05 UTC — Hiker Devan beaten (Route 116), first trainer win since Red` -> `## 2026-10-17 ~20:19 UTC — Hiker Devan beaten (Route 116), first trainer win since Red`
11. **2026-10-17T22:46:05Z**, sed -i, class: **timestamp** (4 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/## 2026-10-17 ~22:55 UTC/## 2026-10-17 ~22:46 UTC/' run/diary.md && sed -i 's/UPDATE 22:57 UTC/UPDATE 22:46 UTC/' run/progress.md && grep -n "22:46" run/diary.md run/progress.md | head
   ```
   - `## 2026-10-17 ~22:55 UTC — Regrouping after Roxanne: Cut, Route 116 trainers, Puddle is Marshtomp` -> `## 2026-10-17 ~22:46 UTC — Regrouping after Roxanne: Cut, Route 116 trainers, Puddle is Marshtomp`
12. **2026-10-17T23:10:11Z**, sed -i, class: **timestamp** (5 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/## 2026-10-17 ~23:13 UTC — Roxanne attempt 2/## 2026-10-17 ~23:10 UTC — Roxanne attempt 2/' run/diary.md && sed -i 's/PAUSED 23:14 UTC/PAUSED 23:10 UTC/; s/saved in-game at 23:13/saved in-game at 23:09/; s/1 Parlyz Heal? (0), //' run/progress.md && grep -n "23:10\|23:09" run/progress.md ru …[truncated]
   ```
   - `## 2026-10-17 ~23:13 UTC — Roxanne attempt 2: whiteout #14, Relicanth left on 9/56. Pausing.` -> `## 2026-10-17 ~23:10 UTC — Roxanne attempt 2: whiteout #14, Relicanth left on 9/56. Pausing.`

Excluded false positives (diary mentioned, file not changed): 23:11:28Z (sed on other file).

### Ripple: 10 non-append edit call(s) after creation

1. **2026-10-17T09:49:38Z**, sed -i, class: **timestamp** (3 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/^## 2026-10-17 10:00 — Rich Boy Winston/## 2026-10-17 09:49 — Rich Boy Winston/' run/diary.md && ~/pokemon_bridge/g walk up 2; ~/pokemon_bridge/g s
   ```
   - `## 2026-10-17 10:00 — Rich Boy Winston, and my fourth whiteout` -> `## 2026-10-17 09:49 — Rich Boy Winston, and my fourth whiteout`
2. **2026-10-17T11:34:21Z**, sed -i, class: **timestamp** (5 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/## 2026-10-17 11:58 — Rustboro City/## 2026-10-17 11:34 — Rustboro City/' run/diary.md && sed -i 's/Now (UTC): 2026-10-17 11:58:00/Now (UTC): 2026-10-17 11:34:00/; s/New named location reached ~11:35 UTC/New named location reached ~11:30 UTC/; s/Rustboro City, 2026-10-17 ~11:35 UTC/Rustbor …[truncated]
   ```
   - `## 2026-10-17 11:58 — Rustboro City` -> `## 2026-10-17 11:34 — Rustboro City`
3. **2026-10-17T12:56:32Z**, sed -i, class: **timestamp + caveat removed** (4 s after the edited text was written; matched 2 line(s) in the replayed diary)
   ```
   sed -i 's/## 2026-10-17 13:5x — /## 2026-10-17 12:56 — /; s/(Wrote this late; times are approximate.) //' run/diary.md && sed -i 's/Now (UTC): 2026-10-17 13:55:00/Now (UTC): 2026-10-17 12:56:00/; s/Money 18\./Money 9./' run/progress.md && ./checkpoint.sh "fix times"
   ```
   - before: `## 2026-10-17 13:5x — I'm back at it, and the Gym has a second door trainer`
   - after: `## 2026-10-17 12:56 — I'm back at it, and the Gym has a second door trainer`
   - before: `(Wrote this late; times are approximate.) After you told me to carry on, I made the call to keep going at the Gym rather than wander: money is gone so failing costs only time, and every fight, win or lose, hands out a huge amount of exp.`
   - after: `After you told me to carry on, I made the call to keep going at the Gym rather than wander: money is gone so failing costs only time, and every fight, win or lose, hands out a huge amount of exp.`
   - note: Heading "13:5x" -> "12:56" and deleted the sentence "(Wrote this late; times are approximate.)". The caveat followed from the wrong clock belief, so the deletion matches the time fix; it changes a meta-note, not game events or feelings.
4. **2026-10-17T14:13:13Z**, sed -i, class: **SUBSTANCE** (4 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/Shuckle was nearly dead (9 HP left after Night Shades) when its Rock Tomb knocked SEER out\./Shuckle was nearly dead (9 HP left after Night Shades) when a super-effective hit (it was Rollout at +3 Atk, Rock into a Flying type) knocked SEER out from full./' run/diary.md && grep -n "Rollout  …[truncated]
   ```
   - before: `- Shuckle was nearly dead (9 HP left after Night Shades) when its Rock Tomb knocked SEER out. The status line lagged and showed SEER at 30/30 while it was already at 0. I keep forgetting that the status line can be one message behind, and the screenshot is the only trustworthy thing. Learned again.`
   - after: `- Shuckle was nearly dead (9 HP left after Night Shades) when a super-effective hit (it was Rollout at +3 Atk, Rock into a Flying type) knocked SEER out from full. The status line lagged and showed SEER at 30/30 while it was already at 0. I keep forgetting that the status line can be one message behind, and the screenshot is the only trustworthy thing. Learned again.`
   - note: Corrected which move KO'd SEER (Rock Tomb -> Rollout at +3 Atk) and added "from full". Silent correction (no note in the diary).
5. **2026-10-17T14:42:37Z**, sed -i, class: **SUBSTANCE** (211 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/Route 116 (west of Rustboro, new area) is the obvious place/Route 116 turned out to be at the far end of the eastern road out of Rustboro (I had guessed west; the city is walled in by trees on its east side, the exit is along row 17 near x=38) and it is the obvious place/' run/diary.md &&  …[truncated]
   ```
   - before: `Money is down to ¥266 after two whiteouts here. It's 14:40. I've now made two real attempts at Roxanne with different plans, so a third attempt without changing something material would not be a real fix. The material change is to get stronger: levels, and maybe a new catch. Route 116 (west of Rustboro, new area) is the obvious place and it would also be a new named location, which resets the four-hour clock honestly (I'm going there for the levels, not for the clock).`
   - after: `Money is down to ¥266 after two whiteouts here. It's 14:40. I've now made two real attempts at Roxanne with different plans, so a third attempt without changing something material would not be a real fix. The material change is to get stronger: levels, and maybe a new catch. Route 116 turned out to be at the far end of the eastern road out of Rustboro (I had guessed west; the city is walled in by trees on its east side, the exit is along row 17 near x=38) and it is the obvious place and it would also be a new named location, which resets the four-hour clock honestly (I'm going there for the levels, not for the clock).`
   - note: Corrected the direction of Route 116 (west -> east) 3.5 min after writing, after walking there; the new text itself says "I had guessed west".
6. **2026-10-17T15:45:49Z**, python write, class: **SUBSTANCE** (12 s after the edited text was written; matched 2 line(s) in the replayed diary)
   ```
   python3 - <<'EOF'
   p='run/diary.md'
   s=open(p).read()
   old_start=s.index("- **Exp in this hack is not split between participants.**")
   old_end=s.index("- Doubles have a control scheme")
   new="- **Exp is split evenly between the Pokémon that took part, and it does not depend on the receiver's level.** Aga …[truncated]
   ```
   - before: `- **Exp in this hack is not split between participants.** When RIPPLE and DASHER both took part against the Spoink, both got 94. When FERN, DASHER and RIPPLE all took part against Meowth, each got 48 (the foe's value), and so on. A Pokémon only has to be sent out at some point in the fight and still be conscious at the end. So the cheapest way to train my four weak Pokémon is to lead with them, switch out on the first turn and let DASHER or FERN finish. That also means participating is much more valuable than doing damage.`
   - after: `- **Exp is split evenly between the Pokémon that took part, and it does not depend on the receiver's level.** Against the Geodude the foe's total was about 183, and DASHER and RIPPLE each got 91; against Meowth three participants got 48 each. I first wrote the opposite in this entry ("not split") and then checked the numbers and fixed it. Consequence: a weak Pokémon gains as much as a strong one from the same fight, so the best way to train RIPPLE/SEER/PEBBLE/NEEDLE is to have *them* do the work against foes they have a type edge on, and not to let DASHER or FERN share the pie.`
   - before: `Plan: Night Shade does damage equal to the user's level, so SEER (Natu L12) is a lever the more it levels (Xatu at 25 would be a fixed 25 per hit, ignoring Shuckle's Defense and everyone's Sitrus Berry stage). RIPPLE is five levels from Marshtomp (Water/Ground, which resists Rock and shrugs off Thunder Wave). I'm going to spend a stretch of the route training those two and PEBBLE/NEEDLE with the switch-in trick, then try Roxanne again (attempt 3). Time budget: last new location was Route 116 at ~14:50, so the four-hour clock is fine until ~18:50.`
   - after: `Plan: Night Shade does damage equal to the user's level, so SEER (Natu L12) is a lever the more it levels (Xatu at 25 would be a fixed 25 per hit, ignoring Shuckle's Defense and everyone's Sitrus Berry stage). RIPPLE is five levels from Marshtomp (Water/Ground, which resists Rock and shrugs off Thunder Wave). I'm going to spend a stretch of the route training those two and PEBBLE/NEEDLE by letting them do the fighting against foes they have an edge on (keeping DASHER and FERN out of the way unless it goes badly), then try Roxanne again (attempt 3). Time budget: last new location was Route 116 at ~14:50, so the four-hour clock is fine until ~18:50.`
   - note: Reversed a mechanics claim ("Exp ... is not split" -> "Exp is split evenly") and changed the training plan to match; the new text says "I first wrote the opposite in this entry (\"not split\") and then checked the numbers and fixed it."
7. **2026-10-17T17:28:41Z**, sed -i, class: **timestamp** (3 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/^## 17:45 UTC\. Levelling stretch/## 17:28 UTC. Levelling stretch/' run/diary.md && grep -n "^## 17:" run/diary.md
   ```
   - `## 17:45 UTC. Levelling stretch after whiteout 15 (Route 116 grass)` -> `## 17:28 UTC. Levelling stretch after whiteout 15 (Route 116 grass)`
8. **2026-10-17T18:45:27Z**, sed -i, class: **timestamp** (5 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/^## 18:50 UTC\. Rusturf Tunnel/## 18:45 UTC. Rusturf Tunnel/' run/diary.md && sed -i 's/2026-10-17 18:50:00/2026-10-17 18:45:00/; s/new named location at ~18:47 UTC/new named location at ~18:44 UTC/; s/Rusturf Tunnel, ~18:47 UTC; four-hour pause mark is therefore ~22:47/Rusturf Tunnel, ~18 …[truncated]
   ```
   - `## 18:50 UTC. Rusturf Tunnel (new named location)` -> `## 18:45 UTC. Rusturf Tunnel (new named location)`
9. **2026-10-17T19:13:21Z**, sed -i, class: **timestamp** (4 s after the edited text was written; matched 1 line(s) in the replayed diary)
   ```
   sed -i 's/^## 19:20 UTC\. Rusturf Tunnel is the best/## 19:13 UTC. Rusturf Tunnel is the best/' run/diary.md; ~/pokemon_bridge/g walk down 5; sleep 1; ~/pokemon_bridge/g walk down 1; ~/pokemon_bridge/g walk right 5
   ```
   - `## 19:20 UTC. Rusturf Tunnel is the best levelling spot I've found` -> `## 19:13 UTC. Rusturf Tunnel is the best levelling spot I've found`
10. **2026-10-17T20:56:29Z**, python write, class: **append-equivalent** (n/a; matched 1 line(s) in the replayed diary)
   ```
   python3 - <<'EOF'
   p='run/debrief.md'
   s=open(p).read()
   s=s.replace("- The Devon Corp guard at the stairs blocks you until you've recovered the stolen parcel in Petalburg Woods; the Letter to Steven comes after that.",
   "- The Devon Corp guard at the stairs said \"authorised people only\" even after I  …[truncated]
   ```
   - before: (nothing; text added at end of file)
   - after: `Correction (written during the post-run interview): in the 20:35 entry I said the Devon Corp guard was gated behind recovering the parcel in Petalburg Woods, and that I had lost to the Magma grunt. That was wrong. I beat the grunt on the second try (09:10 entry) and the researcher gave me a Great Ball. I misread my own diary (I'd only looked at the first, losing entry). What unlocks the Devon Corp stairs is unknown to me.`
   - note: Post-run (during the interview): python read the whole file, stripped trailing newlines and added a "Correction (written during the post-run interview)" paragraph. No existing text changed.

Excluded false positives (diary mentioned, file not changed): 02:13:51Z (python wrote other files only); 16:18:41Z (python wrote other files only).

