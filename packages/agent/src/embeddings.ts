import { createHash } from "node:crypto";
import { createOpenAI } from "@ai-sdk/openai";
import { embed } from "ai";
import type { ResolvedModel } from "./gateway/types.ts";

export const EMBEDDING_DIMENSIONS = 1536;

/** Memory search on the server's shared OpenRouter key: same vectors as a workspace's OpenAI key. */
export const OPENROUTER_EMBEDDING_MODEL = "openai/text-embedding-3-small";

export interface Embedder {
  readonly model: string;
  embed(text: string): Promise<number[]>;
}

export function openAiEmbedder(m: ResolvedModel): Embedder {
  const provider = createOpenAI({ apiKey: m.apiKey, baseURL: m.baseUrl });
  return {
    model: m.model,
    async embed(text) {
      const { embedding } = await embed({
        model: provider.embedding(m.model),
        value: text,
        maxRetries: 2,
        // One deadline across the tries, so a hung provider can't hold up memory writes for minutes.
        abortSignal: AbortSignal.timeout(45_000),
      });
      return fitDimensions(embedding);
    },
  };
}

/**
 * Stored vectors have 1536 dimensions. A local embedding model's shorter vector is padded with
 * zeros, which keeps cosine similarity exact; a longer one is cut and renormalized, which suits
 * models trained to be cut (D-271). Vectors from different models still don't compare, so a
 * workspace should keep one embedding model.
 */
export function fitDimensions(v: number[], dims = EMBEDDING_DIMENSIONS): number[] {
  if (v.length === dims) return v;
  if (v.length < dims) return [...v, ...new Array<number>(dims - v.length).fill(0)];
  const cut = v.slice(0, dims);
  const norm = Math.hypot(...cut) || 1;
  return cut.map((x) => x / norm);
}

/**
 * Deterministic bag-of-words embedder for tests and offline installs: similar wording gives
 * similar vectors. Not semantic; real installs use a provider embedder.
 */
export function hashEmbedder(dimensions = EMBEDDING_DIMENSIONS): Embedder {
  return {
    model: "hash-bow",
    async embed(text) {
      const v = new Array<number>(dimensions).fill(0);
      for (const word of text.toLowerCase().match(/[\p{L}\p{N}]+/gu) ?? []) {
        if (word.length < 3) continue;
        const h = createHash("sha256").update(word).digest();
        const i = h.readUInt32BE(0) % dimensions;
        v[i] = (v[i] ?? 0) + ((h.readUInt8(4) & 1) === 1 ? 1 : -1);
      }
      const norm = Math.hypot(...v) || 1;
      return v.map((x) => x / norm);
    },
  };
}

export const toPgVector = (v: number[]) => `[${v.join(",")}]`;
