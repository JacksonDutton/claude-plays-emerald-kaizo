#!/usr/bin/env python3
"""plot_k2_progress.py -- draw data/figures/k2-progress.svg from the two CSVs beside it.

Standard library only. Hours of play exclude K2's 23-27 October usage pause. Usage:
    python3 tools/plot_k2_progress.py
"""
import csv, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIG = os.path.join(ROOT, "data", "figures")
W, H = 760, 356
L, R, T, B = 56, 40, 90, 46          # plot margins
XMAX, YMAX = 175, 150                # axis maxima; main() widens them to fit the data

def x(h): return L + (W - L - R) * h / XMAX
def y(n): return H - B - (H - T - B) * n / YMAX

def round_up(v, step): return step * -(-v // step)

def main():
    with open(os.path.join(FIG, "k2-whiteouts.csv")) as f:
        pts = [(float(r["hours_of_play"]), int(r["cumulative_whiteouts"])) for r in csv.DictReader(f)]
    with open(os.path.join(FIG, "k2-milestones.csv")) as f:
        ms = [(float(r["hours_of_play"]), r["milestone"], r["kind"], r["tries"]) for r in csv.DictReader(f)]
    pts.sort()
    global XMAX, YMAX
    XMAX = max(XMAX, int(round_up(max(p[0] for p in pts) + 4, 25)))
    YMAX = max(YMAX, int(round_up(max(p[1] for p in pts) + 1, 50)))
    def at(h):  # cumulative whiteouts at hour h
        n = 0
        for ph, pn in pts:
            if ph <= h: n = pn
        return n
    d = [f"M{x(0):.1f},{y(0):.1f}"]
    for h, n in pts[1:]:
        d.append(f"H{x(h):.1f}V{y(n):.1f}")
    last_h, last_n = pts[-1]
    out = []
    a = out.append
    a(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" '
      f'aria-labelledby="t d" font-family="-apple-system, Segoe UI, Helvetica, Arial, sans-serif">')
    a('<title id="t">K2 in Emerald Kaizo: whiteouts and badges over hours of play</title>')
    a(f'<desc id="d">Cumulative whiteouts rise from 0 to {last_n} over {last_h:.0f} hours of play. '
      'Badges 1 to 8 are marked on the line, with Trainer Red, beaten on the fifteenth try, near the end.</desc>')
    a('<style>.bg{fill:#fcfcfb}.ink{fill:#0b0b0b}.ink2{fill:#52514e}.grid{stroke:#e4e3df;stroke-width:1}'
      '.axis{stroke:#9a9993;stroke-width:1}.line{fill:none;stroke:#2a78d6;stroke-width:2;stroke-linejoin:round}'
      '.dot{fill:#2a78d6;stroke:#fcfcfb;stroke-width:2}.red{fill:#eb6834;stroke:#fcfcfb;stroke-width:2}'
      '@media (prefers-color-scheme: dark){.bg{fill:#1a1a19}.ink{fill:#f0efec}.ink2{fill:#c3c2b7}'
      '.grid{stroke:#33332f}.axis{stroke:#6f6e68}.line{stroke:#3987e5}.dot{fill:#3987e5;stroke:#1a1a19}'
      '.red{fill:#d95926;stroke:#1a1a19}}</style>')
    a(f'<rect class="bg" width="{W}" height="{H}" rx="8"/>')
    a(f'<text class="ink" x="{L}" y="28" font-size="16" font-weight="600">K2 in Emerald Kaizo: '
      f'{last_n} whiteouts and eight badges in {last_h:.0f} hours of play</text>')
    a(f'<text class="ink2" x="{L}" y="48" font-size="12">Line: cumulative whiteouts. Dots 1-8: badges. '
      'R: Trainer Red, beaten on the 15th try.</text>')
    a(f'<text class="ink2" x="{L}" y="65" font-size="12">Hours of play exclude the 23-27 Oct usage pause. '
      'Data and script: data/figures/, tools/plot_k2_progress.py.</text>')
    for n in range(0, YMAX + 1, 50):
        a(f'<line class="grid" x1="{L}" x2="{W-R}" y1="{y(n):.1f}" y2="{y(n):.1f}"/>')
        a(f'<text class="ink2" x="{L-8}" y="{y(n)+4:.1f}" font-size="11" text-anchor="end">{n}</text>')
    for h in range(0, XMAX + 1, 25):
        a(f'<text class="ink2" x="{x(h):.1f}" y="{H-B+18}" font-size="11" text-anchor="middle">{h}</text>')
    a(f'<line class="axis" x1="{L}" x2="{W-R}" y1="{y(0):.1f}" y2="{y(0):.1f}"/>')
    a(f'<text class="ink2" x="{(L+W-R)/2:.0f}" y="{H-8}" font-size="11" text-anchor="middle">hours of play</text>')
    a(f'<text class="ink2" x="14" y="{(T+H-B)/2:.0f}" font-size="11" text-anchor="middle" '
      f'transform="rotate(-90 14 {(T+H-B)/2:.0f})">whiteouts</text>')
    a(f'<path class="line" d="{"".join(d)}H{x(last_h):.1f}"/>')
    badge = 0
    for h, name, kind, tries in ms:
        cx, cy = x(h), y(at(h))
        if kind == "badge":
            badge += 1
            a(f'<circle class="dot" cx="{cx:.1f}" cy="{cy:.1f}" r="5"><title>Badge {badge}: {name} '
              f'(try {tries}), hour {h:.1f}</title></circle>')
            a(f'<text class="ink" x="{cx:.1f}" y="{cy-10:.1f}" font-size="11" font-weight="600" '
              f'text-anchor="middle">{badge}</text>')
        else:
            a(f'<circle class="red" cx="{cx:.1f}" cy="{cy:.1f}" r="5"><title>Trainer Red, beaten on try '
              f'{tries}, hour {h:.1f}</title></circle>')
            a(f'<text class="ink" x="{cx:.1f}" y="{cy-10:.1f}" font-size="11" font-weight="600" '
              f'text-anchor="middle">R</text>')
    a(f'<text class="ink" x="{x(last_h)+6:.1f}" y="{y(last_n)+4:.1f}" font-size="12" font-weight="600">{last_n}</text>')
    a('</svg>')
    path = os.path.join(FIG, "k2-progress.svg")
    tmp = path + ".tmp"
    with open(tmp, "w") as f:          # write aside, then swap in, so a failed run never leaves a broken figure
        f.write("\n".join(out) + "\n")
    os.replace(tmp, path)

if __name__ == "__main__":
    main()
