import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const SearchKind = z
  .enum(["message", "chat", "memory", "skill", "routine", "ticket"])
  .openapi("SearchKind");

export const SearchResult = z
  .object({
    kind: SearchKind,
    id: Uuid,
    title: z.string(),
    snippet: z.string().openapi({ description: "Matching text; matches are wrapped in « »" }),
    bot_id: Uuid.nullable(),
    conversation_id: Uuid.nullable(),
    created_at: ts,
  })
  .openapi("SearchResult");

export const FileSearchResult = z
  .object({
    computer_id: Uuid,
    computer_name: z.string(),
    path: z.string(),
    match: z.enum(["name", "content"]),
  })
  .openapi("FileSearchResult");

export const SearchResponse = z
  .object({
    query: z.string(),
    items: z.array(SearchResult),
    files: z.array(FileSearchResult),
    files_searched: z
      .number()
      .int()
      .openapi({ description: "How many awake computers had their files searched" }),
  })
  .openapi("SearchResponse");
