---
name: digest
description: Generate a daily or weekly digest of activity across all connected sources. Use when catching up after time away, starting the day and wanting a summary of mentions and action items, or reviewing a week's decisions and document updates grouped by project.
---

Adapted for Casama from anthropics/knowledge-work-plugins@877a617b (Apache-2.0). Read activity from apps the workspace has connected, plus files on the computer.

# Digest Command

Scan recent activity across all connected sources and generate a structured digest highlighting what matters.

## Instructions

### 1. Parse Flags

Determine the time window from the user's input:

- `--daily` — Last 24 hours (default if no flag specified)
- `--weekly` — Last 7 days

The user may also specify a custom range:
- `--since yesterday`
- `--since Monday`
- `--since 2025-01-20`

### 2. Check Available Sources

See which apps are connected (chat, email, files, a project tracker, a CRM, a knowledge base) and use those. Also use files already on the computer:

- **connected chat** — channels, DMs, mentions
- **connected email** — inbox, sent, threads
- **connected file storage** — recently modified docs shared with user
- **connected project tracker** — tasks assigned, completed, commented on
- **connected CRM** — opportunity updates, account activity
- **connected knowledge base** — recently updated wiki pages

If no sources are connected, guide the user:
```
To generate a digest, you'll need at least one source connected.
Connect a chat, email, or file app in Settings → Integrations, or work from files they already have.
```

### 3. Gather Activity from Each Source

**connected chat:**
- Search for messages mentioning the user (`to:me`)
- Check channels the user is in for recent activity
- Look for threads the user participated in
- Identify new messages in key channels

**connected email:**
- Search recent inbox messages
- Identify threads with new replies
- Flag emails with action items or questions directed at the user

**connected file storage:**
- Find documents recently modified or shared with the user
- Note new comments on docs the user owns or collaborates on

**connected project tracker:**
- Tasks assigned to the user (new or updated)
- Tasks completed by others that the user follows
- Comments on tasks the user is involved with

**connected CRM:**
- Opportunity stage changes
- New activities logged on accounts the user owns
- Updated contacts or accounts

**connected knowledge base:**
- Recently updated documents in relevant collections
- New documents created in watched areas

### 4. Identify Key Items

From all gathered activity, extract and categorize:

**Action Items:**
- Direct requests made to the user ("Can you...", "Please...", "@user")
- Tasks assigned or due soon
- Questions awaiting the user's response
- Review requests

**Decisions:**
- Conclusions reached in threads or emails
- Approvals or rejections
- Policy or direction changes

**Mentions:**
- Times the user was mentioned or referenced
- Discussions about the user's projects or areas

**Updates:**
- Status changes on projects the user follows
- Document updates in the user's domain
- Completed items the user was waiting on

### 5. Group by Topic

Organize the digest by topic, project, or theme rather than by source. Merge related activity across sources:

```
## Project Aurora
- connected chat: Design review thread concluded — team chose Option B (#design, Tuesday)
- connected email: Sarah sent updated spec incorporating feedback (Wednesday)
- connected file storage: "Aurora API Spec v3" updated by Sarah (Wednesday)
- connected project tracker: 3 tasks moved to In Progress, 2 completed

## Budget Planning
- connected email: Finance team requesting Q2 projections by Friday
- connected chat: Todd shared template in #finance (Monday)
- connected file storage: "Q2 Budget Template" shared with you (Monday)
```

### 6. Format the Digest

Structure the output clearly:

```
# [Daily/Weekly] Digest — [Date or Date Range]

Sources scanned: connected chat, connected email, connected file storage, [others]

## Action Items (X items)
- [ ] [Action item 1] — from [person], [source] ([date])
- [ ] [Action item 2] — from [person], [source] ([date])

## Decisions Made
- [Decision 1] — [context] ([source], [date])
- [Decision 2] — [context] ([source], [date])

## [Topic/Project Group 1]
[Activity summary with source attribution]

## [Topic/Project Group 2]
[Activity summary with source attribution]

## Mentions
- [Mention context] — [source] ([date])

## Documents Updated
- [Doc name] — [who modified, what changed] ([date])
```

### 7. Handle Unavailable Sources

If any source fails or is unreachable:
```
Note: Could not reach [source name] for this digest.
The following sources were included: [list of successful sources].
```

Do not let one failed source prevent the digest from being generated. Produce the best digest possible from available sources.

### 8. Summary Stats

End with a quick summary:
```
---
[X] action items · [Y] decisions · [Z] mentions · [W] doc updates
Across [N] sources · Covering [time range]
```

## Notes

- Default to `--daily` if no flag is specified
- Group by topic/project, not by source — users care about what happened, not where it happened
- Action items should always be listed first — they are the most actionable part of a digest
- Deduplicate cross-source activity (same decision in connected chat and email = one entry)
- For weekly digests, prioritize significance over completeness — highlight what matters, skip noise
- If the user has a memory system (your memories), use it to decode people names and project references
- Include enough context in each item that the user can decide whether to dig deeper without clicking through
