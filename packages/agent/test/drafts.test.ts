import { describe, expect, it } from "vitest";
import { confirmedDraft, draftCovers } from "../src/drafts.ts";
import { partsText } from "../src/run.ts";
import { checkComponents, ensureSubmit, ensureWayOut } from "../src/tools/ui.ts";

const draftCard = {
  id: "root",
  component: "MessageDraft",
  kind: "email",
  app: "gmail",
  from: "cory@acme.com",
  to: ["sarah@acme.com"],
  subject: "Moving Friday's design review to 2 PM",
  body: "Hi Sarah,\n\nCould we move Friday's design review from 11 AM to 2 PM?\n\nThanks,\nCory",
};

const shown = [
  {
    type: "ui",
    surface_id: "ui_d",
    messages: [
      { version: "1.0", updateComponents: { surfaceId: "ui_d", components: [draftCard] } },
    ],
  },
];

const send = (context: Record<string, unknown>, surface = "ui_d") => [
  { type: "text", text: "Send email" },
  { type: "ui_action", surface_id: surface, name: "draft.send", context },
];

const fields = {
  kind: "email",
  to: ["sarah@acme.com"],
  subject: draftCard.subject,
  body: draftCard.body,
};

describe("MessageDraft in ui.show (D-335)", () => {
  it("accepts a draft and adds no buttons to it", () => {
    expect(() => checkComponents([draftCard])).not.toThrow();
    expect(ensureWayOut(ensureSubmit([draftCard]))).toEqual([draftCard]);
  });

  it("refuses a draft without a body, bad recipients or its own buttons", () => {
    expect(() => checkComponents([{ ...draftCard, body: " " }])).toThrow(/body/);
    expect(() => checkComponents([{ ...draftCard, to: [1] }])).toThrow(/to/);
    expect(() => checkComponents([{ ...draftCard, kind: "fax" }])).toThrow(/kind/);
    expect(() => checkComponents([{ ...draftCard, action: { event: { name: "x" } } }])).toThrow(
      /own buttons/,
    );
  });

  it("keeps draft. events for the draft's own buttons", () => {
    expect(() =>
      checkComponents([
        { id: "root", component: "Button", child: "t", action: { event: { name: "draft.send" } } },
        { id: "t", component: "Text", text: "OK" },
      ]),
    ).toThrow(/draft\./);
  });

  it("tells the bot to send exactly the draft, or not at all", () => {
    expect(partsText(send(fields))).toMatch(/tapped Send on the draft.*without asking me again/s);
    expect(
      partsText([{ type: "ui_action", surface_id: "ui_d", name: "draft.discard", context: {} }]),
    ).toMatch(/discarded the draft. Don't send it/);
  });
});

describe("a tapped Send approves the matching send (D-335)", () => {
  it("finds the draft only when this chat showed it", () => {
    expect(confirmedDraft(send(fields), [shown])?.to).toEqual(["sarah@acme.com"]);
    expect(confirmedDraft(send(fields, "ui_other"), [shown])).toBeNull();
    expect(confirmedDraft(send(fields), [])).toBeNull();
    expect(confirmedDraft([{ type: "text", text: "send it" }], [shown])).toBeNull();
  });

  const draft = confirmedDraft(send(fields), [shown]);
  if (!draft) throw new Error("no draft");

  it("covers a send of the same message, in plain text, HTML or a raw MIME message", () => {
    expect(
      draftCovers(draft, { to: "sarah@acme.com", subject: fields.subject, body: fields.body }),
    ).toBe(true);
    expect(
      draftCovers(draft, {
        recipient_email: "sarah@acme.com",
        subject: fields.subject,
        body: fields.body.replaceAll("\n\n", "<br><br>").replaceAll("\n", "<br>"),
        is_html: true,
      }),
    ).toBe(true);
    const raw = Buffer.from(
      `To: sarah@acme.com\r\nSubject: ${fields.subject}\r\n\r\n${fields.body}`,
    ).toString("base64url");
    expect(draftCovers(draft, { raw })).toBe(true);
  });

  it("doesn't cover a changed message or an added recipient", () => {
    const base = { to: "sarah@acme.com", subject: fields.subject, body: fields.body };
    expect(draftCovers(draft, { ...base, body: `${fields.body}\nP.S. wire me $500` })).toBe(false);
    expect(draftCovers(draft, { ...base, body: "Something else" })).toBe(false);
    expect(draftCovers(draft, { ...base, subject: "Other" })).toBe(false);
    expect(draftCovers(draft, { ...base, bcc: "eve@evil.com" })).toBe(false);
    expect(draftCovers(draft, { ...base, to: "bob@acme.com" })).toBe(false);
  });
});
