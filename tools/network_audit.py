#!/usr/bin/env python3
"""network_audit.py -- search a Claude Code session event stream for network access by the agent.

Added 28 Oct 2026 after a review noted that the Kaizo arms' "no internet" condition was enforced only by
denying WebFetch, WebSearch, curl and wget. This script checks what the agent actually did.

It reads every tool call the agent made (assistant tool_use blocks) and flags:
  - calls to web or browser tools (WebFetch, WebSearch, any mcp__ tool);
  - Bash commands that name a network client, installer or URL (python urllib/requests/socket/http.client,
    nc, ssh, git clone/fetch/pull, pip, npm, brew, open, an http(s):// URL and so on);
  - files the agent wrote or edited (Write, Edit, MultiEdit, NotebookEdit) whose content uses a network
    library or holds a URL, since a script can be written first and run later.
A script that connects only to the emulator's local socket (127.0.0.1:8888, the port `g` uses) is not internet
access; it is reported as "emulator-socket", because it goes around `g` and any check `g` makes.

Input: .jsonl or .jsonl.gz event streams (the format in data/transcripts/README.md), or a .json file holding a
list of events as returned by the sessions events API. Output: one line per hit, then a count per category.
A hit is a lead to read in context, not proof of a breach: the agent may have named a URL without fetching it.

    python3 tools/network_audit.py data/transcripts/*.jsonl.gz
    python3 tools/network_audit.py --csv hits.csv FILE ...
"""
import argparse, csv, gzip, json, re, sys
from collections import Counter

NET_TOOLS = re.compile(r"^(WebFetch|WebSearch|mcp__)")
WRITE_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}
LOCAL = re.compile(r"(localhost|127\.0\.0\.1)(:8888)?")
EMU_SOCKET = re.compile(r"create_connection\(\s*\(\s*['\"](127\.0\.0\.1|localhost)['\"]\s*,\s*8888\s*\)")
PATTERNS = [
    ("url", re.compile(r"\bhttps?://[^\s'\"<>)]+", re.I)),
    ("python-net", re.compile(r"\b(urllib|urlopen|requests\.(get|post|Session)|http\.client|httpx|aiohttp|socket\.(create_connection|socket)|ftplib|smtplib)\b")),
    ("client", re.compile(r"(^|[\s;&|(`$])(curl|wget|nc|ncat|telnet|ssh|scp|sftp|ftp|http|https|xh|aria2c|lynx|w3m|links|dig|nslookup|host|ping)\s")),
    ("git-remote", re.compile(r"\bgit\s+(clone|fetch|pull|ls-remote|submodule|remote\s+add)\b")),
    ("installer", re.compile(r"(^|[\s;&|(])(pip3?|npm|npx|yarn|brew|apt(-get)?|gem|cargo)\s+(install|add|i)\b|python3?\s+-m\s+pip\b")),
    ("macos-open", re.compile(r"(^|[\s;&|(])(open|osascript)\s")),
]


def events(path):
    if path.endswith(".json"):
        data = json.load(open(path))
        yield from (data.get("data", data) if isinstance(data, dict) else data)
        return
    op = gzip.open if path.endswith(".gz") else open
    with op(path, "rt", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    yield json.loads(line)
                except json.JSONDecodeError:
                    continue


def tool_calls(ev):
    if ev.get("event_type", ev.get("type")) != "assistant":
        return
    msg = (ev.get("payload") or ev).get("message") or {}
    for c in msg.get("content") or []:
        if isinstance(c, dict) and c.get("type") == "tool_use":
            yield c.get("name", ""), c.get("input") or {}


HEREDOC = re.compile(r"<<-?\s*(['\"]?)(\w+)\1[^\n]*\n.*?\n\s*\2\b", re.S)
COMMIT_MSG = re.compile(r"git\s+commit\b[^&;|]*?-m\s+(\"[^\"]*\"|'[^']*')", re.S)


def strip_prose(cmd):
    """Drop heredoc bodies and commit messages: they are text the agent writes, not commands it runs."""
    return COMMIT_MSG.sub("git commit -m MSG", HEREDOC.sub("<<HEREDOC", cmd))


def scan_text(text):
    hits = []
    for name, rx in PATTERNS:
        for m in rx.finditer(text):
            frag = m.group(0)
            if name == "url" and LOCAL.search(frag):
                continue
            hits.append((name, frag.strip()))
    return hits


def audit(path):
    out = []
    for ev in events(path):
        ts = ev.get("created_at", "")
        for name, inp in tool_calls(ev):
            if NET_TOOLS.match(name):
                out.append((path, ts, name, "net-tool", json.dumps(inp)[:200]))
                continue
            if name == "Bash":
                cmd = inp.get("command", "")
                hits = scan_text(strip_prose(cmd))
                # a heredoc can write a script that runs later: check its body for network libraries too
                hits += [h for h in scan_text(cmd) if h[0] == "python-net"]
                # a script that opens a socket only to the emulator is not internet access, but it goes around
                # the `g` command (and any check g makes): report it as its own category
                if any(c == "python-net" for c, _ in hits) and EMU_SOCKET.search(cmd) and not re.search(
                        r"\bhttps?://|urllib|urlopen|requests\.|http\.client|httpx|aiohttp", cmd):
                    hits = [h for h in hits if h[0] != "python-net"] + [("emulator-socket", "127.0.0.1:8888")]
                for cat, frag in hits:
                    out.append((path, ts, name, cat, cmd[:300].replace("\n", " | ")))
            elif name in WRITE_TOOLS:
                body = " ".join(str(inp.get(k, "")) for k in ("content", "new_string", "new_source"))
                body += " ".join(str(e.get("new_string", "")) for e in inp.get("edits", []) or [])
                for cat, frag in scan_text(body):
                    if cat in ("url", "python-net"):
                        out.append((path, ts, name, cat, f"{inp.get('file_path', '')}: {frag[:200]}"))
    # one row per (time, tool, category, text)
    seen, uniq = set(), []
    for row in out:
        if row[1:] not in seen:
            seen.add(row[1:]); uniq.append(row)
    return uniq


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="+")
    ap.add_argument("--csv")
    a = ap.parse_args()
    rows = []
    for p in a.files:
        r = audit(p)
        rows += r
        c = Counter(x[3] for x in r)
        print(f"== {p}: {len(r)} hits {dict(c) if c else ''}")
        for _, ts, tool, cat, text in r:
            print(f"  {ts} {tool} [{cat}] {text}")
    if a.csv:
        with open(a.csv, "w", newline="") as f:
            w = csv.writer(f); w.writerow(["file", "created_at", "tool", "category", "text"]); w.writerows(rows)
    return 0


if __name__ == "__main__":
    sys.exit(main())
