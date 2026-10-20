#!/usr/bin/env python3
"""Score PokeAgent's 27 first-gym milestones from a Claude Code transcript (JSONL).

Non-intrusive: reads only the transcript the play session already writes, so it
needs no hook in the harness and never touches the emulator. Every `g` call
prints a status line "<group>.<num> <x>,<y> P<party> B<badges> ..." plus any new
dialogue; this script timestamps the first appearance of each milestone signal.

Usage:
  milestones.py SESSION.jsonl [MORE.jsonl ...] [--pause START,END ...]
                [--gap-minutes 30] [--csv out.csv]

Input: either Claude Code's local JSONL (keys 'timestamp', 'message') or an
exported claude.ai session event stream (keys 'created_at', 'payload.message').

Play clock = wall time from the first `g` status line, minus declared pauses
(--pause with ISO times) and minus any silence longer than --gap-minutes
(the session idle while waiting for a message). Both are reported.

Milestone list: PokeAgent starter kit MILESTONE_PHASES (fetched 2026-10-09),
27 to the Stone Badge. Map ids from pret/pokeemerald data/maps/map_groups.json.
Signals marked APPROX are text/heuristic matches, not RAM flags; check them by
hand against the transcript before reporting.

v3 (18 Oct 2026, Jackson's call): SUPPLEMENTARY Kaizo milestones are scored
alongside the 27 but are NOT counted in the /27 total and do NOT renumber the
PokeAgent list, so PokeAgent comparability holds. First one: R1 "Trainer Red"
(Kaizo-only five-mon Kanto team on Route 104 north, between milestones 24 and
25). For each supplementary milestone the script also reports `tries`: the
number of whiteouts seen between first sighting and the win, plus one (APPROX).

v3.1 (20 Oct 2026, companion): (1) R1 win regex fixed. The harness prints a
short glyph token (seen as "ウエ") between "Player defeated /" and "TRAINER RED",
so the v3 pattern missed both real wins in the pilot transcripts; the new
pattern hits exactly those two (B2 18:04:12Z, Ripple 11:22:23Z) and nothing
else. (2) Reads exported session event streams as well as local JSONL.
(3) Tool results of commands that read the agent's own files (cat/grep/tail/
head/sed on .md, diary, lessons, progress) are ignored for text signals, so a
diary read-back can no longer count as a whiteout or a win. (4) Milestone 23
had the same separator problem ("Player defeated / TEAM MAGMA GRUNT!"); fixed
the same way. (5) Status lines at 0,0 ("0.0 0,0 P0 B0 busy", the intro and
loading placeholder) no longer count as map visits; v3 scored PETALBURG_CITY
(18) at 0:00:00 in every arm from them. (6) Milestone 24 (Route 104 north)
now needs y < 40 on map 0.19 after the woods: the south part spans y 45-78 in
all three pilots, and v3 fired when an agent stepped back out of the woods'
south exit (y 46), before the grunt fight. (7) Milestone 15 also counts prize
money ("got ¥") after the rival sends out a Pokemon: B1 won the Route 103
fight (Treecko 0/19, "got ¥300", 16 Oct 09:45:43Z) but the harness never
printed its "Player defeated" line. Validation on the pilots: B1 22/27, B2
26/27, Ripple 27/27, matching kaizo-milestone-times.md; R1 B2 18:04:12Z and
Ripple 11:22:23Z.
"""
import argparse, csv, json, re, sys
from datetime import datetime, timedelta

MAP = {  # group.num -> name (pret/pokeemerald)
    "0.9": "LITTLEROOT_TOWN", "1.0": "BRENDANS_HOUSE_1F", "1.1": "BRENDANS_HOUSE_2F",
    "1.2": "MAYS_HOUSE_1F", "1.3": "MAYS_HOUSE_2F", "1.4": "BIRCH_LAB",
    "0.16": "ROUTE_101", "0.10": "OLDALE_TOWN", "0.18": "ROUTE_103", "0.17": "ROUTE_102",
    "0.0": "PETALBURG_CITY", "8.1": "PETALBURG_GYM", "0.19": "ROUTE_104",
    "24.11": "PETALBURG_WOODS", "0.3": "RUSTBORO_CITY", "11.3": "RUSTBORO_GYM",
}

