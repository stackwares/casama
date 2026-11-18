import { describe, expect, it } from "vitest";
import { titleFromText } from "../src/creations.ts";
import { pageTitle } from "../src/pages.ts";

describe("titles people read", () => {
  it("decodes HTML entities a model copied from a page's <title>", () => {
    expect(pageTitle("Crumb &amp; Co &#8212; Neighbourhood Bakery")).toBe(
      "Crumb & Co — Neighbourhood Bakery",
    );
    expect(pageTitle("Mia&#39;s   &quot;plan&quot;")).toBe(`Mia's "plan"`);
    expect(titleFromText("Crumb &amp; Co hero")).toBe("Crumb & Co hero");
  });

  it("leaves plain titles alone and keeps them to 200 characters", () => {
    expect(pageTitle("Stardust Drift")).toBe("Stardust Drift");
    expect(pageTitle("x".repeat(250))).toHaveLength(200);
  });
});
