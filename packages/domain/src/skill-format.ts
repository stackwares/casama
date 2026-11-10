/**
 * The open Agent Skills format (D-104): a folder with SKILL.md, whose YAML front matter has at least
 * `name` and `description`, followed by the instructions in Markdown.
 */

export interface ParsedSkill {
  name: string;
  description: string;
  body: string;
  /** Every front matter field, as strings (nested values are kept as their raw text). */
  meta: Record<string, string>;
}

export class SkillFormatError extends Error {}

export const SKILL_NAME = /^[a-z0-9][a-z0-9_-]{0,62}$/;

const unquote = (v: string) => {
  const t = v.trim();
  if ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) {
    const inner = t.slice(1, -1);
    return t.startsWith('"')
      ? inner.replace(/\\"/g, '"').replace(/\\n/g, "\n")
      : inner.replace(/''/g, "'");
  }
  return t;
};

/** Parses the small YAML subset skills use: `key: value`, quoted values, and `|` / `>` blocks. */
export function parseFrontMatter(text: string): Record<string, string> {
  const out: Record<string, string> = {};
  const lines = text.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? "";
    const m = /^([A-Za-z0-9_-]+):\s*(.*)$/.exec(line);
    if (!m?.[1]) continue;
    const key = m[1];
    const rest = m[2] ?? "";
    if (/^[|>][+-]?\s*$/.test(rest)) {
      const block: string[] = [];
      while (
        i + 1 < lines.length &&
        (/^\s+\S/.test(lines[i + 1] ?? "") || (lines[i + 1] ?? "").trim() === "")
      ) {
        block.push((lines[++i] ?? "").replace(/^\s{1,}/, ""));
      }
      const joined = rest.startsWith(">") ? block.join(" ").replace(/\s+/g, " ") : block.join("\n");
      out[key] = joined.trim();
    } else if (rest === "") {
      // A nested map or list: keep its indented lines as raw text.
      const block: string[] = [];
      while (i + 1 < lines.length && /^\s+/.test(lines[i + 1] ?? "")) block.push(lines[++i] ?? "");
      out[key] = block.join("\n");
    } else {
      out[key] = unquote(rest);
    }
  }
  return out;
}

/** Parses a SKILL.md file. Throws SkillFormatError with a readable reason. */
export function parseSkillMd(text: string): ParsedSkill {
  const m = /^﻿?---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/.exec(text);
  if (!m) throw new SkillFormatError("SKILL.md must start with front matter between --- lines.");
  const meta = parseFrontMatter(m[1] ?? "");
  const name = (meta.name ?? "").trim();
  const description = (meta.description ?? "").trim();
  if (!SKILL_NAME.test(name))
    throw new SkillFormatError(
      "The skill name must be lowercase letters, digits, - or _ (up to 63).",
    );
  if (!description) throw new SkillFormatError("The skill needs a description.");
  return { name, description: description.slice(0, 300), body: (m[2] ?? "").trim(), meta };
}

/** Writes a SKILL.md file for a skill. */
export function renderSkillMd(s: { name: string; description: string; body: string }) {
  const desc = /[:#\n"']/.test(s.description) ? JSON.stringify(s.description) : s.description;
  return `---\nname: ${s.name}\ndescription: ${desc}\n---\n\n${s.body.trim()}\n`;
}