# (id, name, how) in PokeAgent order. how = ("map", ids) | ("text", regex) | special
MILESTONES = [
    (1, "GAME_RUNNING", "first_status"),
    (2, "PLAYER_NAME_SET", ("text", r"(?i)\b(name|NAME)\b.*\?|your name|g name")),  # APPROX
    (3, "INTRO_CUTSCENE_COMPLETE", ("map_any", ["0.9", "1.0", "1.2"])),  # APPROX: out of the truck
    (4, "LITTLEROOT_TOWN", ("map", ["0.9"])),
    (5, "PLAYER_HOUSE_ENTERED", ("map_any", ["1.0", "1.2"])),  # house depends on player gender
    (6, "PLAYER_BEDROOM", ("map_any", ["1.1", "1.3"])),
    (7, "CLOCK_SET", ("text", r"(?i)\bclock\b")),  # APPROX
    (8, "RIVAL_HOUSE", ("rival_house", None)),
    (9, "RIVAL_BEDROOM", ("rival_bedroom", None)),
    (10, "ROUTE_101", ("map", ["0.16"])),
    (11, "STARTER_CHOSEN", "party_ge1"),
    (12, "BIRCH_LAB_VISITED", ("map", ["1.4"])),
    (13, "OLDALE_TOWN", ("map", ["0.10"])),
    (14, "ROUTE_103", ("map", ["0.18"])),
    (15, "RIVAL_BATTLE_WON", ("text", r"(?i)defeated[\s/]+.{0,30}(MAY|BRENDAN)")),  # APPROX; also see rival_money below
    (16, "RECEIVED_POKEDEX", ("text", r"(?i)(received|obtained|got) (the )?POK.?DEX|POK.?DEX.{0,20}(received|obtained)")),  # APPROX
    (17, "ROUTE_102", ("map", ["0.17"])),
    (18, "PETALBURG_CITY", ("map", ["0.0"])),
    (19, "DAD_FIRST_MEETING", ("map", ["8.1"])),  # APPROX: first entry to Petalburg Gym
    (20, "GYM_EXPLANATION", ("text_after_dad", r"(?i)RUSTBORO|ROXANNE|GYM LEADER")),  # APPROX
    (21, "ROUTE_104_SOUTH", ("map", ["0.19"])),
    (22, "PETALBURG_WOODS", ("map", ["24.11"])),
    (23, "TEAM_AQUA_GRUNT_DEFEATED", ("text", r"(?i)defeated[\s/]+(?:\S{1,6}\s+)?TEAM (AQUA|MAGMA) GRUNT")),  # Kaizo uses MAGMA here; v3.1 separator fix
    (24, "ROUTE_104_NORTH", "r104_after_woods"),
    (25, "RUSTBORO_CITY", ("map", ["0.3"])),
    (26, "RUSTBORO_GYM_ENTERED", ("map", ["11.3"])),
    (27, "STONE_BADGE", "badges_ge1"),
]

# Supplementary Kaizo milestones (v3). (id, name, after_pokeagent_n, seen_regex, win_regex)
# Not counted in /27; listed in the output after the PokeAgent milestone they follow.
SUPPLEMENTARY = [
    ("R1", "KAIZO_TRAINER_RED_DEFEATED", 24,
     r"TRAINER RED",                                                    # first sighting (APPROX)
     r"(?i)defeated[\s/]+(?:\S{1,6}\s+)?TRAINER\s+RED|TRAINER\s+RED.{0,60}(defeated|beaten)"),  # v3.1; APPROX
]
WHITEOUT = re.compile(r"(?i)whited out|blacked out|out of usable POK")
FILE_READ = re.compile(r"(?i)\b(cat|grep|tail|head|sed|less|awk)\b[^|;&]*\.(md|txt)\b|diary|lessons\.md|progress\.md")

STATUS = re.compile(r"^(\d+)\.(\d+) (-?\d+),(-?\d+) P(\d) B(\d+)\b", re.M)


def ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def tool_texts(path):
    """Yield (timestamp, text) for every tool result in a transcript (local JSONL or exported events)."""
    commands = {}
    with open(path, encoding="utf8") as f:
        for line in f:
            try:
                o = json.loads(line)
            except Exception:
                continue
            t = o.get("timestamp") or o.get("created_at")
            msg = o.get("message") or (o.get("payload") or {}).get("message") or {}
            content = msg.get("content") if isinstance(msg, dict) else None
            if not t or not isinstance(content, list):
                continue
            for c in content:
                if not isinstance(c, dict):
                    continue
                if c.get("type") == "tool_result":
                    if FILE_READ.search(commands.get(c.get("tool_use_id"), "")):
                        continue  # the agent reading its own files back, not game output
                    v = c.get("content")
                    if isinstance(v, list):
                        v = "\n".join(x.get("text", "") for x in v if isinstance(x, dict))
                    if isinstance(v, str):
                        yield ts(t), v
                elif c.get("type") == "tool_use":
                    cmd = (c.get("input") or {}).get("command", "")
                    if isinstance(cmd, str):
                        commands[c.get("id")] = cmd
                        if " name " in f" {cmd} ":
                            yield ts(t), "g name " + cmd  # naming signal


