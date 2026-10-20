# Scrub report: four Kaizo session event streams

Date: 2026-10-20. Script: `/home/claude/tx/scripts/scrub.py` (standard library only). Inputs were opened read-only and are unchanged. Nothing was uploaded or sent anywhere. No QUARANTINE file was opened.

## Summary

- All four streams were scrubbed line by line. Every output line parses as JSON, and input and output line counts match exactly.
- A structural diff found no changes to keys, types, list lengths or non-string values. `event_id`, `event_type`, `sequence_num`, `created_at` and `source` are identical on every line. Only string values changed.
- The raw inputs held fewer sensitive items than the brief anticipated:
  - **Found:** Claude session ids (three forms), account-scoped connector and plugin-sync UUIDs, and one email address (`noreply@anthropic.com`, in git commit commands).
  - **Not found:** no credentials of any kind, no `/Users/<name>` or other personal home paths (only the container path `/home/user/...` and `/root/...`), and no populated account or user id fields. `sent_by_account_id` is null on every event.
- **Verification:** zero residual matches for every pattern in all four files, from both the script's own check and an independent GNU grep pass. None of the 33–45 sensitive original values per file appear anywhere in the output.
- **High-entropy review list:** empty after classification. Details are in section 5.
- **Not done (needs a human decision):** account configuration (installed skills, connectors, plan), the PI's GitHub handle, and his name. These were outside the brief and are left in place. See section 7.

## 1. Files

The output names leave out the `-session_01…` segment of the input names. Keeping it would have published the session ids through the filenames.

| Run | Output (`/home/claude/tx/scrubbed/`) | Lines in = out | Output bytes | sha256 (prefix) |
|---|---|---:|---:|---|
| B1 | `kaizo-B1-events-20261020.scrubbed.jsonl` | 30,834 | 38,994,321 | `59de72c0f07280bd…` |
| B2 attempt 1 | `kaizo-B2-attempt1-events-20261020.scrubbed.jsonl` | 1,092 | 4,003,224 | `1677755d7fafcf1c…` |
| B2 | `kaizo-B2-events-20261020.scrubbed.jsonl` | 27,292 | 64,239,850 | `b2b83586375b6980…` |
| Ripple K1-1 | `kaizo-Ripple-K1-1-events-20261020.scrubbed.jsonl` | 76,222 | 109,497,287 | `e907efa00387f13c…` |

There were no unparseable or blank input lines.

## 2. Method

**Pre-pass (raw lines).** This pass collects every value of a `*session_id` / `X-Session-UUID` field, every MCP connector id (`X-MCP-Server-ID`, `mcp_server_id=` in URLs, `server_id_stamp`), the UUID pair in `/root/.claude/plugins/synced/<A>_<B>/`, and any `*account*` / `*org*` / `*user_id*` value that looks like an id. Each of these is then replaced wherever it recurs in any string. For example, the session UUID also sits inside every `scratchpad_path`.

**Main pass.** Each event is parsed, walked recursively and re-serialised as compact JSON.

- **Field rules.** Session-id keys become `<SESSION_n>`. Account, org and user keys become `<ACCOUNT_ID_n>`, `<ORG_ID_n>` or `<USER_ID_n>`. Keys named token, secret, password, credential, api_key, authorization or cookie become `<SECRET_n>`. Trivial values such as `none` are kept: `apiKeySource: "none"` was the only hit.
- **Text rules (all strings, including dict keys).**
  - Session ids: `session_01…` becomes `<SESSION_n>`. `cse_01…` becomes `<CSE_SESSION_n>`, with the same `n` as its session twin, because the two share a suffix.
  - Credentials: JWTs, `sk-ant-…`, other `sk-…` keys, GitHub tokens (`ghp_/gho_/ghs_/ghu_/ghr_/github_pat_`), URL `user:password@`, `x-access-token:…@`, Authorization/Cookie/API-key header values, `Bearer …`, key=value secrets, AWS, Google and Slack keys, and PEM private keys.
  - Account, org and user id key=value pairs and `acct_/org_/user_` prefixed ids.
  - Paths: `/Users/<name>` becomes `/Users/<user>`. The same applies to `C:\Users\<name>`, non-generic `/home/<name>`, and the `-Users-<name>-` project-directory form.
  - Email addresses become `<EMAIL_n>`.
- **Stability.** Placeholders are stable within a file: the same input value always gets the same placeholder.
- **Left untouched on purpose:** game text, agent prose, `toolu_` / `msg_` / `req_` ids, event ids and message uuids, control request ids, trace ids, git SHAs and other hashes, `/home/user/...`, base64 images, and thinking signatures.
- **Testing.** Every rule was exercised on synthetic fake values before the real run. Game text such as "Secret Power: 70", code such as `token = self.next()`, `max_tokens: 4096`, `toolu_` ids and SHAs all survived untouched.

## 3. Per-file counts per pattern

Replacements made (occurrences), followed by distinct values in brackets.

