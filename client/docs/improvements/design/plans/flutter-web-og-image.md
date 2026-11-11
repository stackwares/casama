# Fix: Links to the web app show up as a bare URL in WhatsApp, Slack and X

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/flutter-web-og-image
- **Needs new dependency**: none

## Why

When someone shares a link to the Casama web app in WhatsApp, Slack, iMessage or X, it shows up as a bare
address with no title, description or picture, so it looks broken and few people tap it. A few Open Graph
and X meta tags in `web/index.html`, plus one 1200×630 image, turn the link into a proper preview card with
the Casama name, a one-line description and the Casama cloud.

## Where

All paths are relative to the `client/` folder (the Flutter app, where `pubspec.yaml` is).

`web/index.html` has a page description but no Open Graph (`og:*`) or X (`twitter:*`) tags at all:

```html
<!-- web/index.html:17-21 — current -->
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Casama brings your AI companions together in one place.">
```

`web/` has no image a preview card can use. The ones that exist are the wrong shape for a card:
`web/splash/casama.png` is 480×488 (the transparent Casama cloud shown while the app loads),
`web/icons/Icon-512.png` is 512×512, `web/favicon.png` is 48×48. Cards need 1200×630; off-ratio images get
cropped or dropped. `web/og-image.png` does not exist yet.

The web app's public address is not decided in the code: `client/Dockerfile.web` serves the web build
from whatever server a self-hoster runs, `docs/DECISIONS.md` (D-172) only reserves `app.casama.ai` "for a
hosted web app", and `docs/NEEDS-FROM-OLIVER.md` still lists "a place to host the web preview" as open.
Card images must be absolute URLs, so this plan writes a clearly named placeholder origin,
`https://REPLACE-WITH-WEB-APP-ORIGIN`, that the developer replaces once the address is known.

## The fix

The article's fix: Open Graph tags plus X's own tags in `<head>`, an absolute `og:image` and
`twitter:image`, and an image sized 1200×630.

