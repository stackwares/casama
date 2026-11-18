# The launch video: plan

Status (2026-11-18): **rough cut v2 of the hero is built**:
`Marketing/casama/out/review/launch-hero-roughcut-v2.mp4`, 68.5 s, made from real build 37 captures.
How to capture more: `Marketing/casama/showreel/capture/CAPTURE.md`. **The 30-second fast cut (§15)
is built too (v1)**: `Marketing/casama/out/review/launch-fast-16x9-v2.mp4` and `launch-fast-9x16-v1.mp4`,
plus the 15-second bumper in both shapes (`launch-bumper-*-v1.mp4`). Music and sound effects are made
in code; there's no voice.

Oliver picked hero v2 over the other cuts; it has a 9:16 version too
(`launch-hero-roughcut-v2-9x16.mp4`). **Hero v2 is on casama.ai (D-390), in 16:9 only:** the hero's
"Watch the film" opens it, and "See it at work" plays it muted while it's on screen. The fast cut and
the 9:16 hero are for social posts only. The web masters, without the corner label, are in
`Marketing/casama/out/web/en-US/`; the encoded copy is in `site/assets/film/`.

Decided so far:
- The bots' computers are recreated in code; Casama's own screens stay real (§2a).
- The cast is Anna, Oliver, Max, Rome and Kelly.

