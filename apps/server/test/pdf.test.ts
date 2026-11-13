import { describe, expect, it } from "vitest";
import { chromiumPdfArgs, remotePdf } from "../src/services/pdf.ts";

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

describe("PDF sidecar", () => {
  it("posts the page as index.html and returns the PDF bytes", async () => {
    let seen: { url: string; name?: string; body?: string } | undefined;
    const fetcher = (async (url: string, init: RequestInit) => {
      const file = (init.body as FormData).get("files") as File;
      seen = { url, name: file.name, body: await file.text() };
      return new Response(new Uint8Array([37, 80, 68, 70]));
    }) as unknown as typeof fetch;
    const pdf = await remotePdf("http://pdf:3000/", fetcher).render("<h1>Hi</h1>");
    expect(seen).toEqual({
      url: "http://pdf:3000/forms/chromium/convert/html",
      name: "index.html",
      body: "<h1>Hi</h1>",
    });
    expect([...pdf]).toEqual([37, 80, 68, 70]);
  });

  it("fails when the renderer does", async () => {
    const fetcher = (async () => new Response("no", { status: 503 })) as unknown as typeof fetch;
    await expect(remotePdf("http://pdf:3000", fetcher).render("x")).rejects.toThrow("503");
  });
});
