import { describe, expect, it } from "vitest";
import { checkAppConfig, compareVersions } from "../src/app-config.ts";
import {
  botTemplateFromGallery,
  checkBotDocument,
  checkPluginDocument,
  checkRoutineDocument,
} from "../src/gallery-content.ts";

const bot = {
  description: "Helps with homework.",
  category: "life",
  icon: "graduation-cap",
  mascot: "thinker",
  persona: "You are a patient study partner who asks one question at a time.",
  starters: ["Quiz me"],
  autonomy: "ask_always",
};

describe("gallery bots", () => {
  it("accepts a starter bot and makes a template", () => {
    expect(checkBotDocument(bot).errors).toEqual([]);
    expect(botTemplateFromGallery("study-buddy", "Study buddy", bot)).toMatchObject({
      id: "study-buddy",
      skills: [],
    });
  });

  it("never starts autonomous and only uses shipped mascots", () => {
    expect(checkBotDocument({ ...bot, autonomy: "autonomous" }).errors.length).toBe(1);
    expect(checkBotDocument({ ...bot, mascot: "dragon" }).errors.length).toBe(1);
    expect(checkBotDocument({ ...bot, model: "x" }).errors.length).toBe(1);
  });

  it("checks its routines' schedules", () => {
    const routine = { name: "Daily", instructions_md: "Do it.", schedule_cron: "0 9 * * *" };
    expect(checkBotDocument({ ...bot, routines: [routine] }).errors).toEqual([]);
    expect(
      checkBotDocument({ ...bot, routines: [{ ...routine, schedule_cron: "every day" }] }).errors,
    ).toHaveLength(1);
  });
});

describe("routine ideas and plugins", () => {
  it("checks a routine idea", () => {
    const idea = {
      description: "Weekly review.",
      category: "work",
      icon: "calendar-check",
      instructions_md: "Write my weekly review.",
      schedule_cron: "0 16 * * 5",
    };
    expect(checkRoutineDocument(idea).errors).toEqual([]);
    expect(checkRoutineDocument({ ...idea, category: "games" }).errors).toHaveLength(1);
  });

  it("pins a plugin to a full commit on GitHub", () => {
    const p = {
      description: "Example.",
      url: "https://github.com/stackwares/casama/tree/main/examples/hello-plugin",
      commit: "6efc18250f69b9c2938b689076384237324136e3",
      adds: ["A skill"],
    };
    expect(checkPluginDocument(p).errors).toEqual([]);
    expect(checkPluginDocument({ ...p, commit: "main" }).errors).toHaveLength(1);
    expect(checkPluginDocument({ ...p, url: "https://gitlab.com/a/b" }).errors).toHaveLength(1);
  });
});

describe("remote app settings", () => {
  it("compares versions", () => {
    expect(compareVersions("0.8.0", "0.10.0")).toBe(-1);
    expect(compareVersions("1.0.0", "1.0.0")).toBe(0);
    expect(compareVersions("1.2.0", "1.1.9")).toBe(1);
  });

  it("cleans good settings and names what's wrong", () => {
    const { config, errors } = checkAppConfig({
      min_versions: { ios: "0.8.0", android: "" },
      announcements: [{ id: "hi", title: " Hello ", body: "" }],
      flags: { new_home: true },
    });
    expect(errors).toEqual([]);
    expect(config).toEqual({
      min_versions: { ios: "0.8.0" },
      update_urls: {},
      maintenance: null,
      announcements: [{ id: "hi", title: "Hello", body: "", level: "info" }],
      flags: { new_home: true },
    });
    const bad = checkAppConfig({
      min_versions: { symbian: "1.0.0" },
      update_urls: { ios: "http://x" },
      maintenance: { message: "" },
      flags: { X: 1 },
      extra: true,
    });
    expect(bad.config).toBeUndefined();
    expect(bad.errors).toHaveLength(5);
  });
});
