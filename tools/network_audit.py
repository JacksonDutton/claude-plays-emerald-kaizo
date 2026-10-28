#!/usr/bin/env python3
"""network_audit.py -- search a Claude Code session event stream for network access by the agent.

Added 28 Oct 2026 after a review noted that the Kaizo arms' "no internet" condition was enforced only by
denying WebFetch, WebSearch, curl and wget. This script checks what the agent actually did.

It reads every tool call the agent made (assistant tool_use blocks) and flags, once per call per category:
  - net-tool: calls to web or browser tools (WebFetch, WebSearch, any mcp__ tool);
  - url, client, git-remote, installer, macos-open, python-net, other-net: Bash commands that name a remote URL
    (http, https, ws, wss, ftp), a network client, a git remote operation (including push), a package
    installer or runner, macOS open/osascript, or a network library or socket with a non-local target
    (Python; or Ruby, Node, Perl, PHP, Go, JVM, PowerShell, or the shell's /dev/tcp, reported as other-net);
  - emulator-socket: a script whose socket connects to the emulator (127.0.0.1:8888, the port `g` uses).
    That is not internet access, but it goes around `g` and any check `g` makes;
  - the same for files the agent wrote or edited (Write, Edit, MultiEdit, NotebookEdit), since a script can be
    written first and run later (prose files such as .md are checked for remote URLs only);
  - re-runs: a later command that runs a saved script with any of these (python3 x.py, ./x.sh) is a hit in
    the same category, marked "re-runs x.py", so each use is counted and not only the write.
Heredocs that feed a prose file (diary.md, notes.txt) and commit messages are text, not commands, and are not
scanned; every other heredoc (a script file, python3 -) is scanned as code.

Input: .jsonl or .jsonl.gz event streams (the format in data/transcripts/README.md), or a .json file holding a
list of events as returned by the sessions events API (loaded whole: use JSONL for large sessions). Output: one
line per hit, then a count per category. Unreadable lines are counted, the audit is marked INCOMPLETE and the
exit status is 2. A hit is a lead to read in context, not proof of a breach, and no hit means none found among
these patterns, not none happened: a client the patterns do not know would be missed. Tests: tools/test_network_audit.py.

    python3 tools/network_audit.py data/transcripts/*.jsonl.gz
    python3 tools/network_audit.py --csv hits.csv FILE ...
"""
import argparse
import os, csv, gzip, json, re, sys
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
# other languages and shells (added 28 Oct after review: a pattern scan only finds what it knows)
OTHER_HTTP = re.compile(r"(Net::HTTP|open-uri|URI\.open|Faraday|HTTParty|RestClient|"            # Ruby
                        r"require\(\s*['\"](?:node:)?(?:https?|http2|ws|axios|node-fetch|undici|got)['\"]\s*\)|"
                        r"from\s+['\"](?:node:)?(?:https?|axios|node-fetch|undici|got)['\"]|"
                        r"\bfetch\(|\baxios\b|XMLHttpRequest|new\s+WebSocket\b|https?\.(?:get|request)\(|"   # Node / JS
                        r"LWP::|HTTP::Tiny|Net::FTP|WWW::Mechanize|"                              # Perl
                        r"curl_exec|curl_init|file_get_contents\(\s*['\"](?:https?|ftp)://|"     # PHP
                        r"http\.(?:Get|Post|NewRequest)\(|"                                       # Go
                        r"java\.net\.|HttpClient|URLConnection|"                                  # JVM
                        r"Invoke-WebRequest|Invoke-RestMethod|System\.Net\.)")                    # PowerShell / .NET
OTHER_SOCK = re.compile(r"(TCPSocket|UDPSocket|IO::Socket|Socket\.tcp|net\.(?:connect|createConnection)|"
                        r"fsockopen|stream_socket_client|net\.Dial|require\(\s*['\"](?:node:)?(?:net|dgram|tls)['\"]\s*\))")
