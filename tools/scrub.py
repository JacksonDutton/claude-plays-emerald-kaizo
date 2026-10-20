#!/usr/bin/env python3
"""Scrub identifiers and credentials from an archived Claude Code session event stream (JSONL).

Usage:
    python3 scrub.py IN.jsonl OUT.jsonl [--drop-signatures]
        Writes a scrubbed copy line by line (every line is parsed, string values are scrubbed
        recursively, and the event is re-serialised as compact JSON). A JSON count report goes
        to stderr. Standard library only. The input is never modified.

    python3 scrub.py --verify IN.jsonl OUT.jsonl
        Re-scans OUT for residual matches (strict scrub patterns, looser independent patterns,
        and a literal search for every sensitive value found in IN), and lists remaining
        high-entropy strings for human review (12-character prefix only). JSON to stdout.

What is replaced (stable placeholders per file: the same input value gets the same placeholder):
    session ids          session_01..., cse_01... (same suffix -> same number), payload.session_id
                         and other *session_id / X-Session-UUID values, and those UUIDs wherever
                         they recur in text (e.g. scratchpad paths)          -> <SESSION_n>, <CSE_SESSION_n>
    account-scoped ids   sent_by_account_id and any *account* / *org* / *user_id* key or
                         key=value in text whose value looks like an id      -> <ACCOUNT_ID_n>, <ORG_ID_n>, <USER_ID_n>
                         MCP connector ids (X-MCP-Server-ID, mcp_server_id=, server_id_stamp)
                                                                             -> <MCP_SERVER_n>
                         the UUID pair in /plugins/synced/<A>_<B>/ paths      -> <ACCOUNT_SCOPED_ID_n>
    credentials          JWTs, sk-ant- keys, other sk- keys, GitHub tokens, URL user:password@,
                         x-access-token, Authorization/Cookie/API-key header values, Bearer tokens,
                         values of keys named token/secret/password/credential/api_key (JSON keys
                         and key=value text), AWS/Google/Slack keys, PEM private keys
    personal paths       /Users/<name>/ -> /Users/<user>/, C:\\Users\\<name>, non-generic /home/<name>,
                         and the -Users-<name>- form Claude Code uses for project dirs
    email addresses      all                                                 -> <EMAIL_n>

Deliberately kept: game text and agent prose, tool_use ids, message/request ids, event ids and
uuids, file hashes, trace ids, the container path /home/user/..., base64 images (counted), and
thinking signatures (counted; dropped only with --drop-signatures).
"""
import collections
import json
import math
import os
import re
import sys

UUID = r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
UUID_RX = re.compile(UUID)

# --- key-name rules -------------------------------------------------------------------------
SESSION_KEY_RX = re.compile(r'(?i)^(x-)?(\w+_)?session[_-]?(id|uuid)$')
ACCOUNT_KEY_RX = re.compile(r'(?i)(account|(^|[_-])org(anization|anisation)?([_-]?(id|uuid)|$)|user[_-]?(id|uuid)$)')
SECRET_KEY_RX = re.compile(
    r'(?i)(secret|passw(or)?d|passwd|credential|api[_-]?key|access[_-]?key|private[_-]?key|'
    r'authorization|cookie|bearer|token(?![a-z]))')
TRIVIAL_VALUES = {'', 'none', 'null', 'undefined', 'true', 'false', 'n/a', 'redacted', 'required',
                  'optional', 'string', 'example', '***', 'xxx'}
ID_LIKE_RX = re.compile(r'[A-Za-z0-9_:.\-]{6,}')
GENERIC_HOME_USERS = {'user', 'claude', 'root', 'runner', 'ubuntu', 'node', 'app', '<user>'}

# --- text rules -----------------------------------------------------------------------------
SESSION_RX = re.compile(r'session_(01[A-Za-z0-9]{20,})')
CSE_RX = re.compile(r'(?<![A-Za-z0-9])cse_(01[A-Za-z0-9]{20,})')
JWT_RX = re.compile(r'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]*')
SK_ANT_RX = re.compile(r'sk-ant-[A-Za-z0-9_-]{8,}')
SK_OTHER_RX = re.compile(r'(?<![A-Za-z0-9])sk-(?!ant-)[A-Za-z0-9_-]{20,}')
GITHUB_RX = re.compile(r'(?<![A-Za-z0-9])(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})')
URL_CRED_RX = re.compile(r'([A-Za-z][A-Za-z0-9+.-]*://)([^/\s:@"\'<>]+):([^/\s@"\'<>]+)@')
X_ACCESS_RX = re.compile(r'(?i)(x-access-token:)([^@\s"\'<>]+)@')
AUTH_HDR_RX = re.compile(
    r'(?i)\b((?:proxy-)?authorization|set-cookie|cookie|x-api-key|api-key|x-auth-token)'
    r'(\\*["\']?\s*[:=]\s*\\*["\']?)([^\r\n"\'\\<]+)')
