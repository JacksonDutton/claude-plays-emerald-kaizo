#!/usr/bin/env python3
"""Checks for k3_filter.py: python3 tools/test_k3_filter.py (exits non-zero on a failure).

The filter decides what K arms inherit, so it is part of how the treatment is built. These cases
encode the rules in design/kaizo-K3-extraction-kit.md, section 3 (removed whole; flagged for the
auditor; tip units kept and counted, or removed with --drop-tip), plus a regression check on the
published K2 pack (harness/notes-packs/K2.md), whose results the kit records for 28 Oct.
"""
import contextlib, io, os, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import k3_filter as kf

fails = []
def check(name, got, want):
    if got != want:
        fails.append(f"{name}: got {got!r}, want {want!r}")

def action(line, extra=(), drop_tip=False):
    """What the filter does with one line: REMOVED, FLAG, COUNT or KEEP (no reason at all)."""
    nick, place = kf.build(list(extra))
    rs = kf.reasons(line, nick, place, drop_tip)
    if [x for x in rs if not x.startswith(("direction", "trainer", "tip tag"))]:
        return "REMOVED"
    if not rs:
        return "KEEP"
    return "COUNT" if all(x.startswith("tip tag") for x in rs) else "FLAG"

# (case, line, expected action[, extra names][, drop_tip])
cases = [
    # Removed whole (pre-registered, plus round 6)
    ("coordinate", "- Stand at (11, 17) before talking.", "REMOVED"),
    ("map id", "- The ladder on map 24.45 leads down.", "REMOVED"),
    ("hex", "- The flag lives at 0x02024A6C.", "REMOVED"),
    ("nickname, ALL CAPS", "- Lead with ZAP against water types.", "REMOVED"),
    ("nickname, Title case", "- Zap outspeeds most of them.", "REMOVED"),
    ("extra name from the names file", "- BRAMBLE holds the line.", "REMOVED", ["Bramble"]),
    ("place name", "- Buy Max Repels in Mossdeep.", "REMOVED"),
    ("place name, two words", "- Victory Road has many trainers.", "REMOVED"),
    ("route number", "- Surf down Route 118 first.", "REMOVED"),
    ("route number, lower case", "- route 118 is long.", "REMOVED"),
    ("message tag", "- Heal before bosses. [from message 12]", "REMOVED"),
    ("hint tag", "- Check the statue. [from hint L2]", "REMOVED"),
    ("tip tag with --drop-tip", "- Save before every boss. [from tip B01]", "REMOVED", [], True),
    # Kept and counted
    ("tip tag, default", "- Save before every boss. [from tip B01]", "COUNT"),
    # Flagged for the auditor, kept
    ("direction word", "- Go north when the path splits.", "FLAG"),
    ("named trainer, Title case", "- Wallace leads with a fast water type.", "FLAG"),
    ("named trainer, ALL CAPS", "- WALLACE leads with a fast water type.", "FLAG"),
    # Kept untouched (the filter must not over-remove)
    ("plain lesson", "- Status moves are worth a turn against bosses.", "KEEP"),
    ("nickname as an ordinary lower-case word", "- Listen for the echo of a missed move.", "KEEP"),
    ("damage multiplier, 1.5x", "- Super effective is 1.5x after STAB.", "KEEP"),
    ("damage multiplier, x1.5", "- STAB is x1.5 damage.", "KEEP"),
    ("damage multiplier, 1.5 times", "- Crits do 1.5 times damage here.", "KEEP"),
    ("percentage", "- A 12.5% chance is still a chance.", "KEEP"),
    ("place name inside a longer word", "- Devonshire tea is not in this game.", "KEEP"),
]
for c in cases:
    name, line, want = c[0], c[1], c[2]
    extra = c[3] if len(c) > 3 else []
    drop = c[4] if len(c) > 4 else False
    check(name, action(line, extra, drop), want)

def run_main(args):
    old = sys.argv
    sys.argv = ["k3_filter.py"] + args
    out = io.StringIO()
    try:
        with contextlib.redirect_stdout(out):
            kf.main()
    finally:
        sys.argv = old
    return out.getvalue().strip()

# End to end: output keeps only the right lines, in order; the report numbers kept lines by OUTPUT line.
with tempfile.TemporaryDirectory() as d:
    p = lambda n: os.path.join(d, n)
    lines = [
        "# Lessons\n",
        "- Lead with ZAP.\n",                      # removed (nickname)
        "- Heal before bosses.\n",                 # kept
        "- Go west at the fork.\n",                # kept, flagged
        "- Save first. [from tip B22]\n",          # kept, counted
        "- Stand at (3, 4).\n",                    # removed (coordinate)
        "- BRAMBLE walls them.\n",                 # removed (extra name)
    ]
    open(p("in.md"), "w", encoding="utf-8").writelines(lines)
    open(p("names.txt"), "w", encoding="utf-8").write("Bramble\n")
    summary = run_main([p("in.md"), p("out.md"), "--report", p("rep.tsv"), "--extra-names", p("names.txt")])
    check("end to end: output", open(p("out.md"), encoding="utf-8").readlines(),
          [lines[0], lines[2], lines[3], lines[4]])
    rows = [r.split("\t") for r in open(p("rep.tsv"), encoding="utf-8").read().splitlines()[1:]]
    check("end to end: report actions", [(r[0], r[1], r[2]) for r in rows],
          [("2", "", "REMOVED"), ("4", "3", "FLAG"), ("5", "4", "COUNT"), ("6", "", "REMOVED"), ("7", "", "REMOVED")])
    check("end to end: summary", summary,
          "lines in 7, removed 3, flagged for audit 1, tip-tagged kept 1, out 4")

    # Regression: the published K2 pack (kit, section 3, "Tests, 28 Oct").
    k2 = os.path.join(HERE, "..", "harness", "notes-packs", "K2.md")
    check("K2.md, default settings", run_main([k2, p("k2.md")]),
          "lines in 127, removed 0, flagged for audit 0, tip-tagged kept 22, out 127")
    check("K2.md, --drop-tip", run_main([k2, p("k2d.md"), "--drop-tip"]),
          "lines in 127, removed 22, flagged for audit 0, tip-tagged kept 0, out 105")

n = len(cases) + 5
if fails:
    print(f"{len(fails)} of {n} checks failed:")
    for f in fails:
        print("  " + f)
    sys.exit(1)
print(f"all {n} k3_filter checks pass")
