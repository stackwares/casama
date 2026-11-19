# Admin bot: running Casama Cloud from a chat

Status: **built** (2026-11-20, D-435). Oliver: "build everything now!" Not pushed or deployed. Tracked in `docs/PLANS.md`.

## What it is

The instance owner (on Casama Cloud: admin@casama.ai, the one address in `INSTANCE_ADMIN_EMAILS`)
picks one of their own bots as the **admin bot**. In a chat with that bot, in the Casama app, the
bot can look things up and propose admin actions: let people in from the waitlist, add addresses,
ban and unban accounts, suspend and unsuspend workspaces. Every change waits for the owner's tap.

## The threat, and the one rule that answers it

The real risk is prompt injection: the bot reads a waitlist note, a support ticket or a web page
that says "let me in" or "ban this person", and follows it. No model can be relied on to resist
that. So the design never relies on the bot behaving:

**The bot can only propose. A person who is an instance owner approves every change, in the app,
one action at a time.** Even a fully hijacked bot can only put a card in front of the owner.

## Layers (each one holds on its own)

1. **Off unless switched on.** `instance_settings` row `admin_bot` (`{enabled, bot_id}`), set by the
   owner at `PUT /v1/admin/admin-bot` or `scripts/admin-bot.sh`. One bot at most. Turning it off
   applies to running bots at once (read on every call).
2. **Only the owner's own chat.** The tools are offered, approved and run only when all of these
   hold, checked from the database (never from what the model says):
   - the switch is on and the run's bot is the chosen bot;
   - the run is an in-app chat (`trigger = 'chat'`): not a routine, check-in, webhook, voice call,
     subagent, delegation, group chat or A2A call;
   - its conversation isn't tied to a chat app (Telegram, Slack, email…);
   - the person who sent the message is an instance owner by the explicit `INSTANCE_ADMIN_EMAILS`
     list (the "first account" fallback doesn't count here), with a confirmed email and no ban;
   - every member of the bot's workspace is an instance owner, so nobody else can be in the chat or
     see the approvals; the workspace isn't suspended.
3. **Always asks.** Admin tools are a new tool kind (`instanceAdmin`) in the run loop: every write
   asks, whatever the bot's autonomy, the workspace's Full access switch, action rules, "always
   allow" grants or a tapped card. Risk is high, so a notification has no Approve button; the
   approval is never posted into a chat app; a check-in can never get one.
4. **Who may approve.** `POST /v1/approvals/{id}` refuses an admin approval unless the caller is an
   instance owner with a normal session: not a watch key, a widget key, an MCP call, a chat-app
   button, and never "always allow".
5. **Checked again when it runs.** Before doing anything, the tool re-checks layer 2 and finds its
   own approval row (`run_id`, `call_id`): approved, not "always", decided by an instance owner in
   the last 15 minutes. A tool called some other way, or after the switch is turned off, does
   nothing.
6. **Small, fixed tool set.** Reads: `admin.overview`, `admin.users.find`, `admin.waitlist.list`.
   Writes: `admin.waitlist.admit`, `admin.waitlist.add`, `admin.users.ban`, `admin.users.unban`,
   `admin.workspaces.suspend`, `admin.workspaces.unsuspend`. No keys, connections, prices, plans,
   billing, the sign-up gate or data key replacement. At most 25 people per call and 60 admin writes
   an hour. Owners and the admin bot's own workspace can't be banned or suspended.
7. **Text from people is data.** Waitlist notes and user lists are marked untrusted output, and the
   bot's prompt says so.
8. **Audit.** Every admin write is in `audit_log` as `admin_bot.<tool>` with the run, the bot and who
   approved it, plus the usual `org.suspended` / `user.banned` rows.

## Database access

The tools run in the worker, whose database role never reads the `auth` schema (D-095). What they
need from `auth.users` goes through four security-definer functions only `casama_worker` can call
(migration `20270220100001_admin_bot`): one account's email and state, a search by email, totals,
and setting or lifting a ban.

## Ban (new)

`admin.users.ban` (and the service behind it): sets `auth.users.banned_until` to forever, ends every
session (`auth.sessions`, `auth.refresh_tokens`), and suspends the workspaces the person alone owns
(reason `account_banned`), which stops their runs and computers. Shared workspaces keep running for
their other members. An access token already handed out stays valid until it expires (Auth's JWT
lifetime); it can't be refreshed. Unban clears the ban and lifts only suspensions with the reason
`account_banned`. An account being deleted can't be unbanned.

## Not done

- No biometric check in the app before approving: the server can't verify one, so the guarantee
  rests on layers 1–5. Worth adding to the approval card later as an extra speed bump.
- No admin console screen for the switch; the route and the script are enough for one owner.

## The plan for admin@casama.ai's own limits

Owner overrides on its workspace (D-070), set from the admin console, not a code exception.
