# @casama/page-agent

The script the phone app runs inside its browser (docs/PHONE-BROWSER-PLAN.md §8.3). It does for a
web view what Chrome's debugger does for Casama for Chrome: reads the page into the same snapshot
text with `@e1` refs, and carries out steps on it. One file, the same on iOS and Android, shipped
inside the app (never downloaded).

It runs in an isolated script world, in every frame, from document start. It shares the DOM with
the page but not the page's JavaScript globals.

## Build

`pnpm --filter @casama/page-agent build` writes `dist/page-agent.js` (one IIFE, no imports) and
copies it to `client/assets/app_browser/page_agent.js`. `pnpm --filter @casama/page-agent check`
fails when the copy is stale.

## Talking to native

Native sends one JSON command and gets one JSON answer.

```
command: { "id": "c1", "cmd": "<name>", "args": { ... } }
answer:  { "id": "c1", "ok": true,  ... }
       | { "id": "c1", "ok": false, "code": "<code>", "message": "<for the bot>" }
```

The script exposes one entry point, `globalThis.__casamaPageAgent.handle(command)`, which returns
a Promise of the answer (iOS calls it with `callAsyncJavaScript` in the content world). On start
it also looks for a native message port named `casamaNative` (Android's `addWebMessageListener`
object, in the same world): when present it posts `{"hello":true,"frame":"top"|"child","href"}`
and answers commands that arrive on `casamaNative.onmessage` with `casamaNative.postMessage(json)`.

Only the top frame owns refs. Child frames answer `frame_snapshot` and act on refs the top frame
gave them (see Frames).

## Commands

