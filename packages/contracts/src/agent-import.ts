import { z } from "@hono/zod-openapi";
import { BotTemplateFile } from "./bot-template.ts";
import { Uuid } from "./common.ts";

export const StartAgentImportRequest = z
  .object({
    org_id: Uuid,
    /** A ZIP of the folder. */
    zip_base64: z.string().max(70_000_000).optional(),
    /** Or the folder's files (the desktop app picks a folder). */
    files: z
      .array(
        z.object({ path: z.string().min(1).max(1000), content_base64: z.string().max(14_000_000) }),
      )
      .max(3000)
      .optional(),
  })
  .openapi("StartAgentImportRequest");

export const AgentImportPlan = z
  .object({
    id: Uuid,
    kind: z.enum(["openclaw", "hermes"]),
    template: BotTemplateFile,
    sources: z.object({
      skills: z.array(z.string()),
      routines: z.array(z.string()),
      memories: z.array(z.string()),
    }),
    leftovers: z.array(z.object({ path: z.string(), size: z.number().int() })),
    skipped: z.array(z.object({ path: z.string(), reason: z.string() })),
    notes: z.array(z.string()),
  })
  .openapi("AgentImportPlan");

export const WriteAgentImportFilesRequest = z
  .object({ bot_id: Uuid })
  .openapi("WriteAgentImportFilesRequest");
export const WriteAgentImportFilesResponse = z
  .object({ written: z.number().int(), folder: z.string() })
  .openapi("WriteAgentImportFilesResponse");

export const ImportedMemoryItem = z
  .object({ kind: z.enum(["fact", "preference"]), content: z.string().min(1).max(8000) })
  .openapi("ImportedMemoryItem");
export const MemoryImportPrompt = z.object({ prompt: z.string() }).openapi("MemoryImportPrompt");
export const ParseMemoryImportRequest = z
  .object({ text: z.string().min(1).max(200_000) })
  .openapi("ParseMemoryImportRequest");
export const ParsedMemoryImport = z
  .object({ memories: z.array(ImportedMemoryItem) })
  .openapi("ParsedMemoryImport");
export const SaveImportedMemoriesRequest = z
  .object({ memories: z.array(ImportedMemoryItem).min(1).max(500) })
  .openapi("SaveImportedMemoriesRequest");
