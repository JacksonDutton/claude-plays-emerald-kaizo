---
name: kaizo-milestone-times
description: PokeAgent first-gym milestone times (17-27) plus the supplementary Kaizo milestone R1 "Trainer Red" for every Kaizo arm (B1, B2, Ripple K1.1, K2), plus K2 beyond the first gym (badges 2-3, the Route 113 "Red" R2, Route 114; added 20 Oct), rebuilt 18 Oct from the arms' git histories (progress.md per checkpoint commit), diary headings and messages.md, with method and caveats. Companion, 18 Oct 2026. Update K2 as it plays. Pilot arms scored from their exported transcripts with milestones.py v3.1 on 20 Oct (section at the end); K2 at its export.
---
# Kaizo milestone times (PokeAgent 27, first gym, plus R1)

**Method.** Times are elapsed from each run's own `Start:` line in run/progress.md (run start, includes setup), minus logged pauses. Sources: every checkpoint commit of run/progress.md (`git log -- run/progress.md`, cloned from the archived bundles), diary entry headings (UTC), and run/messages.md for pauses. B1 times from kaizo-baseline-protocol/results. Milestones 1-16 omitted (all arms pass them within ~1 h). "≤" = reached by that time (first record of it), exact moment not recorded.

**Anchors.** Ripple start 01:24:32Z 17 Oct (first press ≈01:54, ~30 min setup). B2 start 11:20Z 17 Oct (booted and named ≈11:47, ~27 min setup). B1 start 08:57Z 16 Oct (7:57pm AEDT). K2 start 01:24:33Z 18 Oct (setup shorter; first diary 01:42). **Setup differs by ~15-25 min in K2's favour**; subtract that before comparing K2 with Ripple/B2.

**Pauses subtracted.** Ripple: 09:43-09:44, ~12:21-12:26, ~16:18-16:20, ~17:08-17:09 (≈9 min). B2: 18:52-18:55, 23:10-23:11 (≈4 min).

**R1 (supplementary, v3; Jackson 18 Oct).** "Trainer Red": a Kaizo-only trainer on Route 104 north with five L9 Kanto mons (Eevee, Bulbasaur, Charmander, Squirtle, Pikachu), between PokeAgent 24 and 25. Scored with time and tries; not counted in the /27 and not renumbering the PokeAgent list.

| # | Milestone | B1 | B2 | Ripple (K1.1) | K2 |
|---|---|---|---|---|---|
| 17 | Route 102 | — | ≤1h07 | ≈2h05 | ≈0h40 |
| 18 | Petalburg City | 3h27m (7 WO) | 3h55m (6 WO) | 4h23m (3 WO) | **≈3h02m (2 WO)** |
| 19-20 | Dad / gym explanation (Wally) | ✓ | ≤4h12m | ≤5h11m | ≈3h15m |
| 21 | Route 104 south | ✓ | ≤4h12m | ≤5h11m | ≈3h21m |
| 22 | Petalburg Woods | ≈5h08m | ≈4h55m | ≈5h40m | ≈4h00m |
| 23 | Grunt (Magma) defeated | ✗ (stopped) | ≈5h30m (1st try) | 7h46m (2nd try) | ≈5h07m (2nd try; WO 3) |
| 24 | Route 104 north | — | ≈5h40m | ≈8h03m | ≈5h20m |
| **R1** | **Trainer Red defeated** | — (not reached) | **≈6h45m (2nd try; WO 8 at 6h29m)** | **≈9h57m (2nd try; WO 5 at ≈9h27m)** | **≈5h58m (1st try)** |
| 25 | Rustboro City | — | 6h51m | ≈10h08m | **≈5h59m** (~07:24Z) |
| 26 | Rustboro Gym entered | — | ≈7h00m | ≈10h20m | **≤6h20m** (by 07:45Z; Josh beaten 1st try) |
| 27 | Stone Badge | — | ✗ (12 h cap; 4 Roxanne attempts) | ≈18h54m (5th attempt) | **≈7h29m (2nd attempt; 7 WO total)** |
| | Final | 22/27 at 6h37m, 10 WO, credit STOP | 26/27 at 12 h, 15 WO | 27/27, 15 WO (own count) | 27/27 + R1 at ≈7h29m, 7 WO; run continues past Roxanne |

