# Tools

Python 3, standard library only. Each script's docstring gives its full usage and decisions.

| Script | What it does |
|---|---|
| `milestones.py` | Scores PokeAgent's 27 first-gym milestones, plus the supplementary Kaizo milestone R1 ("Trainer Red"), from a session transcript. Reads only the transcript, so it needs nothing in the harness. Version 3.1 (20 Oct 2026), validated for milestones 1 to 27 and R1 against the three finished pilots; fixes found in that validation are listed in its docstring. |
| `scrub.py` | First privacy pass over an exported session event stream: replaces session and account identifiers, email addresses and home-directory usernames. `--verify IN OUT` reports anything left. |
| `publish_prep.py` | Second pass, for publication: drops thinking signatures and replaces the account's skill, command, connector and plugin lists with a count note. |
| `session_cost.py` | Reads Claude Code's own cost total from a transcript and recomputes cost at list prices per unique message, with tokens by model and compaction events. |

Pipeline used for the published transcripts:

```
python3 scrub.py RAW.jsonl SCRUBBED.jsonl
python3 scrub.py --verify RAW.jsonl SCRUBBED.jsonl
python3 publish_prep.py SCRUBBED.jsonl PUBLIC.jsonl
python3 milestones.py PUBLIC.jsonl --csv milestones.csv
```
