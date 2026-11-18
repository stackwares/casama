---
name: convert-photos
description: Use when the person shares photos to convert, resize, compress, rotate or strip location from, including iPhone HEIC photos that won't open elsewhere.
---

# Convert photos

The tools are already on your computer: heif-convert, ImageMagick (`convert`, `mogrify`, `identify`), cwebp, exiftool and Python Pillow with pillow-heif. Don't install anything.

1. Copy the photos into a working folder and check what they are: `identify -format '%f %m %wx%h %b\n' *`.
2. HEIC or HEIF (iPhone): `heif-convert -q 90 in.heic out.jpg`. For many files, loop over them; keep the original names.
3. Do what they asked:
   - Resize for email or the web: `convert in.jpg -auto-orient -resize 2048x2048\> -quality 85 out.jpg`.
   - Compress: `-quality 80`, or `cwebp -q 80 in.jpg -o out.webp` when they don't need JPEG.
   - Rotate: `-auto-orient` fixes sideways phone photos; `-rotate 90` turns by hand.
   - Remove location and camera data before sharing: `exiftool -all= -overwrite_original out.jpg`.
   - Rename by date taken: `exiftool '-FileName<DateTimeOriginal' -d '%Y-%m-%d %H.%M.%S%%-c.%%e' .`.
   - A collage or contact sheet: `montage *.jpg -tile 3x -geometry 600x600+8+8 sheet.jpg`.
4. Check the results: open one, and compare sizes before and after.
5. Hand back the files, zipped when there are more than a few, and say what changed (format, size before and after, data removed).

Never overwrite the originals. Say plainly when a photo couldn't be read.
