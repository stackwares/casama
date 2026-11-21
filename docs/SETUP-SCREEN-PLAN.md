# Set Up Casama on This Mac: a better-looking setup screen: plan

Status: **built** 2026-11-21 (Oliver: "write it and execute right away"); checked in a real debug run on a Mac. Builds on the
guided setup (D-309). Layout, scene, mascots and the skipped mark are built (checked in the debug Mac
app); the parts counter (§3) is built too.

## Why

The guided setup at `/setup` works, but on a desktop window it looks unfinished. Everything sits in a
480 px column at the top, with the title pushed into the left corner and the bottom 40% of the window
empty. The longest step, downloading the server's parts (5 to 10 minutes), shows only a sliding bar,
so people think it is stuck. That's how the 2026-11-21 report started: a page that looked stuck when
it really was stuck (the docker PATH bug, fixed in 7698de849).

## What changes

### 1. Layout (side chat; `_SetupScreenState.build` + `setup_art.dart`)

- **Wide windows (≥ 900 px):** two panes.
  - Left (about 45%): the painted "coming home" scene from the splash and sign-in screens
    (`SplashScene`, day or night with the theme), in a rounded panel with a margin. A mascot stands
    on it and changes with the step, with a one-line caption under it.
  - Right: the title as a small line, the five-step bar, then the current step, a little way
    down the window (8% of its height, at most 80 px). Pinned rather than centered, so the bar
    stays put while the step below it grows or shrinks; it scrolls when it doesn't fit.
- **Narrow windows:** one column as today, without the scene or a mascot (a mascot there stacked
  on top of the step's own icon).
- **Skipped steps** (Skip for Now) show a muted dash in the step bar, not the tick of a finished
  step.
- The page background stays plain (white / dark grey, the plain-backgrounds rule). The painting is
  a picture in a panel, not a tinted page.

### 2. Mascot per step

| Step | Mascot | Caption |
|---|---|---|
| Docker | Thinker | "First, the box your server lives in." |
| Server | Focused | "Building your home. This is the long part." |
| Account | Wow | "Your server is running!" |
| AI model | Starry | "Now give it a brain." |
| Phone | Winky | "Last step: bring it with you." |

The mascot plays its Lottie animation and is a still picture with Reduce Motion. It swaps with a
short scale-and-fade when the step changes, so moving on feels like progress.

### 3. Real progress on the long step (main thread; `ServerStep` + `local_server.dart`)

"Downloading its parts" shows how many parts are done ("4 of 7 downloaded") from Compose's
Pulling/Pulled lines. Sizes and time left can follow once the installer reports them.

## Not doing

- No new art: the scene and mascots already exist (D-440, mascots).
- No WebViews; everything is native Flutter.
- No change to what the steps do.

## Checks

- Widget tests: wide layout shows the scene and the mascot for the step; narrow layout shows the
  small mascot and no scene; existing guided setup tests still pass.
- A real run in the debug Mac app (the main thread's worktree run), screenshots at wide and narrow
  sizes, light and dark.
