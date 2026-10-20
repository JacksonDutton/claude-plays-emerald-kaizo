# Pilot session transcripts

The complete event streams of the finished Kaizo pilot sessions, exported from Claude Code cloud sessions on 20 October 2026, then scrubbed and prepared for publication. They are attached to the release [`pilot-transcripts-2026-10-20`](https://github.com/JacksonDutton/claude-plays-emerald-kaizo/releases/tag/pilot-transcripts-2026-10-20), not stored in the repository tree.

| File (release asset) | Arm | Events | First and last event (UTC) | Raw size |
|---|---|---|---|---|
| `kaizo-B1-events-20261020.public.jsonl.gz` | B1 | 30,834 | 16 Oct 08:54 to 20 Oct 05:51 | 31.8 MB |
| `kaizo-B2-attempt1-events-20261020.public.jsonl.gz` | B2, first attempt (about 45 min, stopped and relaunched) | 1,092 | 17 Oct 10:33 to 19 Oct 22:47 | 1.9 MB |
| `kaizo-B2-events-20261020.public.jsonl.gz` | B2 | 27,292 | 17 Oct 11:19 to 19 Oct 22:45 | 54.4 MB |
| `kaizo-Ripple-K1-1-events-20261020.public.jsonl.gz` | Ripple (notes pack K1.1) | 76,222 | 17 Oct 01:19 to 20 Oct 05:51 | 87.5 MB |

The streams continue past the end of play (exit interviews and later `/usage` checks are in the same files), so the last event is not the end of play. Play times are in `data/analyses/milestones-v3.1-*.csv` and the paper.

## Format

JSON Lines, one event per line, in the order the session recorded them. Top-level fields: `created_at`, `event_id`, `event_type`, `payload`, `processed_at`, `processing_at`, `received_at`, `sent_by_account_id`, `sequence_num`, `source`, `device_attestation_status`.

- `event_type` is mostly `assistant` (model turns: text, thinking and tool calls), `user` (tool results, and messages typed by a person), `system` (startup records, compaction summaries) and `control_request` / `control_response`.
- A message typed by a person (the supervisor or the companion) has `event_type: "user"`, text content and a `received_at` timestamp. Harness-generated user messages (compaction summaries, auto-resume) do not.
- Model text and thinking are as recorded. Thinking-block `signature` fields were removed.

## What was changed before publication

1. `tools/scrub.py`: session identifiers, account-scoped connector and plugin-sync IDs, the one email address and any home-directory usernames were replaced with placeholders. Report: `data/analyses/scrub_report.md`.
2. `tools/publish_prep.py`: thinking signatures dropped; the account's installed skill, command, connector and plugin lists, connector `servers` maps, connector-sync replies and MCP tool names were replaced with a note giving the number of entries removed. Nothing about play was changed. Every line is valid JSON and line counts are unchanged.

## Checksums (SHA-256)

Uncompressed:

```
3e44aa391e8ed0655a31aeef09cfa105a17f232fac082856c88eca15ae0222e9  kaizo-B1-events-20261020.public.jsonl
f76c7bb807ae1ba590b29a5800fe078d8924ad6f991aeda4776ebc131dc375d0  kaizo-B2-attempt1-events-20261020.public.jsonl
ebbe410f8119c75c43a03dd080c162733618bdba1b5bd2b08381fbbfdc63155f  kaizo-B2-events-20261020.public.jsonl
db3451d05d5ed6143b5f6356d778b589454c7bc1e428d3784b7a62675d35e787  kaizo-Ripple-K1-1-events-20261020.public.jsonl
```

Compressed (`gzip -9 -n`):

```
b6e7015d7ec2a873e4afb1003aaf776d6c8fc6dda7533edb0f9fdf91c6c49b6d  kaizo-B1-events-20261020.public.jsonl.gz
85c7911015707b4f56b852765c8f69bde0de389a4185aaf9dae0a23df53f1ff3  kaizo-B2-attempt1-events-20261020.public.jsonl.gz
77feca70aa06646c0b9eb3150710b95b7d2e0d0c00b87405e3fe2b41907a59f8  kaizo-B2-events-20261020.public.jsonl.gz
9ca5944497f68684719cc7aa77a66cb25817911622e6e61660b33d079bda30b2  kaizo-Ripple-K1-1-events-20261020.public.jsonl.gz
```

K2's transcript will be added after that run ends.