def score(events):
    hit = {}
    seen_maps, player_house = set(), None
    woods_seen = dad_seen = rival_fight = False
    first = None
    for t, text in events:
        for m in STATUS.finditer(text):
            g, n, x, y, p, b = m.groups()
            mid = f"{g}.{n}"
            if first is None:
                first = t
                hit.setdefault(1, t)
            if x == "0" and y == "0":
                continue  # v3.1: '0.0 0,0' is the intro/loading placeholder, not Petalburg City
            seen_maps.add(mid)
            for i, name, how in MILESTONES:
                if i in hit:
                    continue
                if isinstance(how, tuple) and how[0] in ("map", "map_any") and mid in how[1]:
                    hit[i] = t
                    if i == 5:
                        player_house = mid
                elif how == "party_ge1" and int(p) >= 1:
                    hit[i] = t
                elif how == "badges_ge1" and int(b) >= 1:
                    hit[i] = t
                elif how == "r104_after_woods" and mid == "0.19" and woods_seen and int(y) < 40:  # v3.1: north part only
                    hit[i] = t
                elif isinstance(how, tuple) and how[0] in ("rival_house", "rival_bedroom") and player_house:
                    rival_1f = "1.2" if player_house == "1.0" else "1.0"
                    target = rival_1f if how[0] == "rival_house" else {"1.0": "1.1", "1.2": "1.3"}[rival_1f]
                    if mid == target:
                        hit[i] = t
            if mid == "24.11":
                woods_seen = True
            if mid == "8.1":
                dad_seen = True
        # v3.1: rival battle won = prize money after the rival sent out a Pokemon
        # (the harness sometimes skips the "Player defeated" line, as in B1).
        if re.search(r"(?i)TRAINER\s+(MAY|BRENDAN)\s+sent", text):
            rival_fight = True
        if 15 not in hit and rival_fight and re.search(r"got ¥\d+", text):
            hit[15] = t
        if WHITEOUT.search(text):
            rival_fight = False
        for i, name, how in MILESTONES:
            if i in hit or not isinstance(how, tuple):
                continue
            if how[0] == "text" and re.search(how[1], text):
                hit[i] = t
            elif how[0] == "text_after_dad" and dad_seen and re.search(how[1], text):
                hit[i] = t
    return first, hit


def score_supplementary(events):
    """Return {id: (win_time or None, tries)}; tries = whiteouts between first sighting and win, + 1."""
    out = {}
    for sid, name, after, seen_re, win_re in SUPPLEMENTARY:
        seen = win = None
        whiteouts = 0
        for t, text in events:
            if seen is None and re.search(seen_re, text):
                seen = t
            if seen is not None and win is None:
                if re.search(win_re, text):
                    win = t
                elif WHITEOUT.search(text):
                    whiteouts += 1
        out[sid] = (win, whiteouts + 1 if seen else 0)
    return out


def play_clock(first, t, pauses, silences):
    if first is None:
        return None
    d = t - first
    for a, b in pauses + silences:
        lo, hi = max(a, first), min(b, t)
        if hi > lo:
            d -= hi - lo
    return d


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("jsonl", nargs="+")
    ap.add_argument("--pause", action="append", default=[], help="START,END ISO times")
    ap.add_argument("--gap-minutes", type=float, default=30)
    ap.add_argument("--csv")
    a = ap.parse_args()
    ev = []
    for p in a.jsonl:
        ev.extend(tool_texts(p))
    ev.sort(key=lambda x: x[0])
    first, hit = score(ev)
    supp = score_supplementary(ev)
    pauses = [tuple(ts(s) for s in p.split(",")) for p in a.pause]
    silences = []
    gap = timedelta(minutes=a.gap_minutes)
    for (t0, _), (t1, _) in zip(ev, ev[1:]):
        if t1 - t0 > gap:
            silences.append((t0, t1))

    def clock(t):
        pc = play_clock(first, t, pauses, silences) if t else None
        return str(pc).split(".")[0] if pc is not None else ""

    rows = []
    for i, name, how in MILESTONES:
        t = hit.get(i)
        approx = "APPROX" if i in (2, 3, 7, 15, 16, 19, 20) else ""
        rows.append([i, name, t.isoformat() if t else "", clock(t), approx])
        for sid, sname, after, _, _ in SUPPLEMENTARY:
            if after == i:
                st, tries = supp[sid]
                note = f"SUPPLEMENTARY (Kaizo, not in /27); tries={tries} APPROX" if tries else "SUPPLEMENTARY (Kaizo, not in /27); not seen"
                rows.append([sid, sname, st.isoformat() if st else "", clock(st), note])
    w = csv.writer(open(a.csv, "w", newline="") if a.csv else sys.stdout)
    w.writerow(["n", "milestone", "first_seen_utc", "play_clock", "note"])
    w.writerows(rows)
    n27 = sum(1 for r in rows if isinstance(r[0], int) and r[2])
    ns = sum(1 for r in rows if not isinstance(r[0], int) and r[2])
    print(f"# {n27}/27 reached; supplementary {ns}/{len(SUPPLEMENTARY)}; silences >{a.gap_minutes:g} min excluded: {len(silences)}", file=sys.stderr)


if __name__ == "__main__":
    main()