WO = whiteouts. K2 times are live estimates from the transcript, progress.md and diary headings; refine at export.

**R1 sources (diary headings, verbatim).** B2: "2026-10-17 17:49 UTC — Whiteout #8: "Trainer Red"" (beat four of five; walked in "half-healthy") and "2026-10-17 18:05 UTC — Trainer Red, beaten" ("Walked back ... bought two Potions ... went in at full HP"). Ripple: "2026-10-17 10:52:55 — the pier, twins, and "Trainer Red": whiteout five" (lost to the Eevee's Curse/Rest stall alone) and "2026-10-17 11:23 — Red, beaten". K2: diary "2026-10-18 07:23 UTC" ("I beat all of them"; WISP and PEBBLE fainted). R1 times are diary-heading times, so they are upper bounds by a few minutes.

**Readings (descriptive, n=1 per arm).**
- B2 (no notes) was the fastest arm from Petalburg to Rustboro (3h55m → 6h51m), beating the grunt first try; its time went into the Rustboro Gym (5 h, no badge).
- Ripple was slowest to Rustboro (~10 h) but the only arm to take the badge (~8.5 h in Rustboro, mostly levelling on Route 116 and Rusturf Tunnel).
- K2 reached Petalburg fastest with the fewest whiteouts, even after a ~20-min setup adjustment (≈3h20m-equivalent vs B1 3h27m, B2 3h55m, Ripple 4h23m).
- **R1 sorts the arms:** both earlier arms lost to Red first time after walking in with a damaged party, then won the rematch after healing; K2 is the only arm to win first try, about 45 min ahead of B2 and 4 h ahead of Ripple.

**Caveats.** Setup and anchor differences (above); diary times in B1/B2 were sometimes estimated ("~"); APPROX milestones (19-20) are text events; R1 tries in milestones.py are counted from whiteout text between first sighting and win (APPROX); no transcript-based scoring yet (milestones.py on the exported JSONLs will supersede this table).

## K2 beyond the first gym (added 20 Oct 2026, companion)
Times are wall-clock elapsed from K2's start (01:24:33Z, 18 Oct). They include setup, the ~40 min VM outage (10:52Z, 18 Oct), the stop-1 gap (from 16:05Z, 18 Oct) and the stop-2 gap (18:14Z to ~18:3xZ, 19 Oct). They are **not** play time: K2's own debrief reports 35h43m in-game against 40.8 h wall at 18:1xZ, 19 Oct. Sources: the snapshots log (checks 33, 94, 103-110, 133-134) and K2's status lines. The PokeAgent milestones 28-43 between the badges (Route 116 to the Mauville Gym) are left for milestones.py on the export.

| Milestone | Clock (UTC) | Elapsed (wall) | Tries | Source |
|---|---|---|---|---|
| 27 Stone Badge | 08:54Z 18 Oct | ≈7h29m | 2nd attempt | table above |
| Knuckle Badge (PokeAgent ~36) | ≈12:00-12:05Z 18 Oct | ≈10h38m | 1st attempt, 0 new WO | check 33 |
| Dynamo Badge (PokeAgent 43) | ≈09:35Z 19 Oct | ≈32h10m | 5th attempt (WO 10-13 = attempts 1-4) | check 94 |
| Fiery Path (unaided; D2 not sent) | by 12:14Z 19 Oct | ≈34h50m | — | check 103 |
| Route 113 (unaided, from grunt dialogue) | ≈13:37Z 19 Oct | ≈36h12m | — | check 107 |
| **R2 (supplementary): "Trainer Red", Route 113** (Kanto team incl. Pikachu, Venusaur, Charizard, Snorlax) | first fight ≈14:3xZ; won ≈20:30-20:45Z 19 Oct | ≈43h06m-43h20m | **8th attempt**; stop after attempt 5, resumed on the order-A note | checks 110-134 |
| Fallarbor → Route 114 (unaided; D3 not sent) | by 21:04Z 19 Oct | ≈43h40m | — | check 134 |
| Route 114 Magma gauntlet | 9 grunts; 6th beaten ≈22:41Z, 9th beaten ≈23:25Z | ≈45h16m (6th) to ≈46h00m (9th) | first try each, no whiteout | checks 139-141 |
| Meteor Falls (unaided) | ≈23:32-23:3xZ 19 Oct | ≈46h08m | — | transcript paste 23:47Z |
| Route 112 cable car → Mt. Chimney (unaided; D3 not sent) | ≈23:42Z 19 Oct (K2 "by the clock") | ≈46h17m | — | transcript paste 23:47Z |
| Mt. Chimney summit: Tabitha | lost ≈00:17Z (WO 21), won ≈00:35Z 20 Oct | ≈47h11m | 2nd attempt | checks 143-145 |
| Mt. Chimney summit: **Maxie** (Registeel lead) | lost ≈00:51Z (WO 22), won ≈01:08Z 20 Oct | ≈47h43m | 2nd attempt | checks 146-148 |
| Jagged Pass (unaided) | by 01:14Z 20 Oct | ≈47h50m | — | check 148 |
| Lavaridge Town (unaided) | ≈02:05Z 20 Oct (check 152 at 02:10Z found him there) | ≈48h40m | — | check 152 (live) |
| Lavaridge Gym: **Flannery** (gym 4, Heat Badge) | lost ≈04:00Z (WO 24), ≈04:15Z (WO 25), ≈04:28Z (WO 26), ≈05:15Z (WO 27) 20 Oct; **not won as of 06:37Z** | ≈50h35m (1st loss) to ≈51h50m (4th); no badge at ≈53h12m | 4 attempts, all lost (WO 24-27) | companion checks to 06:37Z (live) |
| Lavaridge egg hatched: Wynaut L5, nicknamed ECHO (received 05:27Z; about 1 h 53 m of hatch-walking, ending in B-run SEQ legs; K2's own estimate 15,000–17,000 steps). Exp. Share moved to ECHO 07:23Z | 07:20Z 20 Oct | ≈53h55m | — | K2 status lines; world-knowledge.md (self-pull) |
| *Status (live)*: 3 badges; 27 WO + 1 probable; 25 interventions; levelling ECHO on Route 114 | 07:26Z 20 Oct | ≈54h01m | — | companion log (live) |

**Updated 20 Oct 06:52Z (companion).** Added Lavaridge Town, the Flannery attempts (gym 4, open) and the 06:37Z status row, and brought the whiteout line up to date: live estimates from the companion's checks (read times), not from an export. Existing rows kept: the live log's read times for Tabitha (≈00:36Z, check 145) and Maxie (≈01:15Z, check 148) are consistent with them.

**Whiteouts (K2):** 27 confirmed + 1 probable as of 06:37Z 20 Oct (live count; WO 21-22 on Mt. Chimney, WO 24-27 to Flannery, WO 23 ≈01:40Z 20 Oct on Jagged Pass (diary 01:42 "whited out to Fallarbor")); 20 confirmed + 1 probable by 19 Oct evening, reconciled from diary money figures. Each blackout halves money, which is how the unstated ones were inferred. Refine at export.

**R2 (supplementary, defined 20 Oct by the companion under Jackson's order G; reversible).** "Trainer Red, Route 113": the second Kaizo-only Red, a six-mon Kanto team (seen: Pikachu, Venusaur, Charizard, Snorlax, Espeon, ...) on Route 113, after the Dynamo Badge and before Fallarbor. It is scored like R1: time of the win, the number of tries (losses between first sighting and the win), and whiteouts. It is not counted in any PokeAgent total and does not renumber anything.
- K2: first fight ≈14:3xZ, win ≈20:30-20:45Z 19 Oct (≈43h06m-43h20m wall), **8th attempt**, with a stop after attempt 5 reversed by the order-A note.
- milestones.py: add R2 only after the export, once the Route 113 map id is checked against pret.

## Transcript scoring of the pilots (added 20 Oct 2026 ~11:30Z, companion)
Scored with claude/tools/milestones.py **v3.1** on the archived session event streams (project-archive/runs/<arm>/transcripts/; CSVs in project-archive/analyses-2026-10-20/milestones-v3.1-<arm>.csv). Play clock = from the first `g` status line, minus silences over 30 minutes (B2 1, Ripple 2), so it starts a few minutes later than the table's anchors above.
**v3 → v3.1 fixes (all found by running the scorer on the exports):** (1) the R1 win line is "Player defeated / ウエ TRAINER RED!" and v3's regex missed both real wins; (2) milestone 23 had the same separator problem ("Player defeated / TEAM MAGMA GRUNT!"); (3) the intro/loading placeholder status "0.0 0,0" was scored as Petalburg City (18) at 0:00:00 in every arm; (4) milestone 24 fired when an agent stepped back out of the woods' south exit (Route 104 y 46) before the grunt fight: now needs y < 40 (south part spans y 45–78); (5) B1 won its rival fight (Treecko 0/19, "got ¥300", 16 Oct 09:45:43Z) but the harness never printed the "Player defeated" line, so milestone 15 also counts prize money after the rival sends out a Pokémon; (6) tool results from the agent reading its own files are ignored for text signals.
**Result:** counts match the table: B1 **22/27**, B2 **26/27**, Ripple **27/27**.

| # | B1 | B2 | Ripple |
|---|---|---|---|
| 17 Route 102 | 0:59:01 | 1:02:44 | 2:06:22 |
| 18 Petalburg City | 3:20:51 | 3:51:50 | 4:24:40 |
| 22 Petalburg Woods | 5:10:06 | 4:50:40 | 5:30:28 |
| 23 Grunt defeated | — | 5:25:00 | 7:45:40 |
| 24 Route 104 north | — | 5:31:39 | 8:05:46 |
| **R1 Trainer Red** | — | **6:43:31** (18:04:12Z; 2 tries) | **10:01:41** (11:22:23Z; 2 tries) |
| 25 Rustboro City | — | 6:46:33 | 10:03:56 |
| 26 Rustboro Gym | — | 6:53:20 | 10:18:06 |
| 27 Stone Badge | — | — | 19:07:33 (20:28:15Z) |

**29 Oct note:** `milestones.py` v3.5 starts B1's clock 5 s earlier (08:55:27.72Z; a `g` call chained with a record write is no longer skipped), so the B1 clocks in this table read 5 s low against `data/analyses/milestones-v3.1-B1.csv`. B2 and Ripple are unchanged.
Agreement with the table above: within about 1–5 minutes everywhere except where the anchor differs. Ripple's table clock starts at diary creation (01:24:32Z), the scorer's at the first `g` line (01:20:41Z): that and the silence rule account for Ripple R1 ≈9h57m vs 10h01m41s. Ripple's badge is 13 min later on the scorer than in the table (≈18h54m), from the same causes plus the table's pause subtraction (unverified split).
**Whiteouts from the transcripts** (in-game "whited out / out of usable POKéMON" lines, ≥3 min apart, excluding the agent's file reads): B1 **10**, B2 **15**, **Ripple 16** (its own count was 15; from about 09:49Z its diary numbers whiteouts one too low, so its Trainer Red loss at 10:51Z was its 6th whiteout, not the 5th). The paper's arms table now says "16 by transcript (own count 15)" (rev 362).
**Still open:** milestones 28–43 (needs map ids checked against pret, then a run on K2's export); R2 on K2's export.

