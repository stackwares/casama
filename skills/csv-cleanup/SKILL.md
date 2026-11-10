---
name: csv-cleanup
description: Clean a messy CSV file - trim spaces, normalize headers, drop empty and duplicate rows - and report what changed.
---

# CSV cleanup

Use the bundled script on your computer; it only reads the input and writes a new file.

```
python3 ~/skills/csv-cleanup/scripts/clean.py input.csv cleaned.csv
```

It trims whitespace in every cell, turns headers into `snake_case`, removes fully empty rows and exact duplicate rows, and prints a summary.

After running it:

1. Open the first rows of the cleaned file and check the headers look right.
2. Tell the person how many rows were removed and why (the script's summary).
3. Ask before doing anything that changes meaning, such as merging near-duplicates, fixing dates or filling blanks.
