# Founder Taste Standard
> Loaded when: TASTE, quality, code review keywords detected.

## Code Quality
- Clarity over cleverness — junior dev should understand any function
- Names explain intent: getUserByEmail() not getData()
- No premature abstraction — don't build a framework for a one-time problem
- Small functions — if it needs a comment to explain, split it
- Errors are first-class — handle explicitly, never swallow silently

## Architecture
- Simple before clever — boring solution unless documented reason not to
- Separation of concerns — UI/API/DB don't know about each other
- One source of truth — never duplicate state
- Build for actual scale, not imagined scale

## UI/UX
- Functional is the aesthetic — clean, purposeful, no visual noise
- Mobile-first always — smallest screen first, expand up
- Empty states are not afterthoughts — every list/table/feed needs one
- Loading states are UX — skeleton screens over spinners
- Error messages speak to the user — "Something went wrong" is not acceptable

## Done = proud to show someone you respect. Not "technically works." Tight, clear, honest.
