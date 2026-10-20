# Injected check-ins (companion, 20 Oct ~10:58Z)

Method: every user-role event in the four pilot event streams that is not a pure tool_result, classified as human-sent (the event carries received_at/processing timestamps: typed in the UI by Jackson or the companion) or harness-injected (isSynthetic / origin / no human timestamps). Also searched every tool_result and text block for <system-reminder> blocks.

Result: no automatic "status check-in" nudges appear in any pilot's record.
- B1: 12 human messages (start, budget STOP, 7 interview turns + answers, pronoun question, /usage on 19 Oct). Injected: 1 stream-cut auto-resume (16 Oct 09:54:52Z, "Your response above was cut off mid-stream. Resume directly from where it stops — no apology, no recap. …") and 1 compaction continuation summary (12:46:16Z).
- B2 attempt 1: 6 human messages (start, a "carry on: run setup" restart, STOP, "why did you choose RIPPLE", clone request, /usage); 1 "[Request interrupted by user for tool use]" marker.
- B2: 19 human messages (start, emulator-restart carry-on, two CONTINUEs after pauses, STOP, interview, answers, housekeeping, /usage); injected: 3 compaction summaries, 1 "[Request interrupted by user]" marker, and 2 post-run Stop-hook messages ("Stop hook feedback: [~/.claude/stop-hook-git-check.sh]: There are untracked files in the repository. Please commit and push …", 18 Oct 00:52:34Z and 00:59:11Z, after play ended).
- Ripple: 46 human messages (start, companion K1.md check, BAG correction, no-healing note, rule update, diary note, rule clarification, welfare handout, PAUSE + correction, three CONTINUEs, STOP, 24-question interview, answers, housekeeping, chat, /usage); injected: 4 compaction summaries and 1 background-task notification (17 Oct 14:16:36Z).
- <system-reminder> blocks in tool results: none, except Ripple ×2 "Warning: the file exists but the contents are empty." (17 Oct 14:15–14:16Z).
Caveat: the event stream records messages and tool traffic; anything the harness adds to the model's context without an event (system prompt, internal reminders) would not show here.
