#!/usr/bin/env python3
"""Checks for milestones.py: python3 tools/test_milestones.py (exits non-zero on a failure).

Two parts. (1) The play clock. (2) The own-file rule (v3.5): which tool results are skipped because the
command read the agent's own record files, and which are kept because the command only wrote to them.

The play clock is wall time from the first `g` status line, minus declared pauses (--pause) and
silences longer than --gap-minutes. A stretch that is both a pause and a silence must be taken
off once. K2's 23-27 October usage pause is that case: the session sat idle through it, so it is
a silence as well as a declared pause. Before v3.4 it would have been subtracted twice.
"""
import os, sys
from datetime import datetime, timedelta, timezone
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import milestones as m

fails = []
def check(name, got, want):
    if got != want:
        fails.append(f"{name}: got {got!r}, want {want!r}")

T0 = datetime(2026, 10, 18, 0, 0, tzinfo=timezone.utc)
def at(hours): return T0 + timedelta(hours=hours)
def hrs(d): return None if d is None else round(d.total_seconds() / 3600, 6)

cases = [
    # (name, t (hours), pauses, silences, expected play hours)
    ("no pauses or silences", 10, [], [], 10),
    ("one pause inside", 10, [(at(2), at(3))], [], 9),
    ("one silence inside", 10, [], [(at(4), at(6))], 8),
    ("pause and silence the same stretch", 10, [(at(2), at(5))], [(at(2), at(5))], 7),
    ("silence inside a longer pause", 10, [(at(2), at(6))], [(at(3), at(5))], 6),
    ("pause and silence overlapping", 10, [(at(2), at(4))], [(at(3), at(6))], 6),
    ("touching spans", 10, [(at(2), at(3))], [(at(3), at(4))], 8),
    ("separate spans", 10, [(at(1), at(2))], [(at(5), at(7))], 7),
    ("span after t is ignored", 5, [(at(6), at(8))], [], 5),
    ("span straddling t counts up to t", 5, [(at(4), at(8))], [], 4),
    ("span before first is ignored", 3, [(at(-5), at(-1))], [], 3),
    ("span straddling first counts from first", 3, [(at(-2), at(1))], [], 2),
    # K2-shaped case: a four-day pause declared, and the same idle time seen as one long silence
    ("K2-shaped usage pause", 220, [(at(120), at(216))], [(at(120.2), at(215.9))], 124),
]
for name, t, pauses, silences, want in cases:
    check(name, hrs(m.play_clock(T0, at(t), pauses, silences)), want)

check("no first status line", m.play_clock(None, at(5), [], []), None)
check("merge: unsorted and nested", m.merge_intervals([(at(5), at(6)), (at(1), at(4)), (at(2), at(3))]),
      [(at(1), at(4)), (at(5), at(6))])
check("merge: empty spans dropped", m.merge_intervals([(at(2), at(2)), (at(3), at(1))]), [])

# (2) The own-file rule: True means the tool result is skipped (the command read the agent's own files).
own_file_cases = [
    ("plain game command", "./g a; ./g s", False),
    ("read the progress file", "cat run/progress.md", True),
    ("read the diary tail", "tail -5 run/diary.md", True),
    ("game command then a lessons read", "g s; tail -30 run/lessons.md | cut -c1-300", True),
    ("grep the world notes", "grep -n Caroline run/world-knowledge.md", True),
    ("joy heredoc write (quoted EOF)", "cat >> run/joy.md <<'EOF'\n2026 joy: good; x\nEOF", False),
    ("g then two heredoc writes (K2, 29 Oct)",
     "~/pokemon_bridge/g money; cat >> run/joy.md <<'EOF'\nline\nEOF\ncat >> run/world-knowledge.md <<'EOF'\n- x\nEOF\ngit add -A", False),
    ("diary heredoc write (unquoted EOF)", "T=$(date) && cat >> run/diary.md <<EOF\n## $T - x\nbody\nEOF", False),
    ("progress overwrite then checkpoint", "cat > run/progress.md <<EOF\n# Progress\nEOF\n./checkpoint.sh x", False),
    ("echo write with semicolons inside quotes", 'echo "$T; joy: bad; a; trigger: b" >> run/joy.md', False),
    ("echo write, then a read", 'echo "$T; joy: bad" >> run/joy.md && cat run/progress.md', True),
    ("heredoc whose body mentions a read", "cat >> run/diary.md <<'EOF'\nI ran cat run/progress.md\nEOF", False),
]
for name, cmd, want in own_file_cases:
    check("own-file rule: " + name, m.reads_own_files(cmd), want)

n = len(cases) + 3 + len(own_file_cases)
if fails:
    print(f"{len(fails)} of {n} checks failed:")
    for f in fails:
        print("  " + f)
    sys.exit(1)
print(f"all {n} milestones.py checks pass (play clock and own-file rule)")
