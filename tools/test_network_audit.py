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
    ("ruby socket to the emulator", [B("ruby -e 's=TCPSocket.new(\"127.0.0.1\", 8888)'")], ["emulator-socket"]),
    ("ruby socket elsewhere", [B("ruby -rsocket -e 'TCPSocket.new(\"example.com\", 80)'")], ["other-net"]),
    ("ruby Net::HTTP", [B("ruby -rnet/http -e 'Net::HTTP.get(URI(h))'")], ["other-net"]),
    ("node fetch", [B("node -e 'fetch(u).then(r=>r.text())'")], ["other-net"]),
    ("node net.connect to emulator", [B("node -e 'require(\"net\").connect(8888, \"127.0.0.1\")'")], ["emulator-socket"]),
    ("perl LWP", [B("perl -MLWP::Simple -e 'get($u)'")], ["other-net"]),
    ("bash /dev/tcp to emulator", [B("exec 3<>/dev/tcp/127.0.0.1/8888; echo S >&3")], ["emulator-socket"]),
    ("bash /dev/tcp elsewhere", [B("exec 3<>/dev/tcp/example.com/80")], ["other-net"]),
    ("socat and openssl", [B("socat - TCP:example.com:80"), B("openssl s_client -connect example.com:443")], ["client", "client"]),
    ("ordinary play command", [B("cd ~/pokemon_bridge && ./g walk up 2; ./g s")], []),
    ("saved socket script re-run later", [B("cat > events.py <<'EOF'\n" + EMU + "EOF\npython3 -I events.py"), B("./g s"), B("cd /tmp/x && timeout 110 python3 -I events.py 2>&1 | head")], ["emulator-socket"] * 2),
    ("re-run via nohup and ./", [("Write", {"file_path": "/s/conn2.py", "content": EMU}), B("(nohup python3 -I conn2.py g.json > o 2>&1 &)"), B("./conn2.py")], ["emulator-socket"] * 3),
    ("editing or reading a saved script is not a run", [B("cat > e.py <<'EOF'\n" + EMU + "EOF"), B("sed -i 's/a/b/' e.py; cat e.py; cat >> e.py <<'EOF'\nprint(1)\nEOF")], ["emulator-socket"]),
    ("overwritten without the socket, then run", [B("cat > e.py <<'EOF'\n" + EMU + "EOF"), B("cat > e.py <<'EOF'\nprint(1)\nEOF"), B("python3 e.py")], ["emulator-socket"]),
    ("redirection after the heredoc delimiter", [B("cat <<'EOF' > s/ev.py\n" + EMU + "EOF"), B("python3 \"s/ev.py\"")], ["emulator-socket"] * 2),
    ("an earlier command's redirection is not this heredoc's target", [B("echo x > a.py; cat <<'EOF' > b.py\n" + EMU + "EOF"), B("python3 a.py"), B("python3 b.py")], ["emulator-socket"] * 2),
    ("source, absolute path and interpreter option with a value", [B("cat > n.sh <<'EOF'\nexec 3<>/dev/tcp/127.0.0.1/8888\nEOF"), B("source n.sh"), B("/tmp/w/n.sh"), B("cd w && python3 -W ignore n.sh")], ["emulator-socket"] * 4),
    ("written shell script uses the shell patterns", [("Write", {"file_path": "/s/get.sh", "content": "curl -s example.com/x"}), B("bash get.sh")], ["client", "client"]),
    ("safe overwrite then run in one command", [B("cat > e.py <<'EOF'\n" + EMU + "EOF"), B("cat > e.py <<'EOF'\nprint(1)\nEOF\npython3 e.py")], ["emulator-socket"]),
    ("run from inside a shell heredoc", [B("cat > e.py <<'EOF'\n" + EMU + "EOF"), B("bash <<'EOF'\ncd /tmp && python3 e.py\nEOF")], ["emulator-socket"] * 2),
    ("copy made by python open().write keeps the socket (K2 conn2.py)", [B("cat > conn.py <<'EOF'\n" + EMU + "EOF\npython3 -I conn.py"), B("python3 - <<'EOF'\ns=open('conn.py').read()\nopen('conn2.py','w').write(s)\nEOF\nnohup python3 -I conn2.py g.json > o 2>&1 &"), B("python3 -I conn2.py vr1.json")], ["emulator-socket"] * 3),
    ("cp copy keeps the socket", [B("cat > a.py <<'EOF'\n" + EMU + "EOF"), B("cp a.py b.py"), B("python3 b.py")], ["emulator-socket"] * 2),
    ("sed redirect copy keeps the socket", [B("cat > a.py <<'EOF'\n" + EMU + "EOF"), B("sed 's/x/y/' a.py > c.py"), B("python3 c.py")], ["emulator-socket"] * 2),
    ("install with a mode value, and a copy into a directory", [B("cat > a.py <<'EOF'\n" + EMU + "EOF"), B("install -m 755 a.py i.py; cp a.py bin/"), B("python3 i.py"), B("python3 bin/a.py")], ["emulator-socket"] * 3),
    ("python open with mode= keyword", [B("cat > a.py <<'EOF'\n" + EMU + "EOF"), B("python3 - <<'EOF'\nopen('k.py', mode='w').write(open('a.py').read())\nEOF"), B("python3 k.py")], ["emulator-socket"] * 2),
    ("mv moves the tracking to the new name", [B("cat > a.py <<'EOF'\n" + EMU + "EOF"), B("mv a.py m.py"), B("python3 m.py"), B("python3 a.py")], ["emulator-socket"] * 2),
    ("a saved script that would write a copy is not run yet", [B("cat > a.py <<'EOF'\n" + EMU + "EOF"), B("cat > w.py <<'EOF'\nopen('z.py','w').write(open('a.py').read())\nEOF"), B("python3 z.py")], ["emulator-socket"]),
    ("a new script that names no saved script is not tainted", [B("cat > a.py <<'EOF'\n" + EMU + "EOF"), B("echo 'print(1)' > d.py"), B("python3 d.py")], ["emulator-socket"]),
    ("a script that reads a json is not a run of another", [B("cat > conn2.py <<'EOF'\n" + EMU + "EOF"), B("python3 -I vrelev.py vr1.json; python3 conn2.pyc")], ["emulator-socket"]),
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
rows, _ = run([B("cat > ev.py <<'EOF'\n" + EMU + "EOF"), B("python3 ev.py")])
ok = all(r[5].startswith("re-runs ev.py: ") for r in run([B("cat > ev.py <<'EOF'\n" + EMU + "EOF"), B("python3 - <<'EOF'\n" + EMU + "EOF\npython3 ev.py")])[0][1:])
fail += not ok
print(("PASS" if ok else "FAIL"), "re-run label kept when the same category is also found directly")
err = json.dumps({"event_type": "user", "created_at": "t", "payload": {"message": {"content": [{"type": "tool_result", "tool_use_id": "c1", "is_error": True}]}}})
rows2, _ = run([("Write", {"file_path": "/s/e.py", "content": EMU}), ("Write", {"file_path": "/s/e.py", "content": "print(1)"}), B("python3 e.py")], raw_lines=[err])
ok = [r[4] for r in rows2] == ["emulator-socket", "emulator-socket"]; fail += not ok
print(("PASS" if ok else "FAIL"), "a failed overwrite does not clear a saved socket script", "" if ok else rows2)
ok = rows[-1][5].startswith("re-runs ev.py: "); fail += not ok
print(("PASS" if ok else "FAIL"), "re-run rows name the script", "" if ok else rows[-1][5])
sys.exit(1 if fail else 0)
