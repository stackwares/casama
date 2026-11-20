# Live showcase on casama.ai: plan

Status: **done** (live on casama.ai 2026-11-19).

Original status: **built, not committed or deployed** (2026-11-19). Oliver: "go and build them now", so the
recommended answer to each question in §7 was taken: desktop + phone + tablet, watch-and-take-over as
scene C, screenshots out of this section, pause buttons everywhere including the hero. Code:
`site/showcase.css`, `site/showcase.js`, the `.showcase` block in `site/index.html`, and the hero's pause
button in `site/site.js`. The `mac-group-*` and `mac-nova-*` images stay on disk: `docs-site/index.md`
and `README.md` still use them.

## 0. Summary

Replace the two flat Mac screenshots under "See it at work" with three short live scenes, each in a
different device and each showing one thing Casama does well. They are built like the hero chat: real
HTML and CSS that plays itself in a loop, not video. Text stays sharp, the scenes follow light and dark
mode, they cost a few KB instead of megabytes, and they can be changed with a text edit.

| Scene | Device | What it shows | Loop |
|---|---|---|---|
| A. Group chat | Desktop window (Mac style) | You ask @everyone; Nova splits the work; three bots start at once; Ada's invite and Milo's RSVP page come back | ~20 s |
| B. Answers you can use | Phone | Nova plans a Kyoto weekend; a map card draws itself in the chat, pins drop in order, the route traces, day tabs switch | ~18 s |
| C. Watch and take over | Tablet, landscape, split view | Chat on the left, the bot's computer live on the right: it browses, fills a form, stops at "Needs your OK"; a tap on "Take over" hands you the controls, then you hand them back | ~22 s |

Scene C is new: the section's lead line promises "watch a bot's computer live while it works, and take
the controls whenever you want", but no picture on the page shows that today.

## 1. What exists today

- `site/index.html` section `#see`: the film reel, then `.shot-pair` with two `<figure class="shot">`,
  each a light and a dark `.webp` (`mac-group-*`, `mac-nova-*`, 2000×1330).
- The hero chat now plays itself (`site.js`, uncommitted): a pause-aware `wait()`, step show/hide,
  a fixed height so the page never moves, and a still frame for reduced motion or Save-Data.
- Bot avatars as SVG in `site/assets/bots/`. Site tokens in `site/site.css` (`--bg`, `--card`,
  `--accent`, `--good`…), with light and dark.

## 2. How it's built

- **One small player in `site.js`**, pulled out of the hero code: `scene(el, script)` gives each scene
  `wait`, `show`, `hide`, `type`, `count` and a loop. It pauses when the scene is off screen or the tab
  is hidden. The hero moves onto it too.
- **Device frames drawn in CSS** (rounded bezel, notch or camera dot, window dots). No device photos,
  no Apple artwork, no "iPhone"/"iPad" in visible copy ("phone", "tablet", "desktop").
- **App screens rebuilt in HTML** with the app's Plain theme colors (D-380) mapped onto site tokens,
  so they look like Casama and switch with light and dark.
- **The map is an inline SVG** we draw (streets, river, park shapes, numbered pins, a dashed route).
  No map tiles, no third-party licence.
- **Only `transform` and `opacity` animate.** Each scene keeps a fixed size from first paint
  (`aspect-ratio`), so there's no layout shift. All of it adds roughly 15–25 KB, against ~600 KB of
  `.webp` removed.
- **Still frames:** with reduced motion, Save-Data or no JavaScript, each scene shows its finished
  state in plain HTML. That replaces the screenshots entirely, so the `.webp` files can go.
- **Pause control:** every scene (and the hero) gets a small pause/play button. Content that moves
  for over 5 seconds needs one (WCAG 2.2.2).
- **Screen readers:** each scene is a `<figure>` with a one-sentence label and the caption; the fake UI
  inside is `aria-hidden`.

## 3. Layout

Desktop width:

```
┌───────────────────────────────┬────────────┐
│  A. desktop window (2/3)      │ B. phone   │
│                               │   (1/3)    │
├───────────────────────────────┴────────────┤
│  C. tablet, landscape, full width          │
└────────────────────────────────────────────┘
   caption under each, as today
```

Phone width: A, B, C stacked; B is centered at its natural phone size. Only the scenes on screen play.

## 4. Scene scripts

**A. Group chat (desktop).** Sidebar with Ada, Milo, Nova, Juno and "Sam's birthday". Your
@everyone message arrives → Nova types → "Splitting it up: @Ada the invite, @Milo the RSVP page, I'll
shortlist three places" → three "working" chips appear in the sidebar and pulse at the same time →
Milo: "On it — building the RSVP page" → Ada's invite slides in as a card → Milo's page arrives as a
small page preview card → Nova's shortlist (3 rows) → the sidebar badges clear → hold, fade, loop.

**B. Answers you can use (phone).** You: "Plan a 3-day weekend in Kyoto…" → "On it — checking a
couple of December dates" with the usage line → the map card opens, pins 1–5 drop in order, the route
draws between them, the day tabs move Fri → Sat → Sun and the pins change each time → a "Saved to
Library" chip → hold, loop.

**C. Watch and take over (tablet).** Left: chat with Kai, "Renew my parking permit before Friday."
Right: the bot's computer, live: a made-up city site, the cursor moves, fields fill, a checkpoint
saves → a "Needs your OK · $48" bar → a tap on "Take over" → the frame gets a "You're in control"
border and the cursor turns into yours, you tick one box → "Hand back" → the bot finishes, "Permit
renewed" in the chat → loop. Sites, names and prices are made up, like the film's (the reel note
already says so).

## 5. Phases

1. Player pulled out of the hero; the hero moved onto it; pause buttons. **Done when:** the hero
   behaves the same and pauses.
2. Device frames and the layout grid with still frames only. **Done when:** light, dark, 375 px and
   1440 px look right with motion off.
3. Scenes A, B, C, one at a time. **Done when:** each loops with no layout shift, pauses off screen,
   and the stills match the last frame.
4. Remove the `.webp` files from the section, check Lighthouse (CLS 0, no new long tasks), commit.
5. Deploy casama.ai with `scripts/deploy-web.sh` **after Oliver's yes**.

About one working session for 1–4.

## 6. Not doing

- No video files, Lottie, Remotion or canvas.
- No real brands, airline/booking sites or map tiles in the scenes.
- No change to the film reel above the scenes.

## 7. Questions for Oliver

1. **Devices:** desktop + phone + tablet (recommended: everyone knows a tablet, and its split view
   suits scene C), or a folding phone (iPhone Duo style, D-411) in place of the tablet? The folding
   phone is more novel but less familiar, and it shows up fine in a tablet-sized slot.
2. **Scene C:** watch-and-take-over (recommended, since nothing on the page shows it yet), or
   something else, such as a voice call or the morning brief?
3. **Screenshots:** drop the `.webp` files from this section entirely (recommended), or keep one
   real screenshot somewhere as proof it's the actual app?
4. **Pause buttons** on the hero and all scenes (recommended), or leave the hero without one?
