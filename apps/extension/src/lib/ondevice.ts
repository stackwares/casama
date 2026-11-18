/**
 * Quick answers on this computer (F1): Chrome's built-in Summarizer, Translator and Prompt API
 * (LanguageModel), feature-detected. When a model isn't there the buttons are absent, never
 * disabled, and nothing else depends on it (plan §9.7). Nothing leaves the computer.
 */

type Availability = "unavailable" | "downloadable" | "downloading" | "available";
interface Summarizer {
  summarize(text: string, o?: { context?: string }): Promise<string>;
  destroy?(): void;
}
interface Session {
  prompt(text: string): Promise<string>;
  destroy?(): void;
}
interface TranslatorI {
  translate(text: string): Promise<string>;
  destroy?(): void;
}
type G = typeof globalThis & {
  Summarizer?: {
    availability(o?: unknown): Promise<Availability>;
    create(o?: unknown): Promise<Summarizer>;
  };
  LanguageModel?: {
    availability(o?: unknown): Promise<Availability>;
    create(o?: unknown): Promise<Session>;
  };
  Translator?: {
    availability(o: { sourceLanguage: string; targetLanguage: string }): Promise<Availability>;
    create(o: { sourceLanguage: string; targetLanguage: string }): Promise<TranslatorI>;
  };
  LanguageDetector?: {
    create(): Promise<{ detect(t: string): Promise<{ detectedLanguage: string }[]> }>;
  };
};
const g = () => globalThis as G;

export type QuickKind = "summarize" | "explain" | "translate";

/** Which quick answers this computer can give right now (only models already downloaded). */
export async function quickKinds(): Promise<QuickKind[]> {
  const out: QuickKind[] = [];
  const ok = async (f?: () => Promise<Availability>) => {
    try {
      return f ? (await f()) === "available" : false;
    } catch {
      return false;
    }
  };
  const lm = await ok(g().LanguageModel && (() => g().LanguageModel!.availability()));
  if (lm || (await ok(g().Summarizer && (() => g().Summarizer!.availability()))))
    out.push("summarize");
  if (lm) out.push("explain");
  if (g().Translator || lm) out.push("translate");
  return out;
}

const lang = () => (navigator.language || "en").split("-")[0]!;

export async function quickAnswer(kind: QuickKind, text: string): Promise<string> {
  const t = text.slice(0, 12_000);
  if (kind === "summarize" && g().Summarizer) {
    try {
      const s = await g().Summarizer!.create({ type: "key-points", length: "short" });
      try {
        return await s.summarize(t);
      } finally {
        s.destroy?.();
      }
    } catch {
      // Fall through to the Prompt API.
    }
  }
  if (kind === "translate" && g().Translator) {
    const target = lang();
    let source = "en";
    try {
      const d = await g().LanguageDetector?.create();
      source = (await d?.detect(t))?.[0]?.detectedLanguage ?? "en";
    } catch {
      // Unknown: assume English.
    }
    const to = source === target ? (target === "en" ? "es" : "en") : target;
    if (
      (await g().Translator!.availability({ sourceLanguage: source, targetLanguage: to })) !==
      "unavailable"
    ) {
      const tr = await g().Translator!.create({ sourceLanguage: source, targetLanguage: to });
      try {
        return await tr.translate(t);
      } finally {
        tr.destroy?.();
      }
    }
  }
  if (!g().LanguageModel) throw new Error("This computer's built-in model isn't available.");
  const s = await g().LanguageModel!.create();
  try {
    const ask = {
      summarize: "Summarize this in three short bullet points:",
      explain: "Explain this simply, in a short paragraph:",
      translate: `Translate this into ${lang() === "en" ? "English (or Spanish if it is already English)" : `the language with code "${lang()}"`}:`,
    }[kind];
    return await s.prompt(`${ask}\n\n${t}`);
  } finally {
    s.destroy?.();
  }
}

/** Whether this computer's built-in model can answer a free question now (F3). */
export async function canAnswerLocally(): Promise<boolean> {
  try {
    return (await g().LanguageModel?.availability()) === "available";
  } catch {
    return false;
  }
}

/** A question about the page, answered by the built-in model; nothing leaves the computer (F3). */
export async function localAnswer(question: string, context: string): Promise<string> {
  if (!g().LanguageModel) throw new Error("This computer's built-in model isn't available.");
  const s = await g().LanguageModel!.create();
  try {
    return await s.prompt(
      `Answer the question using the page below. Say so if the page doesn't answer it.\n\nQuestion: ${question || "What is this page about?"}\n\nPage:\n${context.slice(0, 12_000)}`,
    );
  } finally {
    s.destroy?.();
  }
}
