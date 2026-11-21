# @casama/page-agent

The script the phone app runs inside its browser (docs/PHONE-BROWSER-PLAN.md §8.3). It does for a
web view what Chrome's debugger does for Casama for Chrome: reads the page into the same snapshot
text with `@e1` refs, and carries out steps on it. One file, the same on iOS and Android, shipped
inside the app (never downloaded).

It runs in an isolated script world, in every frame, from document start. It shares the DOM with
the page but not the page's JavaScript globals. As a second line of defence it captures the DOM and
language built-ins it uses when it starts (before any page script) and only calls those, so a page
that later replaces `String.prototype.trim`, `Element.prototype.getAttribute`, `JSON.stringify` or
an inherited property can't change what it reads or does (see `src/prims.ts` for the rules).

## Build

`pnpm --filter @casama/page-agent build` writes `dist/page-agent.js` (one IIFE, no imports) and
copies it to `client/assets/app_browser/page_agent.js`. `pnpm --filter @casama/page-agent check`
fails when the copy is stale. The output is deterministic. `EXTRACT_TABLES_JS` is compiled in as a
function at build time, so the script never evaluates a string.

Before injecting the script native may define, in the same world,
`__casamaPageAgentConfig = { secret: "<random per page load>", downloadCap: <bytes> }`. The script
reads it once and deletes it. `secret` guards the frame channel (see Frames); `downloadCap` can only
lower the 20 MB cap.

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
and answers commands that arrive on `casamaNative.onmessage` (or its `message` event, when it has
`addEventListener`) with `casamaNative.postMessage(json)`. Commands and answers on that port are JSON
strings. The script takes the object and deletes the `casamaNative` global, so page scripts that
run later can't post fake answers through it. `handle` also accepts the command as a JSON string.

Command fields are read as own properties only: a page that plants `Object.prototype.ref` doesn't
give a command a ref.

Only the top frame owns refs. Child frames answer `frame_snapshot` and act on refs the top frame
gave them (see Frames).

## Commands

