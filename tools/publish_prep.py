#!/usr/bin/env python3
"""Make a publication copy of an already-scrubbed session event stream (scrub.py output).

Usage: python3 publish_prep.py IN.scrubbed.jsonl OUT.public.jsonl
Decisions (Jackson, 20 Oct 2026 22:33 AEDT): drop thinking signatures; remove the
account's installed skill / command / connector / plugin lists (some describe
personal, non-research activity); keep his name and GitHub handle.
- Drops every 'signature' key inside thinking / redacted_thinking blocks.
- Replaces these list fields, wherever they occur, with a short note:
  skills, slash_commands, terminal_slash_commands, commands, mcp_servers, plugins,
  mcpTools, skillFrontmatter (lists or dicts; /context-style usage replies included).
- In 'tools' lists, replaces MCP tool names (mcp__...) with one note entry.
- Replaces connector-sync fields: any 'servers' dict (connector names and upstream URLs
  in control requests) and the 'added' / 'removed' / 'errors' fields of a connector-sync
  reply (a dict holding all three keys). Added 20 Oct 2026 ~22:55 AEDT after a check of
  the first public copies found connector names left in those fields.
Every line stays valid JSON; line count unchanged. Standard library only.
A JSON count report goes to stderr.
"""
import json, sys

LISTS = {"skills", "slash_commands", "terminal_slash_commands", "commands", "mcp_servers", "plugins", "mcpTools", "skillFrontmatter"}
NOTE = "[removed for privacy before publication: {} entries (account-level skills, commands, connectors or plugins)]"


def walk(o, c):
    if isinstance(o, dict):
        if o.get("type") in ("thinking", "redacted_thinking") and "signature" in o:
            del o["signature"]
            c["signatures_dropped"] += 1
        if {"added", "removed", "errors"} <= set(o.keys()):
            for k in ("added", "removed", "errors"):
                v = o[k]
                if isinstance(v, (list, dict)) and len(v):
                    o[k] = NOTE.format(len(v))
                    c["lists_removed"] += 1
                    c["list_entries_removed"] += len(v)
        for k in list(o.keys()):
            v = o[k]
            if k == "servers" and isinstance(v, dict):
                o[k] = NOTE.format(len(v))
                c["lists_removed"] += 1
                c["list_entries_removed"] += len(v)
            elif k in LISTS and isinstance(v, (list, dict)):
                o[k] = NOTE.format(len(v))
                c["lists_removed"] += 1
                c["list_entries_removed"] += len(v)
            elif k == "tools" and isinstance(v, list) and any(isinstance(x, str) and x.startswith("mcp__") for x in v):
                kept = [x for x in v if not (isinstance(x, str) and x.startswith("mcp__"))]
                n = len(v) - len(kept)
                o[k] = kept + [NOTE.format(n).replace("skills, commands, connectors or plugins", "MCP connector tools")]
                c["mcp_tool_names_removed"] += n
            else:
                walk(v, c)
    elif isinstance(o, list):
        for x in o:
            walk(x, c)


def main(src, dst):
    c = {"lines": 0, "signatures_dropped": 0, "lists_removed": 0, "list_entries_removed": 0, "mcp_tool_names_removed": 0}
    with open(src, encoding="utf8") as fi, open(dst, "w", encoding="utf8") as fo:
        for line in fi:
            e = json.loads(line)
            walk(e, c)
            fo.write(json.dumps(e, ensure_ascii=False, separators=(",", ":")) + "\n")
            c["lines"] += 1
    print(json.dumps(c), file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
