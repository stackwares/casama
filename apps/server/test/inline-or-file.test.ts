import { createPrivateKey, generateKeyPairSync } from "node:crypto";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { inlineOrFile } from "../src/billing/index.ts";

/** How the server reads keys from its env: a file path, inline text, or a PEM on one line. */
describe("inlineOrFile", () => {
  const pem = generateKeyPairSync("ec", { namedCurve: "P-256" })
    .privateKey.export({ type: "pkcs8", format: "pem" })
    .toString();

  it("reads a PEM kept on one line with \\n escapes, as Apple's .p8 is kept in .env", () => {
    const oneLine = pem.trim().replace(/\n/g, "\\n");
    expect(oneLine).not.toContain("\n");
    const read = inlineOrFile(oneLine);
    expect(read).toBe(pem.trim());
    expect(() => createPrivateKey(read)).not.toThrow();
  });

  it("keeps a multi-line PEM as it is", () => {
    expect(inlineOrFile(pem)).toBe(pem.trim());
  });

  it("leaves JSON's own escapes alone (a service account with a key inside)", () => {
    const json = JSON.stringify({ private_key: pem });
    expect(inlineOrFile(json)).toBe(json);
    expect(JSON.parse(inlineOrFile(json)).private_key).toBe(pem);
  });

  it("reads a file path", () => {
    const dir = mkdtempSync(join(tmpdir(), "casama-key-"));
    const path = join(dir, "AuthKey.p8");
    writeFileSync(path, pem);
    expect(inlineOrFile(path)).toBe(pem);
  });
});