| Pattern | B1 | B2 att. 1 | B2 | Ripple |
|---|---:|---:|---:|---:|
| Session ids: `payload.session_id`, `session_01…`, and the session UUID in text → `<SESSION_n>` | 16,481 [12] | 988 [7] | 27,164 [9] | 40,707 [18] |
| … of which `payload.session_id` field values | 16,469 | 983 | 26,522 | 40,636 |
| `cse_01…` remote-session id (X-Session-UUID header, MCP URLs) → `<CSE_SESSION_n>` | 44 | 88 | 66 | 198 |
| MCP connector ids (account-scoped) → `<MCP_SERVER_n>` | 66 [22] | 134 [22] | 101 [22] | 297 [22] |
| `plugins/synced/<A>_<B>` UUID pair (same in all 4 runs; account/org-scoped) → `<ACCOUNT_SCOPED_ID_n>` | 242 [2] | 110 [2] | 396 [2] | 814 [2] |
| Account / org / user ids (`sent_by_account_id` is null throughout) | 0 | 0 | 0 | 0 |
| JWT | 0 | 0 | 0 | 0 |
| Anthropic key `sk-ant-` / other `sk-` | 0 | 0 | 0 | 0 |
| GitHub tokens | 0 | 0 | 0 | 0 |
| URL `user:password@` / `x-access-token` | 0 | 0 | 0 | 0 |
| Authorization / Cookie / Bearer values | 0 | 0 | 0 | 0 |
| Keys or text named token/secret/password/credential/api_key | 0 (11 trivial kept) | 0 (5 trivial kept) | 0 (18 trivial kept) | 0 (37 trivial kept) |
| AWS / Google / Slack keys, PEM private keys | 0 | 0 | 0 | 0 |
| `/Users/<name>`, other home-directory usernames | 0 | 0 | 0 | 0 |
| Email addresses → `<EMAIL_n>` | 0 | 0 | 2 [1] | 2 [1] |

## 4. Verification (on the scrubbed files)

All of the following checks were run on all four files (`python3 scrub.py --verify IN OUT`, plus GNU `grep -o … | wc -l`):

- **Strict scrub patterns** (session, cse, JWT, sk-ant, sk-, GitHub, URL credentials, x-access-token, bearer, AWS/Google/Slack, private key, email, prefixed account ids): **0 matches** in every file.
- **Looser independent patterns:**
  - Patterns with **0 matches** in every file: any `session_01`, `cse_01`, `sk-ant`, GitHub token prefixes, `x-access-token`, `://…@`, the words authorization, bearer and cookie, `/Users/`, a non-generic `/home/`, `x@domain.tld`, and secret key=value pairs.
  - The one exception is any `eyJ` followed by 10 or more characters:
    - Outside base64 fields there are 4 hits (B1: 1, Ripple: 3). All are chance substrings inside kept ids: one at `.payload.request_id` (prefix `req_01…`), and one each at `.payload.message.content[].id`, `.content[].tool_use_id` and `.tool_result_meta[].id` (prefix `toolu_…`, the same tool call). None of them are JWTs: there are no dots.
    - Inside image base64 there are 19 / 1 / 76 / 50 hits. These are expected chance occurrences in about 43 M base64 characters.
- **Independent grep:** 0 for every pattern, including each of the four literal session suffixes from the input filenames. The only `/home/` form left is `/home/user` (44,137 occurrences), the container path kept by design.
- **Literal check:** every sensitive original value the scrubber identified in the raw file (38 / 33 / 36 / 45 values) was searched for in the output. **0 still present.**
- **Placeholder counts** in the output equal the replacement counts in section 3.

## 5. High-entropy strings for human review

**Method.** Every string except image data and thinking signatures was scanned for 32+ character tokens of `[A-Za-z0-9+/=_-]`. Tokens in the deliberately kept classes were set aside:

- UUIDs
- `toolu_` / `msg_` / `req_` ids
- control `request_id`s
- W3C trace ids
- 32/40/64/128-hex hashes
- tokens whose every segment is word-like
- camelCase identifiers and epoch-numbered file names

A token was listed for review only if one of its segments is 16+ characters long and random-looking (entropy ≥ 3.5 bits, frequent character-class switches, a digit present), or if it is non-hash hex. A synthetic check confirmed that random base64, URL-safe base64 and 48-hex strings are flagged, while camelCase ids, screenshot paths, control ids and SHA-1s are not.

**Result: 0 items in the review list in all four files.** No count/path/prefix rows to report.

The kept tokens, for transparency:

