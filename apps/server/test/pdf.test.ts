import { describe, expect, it } from "vitest";
import { chromiumPdfArgs } from "../src/services/pdf.ts";

describe("PDF print", () => {
  const args = (asRoot: boolean) =>
    chromiumPdfArgs(
      { profile: "/tmp/profile", out: "/tmp/page.pdf", src: "/tmp/page.html" },
      { asRoot },
    );

  it("blocks network and other files, and sandboxes when it can", () => {
    const flags = args(false);
    expect(flags).toContain("--host-resolver-rules=MAP * ~NOTFOUND");
    expect(flags).toContain("--proxy-server=http://127.0.0.1:9");
    expect(flags).toContain("--proxy-bypass-list=<-loopback>");
    expect(flags).not.toContain("--no-sandbox");
    expect(flags).not.toContain("--allow-file-access-from-files");
    expect(flags).not.toContain("--disable-web-security");
    expect(flags.at(-1)).toBe("file:///tmp/page.html");
  });

  it("drops the browser sandbox only when the process is root", () => {
    expect(args(true)).toContain("--no-sandbox");
  });
});
