import assert from "node:assert/strict";
import { describe, it } from "vitest";
import { listModels, mergeModelList } from "../src/models.ts";

const fakeFetch =
  (routes: Record<string, { status?: number; body: unknown }>, seen: string[] = []) =>
  async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    seen.push(`${url} ${JSON.stringify(init?.headers ?? {})}`);
    const hit = Object.entries(routes).find(([prefix]) => url.startsWith(prefix));
    if (!hit) return new Response("not found", { status: 404 });
    return new Response(JSON.stringify(hit[1].body), { status: hit[1].status ?? 200 });
  };

describe("model picker list", () => {
  it("puts featured OpenRouter models first and drops batch, image and embedding models", async () => {
    const f = fakeFetch({
      "https://openrouter.ai/api/v1/models": {
        body: {
          data: [
            { id: "acme/new-model", name: "Acme: New", created: 30, context_length: 1000 },
            { id: "openai/gpt-6-luna", name: "OpenAI: GPT-6 Luna", created: 10 },
            { id: "openai/gpt-6-luna:batch", name: "batch", created: 10 },
            {
              id: "google/some-image",
              name: "img",
              created: 20,
              architecture: { output_modalities: ["image"] },
            },
            { id: "openai/text-embedding-9", name: "emb", created: 5 },
          ],
        },
      },
    }) as typeof fetch;
    const r = await listModels({ provider: "openrouter" }, f);
    assert.equal(r.source, "live");
    assert.deepEqual(
      r.models.map((m) => m.id),
      ["openai/gpt-6-luna", "acme/new-model"],
    );
    assert.equal(r.models[0]?.featured, true);
    assert.equal(r.models[1]?.context_length, 1000);
  });

  it("reads OpenAI-compatible servers (Ollama) at the key's base URL with the key", async () => {
    const seen: string[] = [];
    const f = fakeFetch(
      { "http://localhost:11434/v1/models": { body: { data: [{ id: "llama4:8b" }] } } },
      seen,
    ) as typeof fetch;
    const r = await listModels(
      { provider: "openai_compatible", baseUrl: "http://localhost:11434/v1/", apiKey: "k" },
      f,
    );
    assert.deepEqual(
      r.models.map((m) => m.id),
      ["llama4:8b"],
    );
    assert.match(seen[0] ?? "", /Bearer k/);
  });

  it("maps Anthropic and Google lists", async () => {
    const f = fakeFetch({
      "https://api.anthropic.com/v1/models": {
        body: { data: [{ id: "claude-sonnet-5-5", display_name: "Claude Sonnet 5.5" }] },
      },
      "https://generativelanguage.googleapis.com/v1beta/models": {
        body: {
          models: [
            {
              name: "models/gemini-3.8-flash",
              displayName: "Gemini 3.8 Flash",
              supportedGenerationMethods: ["generateContent"],
            },
            { name: "models/embedding-9", supportedGenerationMethods: ["embedContent"] },
          ],
        },
      },
    }) as typeof fetch;
    const a = await listModels({ provider: "anthropic", apiKey: "x" }, f);
    assert.deepEqual(
      a.models.map((m) => [m.id, m.featured]),
      [["claude-sonnet-5-5", true]],
    );
    const g = await listModels({ provider: "google", apiKey: "x" }, f);
    assert.deepEqual(
      g.models.map((m) => m.id),
      ["gemini-3.8-flash"],
    );
  });

  it("falls back to the featured list with a clear error when the provider refuses the key", async () => {
    const f = fakeFetch({
      "https://api.openai.com/v1/models": { status: 401, body: {} },
    }) as typeof fetch;
    const r = await listModels({ provider: "openai", apiKey: "bad" }, f);
    assert.equal(r.source, "featured");
    assert.equal(r.error, "The provider rejected the key.");
    assert.equal(r.models[0]?.id, "gpt-6-luna");
  });

  it("offers the featured list without a live list", () => {
    assert.ok(mergeModelList("openrouter", []).length >= 5);
    assert.deepEqual(mergeModelList("openai_compatible", []), []);
  });
});
