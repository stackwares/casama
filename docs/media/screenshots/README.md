# Screenshots

Each image comes in a `-light` and a `-dark` version, captured from the same screen.

## Framed (transparent PNG, 2400 px wide)

Used by the repository README. They work on the website too.

| File | Shows |
| --- | --- |
| `hero` | The Mac app, with Milo's computer live in the side panel playing the game he made, and the iPhone home screen in front |
| `mac-milo` | The Mac app alone: Milo's chat with his computer live in the side panel |
| `mac-group` | The Mac app: a group chat where Nova splits a birthday plan between Ada and Milo |
| `mac-nova` | The Mac app: Nova's Kyoto plan on a map |
| `iphone` | Four iPhones: home, Nova's Kyoto map, Milo's bakery site, Juno's first chat |
| `ipad` | iPad Pro 13", landscape: Milo playing Stardust Drift live on his computer |
| `ipad-nova` | iPad Pro 13", landscape: Nova's Kyoto map with the computer panel |

## Raw (`raw/`, JPEG, native size)

Unframed, for the website and store listings:

- `mac-*`: the macOS app's window at 1442×902 @2x (2884×1804), captured with `screencapture -o -l`
  (the title bar drawn by the system follows the Mac's appearance, so the framed versions draw their own)
- `desktop-*`: the web app at 1440×900 @2x (2880×1800)
- `iphone-*`: iPhone 18 Pro simulator, 1206×2622, status bar set to 9:41
- `ipad-*`: iPad Pro 13" simulator in landscape, 2752×2064, an App Store iPad size

The data comes from a demo workspace on the local dev stack ("Maya's space", with the bots Ada, Milo,
Nova and Juno). iPhone captures were 1206×2622; App Store Connect's 6.9" slot wants 1320×2868, so
scale them or capture on an iPhone 18 Pro Max before uploading.
