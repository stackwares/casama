/**
 * Questions a connected MCP server asks the person mid-call (MCP elicitation, D-363). The spec
 * keeps the form flat: an object of strings, numbers, integers, booleans and enums. These helpers
 * read that form and check an answer before it goes back to the server.
 */

export interface McpQuestionField {
  name: string;
  type: "string" | "number" | "integer" | "boolean";
  title?: string;
  description?: string;
  required: boolean;
  /** For a choice: the allowed values, and what to show for each. */
  options?: string[];
  optionLabels?: string[];
  minimum?: number;
  maximum?: number;
  minLength?: number;
  maxLength?: number;
  format?: string;
  default?: string | number | boolean;
}

const TYPES = new Set(["string", "number", "integer", "boolean"]);

/** The fields of an elicitation's `requestedSchema`; null when it isn't the flat kind MCP allows. */
export function mcpQuestionFields(schema: unknown): McpQuestionField[] | null {
  if (!schema || typeof schema !== "object") return null;
  const s = schema as { type?: unknown; properties?: unknown; required?: unknown };
  if (s.type !== undefined && s.type !== "object") return null;
  const props = (s.properties ?? {}) as Record<string, unknown>;
  if (typeof props !== "object" || Array.isArray(props)) return null;
  const required = new Set(Array.isArray(s.required) ? s.required.map(String) : []);
  const out: McpQuestionField[] = [];
  for (const [name, raw] of Object.entries(props)) {
    if (!raw || typeof raw !== "object") return null;
    const p = raw as Record<string, unknown>;
    const options = Array.isArray(p.enum)
      ? p.enum.map(String)
      : Array.isArray(p.oneOf)
        ? (p.oneOf as Array<Record<string, unknown>>).map((o) => String(o?.const))
        : undefined;
    const labels = Array.isArray(p.enumNames)
      ? p.enumNames.map(String)
      : Array.isArray(p.oneOf)
        ? (p.oneOf as Array<Record<string, unknown>>).map((o) => String(o?.title ?? o?.const))
        : undefined;
    const type = typeof p.type === "string" ? p.type : options ? "string" : "";
    if (!TYPES.has(type)) return null;
    const num = (v: unknown) => (typeof v === "number" ? v : undefined);
    const def = p.default;
    out.push({
      name,
      type: type as McpQuestionField["type"],
      ...(typeof p.title === "string" ? { title: p.title } : {}),
      ...(typeof p.description === "string" ? { description: p.description } : {}),
      required: required.has(name),
      ...(options ? { options, optionLabels: labels ?? options } : {}),
      ...(num(p.minimum) !== undefined ? { minimum: num(p.minimum) } : {}),
      ...(num(p.maximum) !== undefined ? { maximum: num(p.maximum) } : {}),
      ...(num(p.minLength) !== undefined ? { minLength: num(p.minLength) } : {}),
      ...(num(p.maxLength) !== undefined ? { maxLength: num(p.maxLength) } : {}),
      ...(typeof p.format === "string" ? { format: p.format } : {}),
      ...(["string", "number", "boolean"].includes(typeof def)
        ? { default: def as string | number | boolean }
        : {}),
    });
  }
  return out;
}

/** Why [content] doesn't answer [schema], or null when it does. Unknown fields are refused. */
export function checkMcpAnswer(schema: unknown, content: Record<string, unknown>): string | null {
  const fields = mcpQuestionFields(schema);
  if (!fields) return "The question's form isn't one Casama can show";
  const byName = new Map(fields.map((f) => [f.name, f]));
  for (const key of Object.keys(content))
    if (!byName.has(key)) return `${key} isn't one of the question's fields`;
  for (const f of fields) {
    const label = f.title ?? f.name;
    const v = content[f.name];
    if (v === undefined || v === null || v === "") {
      if (f.required) return `${label} is required`;
      continue;
    }
    if (f.type === "boolean" && typeof v !== "boolean") return `${label} must be yes or no`;
    if ((f.type === "number" || f.type === "integer") && typeof v !== "number")
      return `${label} must be a number`;
    if (f.type === "integer" && !Number.isInteger(v)) return `${label} must be a whole number`;
    if (f.type === "string" && typeof v !== "string") return `${label} must be text`;
    if (typeof v === "number") {
      if (f.minimum !== undefined && v < f.minimum) return `${label} must be at least ${f.minimum}`;
      if (f.maximum !== undefined && v > f.maximum) return `${label} must be at most ${f.maximum}`;
    }
    if (typeof v === "string") {
      if (v.length > 10_000) return `${label} is too long`;
      if (f.options && !f.options.includes(v)) return `${label} must be one of the choices`;
      if (f.minLength !== undefined && v.length < f.minLength)
        return `${label} must be at least ${f.minLength} characters`;
      if (f.maxLength !== undefined && v.length > f.maxLength)
        return `${label} must be at most ${f.maxLength} characters`;
      if (f.format === "email" && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v))
        return `${label} must be an email address`;
      if (f.format === "uri" && !/^[a-z][a-z0-9+.-]*:\/\/\S+$/i.test(v))
        return `${label} must be a link`;
    }
  }
  return null;
}