# literal socket targets in other languages: TCPSocket.new("host", 8888), net.connect(8888, "host"), /dev/tcp/host/port
ALT_TARGETS = [
    (re.compile(r"(?:TCPSocket\.(?:new|open)|Socket\.tcp|fsockopen|net\.Dial)\(\s*['\"]?([^'\",()\s]+?)['\"]?\s*,\s*['\"]?(\d+)"), 1, 2),
    (re.compile(r"(?:net|\))\.(?:connect|createConnection)\(\s*(\d+)\s*,\s*['\"]([^'\"]+)['\"]"), 2, 1),
    (re.compile(r"PeerAddr\s*=>\s*['\"]([^'\":]+)(?::(\d+))?['\"]"), 1, 2),
    (re.compile(r"/dev/(?:tcp|udp)/([^/\s'\"]+)/(\d+)"), 1, 2),
]
COMMAND_PATTERNS = [
    ("client", re.compile(r"(^|[\s;&|(`$])(curl|wget|nc|ncat|telnet|ssh|scp|sftp|ftp|http|https|xh|aria2c|lynx|w3m|"
                          r"links|dig|nslookup|host|ping|websocat|wscat|socat|nmap|whois)\s|openssl\s+s_client")),
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


HEREDOC = re.compile(r"([^\n]*)<<-?\s*(['\"]?)(\w+)\2([^\n]*)\n(.*?)\n\s*\3\b", re.S)
COMMIT_MSG = re.compile(r"git\s+commit\b[^&;|]*?-m\s+(\"[^\"]*\"|'[^']*')", re.S)


def split_bash(cmd):
    """Return (shell part, code bodies). A heredoc that feeds a prose file (diary.md, notes.txt) is text the
    agent writes, so it is dropped; any other heredoc (a script file, python3 -) is code and is scanned in full.
    Commit messages are dropped."""
    code = []
    def sub(m):
        if not PROSE_FILE.search(m.group(1) + m.group(4)):
            code.append(m.group(5))
        return m.group(1) + "<<HEREDOC" + m.group(4)
    shell = COMMIT_MSG.sub("git commit -m MSG", HEREDOC.sub(sub, cmd))
    return shell, code


SCRIPT_NAME = r"\w[\w.-]*\.(?:py|sh|bash|zsh|js|mjs|cjs|ts|rb|pl|php|ps1|go|lua)"
SHELL_SCRIPT = re.compile(r"\.(?:sh|bash|zsh)$")
REDIRECT = re.compile(r"(>>?)\s*['\"]?(?:[^\s'\";&|]*/)?(" + SCRIPT_NAME + r")['\"]?")
SEGMENT_BREAK = re.compile(r".*(?:;|&&|\|\||\|(?!\|)|&(?!&)|\n)", re.S)
# How a saved script is started: an interpreter (options may take one value each), source or ".", or a path
# in command position (./x.sh, /tmp/s/x.py, s/x.py). The name may be quoted.
OPTS = r"(?:-[^\s;&|]*\s+(?:[^-\s;&|][^\s;&|]*\s+)??)*?"
INTERP = (r"\b(?:python[\d.]*|bash|sh|zsh|node|deno|ts-node|ruby|perl|php|lua|pwsh|powershell|go\s+run|source)\s+"
          + OPTS + r"|(?:^|[;&|(]|&&|\|\||\bnohup|\btimeout\s+\S+|\bexec)\s*\.\s+")
CMD_POS = r"(?:^|[;&|(\n]|&&|\|\||\bnohup\s|\btimeout\s+\S+\s|\bexec\s)\s*"


def heredoc_scripts(cmd):
    """(mode, script name, body) for each heredoc written to a script file: mode '>' replaces, '>>' appends.
    The target is the redirection in the heredoc's own command, before or after the << delimiter."""
    out = []
    for m in HEREDOC.finditer(cmd):
        own = SEGMENT_BREAK.sub("", m.group(1))  # drop earlier commands on the same line
        t = REDIRECT.search(own + " " + m.group(4))
        if t:
            out.append((t.group(1), t.group(2), m.group(5)))
    return out


def runs_script(shell, name):
    n = r"['\"]?(?:[^\s'\";&|]*/)?" + re.escape(name) + r"['\"]?(?![\w.-])"
    return (re.search(r"(?:" + INTERP + r")" + n, shell, re.M) is not None
            or re.search(CMD_POS + r"['\"]?(?:\.{0,2}/|[\w~.-]+/)[^\s'\";&|]*?" + re.escape(name) + r"['\"]?(?![\w.-])",
                         shell, re.M) is not None)


def failed_calls(path):
    """tool_use ids whose result came back as an error, so a write that failed does not change what we
    believe a saved script contains."""
    ids = set()
    for ev in events(path, [0]):
        msg = (ev.get("payload") or ev).get("message") or {}
        for c in msg.get("content") or [] if isinstance(msg.get("content"), list) else []:
            if isinstance(c, dict) and c.get("type") == "tool_result" and c.get("is_error"):
                ids.add(c.get("tool_use_id", ""))
    return ids


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
    literal targets are the emulator (127.0.0.1:8888) is "emulator-socket": not internet access, but it goes
    around `g` and any check `g` makes. Any other target, or a socket with no literal target, is python-net
    (Python) or other-net (any other language, or /dev/tcp in the shell)."""
    cats = set()
    if remote_urls(text):
        cats.add("url")
    py_targets = [(m.group(2).lower(), int(m.group(3))) for m in SOCK_TARGET.finditer(text)]
    alt_targets = []
    for rx, h, p in ALT_TARGETS:
        for m in rx.finditer(text):
            port = m.group(p)
            alt_targets.append((m.group(h).lower(), int(port) if port else -1))
    is_emu = lambda t: t[0] in LOCAL_HOSTS and t[1] == EMU_PORT
    if any(is_emu(t) for t in py_targets + alt_targets):
        cats.add("emulator-socket")
    py_other = [t for t in py_targets if not is_emu(t)]
    alt_other = [t for t in alt_targets if not is_emu(t)]
    if py_other:
        cats.add("python-net")
    for m in PY_NET.finditer(text):
        lib = m.group(0)
        if lib in ("socket.create_connection", "socket.socket") and py_targets and not py_other:
            continue  # the only connections are to the emulator, already counted
        cats.add("python-net")
    if alt_other or OTHER_HTTP.search(text):
        cats.add("other-net")
    elif OTHER_SOCK.search(text) and not (alt_targets and not alt_other):
        cats.add("other-net")  # a socket in another language whose target we could not read
    return cats


def scan_shell(text):
    cats = scan_code(text)
    for name, rx in COMMAND_PATTERNS:
        if rx.search(text):
            cats.add(name)
    return cats


def audit(path):
    """Rows of (file, created_at, tool_use_id, tool, category, text). A script the agent saved with network or
    emulator-socket code is remembered by file name, and every later command that runs it (python3 x.py, ./x.sh,
    source x.sh) is a hit too, marked "re-runs x.py": otherwise a saved script would be counted once, when it
    was written. Known limits, which err towards reporting a run for a person to check: names are matched
    without their folder; a mention of "python3 x.py" in quoted text counts as a run; an Edit only adds
    categories (it shows a fragment, not the whole file); a script that only imports another module is not
    followed; parallel tool calls are taken in the order they were issued."""
    rows, bad = [], [0]
    failed = failed_calls(path)
    saved = {}  # script name -> categories found in its code
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
                for mode, script, body in heredoc_scripts(cmd):
                    found = scan_shell(body)
                    saved[script] = found | (saved.get(script, set()) if mode == ">>" else set())
                run_text = "\n".join([shell] + bodies)  # heredoc bodies fed to a shell or python can run scripts
                reruns = {n: set(c) for n, c in saved.items() if c and runs_script(run_text, n)}
                rerun_cats = set().union(*reruns.values()) if reruns else set()
                for cat in sorted(cats | rerun_cats):
                    names = sorted(n for n, c in reruns.items() if cat in c)
                    note = "re-runs " + ", ".join(names) + ": " if names else ""
                    rows.append((path, ts, cid, name, cat, note + cmd[:300].replace("\n", " | ")))
            elif name in WRITE_TOOLS:
                fp = str(inp.get("file_path", "") or inp.get("notebook_path", ""))
                body = " ".join(str(inp.get(k, "")) for k in ("content", "new_string", "new_source"))
                body += " ".join(str(e.get("new_string", "")) for e in inp.get("edits", []) or [])
                scan = scan_shell if SHELL_SCRIPT.search(fp) else scan_code
                cats = {"url"} & scan_code(body) if PROSE_FILE.search(fp) else scan(body)
                base = os.path.basename(fp)
                if re.fullmatch(SCRIPT_NAME, base) and cid not in failed:
                    saved[base] = cats | (saved.get(base, set()) if name != "Write" else set())
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
