import { describe, expect, it } from "vitest";
import { builtinTools } from "../src/tools/builtin.ts";

// A skill's files belong in ~/skills/<name>/ (D-104), where the bot is told they are. A relative
// write would put them in ~/workspace (or the bot's folder on a team computer) instead.
describe("skills.load", () => {
  it("copies the skill's files to ~/skills/<name>/ and makes scripts executable there", async () => {
    const rows = [
      [{ id: "s1", name: "csv-cleanup", body_md: "Clean the CSV." }],
      [
        {
          path: "scripts/clean.py",
          content: Buffer.from("print(1)").toString("base64"),
          executable: true,
        },
        { path: "README.md", content: Buffer.from("hi").toString("base64"), executable: false },
      ],
    ];
    const db = { execute: async () => rows.shift() ?? [] } as never;
    const writes: string[] = [];
    const commands: string[] = [];
    const handle = {
      writeFile: async (p: string) => void writes.push(p),
      exec: (cmd: string) => {
        commands.push(cmd);
        return (async function* () {})();
      },
    } as never;
    const tools = builtinTools({ db, memory: async () => ({}) as never });
    const res = await tools.get("skills.load")!.execute(
      { name: "csv-cleanup" },
      {
        runId: "r",
        botId: "b",
        orgId: "o",
        output: async () => {},
        emit: async () => {},
        computer: async () => handle,
      },
    );
    expect(writes).toEqual([
      "/home/casama/skills/csv-cleanup/scripts/clean.py",
      "/home/casama/skills/csv-cleanup/README.md",
    ]);
    expect(commands).toEqual(["chmod +x '/home/casama/skills/csv-cleanup/scripts/clean.py'"]);
    expect(res.content).toContain("~/skills/csv-cleanup/: scripts/clean.py, README.md");
  });
});
