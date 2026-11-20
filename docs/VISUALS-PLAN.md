# Visuals for the websites (plan, 2026-11-18)

Status: **done** (D-379): share cards, heroes, the 404 scene and wallpapers are live. Not checked item by item (`docs/PLANS.md`, 2026-11-20).

Generated artwork for casama.ai, the docs, the gallery, casama.link and casama.page, made with
`codex/gpt-6-luna`. Nothing is deployed until Oliver picks and says yes.

## Rules

- **No fake product.** Screenshots of the app stay real captures. Generated images never show Casama's
  UI, a phone or Mac screen with our app on it, or a feature that hasn't shipped (the "Coming soon" cards
  wait for real screenshots).
- **No text in generated images.** Words, the wordmark and the mascot are laid over the art in HTML and
  rendered to PNG, so spelling and the mascot always match `site/assets/bots/*.svg`.
- **Mascot stays on-model.** The model draws scenes and backgrounds only; the real SVG cloud is placed on
  top. A scene that needs the mascot leaves room for it.
- **Fits the plain look (D-319).** Pages stay white / dark grey. Art lives in contained places (share
  cards, wallpapers, one hero illustration, 404s), never as page backgrounds behind text.
- **Palette:** Casama purple (#6b4fd8 family, deep #24112f as on the current share card), lavender,
  soft cyan glow (the mascot's orbit), warm blush accents. Soft, rounded, calm, a little dreamy; no
  photo-realism, no neon, no generic "AI brain / circuit" imagery.
- **License:** our own work, CC0 for gallery wallpapers like the existing ones.

## Round 1

| # | What | Size | Where it goes |
|---|------|------|---------------|
| A1 | Share card, casama.ai | 1200×630 | `site/og-image.png` (replace) |
| A2 | Share card, docs | 1200×630 | docs-site `og:image` (none today) |
| A3 | Share card, casama.link | 1200×630 | `link-site/` (uses casama.ai's today) |
| A4 | Share card, casama.page | 1200×630 | `sites-site/` (none today) |
| A5 | Share card, gallery + one per type (apps, bots, routines, plugins, skills, looks) | 1200×630 | `gallery/og*.png`, `build-pages.mjs` picks by type |
| B  | 6 new image wallpapers | 2400×2400 + 640 thumb | `gallery/wallpapers/<id>/` |
| C  | casama.page hero illustration | 1600×900 | `sites-site/index.html` hero |
| D  | 404 scene (one shared, mascot laid on top) | 1600×1000 | 404 pages on all four sites |

Docs illustrations (concept pages such as computers, routines, memory) are round 2.

## How

1. gpt-6-luna generates raw art (backgrounds, scenes, wallpapers) into `visuals/round-1/raw/` with a
   `manifest.json` (file, slot, prompt).
2. Share cards and 404 previews are composed in HTML (`visuals/compose/`) with the real mascot and type,
   then rendered to PNG with headless Chrome.
3. A local review board (`visuals/index.html`, served on :8740) shows each candidate in context: a chat
   link preview, a wallpaper behind chat bubbles, the 404 page, the casama.page hero.
4. Oliver picks or asks for changes; we iterate. Picks are then wired into the sites and checked with
   `scripts/serve-web.py`. Deploy only after a yes.

`visuals/` is a working folder and is not deployed by any script.

## Round 4 (2026-11-18): everywhere else

16 more pictures from gpt-6-luna (raw in `visuals/round-4/raw/`, gitignored), plus reuse of the lost scene,
the casama.page hero and the blog's approvals picture.

| What | Where | Made by |
|------|-------|---------|
| A share card for every written casama.ai page (51): the page's title and the mascot on its section's painting (learn, alternatives, use cases, compare; other pages use the home card's painting) | `site/assets/cards/<slug>.jpg`, picked by `site/build.mjs` | `node visuals/render-cards.mjs` (new and retitled pages; `--all` after a template or background change). Backgrounds in `visuals/cards/` |
| Header pictures for Self-hosted, Open source and Security | `site/assets/pages/` (+ alt text in its `manifest.json`), shown by `site/build.mjs` like a blog post's | by hand |
| Closing picture on the home page, the casama.ai 404 (lost scene), the sign-in-code page (Link scene) | `site/assets/art/`, `site/assets/lost.webp` | by hand |
| Casama for Chrome's what's-new and goodbye pages | `site/assets/chrome/` | by hand |
| Docs: pictures on Computers, Routines, Memory, Casama Link, Autonomy; a 404 page | `docs-site/public/art/`, `docs-site/.vitepress/theme/NotFound.vue` | by hand |
| casama.page hero: the real mascot floats in its sky | `sites-site/index.html`, `.hero-figure` in `link-site/link.css` | |
| Chrome Web Store marquee and small tile on a painted sky | `apps/extension/store/` (uploading is manual) | `visuals/render-store.sh` |
| Mac installer window: painted background, arrow, icon layout | `scripts/dmg/` (`dmgbuild` via `uvx`, used by `scripts/package-macos.sh`; plain window without uv) | `visuals/render-dmg.sh` |

Not done here: GitHub's social preview for the repos has no API; upload `site/og-image.png` in each repo's
settings by hand.
