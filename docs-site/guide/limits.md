# Limits

Every default limit, timeout, budget and cap in Casama, what happens when a run or call hits it,
and whether you can change it. For what happens when a background or chat run ends at a limit, see
[When a run hits a limit](/guide/usage#when-a-run-hits-a-limit); for live calls, see
[When a live call ends for a limit](#when-a-live-call-ends-for-a-limit).

## Runs, check-ins and budgets

| Limit | Default | When hit | Can you change it? | Details |
| --- | --- | --- | --- | --- |
| Steps per run | 40 | Run ends with `max_steps_exceeded` | No (fixed) | [Usage](/guide/usage#other-limits-on-every-run) |
| Steps per check-in (briefs and looks) | 8 (plus 8,000 chars per app read) | Check-in ends with `max_steps_exceeded`; long app results are trimmed | No (fixed) | [Routines](/guide/routines#check-ins) |
| Time per run | 30 minutes | Run ends with `wall_time_exceeded` | No (fixed) | [Usage](/guide/usage#other-limits-on-every-run) |
| Bot per-run budget | $1 | Run ends with `budget_exceeded` | Yes (CLI, API, or a bot managing bots) | [Usage](/guide/usage#bot-budgets) |
| Bot daily budget | $10 (UTC day) | Active runs stop and new runs are refused (`daily_budget_exceeded`) until midnight UTC | Yes (CLI, API, or a bot managing bots) | [Usage](/guide/usage#bot-budgets) |
| Subagent budget and time | 20% of parent's remaining budget (min $0.01); 10 min default (up to 1 hr) | Subagent stops and returns its status to the parent | Parent bot can ask for less budget or set time up to 1 hr | [Bots together](/guide/bots-together#subagents) |
| Parallel subagents | Up to 5 at once (sharing 40% of remaining budget) | Bot waits for the batch before starting more | No (fixed) | [Bots together](/guide/bots-together#subagents) |
| Bot-to-bot delegation depth | 3 levels deep | Deeper delegations or loops back to a bot already in the chain are refused | No (fixed) | [Bots together](/guide/bots-together#hand-a-task-to-another-bot) |
| Loop guard | 3rd identical mutating step blocked; 5 failed steps in a row ends run | Run stops with `stuck_looping` | No (fixed) | [Autonomy](/guide/autonomy#the-loop-guard) |
| Waiting approval or screen takeover | 24 hours | Request expires and counts as denied or dismissed | No (fixed) | [Autonomy](/guide/autonomy#approvals) |
| Connected AI app (`ask_bot`) and external A2A agent wait | 10 minutes | Caller gets `waiting_approval` or a timeout status | No (fixed) | [MCP](/guide/mcp), [Bots together](/guide/bots-together) |
| Simultaneous runs per workspace | 5 active runs (20 per worker) | Extra runs wait in queue until a slot frees | Self-hosted: `RUN_WORKSPACE_CONCURRENCY`, `RUN_CONCURRENCY` | [Configuration](/self-hosting/configuration#models-and-ai-gateway) |

## Tools, coding agents and computers

| Limit | Default | When hit | Can you change it? | Details |
| --- | --- | --- | --- | --- |
| Shell command timeout | 10 minutes (bot can request up to 1 hour) | Command is stopped and returns a timeout error to the run | Bot can pass up to 3,600 s per command | [Computers](/guide/computers#limits) |
| Browser action timeout | 90 seconds | Step fails with a browser error | No (fixed) | [Computers](/guide/computers#the-browser-and-sign-ins) |
| Browser lock wait across chats | 90 seconds | Second chat/bot goes on without the browser or tells you it's waiting | No (fixed) | [Computers](/guide/computers#the-browser-and-sign-ins) |
| Desktop action timeout | 60 seconds | Step fails with a desktop error | No (fixed) | [Computers](/guide/computers#limits) |
| Coding agent run | 30 min on a computer; 60 min in cloud | Agent process or cloud task is stopped | Bot or custom agent can set 1–120 min | [Coding agents](/guide/coding-agents#options-the-bot-can-set) |
| Coding-tool helper commands (install, git diff) | 2 minutes | Helper step fails with a timeout error | No (fixed) | [Coding agents](/guide/coding-agents#limits) |
| Computer idle sleep | 5 minutes without use | Home folder is saved and computer stops | Yes, per computer: 5, 15, 30 or 60 min | [Computers](/guide/computers#sleep-and-wake) |
| Live view auto-pause | 5 minutes without input or bot work | Asks **Still watching?**, then pauses stream so computer can sleep | No (fixed) | [Computers](/guide/computers#live-view) |
| Live view control handback | 15 minutes without input | Control returns to the bot automatically | No (fixed) | [Computers](/guide/computers#take-control-and-hand-back) |
| Live view reconnect | ~45 seconds | Falls back to screenshots with **Try again** | No (fixed) | [Computers](/guide/computers#live-view) |
| Restore points | Automatic ones 10 min apart; keeps last 20 or 7 days | Rapid deletes skip extra auto points; oldest points are deleted | Bot or person can save a manual restore point anytime | [Computers](/guide/computers#restore-points) |
| Download all files zip | 1 GB (`~/workspace`) | Larger folders can't be zipped in one download | No (fixed) | [Computers](/guide/computers#manage-a-computer) |
| Local companion command / question timeout | 10 minutes waiting for your answer | Question expires and is treated as declined | No (fixed) | [Your own computer](/guide/companion) |

## Voice, live calls and bot rings

Self-hosted server owners can change the call and ring limits in **Admin console → Services → Call
limits** (or `GET`/`PUT /v1/admin/call-limits`).

| Limit | Default | When hit | Can you change it? | Details |
| --- | --- | --- | --- | --- |
| Quiet call hangup | 60 seconds with no speech | App hangs up (paused while a task runs or call is held) | Admin console: `silence_seconds` (20–900 s) | [Voice](/guide/voice#the-call-screen) |
| Longest live call | 60 minutes | Bot warns before end, says goodbye, and call closes | Admin console: `max_call_minutes` (5–240 min) | [Voice](/guide/voice#the-call-screen) |
| Pre-limit warning | ~60 seconds before length or spend limit | Bot warns in one short sentence before wrapping up | Admin console: `warning_seconds` (15–300 s, max half call length) | [Voice](/guide/voice#the-call-screen) |
| Abandoned call sweep | 60 seconds without an app heartbeat | Server ends the call and settles billing (`heartbeat_seconds` 15 s, 5–60 s) | Admin console: `abandoned_seconds` (60–900 s) | [Voice](/guide/voice#the-call-screen) |
| Simultaneous billable live calls per workspace | 3 open calls | New call is refused with `429 too_many_calls` | No (fixed) | [Voice](/guide/voice) |
| Live call start reserve (Casama Cloud) | At least 2 minutes of credits | Call is refused (`out_of_credits`) before connecting | Add credits or upgrade plan | [Voice](/guide/voice) |
| Bot ring timeout | 45 seconds | Stops ringing and sends a missed-call notification | No (fixed) | [Voice](/guide/voice#when-a-bot-calls-you) |
| Bot daily ring cap | 3 rings a day across all bots | Stops ringing, sends a notification, and tells the bot why. Rings that reached no device don't count | Admin console: `ring_daily_cap` (0–20; `0` disables rings) | [Voice](/guide/voice#when-a-bot-calls-you) |
| Per-bot ring cooldown | 30 minutes between rings | Same bot waits before ringing again; sends a notification instead. Rings that reached no device don't count | Admin console: `ring_cooldown_minutes` (0–1440 min) | [Voice](/guide/voice#when-a-bot-calls-you) |
| Voice tool handoff | ~12 seconds | Longer tools move to chat and the bot tells you when ready | No (fixed) | [Voice](/guide/voice#the-call-screen) |
| Call context and persona | First 1,500 chars of instructions; up to 20 prior turns (~600 tokens); ~5 min live rolling window | Oldest live turns trim (8,000 → 3,000 tokens); everything stays saved in chat | Self-hosted: `VOICE_CONTEXT_TRIGGER_TOKENS`, `VOICE_CONTEXT_TARGET_TOKENS` | [Voice](/guide/voice#the-call-screen), [Configuration](/self-hosting/configuration#advanced-settings) |
| Read-aloud clip | 4,000 characters | Longer replies are read up to the cap | No (fixed) | [Voice](/guide/voice) |

## When a live call ends for a limit

Unlike chat and routine runs (which end immediately with a failed-run code in
[When a run hits a limit](/guide/usage#when-a-run-hits-a-limit)), a live call tries to wrap up
cleanly so you aren't cut off mid-sentence.

### Before a call starts

On Casama Cloud (or any server enforcing billing/quotas), starting a call checks headroom before
opening the session. If a limit is already hit, the call doesn't start:

- **Out of credits** (`out_of_credits`): workspace has less than 2 minutes of call reserve left;
  the app opens the credits or paywall sheet.
- **Plan daily limit** (`cloud_daily_cap`): Casama Cloud workspace reached its daily model/voice
  spend cap (resets at midnight UTC).
- **Workspace monthly quota** (`quota_exceeded`): self-hosted workspace reached its monthly spend
  limit.
- **Bot daily budget** (`daily_budget_exceeded`): the bot reached its daily budget for the UTC day.
- **Too many open calls** (`too_many_calls`): 3 billable calls are already active in the
  workspace.

### Mid-call

On relayed calls (Casama Cloud, or self-hosted with `LIVE_CALL_RELAY=on`), the server checks
remaining time and headroom every 20 seconds:

1. **Warning (~60 seconds left):** The bot gets a prompt to let you know in one short sentence that
   the call is about to hit its limit.
2. **Goodbye and clean close:** When the limit is reached (or under 20 seconds of headroom remain),
   the bot says a short 1–2 sentence goodbye explaining why and noting that anything already started
   continues in the chat. Once playback finishes (at most 30 seconds), the server closes the call
   cleanly (the app does not auto-reconnect), settles usage, and posts the call recap card in the
   chat.

| End reason (`end_reason`) | Why the call ended |
| --- | --- |
| `max_length` | Reached the longest call limit (60 minutes by default) |
| `credits` | Workspace ran out of credits |
| `daily_cap` | Casama Cloud plan hit its daily spending limit (resets midnight UTC) |
| `quota` | Workspace hit its monthly spending quota |
| `bot_budget` | The bot hit its daily budget (resets midnight UTC) |
| `silent` | Quiet call idle hangup (60 s without speech or running tasks) or abandoned call sweep (60 s without app heartbeats) |
| `hung_up` | You (or another call replacing it) ended the call |

On calls connected straight to Gemini with your own Google AI key (`LIVE_CALL_RELAY=off`), the
server isn't in the audio path, so the app enforces the idle silence hangup and longest-call wrap-up
itself, and the server's abandoned-call sweep handles dropped apps.

## Notifications, workspaces and Casama Cloud plans

| Limit | Default | When hit | Can you change it? | Details |
| --- | --- | --- | --- | --- |
| Proactive non-urgent pushes | 5 per bot per day (user's timezone; brief excluded) | Extra normal-urgency pushes wait in your inbox for the next morning brief | No (urgent pushes and replies don't count) | [Attention](/guide/attention#attention-rules-when-youre-busy) |
| Quiet hours | 22:00 to 07:00 | Non-urgent pushes and scheduled check-ins wait until quiet hours end | Yes, in Settings or per bot | [Attention](/guide/attention#set-quiet-hours) |
| Check-in share of daily limit (Casama Cloud) | 40% across all check-ins | Check-ins stop for the day so your own chats keep headroom | No (fixed) | [Routines](/guide/routines#check-ins) |
| Workspace invite codes and links | Code: 48 hours; email invite: 7 days; custom link: 1, 7, 30 days or never (1, 5, 25 or unlimited uses) | Expired invites are rejected; wrong invite attempts lock for 10 tries in 10 minutes | Admins pick expiry/uses on custom links | [Workspaces](/guide/workspaces#invite-people) |
| Casama Cloud workspaces per person | Up to 5 owned workspaces | Creating another workspace is blocked | No (fixed) | [Usage](/guide/usage#plans) |
| Invite-a-friend rewards | Up to 20 rewarded friends ($2 credits each); code entry within 7 days of signup | Extra invites don't pay credit rewards | No (fixed) | [Usage](/guide/usage#invite-friends) |
| Self-hosted workspace quotas | Unlimited unless set | Blocks new bots or runs past monthly spend (`quota_exceeded`) | Admin console → **Workspaces** → **Edit quotas** | [Usage](/guide/usage#workspace-quotas) |

### Casama Cloud plan caps

| Plan | Bots | Computers (running at once) | Computer hours / month | Daily model & voice limit | People | Library storage | Casama Link servers |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Free** | 3 | 1 (1) | 5 | $0.25 | 1 | 1 GB | 1 |
| **Plus** | 10 | 2 (1) | 30 | $5 | 1 | 10 GB | 1 |
| **Pro** | Unlimited | 5 (2) | 100 | $10 | 3 (+paid extras) | 50 GB | 3 |
| **Max** | Unlimited | 10 (2) | 300 | $25 | 10 (+paid extras) | 200 GB | 10 |

See [Casama Cloud plans and credits](/guide/usage#casama-cloud-plans-and-credits) for full plan
rules, trial allowances and check-in frequency caps.

## Related

- [Usage, budgets and plans](/guide/usage)
- [Voice and calls](/guide/voice)
- [Computers](/guide/computers)
- [Coding agents](/guide/coding-agents)
- [Routines and triggers](/guide/routines)
- [Autonomy and approvals](/guide/autonomy)
- [Self-hosting configuration](/self-hosting/configuration)
