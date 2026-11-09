import { createHash } from "node:crypto";
import { createOpenAI } from "@ai-sdk/openai";
import { embed } from "ai";
import type { ResolvedModel } from "./gateway/types.ts";

export const EMBEDDING_DIMENSIONS = 1536;

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
      });
      return embedding;
    },
  };
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
