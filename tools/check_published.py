#!/usr/bin/env python3
"""check_published.py -- re-derive what can be re-derived from the published files.

Two checks, each failing loudly:
  1. Transcripts. The set of data/transcripts/*.jsonl.gz files equals the set named in SHA256SUMS-gz.txt,
     and every file matches its SHA-256.
  2. Milestones. For B1, B2 and Ripple, re-score the transcript with tools/milestones.py and compare every
     row of the published table data/analyses/milestones-v3.1-<arm>.csv (milestones 1-27 and the
     supplementary R1 row) on the fields n, milestone, first_seen_utc and play_clock. Rows are matched by
     their n, read with a CSV parser (play_clock can hold a comma, e.g. "-1 day, 23:59:53"). The note column
     is not compared: later milestones.py versions reword notes without changing any time.

Standard library only. Usage (from the repository root):
    python3 tools/check_published.py [--analyses DIR]
Exit status 0 when everything matches, 1 otherwise.
"""
import argparse, contextlib, csv, hashlib, io, os, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANSCRIPTS = os.path.join(ROOT, "data", "transcripts")
ARMS = {"B1": "kaizo-B1-events-20261020.public.jsonl.gz",
        "B2": "kaizo-B2-events-20261020.public.jsonl.gz",
        "Ripple": "kaizo-Ripple-K1-1-events-20261020.public.jsonl.gz"}
FIELDS = ("n", "milestone", "first_seen_utc", "play_clock")


def check_transcripts():
    ok = True
    listed = {}
    with open(os.path.join(TRANSCRIPTS, "SHA256SUMS-gz.txt")) as f:
        for line in f:
            if line.strip():
                digest, name = line.split(None, 1)
                listed[name.strip().lstrip("*")] = digest
    present = {n for n in os.listdir(TRANSCRIPTS) if n.endswith(".jsonl.gz")}
    for name in sorted(present - set(listed)):
        print(f"FAIL transcript not in the checksum manifest: {name}")
        ok = False
    for name in sorted(set(listed) - present):
        print(f"FAIL manifest names a missing transcript: {name}")
        ok = False
    for name in sorted(present & set(listed)):
        h = hashlib.sha256()
        with open(os.path.join(TRANSCRIPTS, name), "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
        if h.hexdigest() == listed[name]:
            print(f"ok   checksum {name}")
        else:
            print(f"FAIL checksum {name}")
            ok = False
    return ok


def rescore(transcript, out):
    """Run tools/milestones.py in this process (no subprocess, no shell) and write its table to `out`."""
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import milestones
    argv = sys.argv
    sys.argv = ["milestones.py", transcript, "--csv", out]
    try:
        with contextlib.redirect_stderr(io.StringIO()):
            milestones.main()
    finally:
        sys.argv = argv


def rows_by_n(path):
    with open(path, newline="") as f:
        return {r["n"]: r for r in csv.DictReader(f)}


def check_milestones(analyses):
    ok = True
    for arm, transcript in ARMS.items():
        published = rows_by_n(os.path.join(analyses, f"milestones-v3.1-{arm}.csv"))
        fd, out = tempfile.mkstemp(suffix=".csv"); os.close(fd)
        try:
            rescore(os.path.join(TRANSCRIPTS, transcript), out)
            rescored = rows_by_n(out)
        finally:
            os.remove(out)
        bad = []
        for n, row in published.items():
            other = rescored.get(n)
            if other is None:
                bad.append(f"row {n} missing from the re-scored table")
                continue
            for field in FIELDS:
                if row[field] != other[field]:
                    bad.append(f"row {n} {field}: published {row[field]!r}, re-scored {other[field]!r}")
        if bad:
            ok = False
            print(f"FAIL milestones {arm}:")
            for b in bad:
                print(f"     {b}")
        else:
            print(f"ok   milestones {arm}: all {len(published)} published rows reproduce")
    return ok


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--analyses", default=os.path.join(ROOT, "data", "analyses"),
                    help="folder holding the published milestone tables (default data/analyses)")
    a = ap.parse_args()
    results = [check_transcripts(), check_milestones(a.analyses)]
    sys.exit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