The decisions in §12 and §15 are settled, except the launch date (§12 #13). Platform limits in §3
were checked on 2026-11-18. Most of them come from third-party spec pages, so check them again before
export (sources at the end).

## 0. Summary

One launch film made to be shared on social media, plus cutdowns of it for each platform. It answers
the one question a stranger scrolling past has: *what is this, and why would I want it?* The answer is
the line on casama.ai: **AI teammates with their own computers.**

The film is built around the one thing nobody else shows well: **a bot working on a real computer of
its own while you watch.** It opens on a cursor moving with nobody's hand on it, then a real bot does
real work. It books a trip and waits for your OK before paying. It sends a morning brief, answers
customers, and builds a game that lands in the Library. It closes on "open source, one script, any
model" for the developer crowd.

| Cut | Shape | Length | For |
|---|---|---|---|
| **Hero** | 16:9, 1920×1080 (4K master) | about 60–65 s | YouTube, X, LinkedIn, Product Hunt, Show HN, casama.ai, README, Play promo |
| **Vertical** | 9:16, 1080×1920 | about 30 s | Reels, TikTok, YouTube Shorts, X on phones |
| **Feed** | 4:5, 1080×1350 | about 45 s | LinkedIn, Instagram and X feeds |
| **Teasers** (4) | 9:16 and 16:9 | 8–15 s each | build-in-public posts in the days before launch |
| **Loop** | 16:9, silent | 8–10 s | top of the README and casama.ai |
| **Dev cut** (optional, §12 #10) | 16:9 | about 90 s | Show HN, r/selfhosted, r/LocalLLaMA; the first SEO how-to |

Casama's own screens are real captures of the app with demo data. What happens on the bots'
computers is recreated in code (§2a), so those shots are sharp, on the beat and the same every time.
The dev cut is all real, in one unbroken take, for anyone who wants proof.

## 1. What exists today

| What | Where | Use for the film |
|---|---|---|
| A 13.5 s draft clip of the app flow (590×1282, Phase 8) | `docs/media/demo-app-flow.mp4` | Too small and too old. Replaced by this film |
| Framed and raw screenshots, light and dark, Mac/iPhone/iPad/web | `docs/media/screenshots/` (+ `README.md`) | Animatic stand-ins (§9, phase 1). They show the old bot names (Ada, Milo, Nova, Juno) |
| Demo workspace "Maya's space" on the local dev stack | local Supabase | Becomes the film's world, renamed to the D-382 bots |
| Demo cast picked by Oliver (2026-11-18): Anna, Oliver, Max, Rome and Kelly, all from the D-382 name list | `packages/domain/src/templates.ts` (`BOT_NAMES`) | The film's cast. Names only: they needn't match the starter bots' jobs in the app |
| Animated mascot SVGs, 13 moods (winky, starry, wow…) | `client/assets/bots/*-animated.svg` | End card and transitions |
| Painted art in the casama.ai style, made with gpt-6-luna, plus its brief and rules | `visuals/`, `visuals/BRIEF.md`, `docs/VISUALS-PLAN.md` | Backgrounds for the title and end cards |
| Launch drafts (Show HN, Product Hunt, Reddit, X thread) that all wait on "the 60-second demo" | `docs/launch/` | The film plugs into these |
| "A 60-second narrated demo video" on the needs list | `docs/NEEDS-FROM-OLIVER.md` | This plan answers it |
| SEO plan wants a 60-second demo and three how-to videos on YouTube, and VideoObject data once a video exists | `docs/SEO-PLAN.md` | The hero is the demo; the dev cut is how-to #1 |
| **Marketing hub**: the one home for promo video tooling. Casama isn't registered there yet | `~/Desktop/Projects/Marketing` | The film's project lives there (§12 #1) |
| Remotion promo project to copy (one timeline, many sizes, per-locale copy, safe renders, synthesized music) | `Marketing/nexsnap/showreel/` | Starting point for `Marketing/casama/showreel/` |
| Gemini text-to-speech and voice-over tools, with Whisper word timings for captions | `Marketing/foodscanner/short-form-content/scripts/` (`tts_gemini.py`, `vo.sh`) | Scratch voice for the animatic; caption timing |

## 2. Rules

- **Casama's screens are real.** Every shot of Casama itself is a capture of the shipping app: chat,
  approval cards, notifications, the Library, and the computer panel's frame and status lines. Only
  the desktop inside the computer panel is recreated (§2a).
- **The recreated computer stays truthful.** It never does anything a real bot can't. It shows the
  same staged sites the real runs used, and the counts in the panel come from a real run.
- **Only what's live at launch.** The homepage's "Coming soon" features stay out: the Mac notch and
  menu bar, Lock Screen and Dynamic Island live progress, Casama for Chrome, sites at their own address
  and domains, minimized calls, and local models that read pictures. If any of them ships before the
  launch, beat 10 gets recut to show it (§12 #11).
- **Sped up says so.** Real footage that runs faster than real time carries a small "Sped up" chip
  (the dev cut).
- **Demo data only.** No real inboxes, accounts, names or cards. The booking uses a fictional site and
  the test card ending 4242. Notification previews show only demo names.
- **Claims come from the README and casama.ai copy.** Costs and counts on screen are what the app
  showed in that run.
- **Generated art only behind things.** The painted skies follow `visuals/BRIEF.md`: no text, no UI, no
  mascot. Type and the real mascot SVG go on top.
- **Made for muted autoplay.** Every cut works with the sound off: captions are burned in, and the
  story reads without the voice.

## 2a. Real or recreated (decided 2026-11-18)

Oliver asked whether some shots could be mockups, such as the computer doing work, and left the call
to me. The rule: **Casama is real, the bot's computer is recreated.**

| Shot | Made how | Why |
|---|---|---|
| Casama's screens: chats, the approval card, notifications, the brief, the Library, the computer panel's frame and status | **Real captures** of the launch build, demo workspace | This is what people get when they install. Faking it would be a false promise, and it's easy to capture cleanly |
| The desktop inside the computer panel, and the full-frame computer shots (beats 1, 4, 8, 9) | **Recreated in code** in Remotion: a Linux desktop and browser drawn in code, with the cursor and typing scripted to the music | The live view is a compressed stream and looks soft full-screen. Real runs wander and never land on the beat. The content is a desktop and websites, not Casama's own UI, and bots really do work this way |
| The game in beat 8 | **Real**: the game a bot made, recorded playing at full size | It's a real thing a bot made, and it's easy to record sharp |
| The terminal in beat 11 | **Real** install output, redrawn crisp from an asciinema recording | Same words and timing as a real run, just sharper |
| The dev cut | **All real**, one unbroken take, with the live view as it is | Proof for the skeptics. It also covers the recreated shots |

**How the recreated computer stays true:**
- The staged sites (§7) are built once as React components. They go live for the real runs, and
  Remotion draws the same components for the recreated shots, so the film shows exactly what the
  bot saw.
- The panel's real status lines ("41 flights and 18 hotels checked", "Checkpoint 7 saved") come from
  the real run of the same task.
- No on-screen "illustration" label. That's normal for a launch film, and the recreated shots don't
  make any claim the product can't keep. The YouTube description says: *"Casama's app is shown as it
  is. What's on the bots' computers is recreated for clarity. Here's an unedited run: [dev cut]."*
  The Marketing README says so too, as the hub's rules require.
- Apple's App Previews must be screen captures, so a later store cut uses real live-view footage
  there instead (§10).

What it buys:
- The riskiest part of the plan (repeatable, good-looking real runs) becomes one good run per scene.
- Sharper shots, timed to the music.
- Fewer model calls.
- The rough cut can already use the real recreated scenes, so it looks close to final early.

## 3. What the platforms allow

| Platform | Length | Shape | File | Notes |
|---|---|---|---|---|
| X (no Premium) | 2 min 20 s (one source says 20 min) | 16:9, 9:16 or 1:1; web upload up to 1920×1200 | 512 MB (one source says 2 GB) | Stay under 2:20 and 512 MB; the sources disagree, so take the lower numbers |
| YouTube | long | 16:9; 4K accepted | large | Main home for the hero. Chapters, captions file, thumbnail |
| YouTube Shorts | up to 3 min | 9:16 or 1:1, up to 1080p | — | A 16:9 video is not a Short |
| Instagram Reels | up to 20 min; over 3 min isn't shown to new audiences | 9:16 1080×1920 (4:5 for feed) | — | Keep text out of the top 14 %, the bottom 35 % and 6 % on each side |
| TikTok | 10 min by API, more by app | 9:16 1080×1920 | — | Keep text out of the top 12.5 %, the bottom 34 % and the right-hand button column |
| LinkedIn | 3 s to 15 min | 16:9 1920×1080, or 4:5 1080×1350 on phones | 5 GB | Autoplays in the feed |
| Product Hunt | not stated | not stated | — | Added "by link" in the launch media box; video is optional |
| Google Play promo | first 30 s autoplay, muted | landscape | — | Must be a public or unlisted YouTube video, embeddable, with monetization off |

What this means for the cuts: a 60–65 s hero fits everywhere. The vertical and feed cuts are laid out
again for their shape, not cropped from the hero. The hero's first 30 seconds must work alone, both for
Google Play and for people who stop watching early.

## 4. The story

**Working title:** *Its own computer.*

**The hook (first 3 seconds):** a full-screen desktop. A browser is open, the cursor moves and types,
and nobody is touching the mouse. Caption: *"Nobody's touching this mouse."* Nobody else in this space
can open this way honestly, and it makes people stop scrolling.

**The arc:** meet a bot → give it a job → watch it work → it asks before the risky part → it already did
other things for you → it makes real things → you're in charge → it's everywhere → it's open source.

## 5. The hero cut, shot by shot (about 65 s)

The words below are both the captions and the voice (if there is a voice, §12 #3). The caption is
shortened where it has to be.

| # | Time | Picture | Words | Sound |
|---|---|---|---|---|
| 1 | 0:00–0:03 | Full frame: a bot's desktop (recreated), a browser, the cursor moving and typing on its own | *Nobody's touching this mouse.* | keys, clicks; a low pad starts |
| 2 | 0:03–0:07 | Pull back: it's the live computer panel in the Casama Mac app. Anna's chat on the left, "Working on her computer" | *That's Anna. She's an AI teammate, and this is her computer.* | |
| 3 | 0:07–0:13 | iPhone: Maya dictates, *"Find flights to Lisbon for May 8 to 12 and a hotel in the old town, under $1,200."* It sends | *Ask for anything, the way you'd ask a person.* | |
| 4 | 0:13–0:20 | Anna's computer (recreated), quick cuts: tabs, comparing, a form filled in. The real panel shows "41 flights and 18 hotels checked", "Checkpoint 7 saved" | *She uses real apps, on a computer of her own.* | music builds |
| 5 | 0:20–0:27 | The phone buzzes: *"Anna needs your OK. Book both for $1,104 with your card ending 4242."* Approve / Deny and roll back. A thumb taps Approve | *Booking, paying, sending or deleting waits for your OK. Deny undoes the work.* | a soft haptic tick |
| 6 | 0:27–0:33 | 07:31, a notification from Oliver; open it: the morning brief with its sources cited | *Oliver wakes before you do, and your brief is waiting.* | |
| 7 | 0:33–0:39 | Kelly's General chat: "Answered 23 customer emails. One $48 refund waits for your OK." | *Kelly answers your customers, and asks before any refund.* | |
| 8 | 0:39–0:46 | Max's computer (recreated) building a game, then the real game playing; it lands in the Library; a share link is copied | *They make real things: sites, games, reports, videos. All kept in your Library.* | |
| 9 | 0:46–0:51 | Take control in the real panel: Maya's cursor takes over Anna's (recreated) desktop and does one step; "Saved as a skill" | *Take over anytime. Show it once and it remembers.* | |
| 10 | 0:51–0:55 | Fast montage: the same chat on iPhone, iPad, Android, Mac, web and a terminal | *On your phone, your computer, the web and the terminal.* | |
| 11 | 0:55–1:00 | A terminal: `./install.sh --local` … Casama is up. "Open source · AGPL-3.0" | *Open source. Run it free on your own server, with any model. Or start free on Casama Cloud.* | |
| 12 | 1:00–1:05 | End card on a painted sky: the mascot floats in and winks; wordmark; *AI teammates with their own computers.*; casama.ai | | music resolves |

Two lines that could be cut if it runs long: beat 7 (Kelly) and beat 10 (the montage).

## 6. The other cuts

**Vertical (about 30 s, 9:16).** The phone leads and the bot's computer floats over it as a picture in
picture. Beats 1 (cropped tall), 3+4, 5, 8, 11 (one line) and 12. All text sits inside the Reels and
TikTok safe zones from §3.

**Feed (about 45 s, 4:5).** The hero laid out again for 4:5, without beats 7 and 10.

**Teasers (8–15 s each, 9:16 and 16:9).** One idea each, to post in the week before launch:
1. *Its own computer* (beats 1–2)
2. *It asks first* (beat 5)
3. *Your brief at 07:31* (beat 6)
4. *Open source, one script* (beat 11)

Each ends on the end card with "Launching [date]".

**Loop (8–10 s, silent).** Beats 1–2 and 4, looping seamlessly. MP4 and WebM under about 3 MB, plus a
poster image.

**Dev cut (about 90 s, optional).** One continuous, lightly sped-up take: a clean machine, `git clone`,
`./install.sh --local`, the app connects to the server, add a model key or Ollama, make a bot, and it
opens its computer. This is what Show HN and r/selfhosted readers want to see, and it's the first of
the SEO plan's three how-to videos.

## 7. The demo world

The film needs runs that come out the same way take after take.

- **Workspace:** "Maya's space" on the local dev stack, with the demo cast: Anna, Oliver, Max, Rome
  and Kelly. Renamed in place on 2026-11-18 (Nova → Rome, Juno → Anna, Ada → Oliver, Milo → Max; Kelly
  is new), so the existing Kyoto plan, research report, game and bakery site stay usable. It gets a short history so the chats don't look empty: a few earlier
  results, a Library with real things in it, and a brief from yesterday.
- **Staged sites** for the bots' computers to really use, served from the local stack: a fictional
  travel site for Anna's booking (flights, hotels, a checkout that takes the 4242 test card), and a
  fictional shop with a help desk for Kelly. No real airlines, hotels or brands appear, and nothing
  gets booked. The computers' egress proxy blocks private addresses, so the staged sites get a public
  `-dev` hostname through the existing tunnel (local stack, not production). The sites are React
  components that Remotion also draws for the recreated computer shots (§2a).
- **One good real run per scene.** It gives Casama's screens their real content: Anna's reply and
  approval card, Kelly's result, the panel's status lines. We change the instructions and run again
  until the result reads well; there's no need to repeat takes for the computer itself.
- **A seed script** (`Marketing/casama/captures/seed-demo.mts`, using the TypeScript client) sets up
  the workspace and its history. It only ever touches that demo workspace through the API; the local
  database is never reset.

## 8. How it's made

| Part | How |
|---|---|
| **Project** | `Marketing/casama/` in the hub (register `casama` in `registry.json`): `copy/en-US.json` holds every line, `captures/` the takes with provenance in `captures/README.md`, `art/` the painted backgrounds, `showreel/` the Remotion project copied from `nexsnap/showreel`, `out/web/en-US/` the deliverables |
| **Mac shots** | The Mac app from the launch build, signed into the local server, recorded at 2× (Retina) so the 4K master can zoom in |
| **Phone shots** | iPhone simulator with the status bar at 9:41, driven and recorded through the device tools; or a real iPhone recorded by Oliver (§12 #8) |
| **The bot's computer** | Recreated in Remotion (§2a): a desktop and browser drawn in code, showing the staged sites' own components, with scripted cursor paths and typing. It's dropped into the real computer panel from the Mac captures, or shown full frame. Sharp at 4K |
| **Terminal** | Recorded with asciinema and drawn as crisp text in Remotion, so it stays sharp at any size |
| **Edit and motion** | One Remotion timeline drives every cut. Each shape has its own layout. Device frames, slow push-ins, captions and the "Sped up" chip are built in code |
| **Painted art** | 3–4 new skies from gpt-6-luna for the title, end card and teaser backgrounds, made the way `visuals/BRIEF.md` says |
| **Mascot** | The real animated SVG (winky) on the end card; starry or wow for transitions |
| **Voice** | Oliver records the final voice (§12 #3); Gemini TTS is the scratch voice for the animatic. Whisper word timings drive the captions |
| **Music** | A score built in code, like NexSnap's (`scripts/music.ts`), timed to the cuts; a licensed track if it falls flat (§12 #4) |
| **Mix and export** | −14 LUFS, −1 dB true peak. H.264 + AAC, 30 fps. 4K master for YouTube; 1080p files for social. An SRT captions file for YouTube, LinkedIn and X |
| **Rendering** | Full renders go through `scripts/heavy.sh`, with Remotion concurrency at 4 at most, because this Mac is shared |

**Deliverables** in `Marketing/casama/out/web/en-US/`: `launch-16x9-3840x2160.mp4` (master),
`launch-16x9-1920x1080.mp4`, `launch-9x16-1080x1920.mp4`, `launch-4x5-1080x1350.mp4`,
`teaser-<n>-<WxH>.mp4`, `loop-16x9.{mp4,webm}`, a poster `.jpg` for each, and `launch.en-US.srt`.

## 9. Phases

| Phase | Work | Done when |
|---|---|---|
| **0. Plan** | This document; your answers to §12 | Decisions are settled |
| **1. Script and animatic** | Lines into `copy/en-US.json`; scaffold the Remotion project; a rough cut from the existing screenshots, a scratch TTS voice and scratch music; a review page | You've approved the pacing and the words. Nothing has been captured yet, so changes are cheap |
| **2. Demo world** | Rename and fill the workspace, build the staged sites as React components, write the seed script, then one good real run per scene | Each scene's real run has produced the Casama screens we want |
| **3. Captures** | Launch builds of the Mac and iOS apps (each build needs your yes), then recording Casama's screens, the real game and the terminal | Every real shot in §5 has a take you're happy with |
| **4. Edit and motion** | The recreated computer kit (desktop, browser, cursor, typing), then the hero, then the vertical and feed layouts; captions, the painted end card | The hero picture is locked |
| **5. Sound** | Music, your voice session (about 15 minutes, a quiet room and a phone or USB mic), effects, the mix | The final mix is approved |
| **6. Cutdowns and exports** | Teasers, the loop, posters, SRT; hub checks | All files pass the checks and you've approved every cut |
| **7. Launch kit** | A posting kit in `docs/launch/video.md` (a caption per platform, YouTube title, description and chapters, thumbnail). Then, each only after your yes: YouTube upload (unlisted first), README embed, casama.ai embed with VideoObject data (a web deploy), and the Play promo link | The kit is ready and the links work. The posting itself stays your call, as for the other launch drafts |

## 10. What we're not making

- **Store App Previews** (15–30 s, Apple's sizes and rules). They can be cut from the same Casama
  footage later, under `/store-assets casama preview`. Apple wants screen captures, so they'd show the
  real live view in place of the recreated desktop. Not part of the launch.
- **Live action and actors.** No people on camera; a founder talking-head intro would be a separate
  piece.
- **Translations.** English only for launch. The copy file supports other languages later.
- **Paid promotion.** This plan makes the files; it doesn't buy any ads.
- **An AI-generated video of the app.** Video models can't show our real screens faithfully. They'd
  show a product that doesn't exist. AI helps around the real footage instead: the painted skies,
  the scratch voice, caption timing, and maybe one moving sky made with Casama's own video tool.

## 11. Cost and time

### Cash

| Item | Cost | Notes |
|---|---|---|
| Model calls for the real runs | $5–15 | About 10–15 real runs (one good run per scene, plus retries and the dev cut) at $0.20–1 each on the local stack's OpenRouter key. Computer-use runs read a lot of screenshots |
| Bot computers | $0 | Docker on this Mac |
| Scratch voice (Gemini TTS) | under $1 | About $0.01 a minute of speech (`docs/COSTS.md`) |
| Caption timings (Whisper) | $0 | `mlx-whisper` runs on this Mac, as in the hub's `vo.sh` |
| Painted skies (gpt-6-luna) | $0 extra | Uses the Codex plan's allowance, one image per task as before |
| Music made in code | $0 | |
| Remotion | $0 or $25 a month | Free for an individual or a company of up to 3 people; otherwise a Creators seat at $25 a month. The hub's other Remotion projects would need that too |
| YouTube and the social sites | $0 | |
| **Total** | **about $5–15** | |

Optional:

| Item | Cost | Notes |
|---|---|---|
| A licensed music track (§12 #4) | about $17–50 for a month of a plan | For example Epidemic Sound, whose tracks don't get Content ID claims. Third-party price reports disagree, so check its pricing page. Goes into `docs/COSTS.md` first |
| A moving painted sky on the end card, made with Casama's own video generation | about $2–3 | Gemini Omni Flash 1.2 at $0.07 a second (`docs/COSTS.md`), 8 s, a few tries. That shot is then made with Casama |
| A USB mic for the voice | optional | A phone held close in a quiet room is fine for 60 seconds |

The bigger spend is agent time on your Claude plan: the project is just under two weeks of working
sessions.

### Time

| Phase | Agent work | Your time |
|---|---|---|
| 1. Script and animatic | 1 day | one review, 30–45 min |
| 2. Demo world | 1 day | none |
| 3. Captures | 1 day | a yes to two builds; 15 min for a real-iPhone shot if needed |
| 4. Edit and motion | 4–5.5 days (computer kit 1–1.5, hero 2–3, vertical and feed 1) | two reviews, 30–45 min each |
| 5. Sound | 1–1.5 days | 30 min recording the voice |
| 6. Cutdowns and exports | 1–1.5 days (+0.5 for the dev cut) | the final review, 30 min |
| 7. Launch kit | 0.5 day | a yes to each upload and deploy, then the posting |
| **Total** | **about 9–12 working days** | **about 3–4 hours** |

- **Calendar:** about 2–2.5 weeks including waits for your reviews.
- **Fast track:** the hero and the vertical cut only, with captions and code-made music, and no
  teasers or dev cut. About 5–6 working days, or a little over a week.
- **Recreating the computer (§2a)** saves about a day overall: phases 2–3 shrink and phase 4 grows.
  The bigger gain is that the riskiest part is gone and the shots look better.
- **Renders (estimate):** a full set (the 4K master and three 1080p cuts) takes about an hour on this
  Mac (M2 Max) at concurrency 4, longer if the `heavy.sh` queue is busy. Half-size drafts take
  minutes.
- **Biggest unknown:** how many rounds the motion polish takes (phase 4).

## 12. Decisions for Oliver

On 2026-11-18 Oliver left these to me ("You decide all for me"). Each recommendation below is now the
decision, except the launch date (#13), which only he can set. The fast cut has no voice (§15 F4); the
hero keeps his voice as the plan (#3), with the scratch voice until he records.

| # | Question | Decision |
|---|---|---|
| 1 | Where does the project live? | `Marketing/casama/` in the hub. Its rules say promo tooling and renders stay out of app repos, and NexSnap's project gives us a head start. Only web-sized files come back into this repo |
| 2 | How long is the hero? | About 60–65 s. It matches "the 60-second demo" every launch draft asks for, and it fits every platform |
| 3 | Whose voice? | Yours on the hero, and captions on every cut. A founder's voice reads as real at a launch. Gemini TTS for the animatic only (it may also say "Casama" wrong, as it did with "Kaon"). Other choices: a TTS voice in the final, or captions and music only |
| 4 | Music? | Start with a score made in code: we own it, it costs nothing and no one can claim it. If it falls flat on the animatic, buy one licensed track whose license allows YouTube use without Content ID claims |
| 5 | Staged sites for Anna's booking and Kelly's help desk? | Yes. No real brands or logos on screen, nothing really booked, and every take comes out the same |
| 6 | Show Slack, WhatsApp and other chat apps on screen? | No third-party UI or logos. The montage names them in text. It avoids brand-permission questions, and Kelly's beat works inside Casama |
| 7 | Light or dark app? | Light, to match casama.ai where people land after watching. The terminal beat stays dark |
| 8 | Capture from a fresh launch build? | Yes: Mac and iOS from current main (each build needs your yes), because D-380's Plain theme and D-383 change how the app looks. For the phone: the simulator, with your real iPhone for the notification shot if the simulator's push looks wrong |
| 9 | People on camera? | None. Screen, motion and voice only |
| 10 | Make the 90 s dev cut too? | Yes, after the hero. HN and r/selfhosted readers trust a single unbroken install take more than a polished film, and it doubles as the first SEO how-to video |
| 11 | Coming-soon features? | Leave them out. If any ships before the launch, recut beat 10 to show it |
| 12 | The video on casama.ai? | A YouTube embed that loads only when someone clicks play (no YouTube scripts on page load), and the silent loop as a small file. No big MP4s in the repo |
| 13 | When is the launch? | Needed to plan backward. The teasers say "Launching [date]" |
| 14 | Real footage or mockups for the bots' computers? | **Decided** (Oliver left it to me, 2026-11-18): the computers are recreated in code, Casama's screens are real, and the dev cut is all real (§2a) |

## 13. Risks

| Risk | What we do |
|---|---|
| Someone asks "is that real?" about the computer shots | The YouTube description says what's recreated and links the unedited dev cut. The recreated shots show the same sites and counts as the real runs (§2a) |
| A real run doesn't produce a clean result for a scene | Change the instructions and run it again. Only the end result on Casama's screens matters |
| The app changes between capture and launch | Capture last, from the launch build. The animatic lets editing start before that |
| The Mac is busy with other sessions' work | Full renders queue through `scripts/heavy.sh`; draft renders stay small |
| A music claim on YouTube | Music made in code, or a license that rules out Content ID claims |
| Platform limits change, or the sources are wrong (X's numbers already disagree) | Check each platform's own help page again before exporting; we already take the lowest numbers |
| A claim the product can't back up | Every line traces to the README or casama.ai; no coming-soon features |
| Personal data on screen | Demo workspace only; check every frame of the final cut before publishing |

## 14. How we'll know it worked

YouTube views and how far people watch (the 30-second mark matters most), shares and replies on X and
LinkedIn, Product Hunt and Show HN traffic, casama.ai visits from social sites (the site already counts
the referring site's type, D-381), and sign-ups in the days after.

## 15. The fast cut (proposal, 2026-11-18)

Asked for after rough cut v2: "more energetic, and maybe shorter". The decisions below are settled.
**Built 2026-11-18 (v1):** `Marketing/casama/showreel/src/fast/` (grid, kit, scenes) and
`scripts/music-fast.ts`; how to run and render it is in `Marketing/casama/README.md` → "Fast cut and
bumper".

It tells the same story in **30 seconds**, cut to a **120 BPM** beat. Big words punch in on the beat,
so it works with the sound off, which is how most feeds play video. A **15-second bumper** comes from
the same timeline. The fast cut takes the place of the 30-second vertical cut in §6, and the teasers
can be cut from it.

| Cut | Shape | Length | For |
|---|---|---|---|
| **Fast** | 16:9 1920×1080 and 9:16 1080×1920 | 30 s | X, LinkedIn, Reels, TikTok, Shorts |
| **Bumper** | 9:16 and 16:9 | 15 s | teasers before launch, replies, ads later |

### What changes from the hero

| | Hero (rough cut v2) | Fast cut |
|---|---|---|
| Length | 68.5 s, 12 scenes | 30 s, 15 bars |
| Pace | 4–8 s a scene; the voice sets it | every cut lands on the beat: 1–2 s a shot, 1 s in the montage |
| Words | spoken, plus a full-sentence caption | no voice; lines of 2–5 words that punch in a word per beat |
| Music | soft pad, one chord per scene | 120 BPM drive: kick, off-beat hats, bass, risers, a drop at 0:02, a stop-hit for the logo |
| Motion | slow push-ins and fades | snap zooms with motion blur, whip pans, a small scale punch on each downbeat, speed ramps on the computer |
| Sound | clicks in the hook | a whoosh on every cut, taps, typing, a ding on Approve, a hit on the logo |

Why 120 BPM: at 30 fps, a beat is exactly 15 frames and a bar is 2 seconds, so every cut lands on a
whole frame and 15 bars come to exactly 30 seconds.

### Shot list (16:9; the 9:16 version lays out the same beats again)

| Bars | Time | Picture | Words (one word or phrase per beat) | Sound |
|---|---|---|---|---|
| 1 | 0:00–0:02 | Full-frame recreated desktop: the cursor zips to the To field, types "Lisbon" in a blink, and the dropdown pops | *Nobody's / touching / this / mouse.* | riser, typing, filter opening |
| 2 | 0:02–0:04 | **Drop.** A snap zoom out (8 frames, blurred) to the real Casama window with Anna working | *Anna. / An AI teammate.* | kick comes in |
| 3 | 0:04–0:06 | The phone slides in on beat 1. The real ask bubble pops on beat 2, "On it" on beat 4 | *Ask like you'd ask a person.* | pops |
| 4–5 | 0:06–0:10 | The computer at speed, a cut every 2 beats: flights, hotels, the seat, Review and pay. A counter chip ticks up | *41 flights. / 18 hotels.* | hats double |
| 6 | 0:10–0:12 | The phone: the banner drops (beat 1), the real Needs you card (beat 2), a thumb taps Approve (beat 3), ✓ (beat 4) | *Pays only with your OK.* | tap, ding |
| 7–9 | 0:12–0:18 | Rapid fire, 1 s a shot, each zoomed to the one thing it shows: Oliver's brief (phone), Kelly's inbox, Max's game, Rome's Kyoto map, Sam's birthday group, the Library (phone) | one label a shot: *Morning brief. / 23 emails answered. / A game, built. / Kyoto, mapped. / A party, planned. / All in your Library.* | a whoosh per cut |
| 10 | 0:18–0:20 | Take Control is tapped (beat 1), you're in control, "Saved as a skill" (beat 4) | *Take over anytime.* | |
| 11 | 0:20–0:22 | Phone, computer, web and terminal slam in, one per beat | *Phone. / Computer. / Web. / Terminal.* | four hits |
| 12 | 0:22–0:24 | The terminal: `./install.sh --local` types in one beat and the lines cascade | *Open source. / Any model.* | |
| 13 | 0:24–0:26 | A riser under a flash recap, one beat each: Anna's computer, the Approve tap, the game, the map | — | riser |
| 14–15 | 0:26–0:30 | The end card hits on bar 14's downbeat: the mascot pops in and winks, then the wordmark, the line and casama.ai. Bar 15 holds | *AI teammates with their own computers.* | stop-hit, then it rings out |

**Bumper (15 s, 7.5 bars):**

| Bars | Scene |
|---|---|
| 1 | hook |
| 2 | reveal (the drop) |
| 3 | the computer at speed, one cut per beat |
| 4 | Approve |
| 5–6 (to mid-bar 6) | rapid fire: brief, game, Kyoto |
| last 2 bars | the end card |

### The 9:16 layout

- **Phone shots** fill the height of the frame.
- **Desktop shots** are cropped to the part that matters (Anna's chat and panel, Kelly's message, the
  map) and shown full width.
- **Words** sit in the middle band. They stay out of the top 14 %, the bottom 35 % and 6 % on each
  side (Reels), and out of TikTok's right-hand button column (§3).
- **Same beat grid and sound** as the 16:9 version; only the layout code differs.

### Music, sound and words

- **Score:** build the 120 BPM track in code first, as a "drive" style added to `scripts/music.ts`:
  - four-on-the-floor kick, off-beat open hats, sixteenth-note hats from bar 4
  - a bass on the root and a short pluck hook
  - risers into bars 2 and 14, and a full stop on bar 14's downbeat for the logo hit

  We own it and it costs nothing. If it sounds thin next to real tracks, license one 120 BPM track
  (§12 #4: about $17–50 for a month; it goes into `docs/COSTS.md` first). Because every cut sits on
  the beat grid, a 120 BPM track drops in with only a start offset.
- **Effects,** also made in code: whoosh, tap, typing, ding and the logo hit. Mix to −14 LUFS and
  −1 dB true peak, like the hero.
- **Words:** no voice; the words are the captions.
  - Google Sans Bold, about 120–150 px at 1080p, white with the hero's cyan highlight.
  - A line stays up for at least 0.3 s a word plus 0.4 s, and no line is longer than five words.
  - Every line comes from the hero or from what the captures show, so there are no new claims.
  - The lines go into `copy/en-US.json` under `launchFast`.

### What it needs

- **No new captures.** Every shot uses the 2026-11-18 captures and the recreated computer.
- **Optional:** one second of Max's real Stardust Drift game being played, recorded from the real page
  in headless Chrome. It's the only real moving footage the montage could have. About half an hour,
  and no app build.
- **The demo-data fixes in `CAPTURE.md`,** but only if anything is captured again.

### How it's built

- **Compositions:** new ones in the same Remotion project: `LaunchFast` (16:9), `LaunchFastVertical`
  (9:16) and `LaunchBumper` (9:16 and 16:9).
- **Beat grid:** `src/fast/grid.ts` turns bars and beats into frames.
- **New parts:**
  - kinetic text: a word per beat, with a scale punch
  - the snap zoom with motion blur (`@remotion/motion-blur` if render times allow, a faked
    directional blur if not)
  - the whip pan, the beat punch and the counter chip
- **Reused from the hero:** the phone, the window, the still camera, the recreated computer, the live
  screen and the banners.
- **Renders** go through `heavy.sh` as before. A 30 s render should take a few minutes; motion blur
  can multiply that, so measure it on the first draft.

### Time and cost

| Step | Agent time |
|---|---|
| Beat grid, kinetic text, transitions | 0.5–1 day |
| The 16:9 fast cut | 0.5–1 day |
| The drive score and effects | 0.5 day |
| The 9:16 layout | 0.5 day |
| The bumper | 0.25 day |
| **Total** | **about 2.5–3.5 days**, plus two 15-minute reviews from you |

Cash: $0, or one music license (about $17–50).

Order of work:
1. A 16:9 draft first: it's the quickest way to judge the pacing, because it reuses the hero's layouts.
2. Your review.
3. The 9:16 version.
4. The bumper.

### Decisions (decided 2026-11-18: Oliver left all of them to me)

| # | Question | Decision |
|---|---|---|
| F1 | A 30 s fast cut plus a 15 s bumper? | Yes |
| F2 | Which shape first? | 16:9 for the first review, because it's quickest to build; 9:16 right after, since that's where it will be watched most |
| F3 | Music made in code first, and a licensed track only if it sounds thin? | Yes |
| F4 | A voice? | None: the words carry it with the sound off. Your voice could add a two-word tag on the end card later |
| F5 | Record one second of the real game for the montage? | Yes: half an hour for the only real moving footage |
| F6 | Does the fast cut replace the 30 s vertical cut in §6? | Yes, and the teasers come from it |

### Risks

| Risk | What we do |
|---|---|
| Too fast to read | The reading rule above, and a muted watch at full speed before you see it |
| A dance track made in code sounds cheap | Swap in a licensed 120 BPM track on the same grid |
| Motion blur slows renders | Measure on the first draft; fake the blur if needed |
| Busy screens flash by as noise | Crop and zoom every shot to the one thing it shows: the card, the number, the map |

## Sources

- Google Play promo video: [support.google.com/…/12932541](https://support.google.com/googleplay/android-developer/answer/12932541?hl=en-GB),
  [12929944](https://support.google.com/googleplay/android-developer/answer/12929944?hl=en-GB),
  [15501235](https://support.google.com/googleplay/android-developer/answer/15501235?hl=en-GB)
- Product Hunt: [How to post a product](https://help.producthunt.com/en/articles/479557-how-to-post-a-product),
  [Build your product page](https://help.producthunt.com/en/articles/17834537-4-build-your-product-page)
- X: [PostFast](https://postfa.st/sizes/x/video), [Postpone](https://help.postpone.app/platforms/twitter/media-limits)
  (third-party; they disagree)
- Reels, TikTok, Shorts, LinkedIn: [PostFast Reels](https://postfa.st/sizes/instagram/reels),
  [TikTok](https://postfa.st/sizes/tiktok/video), [Shorts](https://postfa.st/sizes/youtube/shorts),
  [LinkedIn](https://postfa.st/sizes/linkedin/video) (third-party, last checked by them 2026-09-25)
- App Store preview rules, for the later store cut: `Marketing/docs/store-specs.md`
- Remotion license: [remotion.dev/license](https://remotion.dev/license),
  [pricing](https://www.remotion.dev/docs/pricing)
- Music plans (third-party, prices disagree): [Epidemic Sound: how we compare](https://www.epidemicsound.com/how-it-works/how-we-compare/),
  [FreeVisuals review](https://www.freevisuals.net/reviews/epidemic-sound),
  [Artlist vs Epidemic Sound 2026](https://www.artyfile.com/blog/artlist-vs-epidemic-sound-vs-artyfile-comparison-2026)
