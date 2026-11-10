/** A line diff for previews (skill updates; D-104): unified-style lines with +, - and space. */
export function lineDiff(
  before: string,
  after: string,
  opts: { context?: number; maxLines?: number } = {},
) {
  const a = before.split("\n");
  const b = after.split("\n");
  const ctx = opts.context ?? 2;
  const max = opts.maxLines ?? 400;
  // LCS table (skills are small; capped to keep it cheap).
  if (a.length * b.length > 4_000_000) return [`- (${a.length} lines)`, `+ (${b.length} lines)`];
  const dp: Uint32Array[] = Array.from(
    { length: a.length + 1 },
    () => new Uint32Array(b.length + 1),
  );
  for (let i = a.length - 1; i >= 0; i--)
    for (let j = b.length - 1; j >= 0; j--)
      (dp[i] as Uint32Array)[j] =
        a[i] === b[j]
          ? ((dp[i + 1] as Uint32Array)[j + 1] as number) + 1
          : Math.max(
              (dp[i + 1] as Uint32Array)[j] as number,
              (dp[i] as Uint32Array)[j + 1] as number,
            );
  const ops: Array<[" " | "+" | "-", string]> = [];
  let i = 0;
  let j = 0;
  while (i < a.length && j < b.length) {
    if (a[i] === b[j]) {
      ops.push([" ", a[i] as string]);
      i++;
      j++;
    } else if (
      ((dp[i + 1] as Uint32Array)[j] as number) >= ((dp[i] as Uint32Array)[j + 1] as number)
    )
      ops.push(["-", a[i++] as string]);
    else ops.push(["+", b[j++] as string]);
  }
  while (i < a.length) ops.push(["-", a[i++] as string]);
  while (j < b.length) ops.push(["+", b[j++] as string]);
  // Keep changes with a little context around them.
  const keep = new Set<number>();
  ops.forEach(([op], k) => {
    if (op !== " ") for (let d = -ctx; d <= ctx; d++) keep.add(k + d);
  });
  const out: string[] = [];
  let last = -1;
  for (let k = 0; k < ops.length; k++) {
    if (!keep.has(k)) continue;
    if (last >= 0 && k > last + 1) out.push("…");
    const [op, line] = ops[k] as [string, string];
    out.push(`${op} ${line}`);
    last = k;
    if (out.length >= max) {
      out.push("…");
      break;
    }
  }
  return out;
}
