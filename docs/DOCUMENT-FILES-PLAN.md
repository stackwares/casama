# Making PDF and Word files without a computer (plan)

Status: built 2026-11-17 (approved by Oliver: "All is approved"). Body fonts are Roboto, which pdfmake ships, instead of Noto Sans; code uses Courier. Follows D-351 (file work without a computer).

## The problem

"Send me that as a PDF" or "make this a Word doc" works only when the bot has a computer, where it
runs pandoc or LibreOffice. A bot without a computer, or on the person's Mac with no shared
folders, can only paste the text. This comes up most in chat apps, where a file is the natural
thing to send back.

## What the bot gets

One tool, `documents.make`:

- **Input:** Markdown (headings, paragraphs, bold and italic, links, bullet and numbered lists,
  tables, block quotes, code blocks, horizontal rules, and pictures given as `media:` ids), a
  file name, and `format: "pdf" | "docx"`. Optional page size (A4 or Letter, by the person's
  locale) and a title for the Library.
- **Output:** the file kept like other made files (`chat_media` and the Library), shown under the
  reply and sent on to chat apps (D-342).
- **Limits:** about 200 pages and 10 MB out; pictures shrunk to fit the page.

## How (recommended)

- **Word:** the `docx` package (MIT, pure JS). Markdown parsed with `marked`'s lexer (MIT), which
  maps cleanly onto docx paragraphs, runs, lists and tables. Small and fast.
- **PDF:** `pdfmake` (MIT, pure JS, built on pdfkit) from the same parsed Markdown. It handles text
  flow, page breaks, lists, tables and pictures. Fonts are embedded: Noto Sans and Noto Sans Mono
  (Latin, Greek, Cyrillic, about 1 MB), plus Noto Sans CJK for Chinese, Japanese and Korean (see
  Decisions).

### Rejected

- **Headless Chromium on the server:** best layout, but 300+ MB more image and a browser process
  per request on the API server.
- **Typst binary:** excellent output, but a second toolchain (about 40 MB) and Markdown has to be
  turned into Typst markup first.
- **pdf-lib by hand:** no text flow; we'd be writing a layout engine.

## Decisions

1. **CJK text: included** (Oliver, 2026-11-17: "Yes add those languages"). The server image gets
   Noto Sans CJK (one collection covering Simplified and Traditional Chinese, Japanese and Korean)
   in Regular and Bold, about 40 MB together; pdfkit can't fake bold, so both weights are needed.
   The fonts live in the image, not the repo, and pdfmake picks them for runs of CJK characters,
   so Latin text keeps Noto Sans. Self-hosters get them too (OFL-1.1).
2. **Look: plain** unless Oliver says otherwise: black text, one font family, page numbers in the
   footer. These are the person's documents, not Casama's.

## Work

1. `documents.make` in `file-ops.ts` + `tools/autonomy.ts`; the `documents` group purpose and the
   context line mention it.
2. Tests: each Markdown element in both formats (docx read back through the D-125 parser, PDF
   text through pdf.js), page size, pictures by `media:` id, the limits.
3. Docs: the "Edit pictures and documents without a computer" section in `docs-site/guide/chat.md`.
4. THIRD_PARTY_NOTICES: docx, marked, pdfmake, Noto fonts (OFL-1.1).
5. `apps/server/Dockerfile`: install the Noto Sans CJK Regular and Bold collection in the runtime
   stage. Debian's `fonts-noto-cjk` also ships the Serif collections, so measure it; if it's much
   over 40 MB, copy only the two Sans files into the image instead. Add a test that the server
   finds the fonts (skipped when they aren't installed locally) and a font path setting for
   self-hosters.

About half a day. No database changes, no app build.