| Kept class | B1 | B2 att. 1 | B2 | Ripple |
|---|---:|---:|---:|---:|
| UUIDs (event ids, message uuids, etc.) | 61,803 | 2,233 | 54,761 | 152,968 |
| Control request ids (`list_directory-<ms>-xxxxxx` etc.) | 14,060 | 28 | 574 | 34,445 |
| Path / word identifiers | 38,489 | 4,348 | 44,452 | 98,814 |
| Low-entropy identifiers (screenshot paths `/root/pokemon_bridge/shots/s<epoch>`, `mcp__Server__tool` names, a C++ `GBAVideoSoftware…` identifier) | 1,660 | 272 | 6,488 | 6,883 |
| 40-hex git SHAs (in git output and agent text) | 4 | 10 | 14 | 5 |
| Trace ids (`payload.trace_context`) | 11 | 5 | 18 | 45 |
| Prefixed ids | 6 | 3 | 6 | 48 |

## 6. Thinking signatures and images

**Thinking `signature` fields** (`payload.message.content[].signature` on `type: thinking` blocks):

| | B1 | B2 att. 1 | B2 | Ripple | Total |
|---|---:|---:|---:|---:|---:|
| Count | 1,096 | 113 | 2,306 | 2,815 | **6,330** |
| Characters | 1,488,116 | 135,440 | 3,405,484 | 4,083,944 | **9,112,984 (~9.1 MB, 4.2% of output)** |
| Thinking blocks with empty plaintext | 1,067 | 103 | 2,281 | 2,738 | 6,189 (97.8%) |

These are encrypted model-reasoning blobs, not credentials, so they were kept in this pass.

**Recommendation: drop them from the published copy, and keep the originals in the private archive.**

- They cannot be read or checked by readers, the PI or reviewers, so they add nothing to the research record.
- Publishing them would distribute content nobody on the project has seen.
- They make up about 9 MB.
- Because `thinking_display` was `"updates"`, 97.8% of thinking blocks have no plaintext anyway. Dropping the signatures therefore loses nothing readable.

To produce that copy, run `python3 scrub.py IN OUT --drop-signatures`. This replaces each value with `<THINKING_SIGNATURE_REMOVED>` and leaves the structure intact.

**Base64 images** (kept as is):

| | B1 | B2 att. 1 | B2 | Ripple | Total |
|---|---:|---:|---:|---:|---:|
| Images (`message.content[].content[].source.data`) | 394 | 53 | 1,261 | 1,495 | **3,203** |
| Base64 characters | 4,519,084 | 563,232 | 24,453,900 | 13,278,172 | **42,814,388** |
| Approx. decoded size | 3.4 MB | 0.4 MB | 18.3 MB | 10.0 MB | **~32.1 MB** |

- All 3,203 images are PNGs returned by `Read` on emulator screenshots (`/root/pokemon_bridge/shots/s<epoch>.png`). B2 also has 153 scratchpad crops.
- Every image field contains only base64 characters.
- The parallel `tool_use_result.file.base64` fields (3,203) are present but empty.

## 7. Not scrubbed: needs a human decision before publication

These items are outside the requested categories, so they were left in place.

1. **Account configuration**, repeated in every init and control response:
   - Paths: `payload.skills[]`, `payload.slash_commands[]`, `payload.commands[].description`, `payload.response.response.commands[].description`, `…skills.skillFrontmatter[]`, `payload.mcp_servers[]`, `payload.tools[]`, `payload.plugins[]`, and `payload.request.servers.*` (connector names and upstream URLs).
   - These reveal the account's installed plugins and skills, and its connected services. [Public copy: the list of services is removed here.]
   - Some skill descriptions name the PI and describe personal, non-research activity. [Public copy: example removed.]
   - `response.account.subscriptionType` (`Claude Max` / `Claude API`) shows the plan.
   - **Suggestion:** strip or truncate these lists in the published copy. They carry no information about play.
   - **Done (20 Oct 2026):** `tools/publish_prep.py` replaces all of these lists, the connector `servers` maps and the connector-sync replies with a count note in the public transcripts. Thinking-block signatures were also dropped.
2. **The PI's GitHub handle and repo:** `JacksonDutton` / `jacksondutton` appears 0 / 29 / 46 / 19 times (B1 / B2 att. 1 / B2 / Ripple), including 38 URLs to `github.com/JacksonDutton/kaizo-baseline`, in git output, add_repo results and agent prose.
3. **The PI's name** appears in prompts and agent prose: "Jackson Dutton" 3 / 2 / 5 / 5 times, and "Jackson" throughout. This was kept because the brief says not to scrub prose.
4. **Kept identifiers that are not secrets:** event ids and message uuids, `toolu_` / `msg_` / `req_` ids, 4 `tool_use_result.attachments[].file_uuid` values (claude.ai file ids), and trace ids. The `noreply@anthropic.com` address in `Co-Authored-By` trailers was replaced (`<EMAIL_1>`), as instructed.

## 8. Re-running

```
python3 /home/claude/tx/scripts/scrub.py IN.jsonl OUT.jsonl [--drop-signatures]   # counts → stderr (JSON)
python3 /home/claude/tx/scripts/scrub.py --verify IN.jsonl OUT.jsonl             # residuals + review list → stdout (JSON)
```
Each run took between 2 s (4 MB file) and 38 s (110 MB file).
