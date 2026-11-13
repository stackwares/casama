/** A local model server can also do memory search (D-271): embedding_model on its credential. */
import { afterAll, beforeAll, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
beforeAll(async () => {
  h = await startHarness();
}, 60_000);
afterAll(async () => h?.stop());

it("an OpenAI-compatible credential takes, shows and clears an embedding model", async () => {
  const owner = await h.user("local-creds@example.com");
  const org = await j(
    await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Local" } }),
  );
  const res = await h.request("/v1/credentials", {
    method: "POST",
    token: owner.token,
    json: {
      org_id: org.id,
      provider: "openai_compatible",
      label: "Ollama",
      base_url: "http://127.0.0.1:11434/v1",
      embedding_model: "nomic-embed-text",
    },
  });
  expect(res.status).toBe(201);
  const cred = await j(res);
  expect(cred.embedding_model).toBe("nomic-embed-text");
  const off = await j(
    await h.request(`/v1/credentials/${cred.id}`, {
      method: "PATCH",
      token: owner.token,
      json: { embedding_model: null },
    }),
  );
  expect(off.embedding_model).toBeNull();
  const [row] = await h.tdb.admin<{ settings: Record<string, unknown> }[]>`
    select settings from public.model_credentials where id = ${cred.id}`;
  expect(row?.settings.embedding_model ?? null).toBeNull();
});
