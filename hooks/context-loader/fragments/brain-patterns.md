# Known Patterns (from brain/)

No patterns captured yet. After errors are captured to `~/.claude/brain/log/errors/` and `/reflect` promotes them, this file will contain prevention rules.

When you encounter a build/test/lint error, the `error-capture` hook will prompt you to write an error record to `brain/log/errors/`. Do so before fixing — it captures the raw state.

After fixing, update the error record's Root Cause, Fix, and Prevention fields.
