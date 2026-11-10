/**
 * Replaces known secret values with placeholders before anything reaches events, logs or the model.
 * Values shorter than 6 characters are ignored to avoid mangling ordinary text.
 */
export class Redactor {
  private readonly secrets = new Map<string, string>();

  add(value: string | undefined | null, label: string) {
    if (value && value.length >= 6) this.secrets.set(value, label);
    return this;
  }

  /** Copies another redactor's values in (a rebuilt redactor keeps what was added during the run). */
  merge(other: Redactor | undefined) {
    if (other) for (const [v, l] of other.secrets) this.secrets.set(v, l);
    return this;
  }

  text(s: string): string {
    let out = s;
    for (const [value, label] of this.secrets) out = out.split(value).join(`[secret:${label}]`);
    return out;
  }

  /** Deep-redacts strings inside JSON-like values. */
  value<T>(v: T): T {
    if (this.secrets.size === 0) return v;
    if (typeof v === "string") return this.text(v) as T;
    if (Array.isArray(v)) return v.map((x) => this.value(x)) as T;
    if (v && typeof v === "object") {
      return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, this.value(x)])) as T;
    }
    return v;
  }
}
