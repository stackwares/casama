import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { gunzipSync } from "node:zlib";
import { describe, expect, it } from "vitest";
import { createErrorReporter, scrubContext, scrubText } from "../src/index.ts";

describe("error payload scrubbing", () => {
  it("removes secrets, tokens and emails from text", () => {
    const s = scrubText(
      "call failed for ada@example.com with sk-or-v1-abcdef1234567890 and Bearer eyJabc.defghijklmnop.qrstu1234",
    );
    expect(s).not.toContain("ada@example.com");
    expect(s).not.toContain("sk-or-v1");
    expect(s).not.toContain("eyJabc");
  });

  it("keeps ids and codes but drops prompts, messages, arguments and keys", () => {
    expect(
      scrubContext({
        request_id: "r1",
        status: 500,
        prompt: "my secret plan",
        message: "hello",
        args: { a: 1 },
        api_key: "x",
        authorization: "Bearer y",
      }),
    ).toEqual({ request_id: "r1", status: 500 });
  });

  it("is off when nothing is configured", () => {
    expect(createErrorReporter({ service: "t" })).toBeNull();
    expect(
      createErrorReporter({ service: "t", errorReporting: "none", sentryDsn: "https://k@h/1" }),
    ).toBeNull();
  });
});

describe("PostHog reporter", () => {
  it("sends scrubbed exceptions to the configured host", async () => {
    const bodies: string[] = [];
    const server = createServer((req, res) => {
      const chunks: Buffer[] = [];
      req.on("data", (c) => chunks.push(c));
      req.on("end", () => {
        const raw = Buffer.concat(chunks);
        bodies.push(
          (req.headers["content-encoding"] === "gzip" ? gunzipSync(raw) : raw).toString(),
        );
        res.end("{}");
      });
    });
    await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
    const host = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
    const reporter = createErrorReporter({
      service: "kasama-api",
      posthogKey: "phc_test",
      posthogHost: host,
    });
    expect(reporter).not.toBeNull();
    reporter?.capture(
      new Error("model call failed for bob@example.com key sk-live-0123456789abcdef"),
      {
        run_id: "run-1",
        prompt: "do not send me",
      },
    );
    await reporter?.close();
    server.close();
    const all = bodies.join("\n");
    expect(all).toContain("$exception");
    expect(all).toContain("run-1");
    expect(all).not.toContain("bob@example.com");
    expect(all).not.toContain("sk-live-0123456789abcdef");
    expect(all).not.toContain("do not send me");
  });
});
