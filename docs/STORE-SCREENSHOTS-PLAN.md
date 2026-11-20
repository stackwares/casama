# Store screenshots (plan, 2026-11-18)

**Status:** **done** (checked live 2026-11-20): App Store iPhone, iPad and Mac have 10 screenshots each, plus
folding iPhone, Watch and App Previews; Google Play has phone, 7" and 10" tablet sets of 8, the feature
graphic and Wear. Originally a proposal that waited on the decisions in §9. The listing text and the store forms are handled in another session; this plan covers
pictures only.

## 1. Summary

- Three designed sets for the App Store (iPhone, iPad, Mac), 10 screenshots each, at the one size
  Apple requires for each device.
- Two sets for Google Play made from those (phone, tablets), 8 each, plus the feature graphic (the
  banner at the top of the Play listing).
- `codex/gpt-6-luna` paints the artwork. The app's screens are real captures, and the words are real
  type laid on top. §4 explains why luna doesn't draw the app itself.
- It starts small: the first three iPhone screenshots in three looks. Oliver picks a look and edits the
  wording, then the rest follows set by set, each one approved before the next.

## 2. What gets made

| Set | Store slot | Size | Count |
|---|---|---|---|
| iPhone | App Store, iPhone large display | 1320×2868 | 10 |
| iPad | App Store, iPad 13" | 2064×2752 | 10 |
| Mac | Mac App Store | 2880×1800 | 10 |
| Play phone | Google Play, phone | 1080×1920 | 8 |
| Play tablets | Google Play, 7" and 10" tablet (the same 8 in both) | 1440×2560 | 8 |
| Play feature graphic | Google Play, listing banner | 1024×500 | 1 |

That is 46 screenshots and one banner, filling every slot each store shows for these devices.
The Play sets are the first 8 of the iPhone and iPad sets, laid out again for Play's shape and rules.

## 3. What the stores require (checked 2026-11-18)

**App Store**
- 1 to 10 screenshots per device size, PNG or JPEG, no transparency.
- iPhone: one set is enough. The large-display size (1320×2868) is scaled down for every smaller
  iPhone. iPad: the 13" set is required and covers the other iPads. Mac: one 16:10 size.
- iPhone Duo (the folding iPhone) has its own optional sets. They become required in April 2027 for
  apps built with the iOS 27.1 SDK.
- Screenshots must show the app in use, and can't name or show other mobile platforms (so no Android
  on the Apple sets). These two come from the App Review Guidelines, which I did not re-read today.

**Google Play**
- Up to 8 screenshots per device type, JPEG or 24-bit PNG, no transparency, each side 320 to 3840 px,
  and the long side at most twice the short side.
- To be picked for Play's promoted spots: at least 4 screenshots, 9:16 or 16:9, 1080 px or more.
- Feature graphic: required, 1024×500, no transparency.
- Screenshots must show the real app. Google also recommends: captions take at most 20% of the
  picture, no device pictures, and none of "best", "#1", "top", "new", "free", "sale", "download now".

## 4. How luna is used

Luna paints, one image per task (it stops after one or two, and that is how the website art was made):

- a background painting for each slide, upright for iPhone, iPad and Play, and wide for Mac;
- small painted props where a look needs them;
- two more versions of the Play banner in the chosen look, next to the one made this morning
  (`Marketing/casama/art/play-feature-graphic.png`).

Luna does not draw the app, a phone, any words or the mascot. The reasons:

- **Store rules.** Apple and Google both require screenshots of the real app. A painted screen is an
  invented one, and it can get the listing rejected.
- **Quality.** Painted app text comes out misspelled, and painted mascots come out off-model. Real
  captures and the real mascot SVGs stay sharp at any size.

The same split is already written down for all Casama art (`docs/VISUALS-PLAN.md`,
`Marketing/casama/README.md`). If you want luna to paint whole screenshots anyway, that is decision 1.

