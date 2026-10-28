#!/usr/bin/env python3
"""network_audit.py -- search a Claude Code session event stream for network access by the agent.

Added 28 Oct 2026 after a review noted that the Kaizo arms' "no internet" condition was enforced only by
denying WebFetch, WebSearch, curl and wget. This script checks what the agent actually did.

It reads every tool call the agent made (assistant tool_use blocks) and flags, once per call per category:
  - net-tool: calls to web or browser tools (WebFetch, WebSearch, any mcp__ tool);
  - url, client, git-remote, installer, macos-open, python-net: Bash commands that name a remote URL
    (http, https, ws, wss, ftp), a network client, a git remote operation (including push), a package
    installer or runner, macOS open/osascript, or a network library or socket with a non-local target;
  - emulator-socket: a script whose socket connects to the emulator (127.0.0.1:8888, the port `g` uses).
    That is not internet access, but it goes around `g` and any check `g` makes;
  - the same for files the agent wrote or edited (Write, Edit, MultiEdit, NotebookEdit), since a script can be
    written first and run later (prose files such as .md are checked for remote URLs only).
Heredocs that feed a prose file (diary.md, notes.txt) and commit messages are text, not commands, and are not
scanned; every other heredoc (a script file, python3 -) is scanned as code.

Input: .jsonl or .jsonl.gz event streams (the format in data/transcripts/README.md), or a .json file holding a
list of events as returned by the sessions events API (loaded whole: use JSONL for large sessions). Output: one
line per hit, then a count per category. Unreadable lines are counted, the audit is marked INCOMPLETE and the
exit status is 2. A hit is a lead to read in context, not proof of a breach. Tests: tools/test_network_audit.py.

    python3 tools/network_audit.py data/transcripts/*.jsonl.gz
    python3 tools/network_audit.py --csv hits.csv FILE ...
"""
import argparse, csv, gzip, json, re, sys
from urllib.parse import urlsplit
from collections import Counter

NET_TOOLS = re.compile(r"^(WebFetch|WebSearch|mcp__)")
WRITE_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}
LOCAL_HOSTS = {"localhost", "127.0.0.1", "::1", "0.0.0.0"}
EMU_PORT = 8888
URL = re.compile(r"\b(?:https?|wss?|ftp)://[^\s'\"<>)]+", re.I)
PY_NET = re.compile(r"\b(urllib3?|urlopen|requests\.\w+|http\.client|httpx|aiohttp|pycurl|websockets?|ftplib|smtplib|"
                    r"telnetlib|paramiko|xmlrpc\.client|asyncio\.open_connection|"
                    r"socket\.(gethostbyname\w*|getaddrinfo|create_connection|socket))\b")
# a socket connection with a literal target: create_connection(("host", port)) or s.connect(("host", port))
SOCK_TARGET = re.compile(r"(?:create_connection|\.connect(?:_ex)?)\(\s*\(\s*(['\"]?)([^'\",()\s]+)\1\s*,\s*(\d+)\s*\)")
COMMAND_PATTERNS = [
    ("client", re.compile(r"(^|[\s;&|(`$])(curl|wget|nc|ncat|telnet|ssh|scp|sftp|ftp|http|https|xh|aria2c|lynx|w3m|"
                          r"links|dig|nslookup|host|ping|websocat|wscat)\s")),
    ("git-remote", re.compile(r"\bgit\s+(clone|fetch|pull|push|ls-remote|submodule|remote\s+add)\b")),
    ("installer", re.compile(r"(^|[\s;&|(])(npx|pnpm\s+dlx|bunx)\s|(^|[\s;&|(])(pip3?|npm|pnpm|yarn|bun|brew|apt(-get)?|gem|"
                             r"cargo|conda|poetry|uv|go)\s+(install|add|i|ci|get|sync|pip)\b|python3?\s+-m\s+pip\b")),
    ("macos-open", re.compile(r"(^|[\s;&|(])(open|osascript)\s")),
]
PROSE_FILE = re.compile(r"\.(md|txt|csv|log)\b")


def events(path, bad):
    """Yield events; count unreadable lines in bad[0] so the audit can say it is incomplete.
    A .json input (a list of events from the sessions API) is loaded whole: use JSONL for large sessions."""
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
                    bad[0] += 1


def tool_calls(ev):
    if ev.get("event_type", ev.get("type")) != "assistant":
        return
    msg = (ev.get("payload") or ev).get("message") or {}
    for c in msg.get("content") or []:
        if isinstance(c, dict) and c.get("type") == "tool_use":
            yield c.get("id", ""), c.get("name", ""), c.get("input") or {}