BEARER_RX = re.compile(r'(?i)\b(bearer\s+)([A-Za-z0-9._~+/=-]{8,})')
KV_SECRET_RX = re.compile(
    r'(?i)(?P<k>[A-Za-z0-9_.-]*?(?:secret|passw(?:or)?d|passwd|credential|api[_-]?key|access[_-]?key|'
    r'private[_-]?key|token)(?![a-z])[A-Za-z0-9_]*)(?P<sep>\\*["\']?\s*[:=]\s*\\*["\']?)'
    r'(?P<v>[A-Za-z0-9_\-./+=:~]{8,})')
AWS_RX = re.compile(r'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b')
GAPI_RX = re.compile(r'\bAIza[0-9A-Za-z_-]{35}')
SLACK_RX = re.compile(r'\bxox[abprs]-[A-Za-z0-9-]{10,}')
PEM_RX = re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----.*?(-----END [A-Z ]*PRIVATE KEY-----|$)', re.S)
ACCT_KV_RX = re.compile(
    r'(?i)(?P<k>[A-Za-z_]*?(?P<kind>account|organi[sz]ation|org|user)[_-]?(?:id|uuid))'
    r'(?P<sep>\\*["\']?\s*[:=]\s*\\*["\']?)(?P<v>[A-Za-z0-9_-]{6,})')
ACCT_PREFIX_RX = re.compile(r'(?<![A-Za-z0-9])(acct|org|user)_([A-Za-z0-9]{12,})')
USERS_PATH_RX = re.compile(r'/Users/([^/\s"\'\\<>]+)')
WIN_PATH_RX = re.compile(r'([A-Za-z]:(?:\\{1,2})Users(?:\\{1,2}))([^\\\s"\'<>]+)')
HOME_PATH_RX = re.compile(r'/home/([^/\s"\'\\<>]+)')
DASH_USERS_RX = re.compile(r'-Users-([A-Za-z0-9._]+?)-')
EMAIL_RX = re.compile(r'(?<![A-Za-z0-9._%+-])[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}(?![A-Za-z0-9-])')

# pre-pass (raw line) collectors; tolerate JSON-escaped quotes inside nested strings
P1_SESSION_RX = re.compile(r'\\*"((?:x-)?(?:\w+_)?session[_-]?(?:id|uuid))\\*"\s*:\s*\\*"([^"\\]+)', re.I)
P1_MCP_RX = re.compile(r'(?:X-MCP-Server-ID|server_id_stamp|mcp_server_id)\\*"?\s*[:=]\s*\\*"?(' + UUID + ')', re.I)
P1_SYNC_RX = re.compile(r'plugins/synced/(' + UUID + ')_(' + UUID + ')')
P1_ACCT_RX = re.compile(
    r'\\*"([A-Za-z_]*(?:account|org|organi[sz]ation|user)[_-]?(?:id|uuid)[A-Za-z_]*)\\*"\s*:\s*\\*"([^"\\]{6,})', re.I)


def is_placeholder(v):
    return v.startswith('<') and v.endswith('>')


