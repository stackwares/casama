/**
 * Check-in costs (D-247): the first prod scans stopped on approvals for mail reads, loaded tools
 * over a dozen turns and ran on every new email. These cover the fixes: app reads are low risk,
 * check-ins offer only reads and suggestions.add, and only events worth a look start a scan.
 */
import { describe, expect, it } from "vitest";
import { checkinToolAllowed, isCheckinKind, scanTask } from "../src/checkins.ts";
import { composioEventNote } from "../src/composio-triggers.ts";
import { composioToolRisk } from "../src/integrations.ts";

describe("Composio tool risk", () => {
  it("reads are low, changes and unclear tools are medium, hints win", () => {
    expect(composioToolRisk("GMAIL_FETCH_EMAILS")).toBe("low");
    expect(composioToolRisk("googlecalendar_events_list")).toBe("low");
    expect(composioToolRisk("GMAIL_FETCH_MESSAGE_BY_MESSAGE_ID")).toBe("low");
    expect(composioToolRisk("GMAIL_SEND_EMAIL")).toBe("medium");
    expect(composioToolRisk("GMAIL_CREATE_EMAIL_DRAFT")).toBe("medium");
    expect(composioToolRisk("GOOGLECALENDAR_QUICK_ADD")).toBe("medium");
    expect(composioToolRisk("GMAIL_LIST_AND_DELETE")).toBe("medium");
    expect(composioToolRisk("SLACK_CHAT_POST_MESSAGE")).toBe("medium");
    expect(composioToolRisk("NOTION_PAGES")).toBe("medium");
    expect(composioToolRisk("GMAIL_SEND_EMAIL", ["readOnlyHint"])).toBe("low");
    expect(composioToolRisk("GMAIL_LIST_LABELS", ["destructiveHint"])).toBe("high");
  });
});

describe("check-in tools", () => {
  it("only reads and suggestions.add, no computer, a few reads from big apps", () => {
    expect(isCheckinKind("scan")).toBe(true);
    expect(isCheckinKind("brief")).toBe(true);
    expect(isCheckinKind("task")).toBe(false);
    expect(checkinToolAllowed({ name: "suggestions.add", risk: "low" })).toBe(true);
    expect(checkinToolAllowed({ name: "device.read", risk: "low" })).toBe(true);
    expect(checkinToolAllowed({ name: "routines.list", risk: "low" })).toBe(false);
    expect(checkinToolAllowed({ name: "tools.load", risk: "low" })).toBe(false);
    expect(checkinToolAllowed({ name: "notify.user", risk: "low" })).toBe(false);
    expect(
      checkinToolAllowed({ name: "files.read", risk: "low", requires: { computer: true } }),
    ).toBe(false);
    expect(checkinToolAllowed({ name: "composio.apps.gmail_fetch_emails", risk: "low" })).toBe(
      true,
    );
    expect(checkinToolAllowed({ name: "composio.apps.gmail_list_labels", risk: "low" })).toBe(
      false,
    );
    expect(checkinToolAllowed({ name: "composio.apps.gmail_send_email", risk: "medium" })).toBe(
      false,
    );
    expect(checkinToolAllowed({ name: "mcp.linear.list_issues", risk: "low" })).toBe(true);
    expect(checkinToolAllowed({ name: "mcp.linear.create_issue", risk: "medium" })).toBe(false);
  });

  it("the scan starts from what changed", () => {
    const task = scanTask("Check-in scan.", "event", "", "New email from Ana: Q3 invoice");
    expect(task).toContain("What changed:\nNew email from Ana: Q3 invoice");
    expect(scanTask("Check-in scan.", null, "")).toBe("Check-in scan.");
  });
});

describe("app events worth a scan", () => {
  const now = Date.parse("2026-11-13T09:00:00Z");
  const ev = (slug: string, data: Record<string, unknown>) =>
    composioEventNote(
      { type: "composio.trigger.message", metadata: { trigger_slug: slug }, data },
      now,
    );

  it("mail from a person scans, with sender and subject", () => {
    expect(
      ev("GMAIL_NEW_GMAIL_MESSAGE", {
        sender: "Ana Ruiz <ana@example.com>",
        subject: "Q3 invoice",
        label_ids: ["INBOX", "IMPORTANT"],
      }),
    ).toEqual({ scan: true, note: "New email from Ana Ruiz <ana@example.com>: Q3 invoice" });
    expect(
      ev("OUTLOOK_MESSAGE_TRIGGER", {
        from: { emailAddress: { name: "Sam", address: "sam@example.com" } },
        subject: "Design review",
        inferenceClassification: "focused",
      }),
    ).toEqual({ scan: true, note: "New email from Sam <sam@example.com>: Design review" });
  });

  it("promotions, updates, other and machine senders don't", () => {
    expect(ev("GMAIL_NEW_GMAIL_MESSAGE", { label_ids: ["CATEGORY_UPDATES"] }).scan).toBe(false);
    expect(ev("GMAIL_NEW_GMAIL_MESSAGE", { sender: "noreply@x.example" }).scan).toBe(false);
    expect(ev("GMAIL_NEW_GMAIL_MESSAGE", { sender: "Bank <do-not-reply@bank.example>" }).scan).toBe(
      false,
    );
    expect(ev("GMAIL_NEW_GMAIL_MESSAGE", { sender: "Weekly <newsletter@pub.example>" }).scan).toBe(
      false,
    );
    expect(ev("OUTLOOK_MESSAGE_TRIGGER", { inferenceClassification: "other" }).scan).toBe(false);
  });

  it("calendar changes in the next two days scan; later ones and old ones don't", () => {
    const soon = ev("GOOGLECALENDAR_GOOGLE_CALENDAR_EVENT_UPDATED_TRIGGER", {
      summary: "Flight to Bacolod",
      start: { dateTime: "2026-11-14T06:00:00Z" },
    });
    expect(soon).toEqual({
      scan: true,
      note: "Calendar change: Flight to Bacolod at 2026-11-14T06:00:00.000Z",
    });
    expect(
      ev("GOOGLECALENDAR_GOOGLE_CALENDAR_EVENT_CREATED_TRIGGER", {
        summary: "Dentist",
        start: { dateTime: "2026-11-20T06:00:00Z" },
      }).scan,
    ).toBe(false);
    expect(
      ev("GOOGLECALENDAR_GOOGLE_CALENDAR_EVENT_CREATED_TRIGGER", {
        start: { dateTime: "2026-11-01T06:00:00Z" },
      }).scan,
    ).toBe(false);
  });

  it("unknown events still scan", () => {
    expect(ev("SOMETHING_ELSE", {})).toEqual({ scan: true, note: null });
  });
});
