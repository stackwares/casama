# Saved resets

A saved reset refills your workspace’s included credits. Your server’s administrator may give you
one after an outage or as goodwill. It cannot be purchased or earned.

Look under the credit meter in **Usage** or **Billing**. The message shows the exact expiry in your
local time. Workspace owners can choose **Use Reset** and review the refill amount before confirming.
Other workspace members can see the reset but cannot use it.

A reset tops up the included allowance; using it while nearly full gives little credit. It never
refills past what the period actually granted, such as a trial's smaller amount, and a second free
workspace that gets no free credits gets none from a reset. It leaves purchased credit alone. On a
negative balance, part of the refill pays off what's owed first. Refilled credit expires at the end of the current billing period. A reset
may also clear the day’s model cap or refill the month’s computer hours when the administrator has
included those options. A cleared daily cap applies everywhere: chat, voice calls, Casama Link and
check-ins. The confirmation cannot be undone by the workspace owner.

A paused campaign, an exhausted campaign budget, the workspace’s period allowance, or nothing to
refill yet can make a reset temporarily unavailable; the row under the meter says which. Its expiry continues to count down. If several resets are saved,
the earliest expiring available reset is used first.

## For instance owners

Open **Admin → Resets**. Enable saved resets, set the period allowance and held-reset limit, then
create a campaign. Choose the audience, start and expiry, refill percentage, optional per-use cap,
optional total budget, and arrival/reminder notifications. Preview the recipient count and maximum
credit exposure before saving. New campaigns are drafts; choose **Schedule** to launch them.

Audience filters intersect. Empty plan or workspace lists leave those filters unrestricted. The
workspace list is fixed when the campaign starts. Workspaces already holding the maximum number
are skipped. No reset is added to a workspace that subscribes after launch.

Draft and scheduled campaigns can be edited fully. After launch, audience and refill settings are
fixed. Pause stops redemption while expiry continues. Cancel stops every unused reset. Only drafts
can be deleted. To change a launched audience, cancel and create another campaign.

While saved resets are switched off, nothing is handed out: a scheduled campaign waits and launches
once they're switched on (if it hasn't expired), and a one-off reset is refused.

Use the workspace ID field to give a one-off reset, load history, take back an unused reset, or undo
a used reset’s unspent refill. **Copy CSV** copies the full filtered audit history.
The history remains after a draft or workspace is deleted.

Developers use `scripts/limit-resets.sh METHOD ROUTE [JSON_FILE]` with `CASAMA_API_URL` and
`CASAMA_ACCESS_TOKEN_FILE` pointing to an instance-owner token file. This uses the same authorization
and audit trail as the app. Do not put the token in a command argument. The `/v1/admin/limit-resets/events.csv` endpoint streams the full filtered log. The JSON event endpoint accepts
`campaign_id`, `org_id`, and `limit` filters for exporting more focused history.

Saved resets are hidden on servers with billing disabled.
