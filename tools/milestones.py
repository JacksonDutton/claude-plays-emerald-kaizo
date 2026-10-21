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

v3.2 (21 Oct 2026, companion, at Jackson's "clear the to-do list"): PokeAgent milestones
28 to 43 (Route 116 to the Dynamo Badge, starter kit MILESTONE_PHASES phases 8-11) added,
with map ids checked against pret/pokeemerald data/maps/map_groups.json (master, fetched
21 Oct; ids 1-27 re-checked at the same time and all match). Supplementary R2 (the second
Kaizo "Trainer Red", Route 113 = map 0.28) added: seen and won only while on that map.
R1 is now bound to Route 104 (0.19) the same way. The /27 total is unchanged; a /43 total
is printed beside it. Regression: v3.1 and v3.2 give identical times for every v3.1 row on
the Ripple and B2 public transcripts (R1 included). Milestones 28 and 29 are confirmed on
Ripple's transcript (Route 116 and Rusturf Tunnel, visited while levelling before its badge);
30-43 and R2 are checked only on a synthetic transcript until K2's export. Signals 30, 34, 38 and 40 are APPROX (first entry to a room, or prize money
after the rival sends out a Pokemon on Route 110).

v3.2 review fixes (21 Oct 2026, PR #2 review): (1) map-bound text cues (milestone 40 and
the supplementary R1/R2) are judged per segment, not per tool result: a result is split at
its status lines, and the text between two status lines counts for the maps of both (text
before the first status line also counts for the map of the previous result), so batched
output from several maps no longer lends one map's cues to another. (2) Milestone 40 needs
both the rival's send-out and the win cue in Route 110 segments; the visited flag is gone.
(3) Supplementary tries count a whiteout whose segment touches the milestone's map, even
when the respawn status comes later in the same result. (4) 28 and 29 are marked as
confirmed, not unvalidated. (5) Gzipped transcripts (.jsonl.gz) are read directly.
"""
import argparse, csv, gzip, json, re, sys
from datetime import datetime, timedelta

MAP = {  # group.num -> name (pret/pokeemerald)
    "0.9": "LITTLEROOT_TOWN", "1.0": "BRENDANS_HOUSE_1F", "1.1": "BRENDANS_HOUSE_2F",
    "1.2": "MAYS_HOUSE_1F", "1.3": "MAYS_HOUSE_2F", "1.4": "BIRCH_LAB",
    "0.16": "ROUTE_101", "0.10": "OLDALE_TOWN", "0.18": "ROUTE_103", "0.17": "ROUTE_102",
    "0.0": "PETALBURG_CITY", "8.1": "PETALBURG_GYM", "0.19": "ROUTE_104",
    "24.11": "PETALBURG_WOODS", "0.3": "RUSTBORO_CITY", "11.3": "RUSTBORO_GYM",
    # v3.2: milestones 28-43 (pret map_groups.json, 21 Oct 2026)
    "0.31": "ROUTE_116", "24.4": "RUSTURF_TUNNEL", "11.2": "RUSTBORO_CITY_DEVON_CORP_3F",
    "17.0": "ROUTE_104_MR_BRINEYS_HOUSE", "0.11": "DEWFORD_TOWN", "0.21": "ROUTE_106",
    "24.10": "GRANITE_CAVE_STEVENS_ROOM", "3.3": "DEWFORD_TOWN_GYM", "0.1": "SLATEPORT_CITY",
    "9.8": "SLATEPORT_CITY_OCEANIC_MUSEUM_2F", "0.25": "ROUTE_110", "0.2": "MAUVILLE_CITY",
    "10.0": "MAUVILLE_CITY_GYM", "0.28": "ROUTE_113",
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
    # v3.2: gyms 2-3 (PokeAgent phases 8-11). Not counted in the /27 total.
    (28, "ROUTE_116", ("map", ["0.31"])),
    (29, "RUSTURF_TUNNEL", ("map", ["24.4"])),
    (30, "DEVON_CORP_3F_MR_STONE", ("map", ["11.2"])),  # APPROX: first entry to Devon Corp 3F
    (31, "MR_BRINEYS_HOUSE", ("map", ["17.0"])),
    (32, "DEWFORD_TOWN", ("map", ["0.11"])),
    (33, "ROUTE_106", ("map", ["0.21"])),
    (34, "GRANITE_CAVE_STEVEN", ("map", ["24.10"])),  # APPROX: Steven's room entered
    (35, "DEWFORD_GYM_ENTERED", ("map", ["3.3"])),
    (36, "KNUCKLE_BADGE", "badges_ge2"),
    (37, "SLATEPORT_CITY", ("map", ["0.1"])),
    (38, "OCEANIC_MUSEUM_AQUA", ("map", ["9.8"])),  # APPROX: museum 2F, where the Aqua scene is
    (39, "ROUTE_110", ("map", ["0.25"])),
    (40, "RIVAL_BATTLE_ROUTE_110", "rival_route110"),  # APPROX: prize money after the rival sends out a Pokemon, Route 110 seen
    (41, "MAUVILLE_CITY", ("map", ["0.2"])),
    (42, "MAUVILLE_GYM_ENTERED", ("map", ["10.0"])),
    (43, "DYNAMO_BADGE", "badges_ge3"),
]

# Supplementary Kaizo milestones (v3). (id, name, after_pokeagent_n, seen_regex, win_regex)
# Not counted in /27; listed in the output after the PokeAgent milestone they follow.
SUPPLEMENTARY = [
    ("R1", "KAIZO_TRAINER_RED_DEFEATED", 24,
     r"TRAINER RED",                                                    # first sighting (APPROX)
     r"(?i)defeated[\s/]+(?:\S{1,6}\s+)?TRAINER\s+RED|TRAINER\s+RED.{0,60}(defeated|beaten)"),  # v3.1; APPROX
    ("R2", "KAIZO_TRAINER_RED_ROUTE_113_DEFEATED", 43,
     r"TRAINER RED",
     r"(?i)defeated[\s/]+(?:\S{1,6}\s+)?TRAINER\s+RED|TRAINER\s+RED.{0,60}(defeated|beaten)"),  # v3.2; only on map 0.28; APPROX
]
SUPP_MAP = {"R1": "0.19", "R2": "0.28"}  # v3.2: the map a supplementary milestone must be seen and won on (Route 104 / Route 113)
WHITEOUT = re.compile(r"(?i)whited out|blacked out|out of usable POK")
FILE_READ = re.compile(r"(?i)\b(cat|grep|tail|head|sed|less|awk)\b[^|;&]*\.(md|txt)\b|diary|lessons\.md|progress\.md")

STATUS = re.compile(r"^(\d+)\.(\d+) (-?\d+),(-?\d+) P(\d) B(\d+)\b", re.M)


def ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def open_text(path):
    """Open a transcript as text; .gz files are decompressed on the fly (v3.2 review fix)."""
    if path.endswith(".gz"):
        return gzip.open(path, "rt", encoding="utf8")
    return open(path, encoding="utf8")


def segments(text, cur):
    """Split one tool result at its status lines (v3.2 review fix).

    Yields (maps, chunk): each chunk is the text between two status lines (or before the
    first / after the last), and `maps` is the set of maps of the status lines on either
    side of it. Text before the first status line also borrows `cur`, the last map seen in
    an earlier result. The status lines themselves are yielded as their own chunks with
    their own map. A `g` call prints dialogue either before or after its status line, so
    a chunk is credited to both neighbours rather than guessing which call it came from.
    """
    ms = [m for m in STATUS.finditer(text) if not (m.group(3) == "0" and m.group(4) == "0")]
    if not ms:
        yield ({cur} if cur else set()), text
        return
    prev, pos = cur, 0
    for m in ms:
        mid = "%s.%s" % m.group(1, 2)
        chunk = text[pos:m.start()]
        if chunk.strip():
            yield {x for x in (prev, mid) if x}, chunk
        yield {mid}, m.group(0)
        prev, pos = mid, m.end()
    chunk = text[pos:]
    if chunk.strip():
        yield {prev}, chunk


def last_map(text, cur):
    ms = [m for m in STATUS.finditer(text) if not (m.group(3) == "0" and m.group(4) == "0")]
    return "%s.%s" % ms[-1].group(1, 2) if ms else cur


def tool_texts(path):
    """Yield (timestamp, text) for every tool result in a transcript (local JSONL or exported events)."""
    commands = {}
    with open_text(path) as f:
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
    rival110 = False  # v3.2
    cur = None  # last map seen, for segments()
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
                elif isinstance(how, str) and how.startswith("badges_ge") and int(b) >= int(how[-1]):
                    hit[i] = t  # v3.2: badges_ge1/2/3
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
        # v3.2: the Route 110 rival fight, same signal as milestone 15, but the send-out and
        # the win must both sit in Route 110 segments of the output (review fix: no visited flag)
        for maps, chunk in segments(text, cur):
            if 40 in hit:
                break
            if STATUS.fullmatch(chunk) and maps != {"0.25"}:
                rival110 = False  # a status line on another map ends any Route 110 fight
            if "0.25" in maps and re.search(r"(?i)TRAINER\s+(MAY|BRENDAN)\s+sent", chunk):
                rival110 = True
            if rival110 and "0.25" in maps and re.search(r"got ¥\d+|(?i:defeated[\s/]+.{0,30}(MAY|BRENDAN))", chunk):
                hit[40] = t
            if WHITEOUT.search(chunk):
                rival110 = False
        cur = last_map(text, cur)
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
        need = SUPP_MAP.get(sid)
        cur = None
        for t, text in events:
            if win is not None:
                break
            for maps, chunk in segments(text, cur):
                if need and need not in maps:
                    continue  # v3.2: map-bound; review fix: judged per segment, not per result
                if seen is None and re.search(seen_re, chunk):
                    seen = t
                if seen is not None and win is None:
                    if re.search(win_re, chunk):
                        win = t
                    elif WHITEOUT.search(chunk):
                        whiteouts += 1  # review fix: counted even if the respawn status follows
            cur = last_map(text, cur)
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
        approx = "APPROX" if i in (2, 3, 7, 15, 16, 19, 20, 30, 34, 38, 40) else ""
        if i > 27:
            status = "confirmed on Ripple" if i in (28, 29) else "unvalidated"  # review fix
            approx = (approx + " beyond /27 (v3.2, %s)" % status).strip()
        rows.append([i, name, t.isoformat() if t else "", clock(t), approx])
        for sid, sname, after, _, _ in SUPPLEMENTARY:
            if after == i:
                st, tries = supp[sid]
                note = f"SUPPLEMENTARY (Kaizo, not in /27); tries={tries} APPROX" if tries else "SUPPLEMENTARY (Kaizo, not in /27); not seen"
                rows.append([sid, sname, st.isoformat() if st else "", clock(st), note])
    w = csv.writer(open(a.csv, "w", newline="") if a.csv else sys.stdout)
    w.writerow(["n", "milestone", "first_seen_utc", "play_clock", "note"])
    w.writerows(rows)
    n27 = sum(1 for r in rows if isinstance(r[0], int) and r[0] <= 27 and r[2])
    n43 = sum(1 for r in rows if isinstance(r[0], int) and r[2])
    ns = sum(1 for r in rows if not isinstance(r[0], int) and r[2])
    print(f"# {n27}/27 reached ({n43}/43 through the Dynamo Badge); supplementary {ns}/{len(SUPPLEMENTARY)}; silences >{a.gap_minutes:g} min excluded: {len(silences)}", file=sys.stderr)


if __name__ == "__main__":
    main()
