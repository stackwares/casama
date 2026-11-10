import { describe, expect, it } from "vitest";
import { fileSearchCommand } from "../src/desktop-context.ts";

describe("desktop file search", () => {
  it("uses each platform's own index, scoped to the allowed folders", () => {
    const mac = fileSearchCommand("macos", ["/Users/ana/Documents", "/Users/ana/Downloads"], "tax 2026", 20);
    expect(mac).toContain("mdfind -onlyin '/Users/ana/Documents' 'tax 2026'");
    expect(mac).toContain("mdfind -onlyin '/Users/ana/Downloads' 'tax 2026'");
    expect(mac).toContain("head -n 20");
    const linux = fileSearchCommand("linux", ["/home/ana/docs"], "inv*oice", 10);
    expect(linux).toContain("locate -i -l 10 '/home/ana/docs/*invoice*'");
    expect(linux).toContain("find '/home/ana/docs' -iname '*invoice*'");
    const win = fileSearchCommand("windows", ["C:\\Users\\Ana\\Documents"], "o'brien", 5);
    expect(win).toContain("powershell -NoProfile -Command");
    // computerd runs commands with bash on every platform, so the PowerShell script is shell-quoted.
    expect(win).toContain("file:C:/Users/Ana/Documents");
    expect(win).toContain("SELECT TOP 5 System.ItemPathDisplay FROM SystemIndex");
    // Quotes in the query can't break out of the shell argument.
    expect(fileSearchCommand("macos", ["/x"], "a'; rm -rf ~; '", 5)).toContain(`'a'\\''; rm -rf ~; '\\'''`);
  });
});
