#!/usr/bin/env python3
"""Recompute API-equivalent cost from a claude.ai/code session events export (JSONL, one event per line).
Companion, 20 Oct 2026. Usage: session_cost.py FILE.jsonl (or FILE.jsonl.gz)
Prints: Claude Code's own running total (result events' total_cost_usd), a recompute at list prices
(per unique message id, max of each usage field), tokens by model, and autocompact events."""
import json, sys, collections, gzip
P = {'claude-sonnet-5-5': (2, 2.5, 4, 0.10, 10), 'claude-opus-5-5': (4, 5, 8, 0.20, 20)}
def haiku(prompt):  # per-request tiering on prompt length
    return (0.5, 0.625, 1, 0.05, 2.5) if prompt > 100000 else (0.1, 0.125, 0.2, 0.01, 0.5)
U = {}; results = []; compact = []; types = collections.Counter(); first = last = None
src = gzip.open(sys.argv[1], 'rt', encoding='utf8') if sys.argv[1].endswith('.gz') else open(sys.argv[1], encoding='utf8')  # .jsonl.gz read directly (21 Oct)
for line in src:
    e = json.loads(line); t = e.get('created_at'); types[e.get('event_type')] += 1
    first = t if first is None or t < first else first; last = t if last is None or t > last else last
    p = e.get('payload') or {}
    if e.get('event_type') == 'assistant':
        m = p.get('message') or {}; u = m.get('usage'); mid = m.get('id')
        if u and mid:
            c = u.get('cache_creation') or {}
            d = U.setdefault(mid, {'model': m.get('model'), 'i': 0, 'c5': 0, 'c1': 0, 'cw': 0, 'cr': 0, 'o': 0})
            for k, v in (('i', u.get('input_tokens')), ('c5', c.get('ephemeral_5m_input_tokens')), ('c1', c.get('ephemeral_1h_input_tokens')),
                         ('cw', u.get('cache_creation_input_tokens')), ('cr', u.get('cache_read_input_tokens')), ('o', u.get('output_tokens'))):
                d[k] = max(d[k], v or 0)
    elif e.get('event_type') == 'result':
        results.append((t, p.get('total_cost_usd'), p.get('subtype')))
    elif e.get('event_type') == 'autocompact_state':
        compact.append((t, {k: v for k, v in p.items() if k not in ('session_id', 'uuid', 'type')}))
by = collections.defaultdict(lambda: collections.Counter()); tot = 0.0
for d in U.values():
    m = d['model'] or '?'; c5 = d['c5'] if (d['c5'] or d['c1']) else d['cw']
    pr = P.get(m) or (haiku(d['i'] + d['cw'] + d['cr']) if 'haiku' in m else None)
    usd = (d['i'] * pr[0] + c5 * pr[1] + d['c1'] * pr[2] + d['cr'] * pr[3] + d['o'] * pr[4]) / 1e6 if pr else 0
    b = by[m]; b['calls'] += 1; b['input'] += d['i']; b['cache_write_5m'] += c5; b['cache_write_1h'] += d['c1']; b['cache_read'] += d['cr']; b['output'] += d['o']; b['usd_x100'] += round(usd * 100)
    tot += usd
print('file', sys.argv[1]); print('events', sum(types.values()), dict(types)); print('span', first, '->', last)
rc = [r for r in results if r[1] is not None]
print('claude_code_total_cost_usd (max of result events)', max((r[1] for r in rc), default=None), 'from', len(rc), 'result events')
print('recomputed_usd_list_prices', round(tot, 2))
for m, b in by.items(): print(' ', m, dict(b))
print('autocompact_state events', len(compact))
for t, d in sorted(compact, key=lambda x: x[0]): print('  ', t, json.dumps(d)[:200])
