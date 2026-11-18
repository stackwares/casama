import { describe, expect, it } from "vitest";
import { lineDiff } from "../src/diff.ts";
import { parseSkillMd, renderSkillMd } from "../src/skill-format.ts";

describe("SKILL.md", () => {
  it("reads front matter, block scalars and the body", () => {
    const s = parseSkillMd(
      '---\nname: pdf-forms\ndescription: >\n  Fill PDF forms\n  from data.\nlicense: MIT\nmetadata:\n  version: "1"\n---\n# Steps\n\nRun fill.py\n',
    );
    expect(s).toMatchObject({
      name: "pdf-forms",
      description: "Fill PDF forms from data.",
      body: "# Steps\n\nRun fill.py",
    });
    expect(s.meta.license).toBe("MIT");
    expect(
      parseSkillMd(renderSkillMd({ name: "a-b", description: "Says: hi", body: "x" })).description,
    ).toBe("Says: hi");
  });

  it("explains what is wrong", () => {
    expect(() => parseSkillMd("no front matter")).toThrow(/front matter/);
    expect(() => parseSkillMd("---\nname: Bad Name\ndescription: x\n---\n")).toThrow(/lowercase/);
    expect(() => parseSkillMd("---\nname: ok\n---\n")).toThrow(/description/);
  });
});

describe("lineDiff", () => {
  it("shows changed lines with context", () => {
    expect(lineDiff("a\nb\nc\nd\ne\nf\ng", "a\nb\nC\nd\ne\nf\ng", { context: 1 })).toEqual([
      "  b",
      "- c",
      "+ C",
      "  d",
    ]);
    expect(lineDiff("x", "x")).toEqual([]);
  });
});
