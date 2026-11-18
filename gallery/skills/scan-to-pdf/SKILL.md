---
name: scan-to-pdf
description: Use when the person shares phone photos or scans of paper (receipts, letters, forms, book pages) and wants a clean, searchable PDF or the text from them.
---

# Scan to PDF

The tools are already on your computer: ImageMagick, heif-convert, ocrmypdf, Tesseract with English, Spanish, French, German, Portuguese, Italian, Japanese, Chinese and Korean, and pdftk. Don't install anything.

1. Put the pages in order. Ask if the order isn't clear from the file names.
2. Convert iPhone HEIC photos first: `heif-convert in.heic in.jpg`.
3. Clean each page: `convert page.jpg -auto-orient -deskew 40% -trim +repage -normalize -quality 85 page-clean.jpg`. For black text on white paper, add `-colorspace Gray`.
4. Join them: `convert page-*-clean.jpg scan.pdf`.
5. Make it searchable: `ocrmypdf -l eng --rotate-pages --deskew --optimize 2 scan.pdf scan-searchable.pdf`. Pick the language code from the text (`spa`, `fra`, `deu`, `por`, `ita`, `jpn`, `chi_sim`, `kor`; join several with `+`).
6. Check the text came through: `pdftotext scan-searchable.pdf - | head -40`.
7. Hand back the PDF. If they wanted the text or the numbers (a receipt total, a date, an address), give those too.

If the text reads badly, say which pages and suggest a sharper photo in better light rather than guessing at the words.
