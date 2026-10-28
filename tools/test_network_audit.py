#!/usr/bin/env python3
"""Checks for network_audit.py: python3 tools/test_network_audit.py (exits non-zero on a failure)."""
import gzip, json, os, sys, tempfile
sys.path.insert(0, os.path.dirname(__file__))
import network_audit as na

def run(calls, raw_lines=()):
    fd, p = tempfile.mkstemp(suffix=".jsonl"); os.close(fd)
    with open(p, "w") as f:
        for i, (name, inp) in enumerate(calls):
            f.write(json.dumps({"event_type": "assistant", "created_at": "t",
                                "payload": {"message": {"content": [{"type": "tool_use", "id": f"c{i}", "name": name, "input": inp}]}}}) + "\n")
        for l in raw_lines:
            f.write(l + "\n")
    try:
        return na.audit(p)
    finally:
        os.remove(p)

def cats(calls):
    rows, _ = run(calls)
    return sorted(r[4] for r in rows)

B = lambda c: ("Bash", {"command": c})
EMU = "import socket\ns=socket.create_connection(('127.0.0.1',8888))\n"
cases = [
    ("emulator-only heredoc script", [B("cat > a.py <<'EOF'\n" + EMU + "EOF\npython3 a.py")], ["emulator-socket"]),
    ("emulator plus remote socket", [B("python3 - <<'EOF'\n" + EMU + "t=socket.create_connection(('example.com',80))\nEOF")], ["emulator-socket", "python-net"]),
    ("socket.socket().connect to emulator", [B("python3 - <<'EOF'\nimport socket\ns=socket.socket(); s.connect(('localhost', 8888))\nEOF")], ["emulator-socket"]),
    ("curl inside a script heredoc", [B("cat > f.sh <<'EOF'\ncurl https://example.com/x\nEOF\nbash f.sh")], ["client", "url"]),
    ("diary prose is ignored", [B("cat >> run/diary.md <<'EOF'\nI could open the door; see https://example.com\nEOF")], []),
    ("url with localhost in the path is remote", [B("python3 -c \"print('https://evil.example/localhost')\"")], ["url"]),
    ("local url is not a hit", [B("echo http://127.0.0.1:8888/x")], []),
    ("git push", [B("git push origin main")], ["git-remote"]),
    ("npm ci / npx / pnpm install", [B("npm ci"), B("npx cowsay hi"), B("pnpm install")], ["installer"] * 3),
    ("requests.put and gethostbyname", [B("python3 -c 'import requests; requests.put(u)'"), B("python3 -c 'import socket; socket.gethostbyname(h)'")], ["python-net"] * 2),
    ("websocket url and library", [B("python3 -c 'import websockets; websockets.connect(\"wss://x.example/s\")'")], ["python-net", "url"]),
    ("written emulator script", [("Write", {"file_path": "/r/e.py", "content": EMU})], ["emulator-socket"]),
    ("written prose file with url", [("Write", {"file_path": "/r/notes.md", "content": "see https://example.com"})], ["url"]),
    ("repeated identical calls both count", [B("git pull"), B("git pull")], ["git-remote", "git-remote"]),
    ("web tool", [("WebFetch", {"url": "https://example.com"})], ["net-tool"]),
]
fail = 0
for name, calls, want in cases:
    got = cats(calls)
    ok = got == sorted(want)
    fail += not ok
    print(("PASS" if ok else "FAIL"), name, "" if ok else f"got {got} want {sorted(want)}")
rows, bad = run([B("ls")], raw_lines=["{not json"])
ok = bad == 1; fail += not ok
print(("PASS" if ok else "FAIL"), "malformed line is counted, not ignored")
sys.exit(1 if fail else 0)
