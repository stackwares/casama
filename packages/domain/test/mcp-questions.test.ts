import { describe, expect, it } from "vitest";
import { checkMcpAnswer, mcpQuestionFields } from "../src/mcp-questions.ts";

const schema = {
  type: "object",
  properties: {
    name: { type: "string", title: "Your name", maxLength: 10 },
    age: { type: "integer", minimum: 0 },
    plan: { type: "string", enum: ["free", "pro"], enumNames: ["Free", "Pro"] },
    size: {
      type: "string",
      oneOf: [
        { const: "s", title: "Small" },
        { const: "l", title: "Large" },
      ],
    },
    ok: { type: "boolean", default: true },
    email: { type: "string", format: "email" },
  },
  required: ["name", "ok"],
};

describe("MCP questions (D-363)", () => {
  it("reads the flat form MCP allows", () => {
    const f = mcpQuestionFields(schema);
    expect(f?.map((x) => x.name)).toEqual(["name", "age", "plan", "size", "ok", "email"]);
    expect(f?.[0]).toMatchObject({
      type: "string",
      title: "Your name",
      required: true,
      maxLength: 10,
    });
    expect(f?.[2]).toMatchObject({ options: ["free", "pro"], optionLabels: ["Free", "Pro"] });
    expect(f?.[3]).toMatchObject({
      type: "string",
      options: ["s", "l"],
      optionLabels: ["Small", "Large"],
    });
    expect(f?.[4]).toMatchObject({ type: "boolean", default: true, required: true });
  });

  it("refuses nested or unknown forms", () => {
    expect(mcpQuestionFields({ type: "object", properties: { a: { type: "object" } } })).toBeNull();
    expect(mcpQuestionFields({ type: "array" })).toBeNull();
    expect(mcpQuestionFields(null)).toBeNull();
    expect(mcpQuestionFields({ type: "object" })).toEqual([]);
  });

  it("checks answers", () => {
    expect(checkMcpAnswer(schema, { name: "Ann", ok: true })).toBeNull();
    expect(checkMcpAnswer(schema, { ok: true })).toBe("Your name is required");
    expect(checkMcpAnswer(schema, { name: "Ann", ok: "yes" })).toBe("ok must be yes or no");
    expect(checkMcpAnswer(schema, { name: "Ann", ok: true, age: 1.5 })).toBe(
      "age must be a whole number",
    );
    expect(checkMcpAnswer(schema, { name: "Ann", ok: true, age: -1 })).toBe(
      "age must be at least 0",
    );
    expect(checkMcpAnswer(schema, { name: "Ann", ok: true, plan: "max" })).toBe(
      "plan must be one of the choices",
    );
    expect(checkMcpAnswer(schema, { name: "Ann", ok: true, email: "nope" })).toBe(
      "email must be an email address",
    );
    expect(checkMcpAnswer(schema, { name: "A very long name", ok: true })).toBe(
      "Your name must be at most 10 characters",
    );
    expect(checkMcpAnswer(schema, { name: "Ann", ok: true, extra: 1 })).toBe(
      "extra isn't one of the question's fields",
    );
  });
});
