# Tools

Python 3, standard library only. Each script's docstring gives its full usage and decisions.

| Script | What it does |
|---|---|
| `milestones.py` | Scores PokeAgent's first-gym milestones (1 to 27) and, from v3.2, milestones 28 to 43 through the Dynamo Badge, plus the supplementary Kaizo milestones R1 and R2 ("Trainer Red" on Route 104 and Route 113), from a session transcript. Reads only the transcript. 1 to 27 and R1 validated on the finished pilots; 28 and 29 confirmed on Ripple; 30 to 43 and R2 await K2's export; the PR #2 review cases (map-bound cues in batched output, the Route 110 rival fight, Trainer Red tries) are tested on synthetic transcripts. Map ids checked against pret (21 Oct 2026). Reads `.jsonl` or `.jsonl.gz`. |
| `scrub.py` | First privacy pass over an exported session event stream: replaces session and account identifiers, email addresses and home-directory usernames. `--verify IN OUT` reports anything left. |
| `publish_prep.py` | Second pass, for publication: drops thinking signatures and replaces the account's skill, command, connector and plugin lists with a count note. |
| `session_cost.py` | Reads Claude Code's own cost total from a transcript and recomputes cost at list prices per unique message, with tokens by model and compaction events. Reads `.jsonl` or `.jsonl.gz`. |
| `check_published.py` | Re-derives what can be re-derived from the published files: every transcript is in the checksum manifest and matches it, and milestones 1 to 27 (plus R1), re-scored from the B1, B2 and Ripple transcripts, match the published tables in `data/analyses/`. Run by the repository's CI on every change. |
| `k3_filter.py` | Mechanical filter for the K3 notes pack (step 4 of the knowledge-extraction protocol). It removes whole lines that contain coordinates, map ids, hex addresses, run nicknames, Hoenn place names, or `[from message]`/`[from hint]` tags. It flags direction words and named trainers for the auditor, and counts inherited `[from tip]` lines. It writes a TSV report. It is meant to run on the distiller's output, not on raw run files. |

Pipeline used for the published transcripts:

```
python3 scrub.py RAW.jsonl SCRUBBED.jsonl
python3 scrub.py --verify RAW.jsonl SCRUBBED.jsonl
python3 publish_prep.py SCRUBBED.jsonl PUBLIC.jsonl
python3 milestones.py PUBLIC.jsonl --csv milestones.csv
```