| cmd | args | answer fields |
|---|---|---|
| `snapshot` | `interactive_only` (default true), `max_lines` (default 1500) | `text`, `url`, `title` |
| `read` | `max` (default 60000 chars) | `text`, `url`, `title` |
| `probe` | `ref`, or `focused: true` | `facts` (below), `fingerprint` |
| `locate` | `ref` | `x`, `y` (CSS px, centre, in the top frame's viewport), `fingerprint`; scrolls it into view first; `covered` error when something else is on top |
| `click` | `ref`, `fingerprint?`, `synthetic` (default true: send the events itself; false: native will tap, only verify) | `text` |
| `fill` | `ref`, `text`, `fingerprint?` | `text` (on a `<select>` it picks the option whose text or value matches, then one whose text contains it: `Picked "Large".`) |
| `type` | `text`, `fingerprint?` | `text` (types into the focused element) |
| `press` | `key` (e.g. `Enter`, `Tab`, `Escape`, `ArrowDown`, `Control+Enter`), `fingerprint?` | `text` |
| `scroll` | `direction` (`up`/`down`/`left`/`right`), `amount?` (px, default 600) | `text` |
| `wait` | `text?`, `ms?` (cap 30000) | `text` |
| `extract` | none | `text` (CSV; uses `EXTRACT_TABLES_JS` from `@casama/contracts`) |
| `upload` | `ref`, `name`, `media_type`, `data` (base64) | `text` |
| `download` | `url`, `max_bytes?` (can only lower the cap) | `text`, `file: { name, media_type, data }` (base64, 20 MB cap; http, https, blob and data addresses) |
| `url` | none | `url`, `title` |

Error codes: `stale_ref` (unknown ref, or the page navigated since the snapshot), `covered`,
`page_changed` (the element's fingerprint no longer matches the one given), `not_editable`,
`not_file_input`, `too_large`, `out_of_sight` (focus is in a frame or shadow root the script can't
see into), `timeout` (`wait` for text that didn't show up), `unsupported`, `error`. A ref that
points at something invisible or off the screen also answers `covered`.

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
  An interactive element's own text is its name and isn't repeated, but controls inside it (options
  in a custom listbox, a checkbox inside a link) are listed under it. A native `<select>`'s options
  aren't listed; `fill` picks one by its text.
- Flags: checked, mixed, disabled, expanded, collapsed, selected, focused, `level=`.
- A value is shown only for textbox, searchbox, combobox, spinbutton and slider, and **never for a
  password field, or a field whose autocomplete is `cc-*`, `one-time-code`, `current-password` or
  `new-password`** (the value is replaced by nothing at all).
- Full mode (`interactive_only: false`) also prints headings (`- heading "…" [level=1]`), text,
  images with alt text, cells, alerts and status, indented two spaces per depth.
- Frames are appended as `- frame:` blocks with refs continuing.
- Ends with `… (snapshot trimmed)` past `max_lines`; an empty page is `(nothing on the page)`.

Roles and names come from the DOM: explicit `role`, else the element's implicit role (`<input
type=date>` and its kin count as textboxes, so `fill` can set them). The name comes from, in order:
`aria-labelledby` (the visible text of what it points at), `aria-label`, the visible text of the
field's `<label>`s, `alt`, a submit or reset button's value, the visible text inside (for roles named
by their content: buttons, links, options, headings, cells…), `title`, `placeholder`. Text that's
hidden never counts, so a visually hidden label leaves a field named by its placeholder or unnamed.

`read` follows `readableText`: headings as `#` lines, fields as `[name]`, a new line at each block
(paragraphs, list items, rows, and any element displayed as a block) and at `<br>`.

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
- `url` and `host`: the address of the frame the element is in.
- `fingerprint`: 8 hex digits, FNV-1a of `role|name|tag|inputType|autocomplete|submits|passwordForm|host`.
  A step that carries a fingerprint is refused with `page_changed` when it no longer matches.
- `probe` with `focused: true` follows focus into open shadow roots and into child frames that
  answer; focus in a closed shadow root or a frame that doesn't answer is `out_of_sight`.

## Acting

- **click**: scroll into view, check nothing covers the centre of its visible part
  (`elementFromPoint` in its own document or shadow root; a `<label>` for the field counts as the
  field), then with `synthetic: true` send pointerover, mouseover, pointerdown, mousedown (focus
  moves as on a real click), pointerup, mouseup and click at the centre, on the element actually
  there. With `synthetic: false` do everything but the events. A ref in a child frame is located
  in the frame, then the top frame checks the frame itself isn't covered at that point.
- **fill**: focus, select all, then insert the text through the browser's own editing path
  (`document.execCommand("insertText")`), falling back to the prototype's own value setter (so a
  React-style value tracker sees the change) plus an `input` event; inputs and textareas then get
  `change`. Works for inputs, textareas and contenteditable. An empty string clears. Refused with
  `not_editable` for anything else (checkboxes: use click), and for read-only or disabled fields.
  When a field reformats what it was given, the answer says what it now shows.
- **type**: the same insert into whatever has focus.
- **press**: keydown, keypress (characters and Enter), keyup on the focused element (the body when
  nothing has focus). When the page didn't cancel the keydown: Enter in a form field calls
  `form.requestSubmit()` with its default button, Enter in a textarea or editable area inserts a new
  line, Enter or Space on a button or link clicks it, Tab and Shift+Tab move focus, Backspace and
  Delete delete, Ctrl/Cmd+A selects all, and a single character is inserted like typing.
- Password, card and one-time-code fields are refused by `fill`, `type` and character `press`es
  with `unsupported` ("typed by the person"), whatever the server decided. A second lock, not the
  only one. Their values are never read: not for the snapshot, `read`, facts, or to check an edit.

## Refs

Kept in the top frame as a map from `e<n>` to a weak reference to the element (and, for elements in
a child frame, to the frame plus a ref inside it). The map is cleared on every snapshot and when
the page unloads, so an old ref is `stale_ref`.

## Frames

The script runs in each frame, cross-site ones included. For `snapshot` and `read` the top frame
connects to each visible child frame: it posts `{"__casamaPageAgent":"connect","secret"}` to
`iframe.contentWindow` with one end of a fresh `MessageChannel`, and the child's agent answers
requests on that port (`ping`, `frame_snapshot`, `frame_read`, and forwarded steps). Frames are
asked in parallel and given up to 1 s to connect and 2 s to answer; what answers is appended as a
`- frame:` block (in an interactive snapshot only when it has refs), and a frame that doesn't answer
is printed as `- frame: (not readable)`. Hidden and zero-size frames are skipped. Up to 20 frames
per document; a child does the same for its own frames, so nesting works.

The child takes a connect message only from its direct parent window, and only with the right
secret when native configured one. Its listener is registered at document start, so it runs first
and stops the message before the page's own listeners see it. Without a configured secret, a script
in the parent page could connect to a child frame's agent too, which is why native should set one.

## Tests

`pnpm --filter @casama/page-agent test` builds the script in memory, loads it into Playwright's
WebKit and Chromium with `addInitScript` (fake `https://site.test` and `https://other.test` origins
served by `context.route`), and runs it against the shared pages in
`packages/evals/src/browser-pages.ts` plus its own: the snapshot shape, every hiding trick, covered
buttons, risky-control facts and fingerprints, sensitive fields, fill on React-style inputs, clicks,
keys, stale refs, frames, extract, download, upload, shadow roots, the Android port, and a page that
replaces built-ins. WebKit needs `pnpm --filter @casama/page-agent exec playwright install webkit` once per machine.

## Known gaps

- Closed shadow roots can't be read; focus inside one is `out_of_sight`.
- A frame where scripts can't run (a `sandbox` frame without `allow-scripts` in some engines, or one
  still loading) is `(not readable)`; its controls are the person's to use.
- Hidden-text rules are the extension's: text the same colour as its background, or covered by
  another element, still counts as visible.
- `extract` runs `EXTRACT_TABLES_JS` unchanged: it reads tables with `innerText`, so a hidden span
  inside a visible cell is included, and it uses the live built-ins rather than captured ones.
- Synthetic events are untrusted (`isTrusted` is false). Sites that check it, or that need real
  touches (some sliders, drag and drop, canvas apps), need native taps (`synthetic: false` plus
  `locate`), which is the Android plan anyway.
- `async`/`await` still go through the promise built-ins, so a page sharing the script's world could
  disturb timing by replacing `Promise.prototype.then`; in an isolated world it can't.