HEREDOC = re.compile(r"([^\n]*)<<-?\s*(['\"]?)(\w+)\2[^\n]*\n(.*?)\n\s*\3\b", re.S)
COMMIT_MSG = re.compile(r"git\s+commit\b[^&;|]*?-m\s+(\"[^\"]*\"|'[^']*')", re.S)


def split_bash(cmd):
    """Return (shell part, code bodies). A heredoc that feeds a prose file (diary.md, notes.txt) is text the
    agent writes, so it is dropped; any other heredoc (a script file, python3 -) is code and is scanned in full.
    Commit messages are dropped."""
    code = []
    def sub(m):
        if not PROSE_FILE.search(m.group(1)):
            code.append(m.group(4))
        return m.group(1) + "<<HEREDOC"
    shell = COMMIT_MSG.sub("git commit -m MSG", HEREDOC.sub(sub, cmd))
    return shell, code


def remote_urls(text):
    out = []
    for m in URL.finditer(text):
        try:
            host = (urlsplit(m.group(0)).hostname or "").lower()
        except ValueError:
            host = ""
        if host not in LOCAL_HOSTS:
            out.append(m.group(0))
    return out


def scan_code(text):
    """Categories for program text: remote URLs, network libraries, and socket targets. A socket whose only
    literal target is the emulator (127.0.0.1:8888) is "emulator-socket": not internet access, but it goes
    around `g` and any check `g` makes. Any other target, or a socket with no literal target, is python-net."""
    cats = set()
    if remote_urls(text):
        cats.add("url")
    targets = [(m.group(2).lower(), int(m.group(3))) for m in SOCK_TARGET.finditer(text)]
    emu = [t for t in targets if t[0] in LOCAL_HOSTS and t[1] == EMU_PORT]
    other = [t for t in targets if t not in emu]
    if emu:
        cats.add("emulator-socket")
    if other:
        cats.add("python-net")
    for m in PY_NET.finditer(text):
        lib = m.group(0)
        if lib in ("socket.create_connection", "socket.socket") and targets and not other:
            continue  # the only connections are to the emulator, already counted
        cats.add("python-net")
    return cats


def scan_shell(text):
    cats = scan_code(text)
    for name, rx in COMMAND_PATTERNS:
        if rx.search(text):
            cats.add(name)
    return cats


def audit(path):
    rows, bad = [], [0]
    for ev in events(path, bad):
        ts = ev.get("created_at", "")
        for cid, name, inp in tool_calls(ev):
            if NET_TOOLS.match(name):
                rows.append((path, ts, cid, name, "net-tool", json.dumps(inp)[:200]))
                continue
            if name == "Bash":
                cmd = inp.get("command", "")
                shell, bodies = split_bash(cmd)
                cats = scan_shell(shell)
                for b in bodies:
                    cats |= scan_shell(b)
                for cat in sorted(cats):
                    rows.append((path, ts, cid, name, cat, cmd[:300].replace("\n", " | ")))
            elif name in WRITE_TOOLS:
                fp = str(inp.get("file_path", "") or inp.get("notebook_path", ""))
                body = " ".join(str(inp.get(k, "")) for k in ("content", "new_string", "new_source"))
                body += " ".join(str(e.get("new_string", "")) for e in inp.get("edits", []) or [])
                cats = {"url"} & scan_code(body) if PROSE_FILE.search(fp) else scan_code(body)
                for cat in sorted(cats):
                    rows.append((path, ts, cid, name, cat, f"{fp}: {body[:200]}".replace("\n", " | ")))
    return rows, bad[0]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="+")
    ap.add_argument("--csv")
    a = ap.parse_args()
    rows, incomplete = [], False
    for p in a.files:
        r, bad = audit(p)
        rows += r
        c = Counter(x[4] for x in r)
        print(f"== {p}: {len(r)} hits {dict(c) if c else ''}")
        if bad:
            incomplete = True
            print(f"  WARNING: {bad} unreadable line(s) skipped: this audit is INCOMPLETE")
        for _, ts, cid, tool, cat, text in r:
            print(f"  {ts} {tool} [{cat}] {text}")
    if a.csv:
        with open(a.csv, "w", newline="") as f:
            w = csv.writer(f); w.writerow(["file", "created_at", "tool_use_id", "tool", "category", "text"]); w.writerows(rows)
    return 2 if incomplete else 0


if __name__ == "__main__":
    sys.exit(main())