class Scrubber:
    def __init__(self, drop_signatures=False):
        self.drop_signatures = drop_signatures
        self.maps = collections.defaultdict(dict)
        self.counts = collections.Counter()
        self.known_uuid = {}          # uuid -> (category, label)
        self.known_literal = {}       # non-uuid literal id -> (category, label)
        self.known_literal_rx = None
        self.usernames = set()
        self.images = collections.Counter()
        self.sig = collections.Counter()
        self.key_hits = collections.Counter()
        self.sensitive_originals = set()   # every original value replaced (for --verify literal check)

    # placeholder for (category, key); label defaults to category
    def ph(self, cat, key, label=None):
        m = self.maps[cat]
        if key not in m:
            m[key] = len(m) + 1
        return '<%s_%d>' % (label or cat, m[key])

    def hit(self, cat, original, label=None, key=None):
        self.counts[label or cat] += 1
        self.sensitive_originals.add(original)
        return self.ph(cat, original if key is None else key, label)

    # ---- pre-pass ---------------------------------------------------------------------------
    def prepass(self, path):
        with open(path, encoding='utf-8') as f:
            for line in f:
                for m in P1_SESSION_RX.finditer(line):
                    v = m.group(2)
                    if UUID_RX.fullmatch(v):
                        self.known_uuid.setdefault(v, ('SESSION', 'SESSION'))
                for m in P1_MCP_RX.finditer(line):
                    self.known_uuid.setdefault(m.group(1), ('MCP_SERVER', 'MCP_SERVER'))
                for m in P1_SYNC_RX.finditer(line):
                    for g in (1, 2):
                        self.known_uuid.setdefault(m.group(g), ('ACCOUNT_SCOPED_ID', 'ACCOUNT_SCOPED_ID'))
                for m in P1_ACCT_RX.finditer(line):
                    k, v = m.group(1), m.group(2)
                    if ID_LIKE_RX.fullmatch(v) and re.search(r'\d', v) and not is_placeholder(v):
                        cat = self.acct_cat(k)
                        if UUID_RX.fullmatch(v):
                            self.known_uuid.setdefault(v, (cat, cat))
                        else:
                            self.known_literal.setdefault(v, (cat, cat))
                if '/Users/' in line:
                    for m in USERS_PATH_RX.finditer(line):
                        if m.group(1) not in ('Shared', '<user>'):
                            self.usernames.add(m.group(1))
                if '/home/' in line:
                    for m in HOME_PATH_RX.finditer(line):
                        if m.group(1) not in GENERIC_HOME_USERS:
                            self.usernames.add(m.group(1))
        if self.known_literal:
            alts = sorted(self.known_literal, key=len, reverse=True)
            self.known_literal_rx = re.compile('|'.join(re.escape(a) for a in alts))
        self.username_rx = None
        names = [u for u in self.usernames if len(u) >= 3]
        if names:
            alt = '|'.join(re.escape(u) for u in sorted(names, key=len, reverse=True))
            self.username_rx = re.compile(r'(~|(?<![A-Za-z0-9._-]))(' + alt + r')(?=@|:|\$| ?%|/)')

    @staticmethod
    def acct_cat(key):
        k = key.lower()
        if 'account' in k:
            return 'ACCOUNT_ID'
        if 'org' in k:
            return 'ORG_ID'
        return 'USER_ID'

    # ---- text scrubbing -----------------------------------------------------------------------
    def scrub_text(self, s):
        if not s or len(s) < 6:
            return s
        low = s.lower()
        if '-' in s and self.known_uuid:
            s = UUID_RX.sub(self._known_uuid_sub, s)
        if self.known_literal_rx is not None:
            s = self.known_literal_rx.sub(
                lambda m: self.hit(self.known_literal[m.group(0)][0], m.group(0)), s)
        if '_01' in s:
            if 'session_01' in s:
                s = SESSION_RX.sub(lambda m: self.hit('SESSION', m.group(0), key='SFX:' + m.group(1)), s)
            if 'cse_01' in s:
                s = CSE_RX.sub(lambda m: self.hit('SESSION', m.group(0), label='CSE_SESSION', key='SFX:' + m.group(1)), s)
        if 'eyj' in low:
            s = JWT_RX.sub(lambda m: self.hit('JWT', m.group(0)), s)
        if 'sk-' in s:
            s = SK_ANT_RX.sub(lambda m: self.hit('ANTHROPIC_KEY', m.group(0)), s)
            s = SK_OTHER_RX.sub(lambda m: self.hit('API_KEY', m.group(0)), s)
        if 'gh' in s or 'github_pat_' in s:
            s = GITHUB_RX.sub(lambda m: self.hit('GITHUB_TOKEN', m.group(0)), s)
        if '@' in s:
            if '://' in s:
                s = URL_CRED_RX.sub(lambda m: m.group(1) + self.hit(
                    'URL_CREDENTIALS', m.group(2) + ':' + m.group(3)) + '@', s)
            if 'x-access-token' in low:
                s = X_ACCESS_RX.sub(lambda m: m.group(1) + self.hit('SECRET', m.group(2)) + '@', s)
        if 'authorization' in low or 'cookie' in low or 'api-key' in low or 'auth-token' in low:
            s = AUTH_HDR_RX.sub(self._auth_sub, s)
        if 'bearer' in low:
            s = BEARER_RX.sub(lambda m: m.group(1) + self.hit('BEARER', m.group(2)), s)
        if ('token' in low or 'secret' in low or 'passw' in low or 'credential' in low or 'key' in low):
            s = KV_SECRET_RX.sub(self._kv_sub, s)
        if 'AKIA' in s or 'ASIA' in s:
            s = AWS_RX.sub(lambda m: self.hit('SECRET', m.group(0)), s)
        if 'AIza' in s:
            s = GAPI_RX.sub(lambda m: self.hit('SECRET', m.group(0)), s)
        if 'xox' in s:
            s = SLACK_RX.sub(lambda m: self.hit('SECRET', m.group(0)), s)
        if 'PRIVATE KEY' in s:
            s = PEM_RX.sub(lambda m: self.hit('PRIVATE_KEY', m.group(0)), s)
        if 'account' in low or 'org' in low or 'user' in low or 'acct_' in low:
            s = ACCT_KV_RX.sub(self._acct_kv_sub, s)
            s = ACCT_PREFIX_RX.sub(self._acct_prefix_sub, s)
        if 'Users' in s:
            s = USERS_PATH_RX.sub(self._users_sub, s)
            s = WIN_PATH_RX.sub(lambda m: m.group(1) + self._user_hit(m.group(2)), s)
            s = DASH_USERS_RX.sub(lambda m: '-Users-' + self._user_hit(m.group(1)) + '-', s)
        if '/home/' in s:
            s = HOME_PATH_RX.sub(self._home_sub, s)
        if self.username_rx is not None:
            s = self.username_rx.sub(lambda m: m.group(1) + self._user_hit(m.group(2)), s)
        if '@' in s:
            s = EMAIL_RX.sub(lambda m: self.hit('EMAIL', m.group(0)), s)
        return s

    def _known_uuid_sub(self, m):
        v = m.group(0)
        info = self.known_uuid.get(v)
        if info is None:
            return v
        return self.hit(info[0], v, label=info[1])

    def _auth_sub(self, m):
        v = m.group(3).strip()
        if not v or is_placeholder(v) or v.lower() in TRIVIAL_VALUES:
            return m.group(0)
        return m.group(1) + m.group(2) + self.hit('AUTH_HEADER', v)

    def _kv_sub(self, m):
        v = m.group('v')
        # skip numbers, placeholder words and code-like values (e.g. token = self.next); real
        # secrets almost always contain a digit or are long
        if v.isdigit() or v.lower() in TRIVIAL_VALUES or (len(v) < 20 and not re.search(r'\d', v)):
            return m.group(0)
        return m.group('k') + m.group('sep') + self.hit('SECRET', v)

    def _acct_kv_sub(self, m):
        v = m.group('v')
        if not re.search(r'\d', v):
            return m.group(0)
        return m.group('k') + m.group('sep') + self.hit(self.acct_cat(m.group('kind')), v)

    def _acct_prefix_sub(self, m):
        if not re.search(r'\d', m.group(2)):
            return m.group(0)
        return self.hit(self.acct_cat(m.group(1).replace('acct', 'account')), m.group(0))

    def _user_hit(self, name):
        if name in ('<user>', 'Shared'):
            return name
        self.counts['USER_PATH'] += 1
        self.sensitive_originals.add(name)
        return '<user>'

    def _users_sub(self, m):
        return '/Users/' + self._user_hit(m.group(1))

    def _home_sub(self, m):
        if m.group(1) in GENERIC_HOME_USERS:
            return m.group(0)
        return '/home/' + self._user_hit(m.group(1))

    # ---- structural walk ----------------------------------------------------------------------
    def walk(self, o):
        if isinstance(o, dict):
            out = {}
            otype = o.get('type')
            for k, v in o.items():
                nk = self.scrub_text(k) if isinstance(k, str) and len(k) >= 6 else k
                if isinstance(v, str):
                    if k == 'signature' and otype in ('thinking', 'redacted_thinking'):
                        self.sig['count'] += 1
                        self.sig['chars'] += len(v)
                        out[nk] = '<THINKING_SIGNATURE_REMOVED>' if self.drop_signatures else v
                        continue
                    if k == 'data' and otype == 'base64':
                        self.images['message_content_base64_count'] += 1
                        self.images['message_content_base64_chars'] += len(v)
                        out[nk] = v
                        continue
                    if k == 'base64':
                        if v:
                            self.images['tool_use_result_base64_count'] += 1
                            self.images['tool_use_result_base64_chars'] += len(v)
                        else:
                            self.images['tool_use_result_base64_empty_fields'] += 1
                        out[nk] = v
                        continue
                    if k == 'data' and otype == 'redacted_thinking':
                        self.sig['redacted_thinking_count'] += 1
                        self.sig['redacted_thinking_chars'] += len(v)
                        out[nk] = v
                        continue
                    out[nk] = self.scrub_field(k, v)
                else:
                    out[nk] = self.walk(v)
            return out
        if isinstance(o, list):
            return [self.walk(x) for x in o]
        if isinstance(o, str):
            return self.scrub_text(o)
        return o

    def scrub_field(self, k, v):
        if v and not is_placeholder(v):
            if SESSION_KEY_RX.match(k):
                self.key_hits['session-key:' + k] += 1
                if SESSION_RX.fullmatch(v) or CSE_RX.fullmatch(v):
                    return self.scrub_text(v)
                return self.hit('SESSION', v)
            if ACCOUNT_KEY_RX.search(k) and ID_LIKE_RX.fullmatch(v) and re.search(r'\d', v):
                self.key_hits['account-key:' + k] += 1
                return self.hit(self.acct_cat(k), v)
            if SECRET_KEY_RX.search(k):
                if v.strip().lower() in TRIVIAL_VALUES:
                    self.key_hits['secret-key-kept-trivial:' + k] += 1
                else:
                    self.key_hits['secret-key:' + k] += 1
                    return self.hit('SECRET', v)
        return self.scrub_text(v)

    def report(self):
        img_n = self.images['message_content_base64_count'] + self.images['tool_use_result_base64_count']
        img_c = self.images['message_content_base64_chars'] + self.images['tool_use_result_base64_chars']
        return {
            'replacements': dict(sorted(self.counts.items())),
            'unique_values': {c: len(m) for c, m in sorted(self.maps.items())},
            'key_name_rules': dict(sorted(self.key_hits.items())),
            'prepass_known_ids': dict(collections.Counter(c for c, _ in self.known_uuid.values())),
            'home_usernames_found': len(self.usernames),
            'images': dict(self.images, total_count=img_n, total_base64_chars=img_c,
                           approx_decoded_bytes=img_c * 3 // 4),
            'thinking_signatures': dict(self.sig, dropped=self.drop_signatures),
        }


def scrub_file(inp, outp, drop_signatures=False):
    sc = Scrubber(drop_signatures)
    sc.prepass(inp)
    stats = collections.Counter()
    tmp = outp + '.partial'
    with open(inp, encoding='utf-8') as fi, open(tmp, 'w', encoding='utf-8') as fo:
        for line in fi:
            stats['lines_in'] += 1
            if not line.strip():
                stats['blank_lines_skipped'] += 1
                continue
            try:
                obj = json.loads(line)
            except ValueError:
                stats['unparseable_lines'] += 1
                obj = {'_scrub_unparseable_line': sc.scrub_text(line.rstrip('\n'))}
            obj = sc.walk(obj)
            fo.write(json.dumps(obj, ensure_ascii=line.isascii(), separators=(',', ':')) + '\n')
            stats['lines_out'] += 1
    os.replace(tmp, outp)
    rep = {'input': os.path.basename(inp), 'output': os.path.basename(outp)}
    rep.update(stats)
    rep.update(sc.report())
    return rep, sc


# ---- verification ---------------------------------------------------------------------------
STRICT = {
    'session_id': SESSION_RX, 'cse_session': CSE_RX, 'jwt': JWT_RX, 'sk_ant': SK_ANT_RX,
    'sk_other': SK_OTHER_RX, 'github_token': GITHUB_RX, 'url_credentials': URL_CRED_RX,
    'x_access_token': X_ACCESS_RX, 'bearer': BEARER_RX, 'aws': AWS_RX, 'google_api': GAPI_RX,
    'slack': SLACK_RX, 'private_key': re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    'email': EMAIL_RX, 'acct_prefix': ACCT_PREFIX_RX,
}
LOOSE = {
    'session_01_any': re.compile(r'session_01'),
    'cse_01_any': re.compile(r'cse_01'),
    'eyJ_any': re.compile(r'eyJ[A-Za-z0-9_-]{10,}'),
    'sk-ant_any': re.compile(r'sk-ant'),
    'gh_token_prefix_any': re.compile(r'(gh[pousr]_|github_pat_)[A-Za-z0-9]'),
    'x-access-token_any': re.compile(r'(?i)x-access-token'),
    'userinfo_url_any': re.compile(r'://[^/\s"]*@'),
    'authorization_word': re.compile(r'(?i)authorization'),
    'bearer_word': re.compile(r'(?i)\bbearer\b'),
    'cookie_word': re.compile(r'(?i)cookie'),
    '/Users/_any': re.compile(r'/Users/(?!<user>)'),
    '/home/_non_generic': re.compile(r'/home/(?!(?:user|claude|root|<user>)\b)[^/\s"\\]'),
    'at_sign_domain_any': re.compile(r'[A-Za-z0-9._%+-]@[A-Za-z0-9-]+\.[A-Za-z]{2,}'),
    'secret_kv_any': re.compile(r'(?i)(secret|passw(or)?d|credential|api[_-]?key|access[_-]?token|auth[_-]?token)\\*["\']?\s*[:=]\s*\\*["\']?[A-Za-z0-9_\-./+=]{8,}'),
}
HE_TOKEN_RX = re.compile(r'[A-Za-z0-9+/=_-]{32,}')
HEX_RX = re.compile(r'[0-9a-fA-F]+')
KEPT_ID_RX = re.compile(r'(toolu|srvtoolu|msg|req|file|run|task)_[A-Za-z0-9]{16,}')
WORDLIKE_RX = re.compile(r'[A-Z]?[a-z]+\d{0,4}|[A-Z]+\d{0,4}|\d+|[a-z]+[A-Z][a-z]+')


def entropy(t):
    n = len(t)
    return -sum(c / n * math.log2(c / n) for c in collections.Counter(t).values())


def class_switch_ratio(seg):
    cls = ['l' if c.islower() else 'u' if c.isupper() else 'd' if c.isdigit() else 'o' for c in seg]
    return sum(1 for a, b in zip(cls, cls[1:]) if a != b) / max(1, len(seg) - 1)


def classify_token(t, path):
    """Return (kind, review) for a 32+ char token."""
    if UUID_RX.fullmatch(t.lower()) or re.fullmatch(r'(' + UUID + r')([_-]' + UUID + r')*', t):
        return 'uuid (kept id)', False
    if KEPT_ID_RX.fullmatch(t) or KEPT_ID_RX.match(t):
        return 'prefixed id (kept)', False
    if path.endswith(('request_id', 'requestId')):
        return 'control request id (kept)', False
    if path.endswith(('trace_context', 'traceparent')) or re.fullmatch(r'00-[0-9a-f]{32}-[0-9a-f]{16}-0[0-9a-f]', t):
        return 'trace id (kept)', False
    if HEX_RX.fullmatch(t):
        if len(t) in (32, 40, 64, 128):
            return 'hex %d (hash, kept)' % len(t), False
        if entropy(t) < 3.0:
            return 'low-entropy hex/game data', False
        return 'hex other', True
    if t.startswith(('iVBORw0KGgo', '/9j/', 'R0lGOD', 'UklGR')):
        return 'embedded image base64 (kept)', False
    segs = [x for x in re.split(r'[/_.=+-]', t) if x]
    if segs and all(WORDLIKE_RX.fullmatch(x) for x in segs):
        return 'path/identifier words', False
    # random-looking: some 16+ char segment that switches character class often (base64/keys),
    # unlike camelCase identifiers, epoch-numbered file names or words
    for x in segs:
        if (len(x) >= 16 and entropy(x) >= 3.5 and re.search(r'[0-9]', t)
                and class_switch_ratio(x) >= 0.4):
            return 'base64-like', True
    return 'low-entropy text / identifiers', False


def verify(raw, scrubbed):
    # sensitive originals from the raw file, via the scrubber itself
    sc = Scrubber()
    sc.prepass(raw)
    with open(raw, encoding='utf-8') as f:
        for line in f:
            if line.strip():
                sc.walk(json.loads(line))
    originals = {v for v in sc.sensitive_originals if len(v) >= 6}
    originals |= {k for k in sc.known_uuid} | set(sc.known_literal)
    m = re.search(r'session_(01[A-Za-z0-9]{20,})', os.path.basename(raw))
    if m:
        originals.add(m.group(1))   # the session suffix (also covers its cse_ twin)
    strict = collections.Counter()
    loose = collections.Counter()
    loose_raw_line = collections.Counter()
    loose_examples = collections.defaultdict(collections.Counter)
    literal = collections.Counter()
    he_kept = collections.Counter()
    review = {}
    sig = collections.Counter()
    imgs = collections.Counter()

    def walk(o, path):
        if isinstance(o, dict):
            otype = o.get('type')
            for k, v in o.items():
                p = path + '.' + k
                if isinstance(v, str) and k == 'signature' and otype in ('thinking', 'redacted_thinking'):
                    sig['count'] += 1
                    sig['chars'] += len(v)
                    continue
                if isinstance(v, str) and ((k == 'data' and otype == 'base64') or k == 'base64'):
                    imgs['count'] += 1
                    imgs['chars'] += len(v)
                    imgs['non_base64_chars'] += len(re.sub(r'[A-Za-z0-9+/=\s]', '', v))
                    continue
                walk(v, p)
        elif isinstance(o, list):
            for x in o:
                walk(x, path + '[]')
        elif isinstance(o, str):
            for name, rx in LOOSE.items():
                for mm in rx.finditer(o):
                    loose[name] += 1
                    ctx = o[max(0, mm.start() - 25):mm.end() + 25].replace('\n', ' ')
                    ctx = re.sub(r'[A-Za-z0-9_+/=-]{13,}', lambda x: x.group(0)[:6] + '…', ctx)
                    loose_examples[name][(path, ctx)] += 1
            for t in HE_TOKEN_RX.findall(o):
                kind, rev = classify_token(t, path)
                if rev:
                    key = (re.sub(r'toolu_\w+', 'TOOLU', path), kind, t[:12])
                    r = review.setdefault(key, [0, set()])
                    r[0] += 1
                    r[1].add(hash(t))
                else:
                    he_kept[kind] += 1

    with open(scrubbed, encoding='utf-8') as f:
        for line in f:
            for name, rx in STRICT.items():
                strict[name] += len(rx.findall(line))
            for name, rx in LOOSE.items():
                loose_raw_line[name] += len(rx.findall(line))
            for v in originals:
                if v in line:
                    literal[v] += 1
            walk(json.loads(line), '')
    return {
        'scrubbed_file': os.path.basename(scrubbed),
        'strict_residuals': {k: v for k, v in strict.items()},
        'loose_residuals_outside_images_and_signatures': {k: loose.get(k, 0) for k in LOOSE},
        'loose_residuals_whole_line_incl_base64': {k: loose_raw_line.get(k, 0) for k in LOOSE},
        'loose_examples_masked': {k: [[p, c, n] for (p, c), n in cnt.most_common(8)]
                                  for k, cnt in loose_examples.items()},
        'sensitive_originals_checked': len(originals),
        'sensitive_originals_still_present': {('%s…(len %d)' % (v[:4], len(v))): n for v, n in literal.items()},
        'high_entropy_kept_by_kind': dict(he_kept),
        'review_list': [
            {'key_path': p, 'kind': k, 'prefix12': pre, 'occurrences': n, 'distinct_values': len(h)}
            for (p, k, pre), (n, h) in sorted(review.items(), key=lambda x: (-x[1][0], x[0]))],
        'thinking_signatures': dict(sig),
        'images': dict(imgs),
    }


def main(argv):
    args = [a for a in argv if not a.startswith('--')]
    flags = {a for a in argv if a.startswith('--')}
    unknown = flags - {'--verify', '--drop-signatures'}
    if unknown or len(args) != 2:
        sys.stderr.write(__doc__)
        return 2
    if '--verify' in flags:
        print(json.dumps(verify(args[0], args[1]), indent=1, ensure_ascii=False))
        return 0
    if os.path.realpath(args[0]) == os.path.realpath(args[1]):
        sys.stderr.write('refusing to overwrite the input\n')
        return 2
    rep, _ = scrub_file(args[0], args[1], '--drop-signatures' in flags)
    sys.stderr.write(json.dumps(rep, indent=1) + '\n')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
