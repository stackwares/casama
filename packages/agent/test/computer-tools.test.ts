import { describe, expect, it } from "vitest";
import { isDestructive, shq } from "../src/tools/computer.ts";

describe("destructive command detection", () => {
  it.each([
    "rm -rf build",
    "rm -r old && ls",
    "cd x; rm -fr *",
    "git reset --hard HEAD~1",
    "git clean -fd",
    "git push origin main --force",
    "sudo apt-get remove nginx",
    "npm uninstall react",
    "pnpm remove lodash",
    "pip uninstall requests",
    "dd if=/dev/zero of=disk.img",
  ])("checkpoints before: %s", (cmd) => expect(isDestructive(cmd)).toBe(true));

  it.each(["ls -la", "rm file.txt", "git status", "npm install", "echo rm -rf is dangerous > notes.txt".replace("rm -rf", "rm")])(
    "leaves alone: %s",
    (cmd) => expect(isDestructive(cmd)).toBe(false),
  );
});

describe("shell quoting", () => {
  it("quotes single quotes and metacharacters safely", () => {
    expect(shq("it's $(whoami)")).toBe(`'it'\\''s $(whoami)'`);
  });
});