| cmd | args | answer fields |
|---|---|---|
| `snapshot` | `interactive_only` (default true), `max_lines` (default 1500) | `text`, `url`, `title` |
| `read` | `max` (default 60000 chars) | `text`, `url`, `title` |
| `probe` | `ref`, or `focused: true` | `facts` (below), `fingerprint` |
| `locate` | `ref` | `x`, `y` (CSS px, centre, in the top frame's viewport), `fingerprint`; scrolls it into view first; `covered` error when something else is on top |
| `click` | `ref`, `fingerprint?`, `synthetic` (true: send the events itself; false: native will tap, only verify) | `text` |
| `fill` | `ref`, `text`, `fingerprint?` | `text` |
| `type` | `text`, `fingerprint?` | `text` (types into the focused element) |
| `press` | `key` (e.g. `Enter`, `Tab`, `Escape`, `ArrowDown`, `Control+Enter`), `fingerprint?` | `text` |
| `scroll` | `direction` (`up`/`down`/`left`/`right`), `amount?` (px, default 600) | `text` |
| `wait` | `text?`, `ms?` (cap 30000) | `text` |
| `extract` | none | `text` (CSV; uses `EXTRACT_TABLES_JS` from `@casama/contracts`) |
| `upload` | `ref`, `name`, `media_type`, `data` (base64) | `text` |
| `download` | `url` | `file: { name, media_type, data }` (base64, 20 MB cap) |
| `url` | none | `url`, `title` |

Error codes: `stale_ref` (unknown ref, or the page navigated since the snapshot), `covered`,
`page_changed` (the element's fingerprint no longer matches the one given), `not_editable`,
`not_file_input`, `too_large`, `out_of_sight` (focus is in a frame or shadow root the script can't
see into), `unsupported`, `error`.

## Snapshot text

The same shape `apps/extension/src/lib/act/snapshot.ts` produces (`formatSnapshot`,
`readableText`), which is `agent-browser`'s:

```
- button "Check out" [ref=e1]
- textbox "Coupon" [ref=e2]: "SAVE10"
- checkbox "Gift wrap" [ref=e3] [checked]
```

- Interactive roles get refs: button, link, textbox, searchbox, combobox, checkbox, radio, switch,
  slider, spinbutton, menuitem, menuitemcheckbox, menuitemradio, option, tab, treeitem, listbox.
- Flags: checked, mixed, disabled, expanded, collapsed, selected, focused, `level=`.
- A value is shown only for textbox, searchbox, combobox, spinbutton and slider, and **never for a
  password field, or a field whose autocomplete is `cc-*`, `one-time-code`, `current-password` or
  `new-password`** (the value is replaced by nothing at all).
- Full mode (`interactive_only: false`) also prints headings (`- heading "…" [level=1]`), text,
  images with alt text, cells, alerts and status, indented two spaces per depth.
- Frames are appended as `- frame:` blocks with refs continuing.
- Ends with `… (snapshot trimmed)` past `max_lines`; an empty page is `(nothing on the page)`.

Roles and names come from the DOM: explicit `role`, else the element's implicit role; the name from
`aria-labelledby`, `aria-label`, a `<label>`, `alt`, `title`, `placeholder`, else its visible text.

## Hidden text is left out

The rules of `hiddenNodes` in the extension are the spec. An element and everything under it is
hidden when any of these holds: `display:none`; `visibility` hidden or collapse; opacity below
0.05; text with font-size under 2px; `clip: rect(0 0 0 0)`; `clip-path` of `inset(50%)`,
`inset(100%)` or `circle(0…`; a box that clips overflow and is 1px or less wide or tall; a text box
under 1px; positioned off the page to the left or above; `aria-hidden="true"`; the `hidden`
attribute; `inert`. A zero-size box counts only when it also clips.

## Facts (for the server's rules)

`probe` returns what `packages/domain/src/browser-risk.ts` needs, and nothing from the field's
value:

```
{ role, name, url, tag, inputType, autocomplete, submits, passwordForm, inForm, submitName,
  editable, isFile, host }
```

- `submits`: a `button` that is not type `button` or `reset`, or an `input` of type `submit` or
  `image`, inside a form.
- `passwordForm`: the element's form has an `input[type=password]`.
- `submitName`: the name of the form's first submit control (for Enter).
- `fingerprint`: a short hash of `role|name|tag|inputType|autocomplete|submits|passwordForm|host`.
  A step that carries a fingerprint is refused with `page_changed` when it no longer matches.

## Acting

- **click**: scroll into view, check nothing covers the centre (`elementFromPoint`, a `<label>` for
  the field counts as the field), then with `synthetic: true` send pointerdown, mousedown,
  pointerup, mouseup and click at the centre. With `synthetic: false` do everything but the events.
- **fill**: focus, select all, then insert the text through the browser's own editing path
  (`document.execCommand("insertText")`), falling back to the native value setter plus `input` and
  `change` events. Works for inputs, textareas and contenteditable. An empty string clears.
- **type**: the same insert into whatever has focus.
- **press**: keydown, keypress, keyup on the focused element; Enter in a form calls
  `form.requestSubmit()` when the page didn't cancel the keydown; Tab moves focus.
- Password, card and one-time-code fields are refused by `fill` and `type` with `unsupported`
  ("typed by the person"), whatever the server decided. A second lock, not the only one.

## Refs

Kept in the top frame as a map from `e<n>` to a weak reference to the element (and, for elements in
a child frame, to the frame plus a ref inside it). The map is cleared on every snapshot and when
the page unloads, so an old ref is `stale_ref`.

## Frames

The script runs in each frame. For `snapshot` and `read` the top frame asks each visible, same-
process-reachable child (`iframe.contentWindow.postMessage` with a per-page random token agreed at
start through a `MessageChannel`) for its part, waits up to 500 ms each, and appends what answers.
A frame that doesn't answer is printed as `- frame: (not readable)`. Up to 20 frames.

## Tests

`pnpm --filter @casama/page-agent test` loads the built file into Playwright's WebKit and Chromium
and runs it against the shared pages in `packages/evals/src/browser-pages.ts` plus its own.
