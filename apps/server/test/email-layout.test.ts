import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  EMAIL_ASSET_BASE,
  renderEmailHtml,
  renderEmailText,
} from "../src/services/email-layout.ts";

describe("Casama email layout", () => {
  const invite = {
    mascot: "wow" as const,
    preheader: "Join <b>Ops</b>",
    title: `You're invited to <script>alert(1)</script>`,
    intro: ["Sign in with a&b@example.com to accept."],
    button: { label: "Join the workspace", url: "https://casama.ai/join/abc?x=1&y=2" },
    note: "This link expires in 7 days.",
  };

  it("escapes what people control and keeps the brand pieces", () => {
    const html = renderEmailHtml(invite);
    expect(html).not.toContain("<script>");
    expect(html).toContain("&lt;script&gt;");
    expect(html).toContain("a&amp;b@example.com");
    expect(html).toContain('href="https://casama.ai/join/abc?x=1&amp;y=2"');
    expect(html).toContain(`${EMAIL_ASSET_BASE}/wow.gif`);
    expect(html).toContain("#7A3FA8"); // plum button
    expect(html).toContain("Libre Baskerville");
    expect(html).toContain("prefers-color-scheme: dark");
  });

  it("has a plain-text part with the link", () => {
    const text = renderEmailText(invite);
    expect(text).toContain("Join the workspace: https://casama.ai/join/abc?x=1&y=2");
    expect(text).toContain("support@casama.ai");
  });

  it("leaves Supabase placeholders as they are in the generated sign-in templates", () => {
    const html = readFileSync(
      new URL("../../../supabase/templates/magic_link.html", import.meta.url),
      "utf8",
    );
    expect(html).toContain("{{ .Token }}");
    expect(html).toContain('href="{{ .ConfirmationURL }}"');
    expect(html).toContain(`${EMAIL_ASSET_BASE}/winky.gif`);
  });
});
