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

  it("open models that read images are known by name (D-330)", () => {
    for (const m of [
      "gemma4:12b",
      "gemma4:e4b",
      "gemma3:27b",
      "llava:13b",
      "qwen2.5vl:7b",
      "llama3.2-vision",
    ])
      expect(capabilitiesOf(m, "openai_compatible").vision, m).toBe(true);
    for (const m of [
      "gemma3:1b",
      "gemma3:270m",
      "llama3.1:8b",
      "qwen3:8b",
      "mistral:7b",
      "my-finetune:q4",
    ])
      expect(capabilitiesOf(m, "openai_compatible").vision, m).toBe(false);
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

  it("a model marked on its OpenAI-compatible credential reads images (D-330)", async () => {
    const [org] = await tdb.admin<{ id: string }[]>`
      insert into public.organizations (name, slug) values ('Vision', 'local-vision') returning id`;
    const [local] = await tdb.admin<{ id: string }[]>`
      insert into public.model_credentials (org_id, provider, label, base_url, settings)
      values (${org!.id}, 'openai_compatible', 'LM Studio', 'http://127.0.0.1:1234/v1',
              ${tdb.admin.json({ vision_models: ["my-vlm"] })}) returning id`;
    const [openai] = await tdb.admin<{ id: string }[]>`
      insert into public.model_credentials (org_id, provider, label, settings)
      values (${org!.id}, 'openai', 'OpenAI', ${tdb.admin.json({ vision_models: ["my-vlm"] })})
      returning id`;
    const creds = new CredentialResolver(h.db);
    expect(await creds.markedVision(org!.id, { credential_id: local!.id, model: "my-vlm" })).toBe(
      true,
    );
    expect(await creds.markedVision(org!.id, { credential_id: local!.id, model: "my-llm" })).toBe(
      false,
    );
    // Only OpenAI-compatible servers, and only in the run's own workspace.
    expect(await creds.markedVision(org!.id, { credential_id: openai!.id, model: "my-vlm" })).toBe(
      false,
    );
    const [other] = await tdb.admin<{ id: string }[]>`
      insert into public.organizations (name, slug) values ('Other', 'local-vision-2') returning id`;
    expect(await creds.markedVision(other!.id, { credential_id: local!.id, model: "my-vlm" })).toBe(
      false,
    );
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