1. A new image, `web/og-image.png`, exactly 1200×630 pixels: the Casama cloud from
   `web/splash/casama.png`, 300 px tall, centred horizontally with its top 95 px from the top edge, and the
   word "Casama" under it in the app's heading font (Libre Baskerville Bold, `assets/fonts/LibreBaskerville-Bold.ttf`),
   84 px, colour `#FCF3FB`, centred at x = 600, y = 500, all on a solid `#25102F` background (the app's dark
   launch background; the light lavender cloud would vanish on the light one). Everything sits in the
   middle of the card so a square crop (WhatsApp's small thumbnail) still shows the cloud and the name.
   `flutter build web` copies everything in `web/` into the build, so it is served at `<origin>/og-image.png`.

2. These tags in `web/index.html`, right after the existing description meta. The title and description
   reuse the page's existing `<title>` and description text:

```html
<!-- target: web/index.html, right after the description meta -->
  <meta name="description" content="Casama brings your AI companions together in one place.">

  <!-- Link preview cards (WhatsApp, Slack, iMessage, X). Images must be absolute URLs: replace
       https://REPLACE-WITH-WEB-APP-ORIGIN with the address this web app is served from. -->
  <!-- Open Graph -->
  <meta property="og:title" content="Casama">
  <meta property="og:description" content="Casama brings your AI companions together in one place.">
  <meta property="og:image" content="https://REPLACE-WITH-WEB-APP-ORIGIN/og-image.png">
  <meta property="og:url" content="https://REPLACE-WITH-WEB-APP-ORIGIN/">
  <meta property="og:type" content="website">

  <!-- X / Twitter -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Casama">
  <meta name="twitter:description" content="Casama brings your AI companions together in one place.">
  <meta name="twitter:image" content="https://REPLACE-WITH-WEB-APP-ORIGIN/og-image.png">
```

`index.html` cannot read Dart constants, and it already spells the product name "Casama" in its `<title>`,
description and `apple-mobile-web-app-title`, so writing it here matches the file.

## Steps

1. From the `client/` folder, create `web/og-image.png` with this one-off command (Pillow is installed on
   this machine; do not save the script anywhere in the repo):

   ```bash
   python3 -I - <<'EOF'
   from PIL import Image, ImageDraw, ImageFont
   W, H = 1200, 630
   card = Image.new('RGBA', (W, H), '#25102F')
   cloud = Image.open('web/splash/casama.png').convert('RGBA')
   ch = 300
   cw = round(cloud.width * ch / cloud.height)
   cloud = cloud.resize((cw, ch), Image.LANCZOS)
   card.alpha_composite(cloud, ((W - cw) // 2, 95))
   font = ImageFont.truetype('assets/fonts/LibreBaskerville-Bold.ttf', 84)
   ImageDraw.Draw(card).text((W // 2, 500), 'Casama', font=font, fill='#FCF3FB', anchor='mm')
   card.convert('RGB').save('web/og-image.png', optimize=True)
   EOF
   ```

   Then open `web/og-image.png` and look at it: a dark plum card, the white-lavender cloud mascot centred in
   the upper part, "Casama" in a serif face centred under it, nothing cut off at any edge.

2. In `web/index.html`, find the line
   `  <meta name="description" content="Casama brings your AI companions together in one place.">`
   and insert, directly after it, a blank line followed by the 14 lines of the target block above (one of
   them is itself blank, before `<!-- X / Twitter -->`), from
   `  <!-- Link preview cards (WhatsApp, Slack, iMessage, X). Images must be absolute URLs: replace`
   down to `  <meta name="twitter:image" content="https://REPLACE-WITH-WEB-APP-ORIGIN/og-image.png">`,
   indented with two spaces like the lines around them. Leave the existing description line and the blank
   line plus `<!-- iOS meta tags & icons -->` after the new block unchanged.

3. Keep `https://REPLACE-WITH-WEB-APP-ORIGIN` exactly as written (three places: `og:image`, `og:url`,
   `twitter:image`), unless the developer told you the web app's public address in this session; then use
   that address instead, with `https://`, no trailing slash before `/og-image.png`, and, if the web build is
   made with `--base-href /some/path/`, that path included (`https://example.com/some/path/og-image.png`).

## Check it

- `file web/og-image.png` → contains `PNG image data, 1200 x 630`.
- `grep -c 'property="og:' web/index.html` → `5`.
- `grep -c 'name="twitter:' web/index.html` → `4`.
- `grep -c 'og-image.png' web/index.html` → `2` (`og:image` and `twitter:image`).
- `grep -c 'content="https://' web/index.html` → `3` (both images and `og:url` are absolute).
- `grep -c 'name="description"' web/index.html` → `1` (the existing description is still there, once).

No Dart changed, so there is nothing to analyze or test.

## Don't touch

- `web/manifest.json`, `web/icons/`, `web/favicon.png`, `web/splash/casama.png` and the splash `<style>`/`<div id="splash">`
  in `index.html`: they are the install icons and the loading screen, not the preview card.
- `scripts/casama-splash.py` and the launch screens it writes: the card image is made once by step 1.
- `site/` (the casama.ai marketing page) and `client/Dockerfile.web`: out of scope; the card belongs to the web app.
- Don't add other meta tags (no `og:site_name`, `og:image:width`, `twitter:site` and so on): the article's set is enough.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt
  (the codebase moved on since this plan was written), or `web/index.html` already has `og:` or `twitter:` tags.
- `web/og-image.png` already exists before step 1.
- The Python command fails (no Pillow, missing font or splash file): report it; don't install anything and
  don't draw the image some other way.
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app
now and one place to open to see it. Not a list of files, the steps already
have those. Say plainly that the card only works once
`https://REPLACE-WITH-WEB-APP-ORIGIN` is replaced, in the three places in `web/index.html`, with the
address the web app is actually served from (D-172 keeps `https://app.casama.ai` for a hosted web app), and
that a self-hoster serving it somewhere else would put their own address there. Once it is live they can paste
the link into an X post draft or a Slack message to see the card.
