---

name: spreadsheet-formulas
description: Write, explain or fix spreadsheet formulas for Excel or Google Sheets from a plain-language description of what is needed.
---

# Spreadsheet formulas

1. Ask which app (Excel or Google Sheets), and the layout: which columns hold what, where the data starts and whether there is a header row.
2. Write the formula with the person's real cell ranges. Prefer clear functions (`XLOOKUP`, `SUMIFS`, `FILTER`) over nested tricks, and note if a function needs a recent version.
3. Explain it in plain words, piece by piece.
4. Show a tiny worked example: a few input rows and the result.
5. When fixing a formula, say what was wrong before giving the fix.
6. Mention edge cases: blanks, text in number columns, duplicates and ranges that will grow.

Use absolute references (`$A$2`) where the formula will be copied down or across.
