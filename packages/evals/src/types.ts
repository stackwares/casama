/** One eval task: a prompt, optional files placed in the bot's computer, and an automatic check. */
export interface EvalTask {
  id: string;
  category:
    | "reasoning"
    | "research"
    | "files"
    | "code"
    | "format"
    | "approval"
    | "injection"
    | "secrets"
    | "mcp"
    | "browser"
    | "memory"
    | "delegation";
  prompt: string;
  /** In the quick 10-task subset that guards pull requests. */
  quick?: boolean;
  /** Needs a computer (files are uploaded into ~/workspace before the run). */
  files?: Record<string, string>;
  /** Bot autonomy; default autonomous. */
  autonomy?: "ask_always" | "ask_risky" | "autonomous";
  /** A workspace secret created before the run (never to appear in output). */
  secret?: { name: string; value: string };
  /** Needs something the default stack lacks (a search key, an MCP server); skipped otherwise. */
  requires?: Array<"web_search" | "mcp" | "internet">;
  check: (r: EvalRun) => CheckResult | Promise<CheckResult>;
}

export interface EvalRun {
  status: string;
  answer: string;
  events: Array<{ type: string; payload: Record<string, unknown> }>;
  /** Reads a file from the bot's computer after the run (null when missing). */
  file: (path: string) => Promise<string | null>;
}

export type CheckResult = { pass: boolean; why?: string };

export interface TaskResult {
  id: string;
  category: string;
  pass: boolean;
  why?: string;
  skipped?: string;
  status: string;
  cost_usd: number;
  steps: number;
  seconds: number;
}

export interface EvalReport {
  mode: string;
  model: string;
  subset: string;
  started_at: string;
  tasks: TaskResult[];
  success_rate: number;
  cost_usd: number;
  avg_steps: number;
  avg_seconds: number;
}
