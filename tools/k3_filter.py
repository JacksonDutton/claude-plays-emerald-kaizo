#!/usr/bin/env python3
"""k3_filter.py -- mechanical geography/name filter for the K3 notes pack (companion, 28 Oct 2026).
Step 4 of the knowledge extraction protocol (pokeagent-setup.md): run on the DISTILLER'S output,
before the independent audit. Lines that match are removed whole, never reworded; each removal is
reported with its reason so the audit and Jackson's sign-off can see exactly what went.

Usage: python3 k3_filter.py IN.md OUT.md [--report report.tsv] [--extra-names names.txt]
Standard library only.
"""
import re, sys, argparse

COORD = re.compile(r'\(\s*\d{1,3}\s*,\s*\d{1,3}\s*\)')
MAPID = re.compile(r'(?<![\w.×])\d{1,2}\.\d{1,3}(?![\w.%×])(?!\s*(?:x|×|times)\b)')  # 24.85, 0.44; not 1.5x, x1.5, 1.5 times, 50% (PR #15 review)
HEX = re.compile(r'\b0x[0-9a-fA-F]{3,}\b')
# Run nicknames (Run 1 Claude-Brendan, Ripple, K2 and the D15 pilot). Extend with --extra-names.
NICKS = ['ZAP','PEBBLE','ECHO','WISP','SNIP','NIMBUS','CINDER','TREMOR','TALON','ANVIL','VIGIL','FORGE','GRIT',
         'WOOLY','MARROW','KILN','BLOAT','PUDDLE','BREEZE','NIBBLE','RIPPLE','PIP']
# Hoenn place names (towns, cities, routes, caves and landmarks of Emerald).
PLACES = ['Littleroot','Oldale','Petalburg','Rustboro','Dewford','Slateport','Mauville','Verdanturf','Fallarbor',
          'Lavaridge','Fortree','Lilycove','Mossdeep','Sootopolis','Pacifidlog','Ever Grande','Granite Cave',
          'Rusturf','Meteor Falls','Mt\\. ?Chimney','Jagged Pass','Fiery Path','Mt\\. ?Pyre','Shoal Cave',
          'Seafloor Cavern','Cave of Origin','Sky Pillar','Victory Road','Safari Zone','Weather Institute',
          'Trick House','New Mauville','Abandoned Ship','Battle Frontier','Desert Underpass','Mirage',
          'Magma Hideout','Aqua Hideout','Space Center','Oceanic Museum','Devon','Route ?1[0-3][0-9]',
          'Petalburg Woods','Scorched Slab','Island Cave','Desert Ruins','Ancient Tomb','Sealed Chamber']
# Round 6 (20 Oct): every unit tracing to a message or hint is excluded. The distiller tags such units.
# [from message] / [from hint] are always removed. [from tip ...] tags inherited from K2.md (supervisor tips from
# Run 1) are KEPT and COUNTED (Jackson, 28 Oct: round 6 covers K2's own run messages only); --drop-tip removes them.
TAG = re.compile(r'\[from (message|hint)[^\]]*\]', re.I)
TIP = re.compile(r'\[from tip[^\]]*\]', re.I)
# Named trainers: FLAG only (the pre-registered filter covers places and nicknames; per-trainer
# knowledge is cut by the auditor, kaizo-K3-candidates section 5).
TRAINERS = ['Roxanne','Brawly','Wattson','Flannery','Norman','Winona','Tate','Liza','Juan','Wallace','Sidney',
            'Phoebe','Glacia','Drake','Steven','Maxie','Archie','Tabitha','Shelly','Matt','Courtney','Wally']
TRN = re.compile(r'\b(' + '|'.join(TRAINERS + [t.upper() for t in TRAINERS]) + r')\b')  # Title case or ALL CAPS
DIRS = re.compile(r'\b(north|south|east|west|northeast|northwest|southeast|southwest|upstairs|downstairs)\b', re.I)

def build(extra):
    names = NICKS + [n.strip() for n in extra if n.strip()]
    # PR #15 review: match a name in ALL CAPS or in Title case (the distiller may retype ZAP as Zap);
    # lower case stays unmatched on purpose, because several nicknames are ordinary words (echo, forge, grit).
    forms = sorted({v for n in names for v in (n.upper(), n.capitalize())}, key=len, reverse=True)
    nick = re.compile(r'\b(' + '|'.join(map(re.escape, forms)) + r')\b')
    place = re.compile(r'\b(' + '|'.join(PLACES) + r')\b', re.I)
    return nick, place

def reasons(line, nick, place, drop_tip=False):
    r = []
    if TAG.search(line): r.append('provenance tag (round 6)')
    if TIP.search(line): r.append('provenance tag [from tip] (round 6)' if drop_tip else 'tip tag (kept, counted)')
    if COORD.search(line): r.append('coordinate')
    if MAPID.search(line): r.append('map id')
    if HEX.search(line): r.append('hex')
    m = nick.search(line)
    if m: r.append('nickname:' + m.group(1))
    m = place.search(line)
    if m: r.append('place:' + m.group(1))
    m = TRN.search(line)
    if m: r.append('trainer (audit):' + m.group(1))
    if DIRS.search(line): r.append('direction (audit: keep only if not a map direction)')
    return r

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('inp'); ap.add_argument('out')
    ap.add_argument('--report'); ap.add_argument('--extra-names')
    ap.add_argument('--drop-tip', action='store_true', help='also remove [from tip ...] units')
    a = ap.parse_args()
    extra = open(a.extra_names).read().split('\n') if a.extra_names else []
    nick, place = build(extra)
    kept, rep = [], []
    # Each report row carries the input line and, for kept lines, the line number in the OUTPUT file,
    # which is what the auditor cites (PR #15 review: input numbers drift after removals).
    for i, line in enumerate(open(a.inp, encoding='utf-8'), 1):
        rs = reasons(line, nick, place, a.drop_tip)
        hard = [x for x in rs if not x.startswith(('direction', 'trainer', 'tip tag'))]
        if hard:
            rep.append((i, '', 'REMOVED', ';'.join(rs), line.strip()[:200]))
            continue
        kept.append(line)
        if rs:
            act = 'COUNT' if all(x.startswith('tip tag') for x in rs) else 'FLAG'
            rep.append((i, len(kept), act, ';'.join(rs), line.strip()[:200]))
    open(a.out, 'w', encoding='utf-8').writelines(kept)
    if a.report:
        with open(a.report, 'w', encoding='utf-8') as f:
            f.write('in_line\tout_line\taction\treason\ttext\n')
            for r in rep: f.write('\t'.join(map(str, r)) + '\n')
    n_rm = sum(1 for r in rep if r[2] == 'REMOVED'); n_fl = sum(1 for r in rep if r[2] == 'FLAG')
    n_tip = sum(1 for r in rep if r[2] != 'REMOVED' and 'tip tag' in r[3])   # kept lines only (PR #15 review)
    print('lines in %d, removed %d, flagged for audit %d, tip-tagged kept %d, out %d' % (i, n_rm, n_fl, n_tip, len(kept)))

if __name__ == '__main__':
    main()
