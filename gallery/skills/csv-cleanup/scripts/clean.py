#!/usr/bin/env python3
"""Clean a CSV file: trim cells, snake_case headers, drop empty and duplicate rows."""
import csv
import re
import sys


def snake(name: str) -> str:
    s = re.sub(r"[^0-9a-zA-Z]+", "_", name.strip()).strip("_").lower()
    return s or "column"


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: clean.py input.csv output.csv", file=sys.stderr)
        return 2
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, newline="", encoding="utf-8-sig") as f:
        rows = list(csv.reader(f))
    if not rows:
        print("The file is empty.")
        return 1
    header = [snake(h) for h in rows[0]]
    seen, out, empty, dupes = set(), [], 0, 0
    for row in rows[1:]:
        cells = tuple(c.strip() for c in row)
        if not any(cells):
            empty += 1
            continue
        if cells in seen:
            dupes += 1
            continue
        seen.add(cells)
        out.append(cells)
    with open(dst, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(out)
    print(f"Kept {len(out)} rows; removed {empty} empty and {dupes} duplicate rows. Headers: {', '.join(header)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
