# Edge Add-ons listing: Casama for Edge

Everything Microsoft Partner Center asks for, ready to paste (plan §13, D-323 Phase 5). Edge runs
the Chrome package unchanged: same zip, same code, same permissions. Inside Edge the extension calls
itself "Casama for Edge" and says "Edge" where Chrome's copy says "Chrome" (`src/lib/browser.ts`).

**Submitted 2026-11-21** (version 0.1.0, In review, about 7 business days) from Oliver's Partner
Center account. Each new submission is a release: Oliver's yes each time (AGENTS.md).

| Edge item | Value |
|---|---|
| Product ID | `8bf15261-6f8c-40ad-a8e6-cf36378a68ab` |
| Store ID | `0RDCKCP6QHRC` |
| CRX ID (extension id in Edge) | `danikigkoiofpcecjobopcgdflgcmchm` |
| Dashboard | https://partner.microsoft.com/dashboard/microsoftedge/8bf15261-6f8c-40ad-a8e6-cf36378a68ab/packages/dashboard |

What Partner Center wanted that differs from the notes below: the support contact must be an email
(`support@casama.ai`, not a URL); the Privacy page asks the Chrome store's questions (single purpose,
a reason per permission including `identity` and `gcm`, remote code, data usage, privacy URL), so
copy them from `../listing.md`. The reviewer account (Vaultwarden "Casama · store review account")
has the bots "Anna" and "Casama", not "Researcher" and "Approver", so the notes sent use Anna and
drop the Approver step.

## Package

- `scripts/build-extension.sh` makes `apps/extension/dist/casama-chrome-<version>.zip`. Upload that
  same file. Don't rebuild for Edge.
- Edge gives the item its own id (Edge ignores the manifest key). Once the item exists, add that id
  to the server's `CHROME_EXTENSION_IDS` (production env) and to `chromeExtensionIds` in
  `client/lib/core/chrome_extension.dart`, so the web app's Connect Chrome and the API's CORS let it
  in (plan §19).
- What differs in Edge, handled in code: Edge has no `chrome.gcm`, so approval notifications come
  from the extension's once-a-minute check instead of pushes, and other news (routine results, bot
  messages) shows in the panel and the badge without a notification. The built-in model
  for on-device answers is Edge's own where present (the panel checks; hidden otherwise).

## Availability

| Field | Value |
|---|---|
| Visibility | Public |
| Markets | All markets |
| Pricing | Free (decision 4) |

## Properties

| Field | Value |
|---|---|
| Category | Productivity |
| Privacy policy | Yes: https://casama.ai/privacy#chrome (the section covers every browser) |
| Website | https://casama.ai |
| Support contact | support@casama.ai (Partner Center wants an email) |
| Mature content | No |

## Store listing (English)

| Field | Value |
|---|---|
| Display name | Casama (from `_locales/en/messages.json`) |
| Extension Store logo (300×300) | `store/edge/logo-300x300.png` |
| Small promotional tile (440×280) | `store/small-tile-440x280.png` |
| Large promotional tile (1400×560) | `store/marquee-1400x560.png` |
| Screenshots (1280×800, up to 10) | `store/screenshot-1-chat.png` … `store/screenshot-5-settings.png` |
| YouTube video | None yet |
| Short description | Your AI bots in your browser: ask about any page, save what matters, and answer what your bots need without leaving your tab. |
| Search terms (7 at most) | AI assistant, side panel, AI agent, summarize page, save to library, approvals, browser automation |

### Description

Paste the Chrome listing's description (`store/listing.md`, "Description") with three changes:

1. First line: "Casama for Edge connects your browser to your Casama bots."
2. "ON YOUR COMPUTER": "With Edge's built-in AI, where your Edge has it, summarize, explain or
   translate a selection without sending anything."
3. "STAY IN THE LOOP": "…from the panel or right from an Edge notification. The toolbar badge shows
   what's waiting. Edge checks for new approvals once a minute."

The pictures show Chrome's frame; Edge's reviewers accept them, and the panel is the same page.
Re-render in Edge later if wanted (plan §19).

## Submission options: notes for certification

```text
Casama for Edge needs a Casama account. Please use this test account on Casama Cloud:

  Email: <reviewer account email, from Vaultwarden "Chrome Web Store reviewer">
  Password: <from the same Vaultwarden item>

This is the same package as our Chrome Web Store item. The steps are the same as there:

1. After installing, the extension's Settings open. Tap "Agree and continue", pick "On all sites" (recommended), and tap Continue.
2. In another tab, sign in at https://app.casama.ai with the account above (Continue with Email, then Use a Password Instead). Open Settings, Sign In on Another Device, copy the sign-in link, and paste it under "Paste a sign-in link" in the extension's settings. (The "Use the web app" button works once our server knows this Edge item's id.)
3. Open any news article, select a sentence, and click the Casama button in the toolbar. The side panel opens. Type a question and press Enter: the reply streams in.
4. Library tab: tap "Markdown" to save the page.
5. Send "Ask me to approve something" to the "Approver" bot: an approval appears in the Inbox, and within a minute as an Edge notification with Approve and Deny buttons.

Bots in your browser (the debugger permission): in the panel's More tab, under "Your browser", tick the Researcher bot and press "Let bots use this browser". In the Researcher chat, send "In my browser, open https://example.com and tell me its heading", and allow example.com once. The bot works in its own collapsed tab group; the debugger is attached only to tabs in that group, while it works, and Edge shows its debugging bar.

What is read and when: a page is read only when the user sends a message, uses the menu or a shortcut, or saves. It never reads Casama's own pages or pages with password or card fields. "What was sent" under each message shows exactly what went with it. No remote code: bot steps arrive as data and the packaged code carries them out.
```

## Before each submission

1. `scripts/build-extension.sh`, the same zip as the Chrome Web Store submission.
2. Oliver's yes, then upload in Partner Center.
