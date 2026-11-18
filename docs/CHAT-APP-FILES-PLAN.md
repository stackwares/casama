# Files in chat apps: plan

Status: built (D-342, 2026-11-17). Links last 7 days; inbound files use the connector's daily allowance; iMessage files are in, pending a desktop build. Teams file consent and Telegram albums are left for later.

## 1. The problem

Oliver asked the bot for an image in Telegram on 2026-11-17. The bot made it (two JPEGs, 0.9 and
1.2 MB, are in `chat_media` for those runs), but only the reply's text went back to Telegram.
When asked for a link, the bot said it "can't give a URL", because it doesn't know it's in a chat
app at all.

The same gap exists everywhere, in both directions:

- **Out.** `replyToChannel` sends `finalMessage.text` only. None of the three kinds of file a
  reply carries reach any chat app:
  - media the bot generated (`chat_media` rows of the run: images, video, audio);
  - files on the bot's computer that the reply links to, copied into the Library
    (`KeptFile`, D-276);
  - Pages it published (`page` parts).
  Links to computer paths in the text (`[report](~/report.pdf)`) show as dead links.
- **In.** Eight adapters replace a photo, file or voice note with `ATTACHMENT_NOTE` ("doesn't
  come through yet"). The bot can't see a photo you send it or read a PDF you forward.
- **Context.** The bot isn't told the conversation is in Telegram, or that what it makes is
  delivered there.

## 2. What we build

### 2.1 Out: every file a reply carries, sent natively

`replyToChannel` collects the reply's files once:

- `chat_media` rows with the run's id (bytes via `readMedia`);
- the run's kept creations (bytes from the object store);
- `page` parts (sent as links, never as files).

It then sends them through a new adapter method:

```ts
sendFile?(cfg, secrets, reply, file: { name; mime; size; bytes; caption?: string }, f): Promise<string | null | void>
```

The rules:

- **Order:** the text goes first, then the files in reply order (the same order as in the app).
  On apps where a caption fits (Telegram 1024, WhatsApp 1024, Twilio 1600, Discord, Teams,
  email), a reply with one file and short text goes as one message with a caption.
- **Kind:** images go as photos (inline preview), video as video, audio as audio, everything
  else as a document. Telegram, WhatsApp and Messenger distinguish these.
- **Too big or not allowed** for the app (the per-app limits below): send a **link** instead (see
  2.2), with the file name and size. The file is never silently dropped.
- **Fail open:** a file that fails is logged in the chat app's Activity with the reason, and the
  link is sent instead. The text reply is never held back by a file.
- **Dead links in the text** (`[report.pdf](~/report.pdf)`) are rewritten before conversion. The
  file goes as an attachment, and the link text stays as plain words.
- **Limit:** at most 10 files per reply (Twilio's and Discord's cap). Any beyond 10 go as links.
- **Mirroring:** each sent file's message ref goes into `channel_message_links`, so reactions to
  it land on the reply (D-331).

### 2.2 Signed links, for what an app can't take

This is a new public route, `GET /files/{token}`. The token is an HMAC (key derived from
`INTERNAL_TOKEN`) over `media:<id>` or `creation:<id>@<version>` plus an expiry.

- **Expiry:** 7 days by default. The route serves the bytes with the right `Content-Type`,
  `Content-Disposition: inline; filename=…`, byte ranges, and the same CSP as `/v1/media`. An
  expired or forged token gets 404.
- **Who uses it:** Twilio MMS (`MediaUrl` must be public; Twilio re-checks the Content-Type),
  oversize files on any app, Teams files outside personal chat, iMessage until the Mac can send
  files, and Linear/Jira when an upload fails.
- **Privacy:** anyone holding the link can open the file until it expires. The link only ever
  goes to the person who asked, in their own chat. This is the same trade-off as
  `casama.link` share links. It goes in the chat apps guide's privacy note.
- **Revocation:** deleting the media or creation kills its links, because the route looks the
  row up.

### 2.3 In: files people send reach the bot

Adapters return attachments next to the text:

```ts
InboundMessage.files?: Array<{ name?; mime?; size?; fetch: Record<string, unknown> }>
```

Here `fetch` holds whatever that app needs (a Telegram `file_id`, a Slack `url_private`, a
WhatsApp media id, …). A new adapter method, `downloadFile(cfg, secrets, fetch, f)`, returns the
bytes.

`handleInbound` downloads each file and saves it to `chat_media`:

- columns: `uploaded_by` = the connector, `in_library` false, the conversation's id;
- each file is capped at 25 MB, at most 10 per message, and counted against the connector's
  daily attachment allowance (`DAILY_ATTACHMENTS`);
- the user message gets `file` parts (`path: media:<id>`, `uploaded: true`), exactly like a photo
  sent in the app.

From there everything already works:

- `loadImages` shows images to vision models;
- `partsText` lists the files for the model;
- `files.from_chat` copies one onto the computer.

The edge cases:

- **Download fails:** the message still starts the run, with a note naming the file and the
  reason ("too large for Telegram's 20 MB bot limit"), instead of today's generic note.
- **Voice notes** come in as audio files. If the bot's voice setup can transcribe, the
  transcript is added to the text so the bot can answer a voice note directly; otherwise the bot
  gets the file. This is phase 3.
- **Safety:** downloads go through `fetchOut` (egress rules), with the content type checked
  against the bytes. Slack's token is only ever sent to `https://files.slack.com`, with no auth
  on redirects. Each app's signature check on the webhook still gates everything.

### 2.4 The bot knows where it is

When a run's trigger is `channel`, the context gets one line, for example:

> This chat is in Telegram (from Ana). Images, videos, audio and files you make or link in your
> reply are sent into the chat automatically. Don't say you can't send files or links.

It also names what doesn't go through on that app (for example "SMS: files go as links").

## 3. Per app

| App | Out (native) | Out limits | Out fallback | In |
|---|---|---|---|---|
| Telegram | `sendPhoto` / `sendVideo` / `sendAudio` / `sendVoice` / `sendDocument`, multipart upload; caption 1024 | photo 10 MB, others 50 MB | link | `getFile` then download; 20 MB bot limit |
| Slack | `files.getUploadURLExternal`, then POST bytes, then `files.completeUploadExternal` with `channel_id` + `thread_ts`, `initial_comment` as caption | 1 GB | link | `url_private_download` + bot token (only to files.slack.com); needs `files:read` scope (docs + Casama's Slack app) |
| WhatsApp | `POST /{phone}/media` upload, then message by `id`; caption on image, video, document | image 5 MB (JPEG/PNG/WebP), video 16 MB (MP4), audio 16 MB, document 100 MB (PDF/Office/TXT) | other types, or too big: link | `GET /{media_id}` gives a URL valid 5 min, then download with the token; 100 MB |
| Messenger | `POST /me/messages` multipart `filedata`, attachment type image / audio / video / file; text as its own message | 25 MB | link | `attachments[].payload.url`, downloaded at once |
| SMS (Twilio) | `MediaUrl` = signed link (2.2); `Body` as caption | 5 MB total; images 5 MB, others 500 KB; MMS only in US/CA/AU | outside MMS countries Twilio's converter sends a short link; we send our link in the text when over the limits | `MediaUrl{N}`, Basic auth with SID and token |
| Email (Resend) | `attachments[]` as base64 `content`; images also shown inline via `cid:` in the HTML body | 40 MB per email after base64 | link | `GET /emails/receiving/{id}/attachments` gives `download_url` (valid 1 h) |
| Feishu | `POST /im/v1/images` then `msg_type:image`; `POST /im/v1/files` then `msg_type:file` | images 10 MB, files 30 MB | link | `GET /im/v1/messages/{id}/resources/{key}?type=image\|file` |
| Teams | images ≤ 1 MB and 1024 px as base64 data URI attachment; other files as a link (FileConsentCard flow is phase 3, personal chat only) | 1 MB inline | link | personal chat: `downloadUrl` (no auth); pasted images: `contentUrl` + Bearer |
| Discord | multipart `files[n]` + `payload_json` on the followup or channel message | 20 MiB (or the interaction's `attachment_size_limit`) | link | `/ask` gets an optional attachment option, `data.resolved.attachments`; CDN URL, no auth |
| Linear | `fileUpload` mutation, PUT, then `![](assetUrl)` / `[name](assetUrl)` in the comment | not stated | link | uploads.linear.app URLs in issue/comment markdown + Bearer |
| Jira | `POST /issue/{key}/attachments` (`X-Atlassian-Token: no-check`), then a media node or link in the comment | site setting (`/attachment/meta`) | link | attachment ids on the issue/comment, `GET /attachment/content/{id}` |
| iMessage | link for now (the Mac's `/imessage/send` takes text only); native files need a desktop app change: phase 3 | – | link | phase 3 (the Mac reads attachment paths from chat.db) |

Pages are always links (`https://…/p/<id>` or the published address), on every app.

## 4. Phases

1. **Out + context (the bug Oliver hit).** Covers:
   - collecting reply files, `sendFile` for Telegram, Slack, WhatsApp, Messenger, email, Feishu,
     Discord, Teams (images), Linear and Jira;
   - signed links and the `/files/{token}` route, with Twilio MMS on top;
   - rewriting dead computer links, and the chat app line in the bot's context (2.4);
   - Activity rows for sent and failed files.
2. **In.** `files` on `InboundMessage` and `downloadFile` for every adapter that receives files;
   saving to `chat_media`; real notes when a download fails; Discord's `/ask` attachment option;
   Slack's `files:read` scope in docs and Casama's Slack app.
3. **Extras.** Voice-note transcripts; Teams file consent in personal chat; native files in
   iMessage through the Mac (desktop app build); Telegram `sendMediaGroup` for several images as
   one album.

Each phase is server-only except phase 3's iMessage part. Each needs a production deploy (ask
first), and no app build.

## 5. Tests

- `packages/agent/test/channels.test.ts`: per adapter, what `sendFile` sends (method, field
  names, kind by MIME type, caption), the size and type limits falling back to a link, and
  `downloadFile` against recorded payloads.
- `apps/server/test/channels.test.ts`, against the fake provider:
  - a run with a generated image replies with `sendPhoto` after the text;
  - a too-big file becomes a signed link that downloads, and expires and forged tokens get 404;
  - a Telegram photo message saves `chat_media` and the run's message has a `file` part;
  - a download over the limit still starts the run, with the reason;
  - strangers' files are never downloaded.
- pgTAP: no new tables (`chat_media` already allows the worker). If a table for signed-link
  revocation turns out to be needed, it gets `allow_worker` and RLS tests.

## 6. Open questions for Oliver

1. Signed links last **7 days**. Shorter (24 h) is more private; longer helps people who come back
   to an old chat. 7 days is the proposal.
2. Inbound files count against the **connector's daily attachment allowance** (300 files and
   1 GB a day). Same as the app, or separate?
3. Phase 3's **iMessage** needs a desktop app change and a Mac build. Keep it in this track or
   later?
