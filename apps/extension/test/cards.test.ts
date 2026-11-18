import { describe, expect, it } from "vitest";
import { answerText, checkCall, failingCheck, resolve, surfaceOf } from "../src/lib/cards.ts";

const messages = [
  { version: "1.0", createSurface: { surfaceId: "s1", catalogId: "x" } },
  {
    version: "1.0",
    updateDataModel: { surfaceId: "s1", path: "/", value: { form: { name: "", plan: ["pro"] } } },
  },
  {
    version: "1.0",
    updateComponents: {
      surfaceId: "s1",
      components: [
        { id: "root", component: "Column", children: ["name", "send"] },
        { id: "name", component: "TextField", label: "Name", value: { "@path": "/form/name" } },
        {
          id: "send",
          component: "Button",
          child: "send-label",
          checks: [
            {
              condition: { "@call": "required", args: { value: { "@path": "/form/name" } } },
              message: "Name first",
            },
          ],
          action: {
            event: {
              name: "submit",
              context: { name: { "@path": "/form/name" }, plan: { "@path": "/form/plan" } },
            },
          },
        },
        { id: "send-label", component: "Text", text: "Send" },
      ],
    },
  },
];

describe("cards in replies (A2)", () => {
  it("reads components and data from the A2UI messages", () => {
    const { comps, data } = surfaceOf(messages);
    expect([...comps.keys()]).toEqual(["root", "name", "send", "send-label"]);
    expect(resolve({ "@path": "/form/plan" }, data)).toEqual(["pro"]);
    expect(resolve({ path: "/form/name" }, data)).toBe("");
  });

  it("keeps a Send button off until its checks pass (D-322)", () => {
    const { comps, data } = surfaceOf(messages);
    const send = comps.get("send")!;
    expect(failingCheck(send, data)).toBe("Name first");
    (data.form as Record<string, unknown>).name = "Ada";
    expect(failingCheck(send, data)).toBeNull();
  });

  it("evaluates each check function", () => {
    const d = { a: "ada@example.com", n: "7", e: "" };
    const call = (name: string, args: object) => checkCall({ "@call": name, args }, d);
    expect(call("email", { value: { "@path": "/a" } })).toBe(true);
    expect(call("numeric", { value: { "@path": "/n" }, min: 1, max: 10 })).toBe(true);
    expect(call("numeric", { value: { "@path": "/n" }, max: 5 })).toBe(false);
    expect(call("length", { value: { "@path": "/a" }, max: 3 })).toBe(false);
    expect(call("regex", { value: { "@path": "/n" }, pattern: "^\\d$" })).toBe(true);
    expect(
      call("not", { value: { "@call": "required", args: { value: { "@path": "/e" } } } }),
    ).toBe(true);
    expect(call("or", { values: [false, true] })).toBe(true);
    expect(call("and", { values: [true, false] })).toBe(false);
    expect(call("nope", {})).toBe(false);
  });

  it("writes the answer as the app does", () => {
    expect(answerText("Send", { name: "Ada", plan: ["pro", "max"], empty: "" })).toBe(
      "Send\nname: Ada\nplan: pro, max",
    );
  });

  it("never writes to Object.prototype from a card's data paths", () => {
    const { data } = surfaceOf([
      { version: "1.0", updateDataModel: { surfaceId: "s", path: "/__proto__/send", value: true } },
      {
        version: "1.0",
        updateDataModel: { surfaceId: "s", path: "/a/constructor/prototype/x", value: 1 },
      },
    ]);
    expect(({} as Record<string, unknown>).send).toBeUndefined();
    expect(({} as Record<string, unknown>).x).toBeUndefined();
    expect(resolve({ "@path": "/__proto__" }, data)).toBeUndefined();
    expect(resolve({ "@path": "/toString" }, data)).toBeUndefined();
  });
});
