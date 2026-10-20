# Harness v2: two changes to the frozen v1 harness
Only `harness/director.lua` (VERSION `aba96c3c` -> `v2.0`) and `harness/g` changed. Diff: `harness-v2.diff` (+287/-24).
New sha256 (first 16): director.lua `ef6cee84d2a97a7f`, g `e789248010a69e24` (v1: fa9d50962f444e99, f849592e98f805e8).

## Change 1: `g t` / `TEXT` freshness
- Output: `[f] text` (live), `[f old] text` (stale), `[b] text`, `[b menu] text`, plus ` (unchanged Ns)` after 3 s. Prefix `[f]`/`[b]` kept.
- Field: `sFieldMessageBoxMode` 0x020375bc (u8; sym file + src/field_message_box.c). Deviation from the brief: HIDDEN alone is NOT "gone".
  Task_DrawFieldMessage sets HIDDEN as soon as printing ends while the box still waits for A (verified live, screenshots d2_*). So
  `old` = mode HIDDEN and `sLockFieldControls` (0x03000f2c) clear, and only in game modes overworld / naming_screen.
  In other modes (new-game intro speech, clock, starter screen) gStringVar4 can be live or stale, so no word is shown (age still is).
- Battle: `getBattleDecisionState().battle_input` choose_action / choose_move / choose_target -> `menu`.
- Age: onFrame samples the decoded text every 6 frames (cheap; first thing in onFrame so it also runs while presses drain). A
  hidden->shown edge of the message box also restarts the age, so re-showing identical text is not "unchanged".
- `TEXT` JSON adds `live` (false for old/menu), `box` (hidden/normal/autoscroll or battle_input), `age_s`.
- `g`: new `txt()` strips the `[x ...] ` prefix and the `(unchanged Ns)` tail. `newtext` and all 4 comparisons in `adv` use it, so
  live->old flips or age ticks never reprint or end `adv` early.
## Change 2: `g name <TEXT>` (`NAME <text>` op; bare `NAME` = read-back line)
- Source: pret src/naming_screen.c: sKeyboardChars (3 pages; letters 8 cols, symbols 6 cols + a button column at col == count),
  Task_HandleInput (rows wrap mod 4; left/right move through the button column and change the row), SELECT cycles pages
  symbols->upper->lower, A on the last char jumps to OK. Space is a key (0x00).
- Addresses: sNamingScreen 0x02039f94 (heap ptr; sym). Struct offsets computed from the C struct, then verified live
  (state@+0x1E10=2 idle, page@+0x1E22, cursorSpriteId@+0x1E23, template@+0x1E28 -> maxChars=byte 1: 7 player, 10 mon nickname,
  textBuffer@+0x1800). Cursor = gSprites 0x02020630 + id*0x44, data[0]/data[1] (sX/sY, +0x2E).
- Every press: re-read page/cursor/text from RAM, pick one button (namePlan: SELECT if the page is wrong, LEFT off the button
  column, vertical by shortest wrap, then horizontal, then A), verify typed text equals the expected prefix, abort on mismatch,
  3 no-progress presses, naming screen gone, or timeout. Never presses START/OK. Row-length and wrap quirks are handled by position.
- Accepts A-Z a-z 0-9 space . , ! ? / - ' and the UTF-8 glyphs male/female/ellipsis/curly quotes. Errors: bad char (with position),
  too long (max read from the screen), not on a naming screen, busy, name box already holds a different prefix. A matching prefix
  is continued. `S` shows `busy` while the job runs. `g name` prints the RAM read-back and a not-confirmed reminder.
## Tests (scratch HOME with setup.sh; booted Kaizo ROM headless; scripts in /tmp/claude-0/scr)
- SELFTEST in-game (battle): v1 31/31 true; v2 37/37 true (+6: text_label, text_status_read, name_parse, name_layout, name_plan,
  name_screen_read_safe). Boot-screen SELFTEST false for party_decrypt/live_player_pos in BOTH v1 and v2 (no game yet).
  No luac/lua binary here: syntax checked by the emulator's RELOAD (load error caught the 200-local limit once; fixed with a `v2` table).
- NAME, player screen (max 7), `NAME` read-back + screenshots: `Claude` (page switch, 325 frames, 5.8 s at 60 fps), `TEST`, `Aa 'z`
  (typed apostrophe reads back as the curly one), `ZZZZZZZ` (cursor lands on OK), male/female/ellipsis mix; refused: `ABCDEFGH`
  (8>7), `ab$c`, a CJK char. Mon nickname screen (max 10): `Bluebird 9`, `Mr.Mime-!?`, `TORCHIC1`; `Elevenchars` refused.
  Continue `Cla`->`Claude`; `Bob` over `Claude` refused; after START (cursor on OK) `TEST`->`TEST7`->`TEST7xyz` works; busy and
  not-on-naming-screen errors. End-to-end `g name 'Mr Mime'`, `g start`, `g a` -> "So it's Mr Mime?".
- Text, before (v1 director RELOAD'd on the same state) vs after, truck box message, boxmode/lock read raw:
  press 5 printing done, waiting for A (mode 0, lock 1): before `[f] The box...`, after `[f] The box...` (correct, live, screenshot shows it)
  press 6 closed (mode 0, lock 0): before `[f] The box...`, after `[f old] The box...` (screenshot: empty screen)
  Battle (Route 101 Zigzagoon, driven by scripted presses): before `[b] What will / TORCHIC do?`, `[b] TYPE/NORMAL`;
  after `[b menu] What will / TORCHIC do? (unchanged 210s)`, `[b menu] TYPE/NORMAL`; messages stay `[b] TORCHIC used / SCRATCH!`.
  `g a`/`g adv` print each new message once (live->old flips do not reprint). Naming screen shows `[f old]` (was stale, unlabeled).
## Known limits
- Unknown screens (clock, starter pick, bag, party) get no word: stale text there is only hinted by `(unchanged Ns)`.
- A script that holds the field lock with no box on screen (cutscene walking) reads live; the age grows. Age is emulated seconds
  (uncapped runs inflate it; at 60 fps it equals wall time). Identical text re-shown in battle cannot restart the age.
- choose_action is labelled `menu` per the brief although the buffer holds its live "What will X do?" prompt.
- NAME: leading/trailing spaces need the argument quoted (`g name "AB "`); ASCII `"` is not supported (use the curly quote glyphs);
  the read-back comes from RAM (textBuffer), not OCR. `S` still raises `yn?` on a stale question on the naming screen (untouched).