**How a screenshot is put together:** luna's painting at the back, the real capture inside the device
frame, one enlarged piece of the real screen popping out where it helps (the Approve button, the
"1 thing needs you" banner), the real mascots, and the headline in Google Sans Bold.

It is built in the store screenshot editor (`Marketing/casama/screenshots/`, the same editor as
NexBot's), so you can open it, drag things and retype a headline yourself. It exports every size above
in one go.

## 5. The ten screenshots, in order

The first three show side by side in App Store search, so they carry the whole pitch: what it is, what
makes it different, and why it is safe. `*word*` marks the accent words.

| # | Shows | Headline | Supporting line | Capture |
|---|---|---|---|---|
| 1 | Chats, with the five teammates | Meet your *AI team* | Teammates who remember you, each with a computer of its own. | Have it; retake on the new build |
| 2 | A teammate's computer, live | They work on *real computers* | A browser, files and a terminal. Watch live, or take over. | New |
| 3 | An approval waiting | Nothing risky *without your OK* | Risky steps wait for your tap. You decide how much each bot does alone. | Have "Needs you", but it shows raw JSON; retake from the chat's card |
| 4 | The morning brief | Wake up to *work that's done* | A brief every morning: what's done, and what needs you. | Have it |
| 5 | A teammate using what it remembers | Tell it once. *It remembers.* | Every teammate keeps its own memory of you and your work. | New |
| 6 | Routines | Set it once. *It runs itself.* | Routines run on a schedule, or when something happens. | New |
| 7 | Library | Everything they make, *in one place* | Documents, pictures, sites and games land in your Library. | Have it; the demo data needs tidying |
| 8 | Apps | Works with *your apps* | Email, calendar, files and more, with the access you allow. | New |
| 9 | A live call | Just *call it* | Talk a task through out loud. Dictation and read-aloud too. | New; needs voice keys on the local stack |
| 10 | A chat with a painted wallpaper, dark | Make it *yours* | Themes and wallpapers, in light and dark. | New |

- **Play** uses 1 to 8.
- **iPad and Mac** tell the same story with their wider screens: slide 2 shows the chat and the bot's
  computer side by side. Mac's slide 10 may become a Mac-only feature (coding agents, local models)
  once I've checked what the Mac App Store build really does.
- **On the bench**, to swap in: group chats ("One chat. The whole team."), your own models and server,
  chat apps (WhatsApp, Slack), every device.
- Every claim is checked against the build that ships before its screen is captured. No prices, "free",
  rankings or store badges anywhere.

## 6. Three looks for the first round

| Look | What it is | Why |
|---|---|---|
| A. Storybook sky | Luna's painted world behind every slide (cloud sea, floating cottages). The sky moves through a day across the set, dawn on slide 1 to night on slide 10. White headlines. | Most Casama: matches the Play banner, the film and the website art |
| B. Plain and bold | casama.ai's look: white slides, near-black headlines with the accent in Casama purple, a big device, the mascots as the colour. Luna paints only small props. | Easiest to read at thumbnail size |
| C. Night | Deep plum night sky with stars, a glowing device, lavender accents. | Stands out in a list of white screenshots |

## 7. Captures

- **Build.** The simulator build kept from the film is build 37; the app is now on build 40 (new app
  logos, chat times, the plain theme). A fresh simulator build of current `main` needs your yes
  (decision 4). It covers iPhone and iPad.
- **Demo data.** "Maya's space" on the local dev stack with the film's cast (Anna, Oliver, Max, Rome,
  Kelly). To fix first: the Library shows the same page twice, raw file names and empty thumbnails.
  Seeds are added rows with an undo block. The local database is never reset.
- **iPhone and iPad.** Driven on the simulators with the T3 device tools, status bar at 9:41. Needs
  your OK for this task (decision 5).
- **Mac.** The Mac set should be the real Mac app, not the web app in a drawn window. T3 Code has no
  Screen Recording permission, so either you grant it or you take the shots from a list I give you
  (decision 6). It also needs a Mac debug build pointed at the local stack, which I'd ask for then.
