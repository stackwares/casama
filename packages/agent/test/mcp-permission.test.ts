import { describe, expect, it } from "vitest";
import { mcpFailure, mcpPermission } from "../src/integrations.ts";
import { ToolError } from "../src/tools/registry.ts";

describe("MCP servers naming a system permission (D-376)", () => {
  it("reads casama_permission from an error's data or a result", () => {
    expect(mcpPermission({ casama_permission: "camera" })).toBe("camera");
    expect(mcpPermission({ casama_permission: "Camera!" })).toBeNull();
    expect(mcpPermission({ casama_permission: 3 })).toBeNull();
    expect(mcpPermission(null)).toBeNull();
    expect(mcpPermission("camera")).toBeNull();
  });

  it("turns a JSON-RPC error into a ToolError the run shows a card for", () => {
    const named = Object.assign(new Error("MCP error -32000: no camera access"), {
      data: { casama_permission: "camera" },
    });
    const out = mcpFailure(named);
    expect(out).toBeInstanceOf(ToolError);
    expect(out).toMatchObject({ code: "permission_needed:camera", message: named.message });
    const plain = new Error("boom");
    expect(mcpFailure(plain)).toBe(plain);
  });
});
