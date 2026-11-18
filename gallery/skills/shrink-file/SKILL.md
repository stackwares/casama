---
name: shrink-file
description: Use when a file is too big to send or upload (a PDF, photo, video, slide deck or folder) and the person needs it smaller, often under a size limit.
---

# Shrink a file

The tools are already on your computer: Ghostscript, qpdf, ocrmypdf, ImageMagick, cwebp, ffmpeg, LibreOffice, zip and 7z. Don't install anything.

1. Ask for the size limit if they didn't say one (email is often 20–25 MB, many forms 2–5 MB). Check the current size with `ls -lh`.
2. Pick by type, mildest first, and stop once it fits:
   - **PDF:** `gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=out.pdf in.pdf`. Use `/screen` if that isn't enough, `/printer` to keep print quality. Scans: `ocrmypdf --optimize 3 --skip-text in.pdf out.pdf`.
   - **Photo:** `convert in.jpg -auto-orient -resize 2048x2048\> -quality 80 out.jpg`, or WebP with `cwebp -q 75`.
   - **Video:** `ffmpeg -i in.mov -c:v libx264 -crf 28 -preset slow -vf "scale='min(1280,iw)':-2" -c:a aac -b:a 96k out.mp4`. To hit a size, work out the bitrate from the length and use two passes.
   - **Slides or documents:** shrink the pictures inside. Unzip the .pptx or .docx, run the photo step on `ppt/media` or `word/media`, zip it back. Or offer a PDF copy.
   - **Many files:** `7z a -mx=9 out.7z folder/`, or `zip -r -9` when they need a plain .zip.
3. Open the result and check it still looks right: text readable, faces clear, sound in sync.
4. Hand it back with the size before and after. If it can't reach the limit without looking bad, say so and offer to split it.

Never overwrite the original.
