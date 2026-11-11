/**
 * Casama's email look, shared by the server's own emails (invites) and the sign-in emails our
 * Supabase sends (generated into supabase/templates by scripts/build-email-templates.ts).
 *
 * The app's brand: plum and lilac, Libre Baskerville headings and Lato text, and a mascot on top.
 * Built for email clients: tables, inline styles, animated GIF mascots on casama.ai (Lottie needs
 * JavaScript and SVG is stripped by most clients; Outlook on Windows shows the first frame), web fonts with Georgia and Helvetica fallbacks, and a dark variant for clients
 * that honor prefers-color-scheme.
 */

/**
 * The mascots, as animated GIFs made from the app's Lottie animations
 * (scripts/render-email-gifs.mjs). Each kind of email has its own:
 * sign-in winky, welcome lovey, Casama invite wow, workspace invite starry, password reset
 * thinker, email change focused, security code shy; giggly, cool and sleepy are free.
 */
export type EmailMascot =
  | "winky"
  | "lovey"
  | "wow"
  | "thinker"
  | "focused"
  | "shy"
  | "giggly"
  | "starry"
  | "cool"
  | "sleepy";

export interface BrandedEmail {
  mascot: EmailMascot;
  /** Inbox preview line (hidden in the body). */
  preheader: string;
  title: string;
  /** Paragraphs above the code and button. */
  intro: string[];
  /** A one-time code shown large (sign-in emails also accept typing it). */
  code?: string;
  button?: { label: string; url: string };
  /** Small print under the button. */
  note?: string;
  /**
   * Values already safe to insert as they are (Supabase's Go template placeholders such as
   * {{ .Token }}). Everything else is HTML-escaped.
   */
  raw?: boolean;
}

/** Where the mascot GIFs live (served by the casama.ai site, site/email). */
export const EMAIL_ASSET_BASE = "https://casama.ai/email";

const C = {
  page: "#F7F1FC",
  card: "#FFFFFF",
  border: "#EBDDF7",
  ink: "#2A1035",
  text: "#4A4453",
  muted: "#8A8494",
  plum: "#7A3FA8",
  lilac: "#F1E2FC",
  codeInk: "#5A1F6E",
};

const HEADING = "'Libre Baskerville', Georgia, 'Times New Roman', serif";
const BODY = "Lato, 'Helvetica Neue', Helvetica, Arial, sans-serif";

const esc = (s: string) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

export function renderEmailHtml(e: BrandedEmail, assetBase = EMAIL_ASSET_BASE): string {
  const t = (s: string) => (e.raw ? s : esc(s));
  const paragraphs = e.intro
    .map(
      (p) =>
        `<p class="t" style="margin:0 0 16px;font-family:${BODY};font-size:16px;line-height:1.6;color:${C.text}">${t(p)}</p>`,
    )
    .join("\n");
  const code = e.code
    ? `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:8px 0 24px"><tr><td class="code" align="center" style="background:${C.lilac};border-radius:16px;padding:18px 12px;font-family:${BODY};font-size:32px;font-weight:700;letter-spacing:10px;color:${C.codeInk}">${t(e.code)}</td></tr></table>`
    : "";
  const button = e.button
    ? `<table role="presentation" cellpadding="0" cellspacing="0" align="center" style="margin:0 auto 24px"><tr><td align="center" bgcolor="${C.plum}" style="border-radius:999px"><a href="${t(e.button.url)}" style="display:inline-block;padding:14px 34px;font-family:${BODY};font-size:16px;font-weight:700;color:#FFFFFF;text-decoration:none;border-radius:999px">${t(e.button.label)}</a></td></tr></table>`
    : "";
  const note = e.note
    ? `<p class="m" style="margin:0;font-family:${BODY};font-size:13px;line-height:1.6;color:${C.muted}">${t(e.note)}</p>`
    : "";
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<meta name="supported-color-schemes" content="light dark">
<title>${t(e.title)}</title>
<link href="https://fonts.googleapis.com/css2?family=Lato:wght@400;700&family=Libre+Baskerville:wght@700&display=swap" rel="stylesheet">
<style>
  @media (prefers-color-scheme: dark) {
    .bg { background: #1A0F20 !important; }
    .card { background: #241629 !important; border-color: #3A2443 !important; }
    .h { color: #F1E2FC !important; }
    .t { color: #D8CCE0 !important; }
    .m, .f, .f a { color: #A99BB4 !important; }
    .code { background: #3A1F4A !important; color: #F1E2FC !important; }
    .w { color: #D9B6F7 !important; }
  }
  @media (max-width: 520px) { .card { padding: 28px 22px !important; } }
</style>
</head>
<body class="bg" style="margin:0;padding:0;background:${C.page}">
<div style="display:none;max-height:0;overflow:hidden;opacity:0">${t(e.preheader)}</div>
<table role="presentation" class="bg" width="100%" cellpadding="0" cellspacing="0" style="background:${C.page}">
<tr><td align="center" style="padding:32px 16px">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px">
    <tr><td align="center" style="padding:0 0 16px">
      <span class="w" style="font-family:${HEADING};font-size:20px;font-weight:700;letter-spacing:0.5px;color:${C.plum}">Casama</span>
    </td></tr>
    <tr><td class="card" style="background:${C.card};border:1px solid ${C.border};border-radius:24px;padding:32px 32px 28px">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
        <tr><td align="center" style="padding:0 0 12px">
          <img src="${assetBase}/${e.mascot}.gif" width="112" height="112" alt="" style="display:block;width:112px;height:112px;border:0;border-radius:28px">
        </td></tr>
        <tr><td>
          <h1 class="h" style="margin:0 0 16px;font-family:${HEADING};font-size:24px;line-height:1.3;font-weight:700;text-align:center;color:${C.ink}">${t(e.title)}</h1>
          ${paragraphs}
          ${code}
          ${button}
          ${note}
        </td></tr>
      </table>
    </td></tr>
    <tr><td class="f" align="center" style="padding:20px 8px 0;font-family:${BODY};font-size:12px;line-height:1.6;color:${C.muted}">
      Casama · AI teammates with their own computers<br>
      <a href="https://casama.ai" style="color:${C.muted};text-decoration:underline">casama.ai</a> ·
      <a href="mailto:support@casama.ai" style="color:${C.muted};text-decoration:underline">support@casama.ai</a>
    </td></tr>
  </table>
</td></tr>
</table>
</body>
</html>
`;
}

/** The plain-text part, for clients that don't show HTML. */
export function renderEmailText(e: BrandedEmail): string {
  return [
    e.title,
    "",
    ...e.intro.flatMap((p) => [p, ""]),
    ...(e.code ? [`Code: ${e.code}`, ""] : []),
    ...(e.button ? [`${e.button.label}: ${e.button.url}`, ""] : []),
    ...(e.note ? [e.note, ""] : []),
    "Casama · https://casama.ai · support@casama.ai",
  ].join("\n");
}