- **Play.** The same iPhone and iPad captures, in the iPhone and iPad frames the Marketing hub uses for
  every product. Captions are kept under 20% of the picture.

## 8. Rounds

| Round | What | Done when |
|---|---|---|
| 1. Pilot | iPhone slides 1 to 3 in looks A, B and C: 9 pictures on one review sheet. About 7 luna paintings. Uses the kept build 37, so no Flutter build | You pick a look and settle the wording of slides 1 to 3 |
| 2. iPhone | New build, tidy demo data, the remaining captures and paintings, all 10 slides | You approve the 10 |
| 3. iPad and Mac | 10 each, wide paintings for Mac | You approve both sets |
| 4. Play | Phone 8, tablets 8, the banner with two more versions | You approve them |
| 5. Checks | `check_copy.py` and `check_assets.py` pass, files flattened to RGB, Play alt text drafted, `Marketing/casama/README.md` updated, sets staged | Ready to upload; nothing is uploaded until you say yes for each store |

About 30 luna tasks in total, on the same Codex sign-in as the website art. No new service or key.

Files: copy in `Marketing/casama/copy/en-US.json` (`screenshots`), captures in
`captures/{iphone-6.9,ipad-13,mac}/en-US/`, paintings and their prompts in `art/screenshots/raw/`,
finals in `out/screenshots/en-US/<device>/NN-<scene>.png`, review sheets in `out/review/`.

## 9. Decisions for Oliver

| # | Decision | Default |
|---|---|---|
| 1 | What luna paints | Backgrounds and props; the app's screens are real captures |
| 2 | Slide order and headlines (§5) | As listed |
| 3 | Looks in the pilot | All three (A, B, C) |
| 4 | Build for captures after the pilot | A fresh simulator build of current `main` (a Flutter build, so it needs your yes) |
| 5 | Driving the iPhone and iPad simulators | Yes, for this task |
| 6 | Mac captures | You grant T3 Code Screen Recording and I capture the Mac app. Otherwise you take them from my list |
| 7 | Frames on the Play sets | The hub's iPhone and iPad frames, as on your other apps. Google recommends no device pictures, so the other choice is plain rounded screens |
| 8 | Chromebook set on Play (optional, 8 wide pictures) | Skip |
| 9 | Dark mode | One dark slide (slide 10), the rest light |
| 10 | Other apps' logos on slide 8 | Show the real Apps screen. Otherwise swap in group chats |

## 10. Not in this round

- iPhone Duo sets (optional until April 2027; they need captures from the Duo simulator).
- App Preview videos, custom product pages, in-app event art.
- Other languages: Casama v1 is English only.
- The App Store header and search art: made this morning, waiting for your yes to place them.
- Play sets for Android XR, Wear OS, TV and cars: the app doesn't target them.

## 11. Risks

- **Paintings are about 1,500 px wide** and get enlarged about 1.9 times. That suits soft skies behind
  a device. The pilot is checked at full size; if it looks soft, the look leans on flat colour instead.
- **Luna sometimes copies the wrong file.** Each painting is copied from the path its task reports and
  checked by hash, as for the website art.
- **Apple's page is unclear in one place.** Its summary line names the medium iPhone size as required,
  and its table says a large-display set covers every size. One large set matches what the hub uploaded
  for other apps in October. I'll confirm in App Store Connect at upload time; the captures are
  medium-size natively, so a second export is cheap.
- **Features that are hard to capture.** The live call needs voice keys on the local stack. If a screen
  can't be captured honestly, its slide is swapped for one from the bench.
- **The Mac App Store build is sandboxed**, so some Mac features may not be in it. Mac-only slides are
  chosen after checking.
- **Renders go to the external SSD** (`Marketing/casama/out`). It has to be plugged in.

## Sources

- Apple, Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
- Google Play Console Help, Add preview assets to showcase your app: https://support.google.com/googleplay/android-developer/answer/9866151
- Marketing hub rules: `Marketing/AGENTS.md`, `Marketing/docs/conventions.md`, `Marketing/docs/store-specs.md`
