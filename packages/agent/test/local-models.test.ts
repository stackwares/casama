/** Local models (D-271): free to run, and a local server can do memory search. */
import { createDb, type DbHandle } from "@casama/db";
import { startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { CredentialResolver } from "../src/credentials.ts";
import { EMBEDDING_DIMENSIONS, fitDimensions } from "../src/embeddings.ts";
import { capabilitiesOf, costOf } from "../src/gateway/registry.ts";

describe("local models (D-271)", () => {
  it("cost nothing on an OpenAI-compatible server, whatever they're called", () => {
    const usage = { inputTokens: 100_000, outputTokens: 50_000 };
    expect(costOf("my-finetune:q4", usage, "openai_compatible")).toBe(0);
    expect(capabilitiesOf("my-finetune:q4", "openai_compatible").inputPrice).toBe(0);
    // Elsewhere an unknown model still gets the cautious default.
    expect(costOf("my-finetune:q4", usage, "openrouter")).toBeGreaterThan(0);
  });

  it("shorter vectors are padded without changing similarity; longer ones are cut and renormalized", () => {
    const a = fitDimensions([0.6, 0.8]);
    expect(a).toHaveLength(EMBEDDING_DIMENSIONS);
    expect(a.slice(0, 2)).toEqual([0.6, 0.8]);
    const long = fitDimensions(new Array(EMBEDDING_DIMENSIONS + 512).fill(1));
    expect(long).toHaveLength(EMBEDDING_DIMENSIONS);
    expect(Math.hypot(...long)).toBeCloseTo(1, 6);
  });
});

describe("embedding credential", () => {
  let tdb: TestDatabase;
  let h: DbHandle;
  beforeAll(async () => {
    tdb = await startTestDatabase();
    h = createDb(tdb.url, { max: 2 });
  });
  afterAll(async () => {
    await h?.close();
    await tdb?.stop();
  });

  it("uses a local server that names an embedding model, and prefers an OpenAI key", async () => {
    const [org] = await tdb.admin<{ id: string }[]>`
      insert into public.organizations (name, slug) values ('Local', 'local-embed') returning id`;
    const creds = new CredentialResolver(h.db);
    await tdb.admin`insert into public.model_credentials (org_id, provider, label, base_url)
      values (${org!.id}, 'openai_compatible', 'Ollama, chat only', 'http://127.0.0.1:11434/v1')`;
    expect(await creds.embeddingCredential(org!.id)).toBeNull();
    await tdb.admin`insert into public.model_credentials (org_id, provider, label, base_url, settings)
      values (${org!.id}, 'openai_compatible', 'Ollama', 'http://127.0.0.1:11434/v1',
              ${tdb.admin.json({ embedding_model: "nomic-embed-text" })})`;
    expect(await creds.embeddingCredential(org!.id)).toMatchObject({
      provider: "openai_compatible",
      model: "nomic-embed-text",
      baseUrl: "http://127.0.0.1:11434/v1",
    });
    await tdb.admin`insert into public.model_credentials (org_id, provider, label, vault_secret_id)
      values (${org!.id}, 'openai', 'OpenAI', vault.create_secret('sk-openai-test-1234'))`;
    expect(await creds.embeddingCredential(org!.id)).toMatchObject({
      provider: "openai",
      model: "text-embedding-3-small",
    });
  });
});
