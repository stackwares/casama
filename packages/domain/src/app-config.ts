/**
 * Remote app settings (D-241): what a server's owner can change in every installed app without a
 * release. The oldest app version each platform still accepts, a maintenance notice, short
 * announcements, and on/off switches for features. Stored per server (instance_settings key
 * "app_config"), edited in Admin, served without sign-in at GET /v1/app-config.
 */

import { normalizeReaction } from "./reactions.ts";

export const APP_PLATFORMS = ["ios", "android", "macos", "windows", "linux", "web"] as const;
export type AppPlatform = (typeof APP_PLATFORMS)[number];
/**
 * Platforms with a minimum version and an update link: the apps, plus Casama for Chrome (D-323).
 * Announcements stay app-only: shipped apps read their platform list strictly.
 */
export const VERSION_PLATFORMS = [...APP_PLATFORMS, "chrome"] as const;
export type VersionPlatform = (typeof VERSION_PLATFORMS)[number];

/** The crash reporters an app can run, one at a time (D-417). */
export const CRASH_REPORTERS = ["sentry", "crashlytics", "posthog", "none"] as const;
export type CrashReporter = (typeof CRASH_REPORTERS)[number];
/** Which crash reporter the apps run: `default` for every platform, a platform's own key over it. */
export type CrashReporterChoice = Partial<Record<"default" | AppPlatform, CrashReporter>>;

export interface Announcement {
  /** Stable id: an app hides an announcement once its id is dismissed. */
  id: string;
  title: string;
  body: string;
  /** An https link opened from the banner. */
  url?: string;
  level: "info" | "warning";
  starts_at?: string;
  ends_at?: string;
  /** Only these platforms; every platform when unset. */
  platforms?: AppPlatform[];
  /** Only apps from this version on (inclusive) or up to this version (inclusive). */
  min_version?: string;
  max_version?: string;
}

export interface RemoteAppConfig {
  /** Apps older than this on a platform must update before they can be used. */
  min_versions: Partial<Record<VersionPlatform, string>>;
  /** Where "Update" goes per platform (a store page or the download page). */
  update_urls: Partial<Record<VersionPlatform, string>>;
  /** When set, apps show this instead of the app until it's cleared. */
  maintenance: { message: string } | null;
  announcements: Announcement[];
  /** Feature switches by name; an app treats a missing name as its own default. */
  flags: Record<string, boolean>;
  /**
   * Links the apps open, by name (D-372): `status`, `docs`, `terms`, `privacy`… An app uses its
   * own address for any name that isn't here. Optional: older servers and apps don't know it.
   */
  links?: Record<string, string>;
  /**
   * Prompts Casama for Chrome sends, by name (D-372): `selection.explain`, `write.draft`… The
   * extension keeps its own text for any name that isn't here.
   */
  prompts?: Record<string, string>;
  /** The reactions offered first under a message (D-331), in order; the apps' own six otherwise. */
  quick_reactions?: string[];
  /**
   * Display names the server knows and the apps used to copy (D-372): `apps` (tool-call app
   * names by slug) and `dns_providers`. Filled in by the server on GET /v1/app-config, never
   * stored or edited.
   */
  names?: Record<string, Record<string, string>>;
  /**
   * The one crash reporter the apps run (D-417), per platform over `default`. An app takes a
   * change on its next launch, and falls back to its build's own choice when the named one isn't
   * in that build. Optional: older servers and apps don't know it.
   */
  crash_reporter?: CrashReporterChoice;
}

/** Keys the server fills in when it serves the settings; a saved copy that has them drops them. */
export const SERVED_APP_CONFIG_KEYS = ["names"] as const;

export const EMPTY_APP_CONFIG: RemoteAppConfig = {
  min_versions: {},
  update_urls: {},
  maintenance: null,
  announcements: [],
  flags: {},
};

const VERSION = /^\d{1,4}\.\d{1,4}\.\d{1,4}$/;
const ID = /^[a-z0-9][a-z0-9-]{0,62}$/;
const FLAG = /^[a-z0-9][a-z0-9_.-]{0,62}$/;

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

function https(v: unknown): string | undefined {
  if (typeof v !== "string" || v.length > 500) return undefined;
  try {
    return new URL(v).protocol === "https:" ? v : undefined;
  } catch {
    return undefined;
  }
}

function time(v: unknown): string | undefined {
  return typeof v === "string" && v.length <= 40 && !Number.isNaN(Date.parse(v)) ? v : undefined;
}

/** -1, 0 or 1: a before, equal to or after b, for x.y.z versions. */
export function compareVersions(a: string, b: string): number {
  const pa = a.split(".").map((n) => Number.parseInt(n, 10) || 0);
  const pb = b.split(".").map((n) => Number.parseInt(n, 10) || 0);
  for (let i = 0; i < 3; i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d) return d < 0 ? -1 : 1;
  }
  return 0;
}

/** Checks an owner's settings. Returns them cleaned when there are no errors. */
export function checkAppConfig(raw: unknown): { config?: RemoteAppConfig; errors: string[] } {
  const errors: string[] = [];
  if (!isRecord(raw)) return { errors: ["settings must be an object"] };
  for (const key of Object.keys(raw))
    if (
      ![
        "min_versions",
        "update_urls",
        "maintenance",
        "announcements",
        "flags",
        "links",
        "prompts",
        "quick_reactions",
        "crash_reporter",
        ...SERVED_APP_CONFIG_KEYS,
      ].includes(key)
    )
      errors.push(`unknown setting ${key}`);

  const perPlatform = (
    name: string,
    value: unknown,
    check: (v: unknown) => string | undefined,
    hint: string,
  ) => {
    const out: Partial<Record<VersionPlatform, string>> = {};
    if (value === undefined || value === null) return out;
    if (!isRecord(value)) {
      errors.push(`${name} must map platforms to values`);
      return out;
    }
    for (const [k, v] of Object.entries(value)) {
      const platform = VERSION_PLATFORMS.find((p) => p === k);
      if (!platform) errors.push(`${name}.${k} isn't a platform (${VERSION_PLATFORMS.join(", ")})`);
      else if (v === null || v === "") continue;
      else if (!check(v)) errors.push(`${name}.${k} must be ${hint}`);
      else out[platform] = v as string;
    }
    return out;
  };
  const min_versions = perPlatform(
    "min_versions",
    raw.min_versions,
    (v) => (typeof v === "string" && VERSION.test(v) ? v : undefined),
    "a version such as 0.8.0",
  );
  const update_urls = perPlatform("update_urls", raw.update_urls, https, "an https link");

  let maintenance: RemoteAppConfig["maintenance"] = null;
  if (raw.maintenance !== undefined && raw.maintenance !== null) {
    const m = isRecord(raw.maintenance) ? raw.maintenance : null;
    const message = m && typeof m.message === "string" ? m.message.trim() : "";
    if (message.length < 1 || message.length > 300)
      errors.push("maintenance.message must be 1 to 300 characters");
    else maintenance = { message };
  }

  const announcements: Announcement[] = [];
  if (raw.announcements !== undefined) {
    if (!Array.isArray(raw.announcements) || raw.announcements.length > 10)
      errors.push("announcements must be a list of at most 10");
    else
      raw.announcements.forEach((a, i) => {
        const at = `announcements[${i}]`;
        if (!isRecord(a)) {
          errors.push(`${at} must be an object`);
          return;
        }
        const id = typeof a.id === "string" && ID.test(a.id) ? a.id : undefined;
        const title = typeof a.title === "string" ? a.title.trim() : "";
        const body = typeof a.body === "string" ? a.body.trim() : "";
        if (!id) errors.push(`${at}.id must be lowercase letters, digits and dashes`);
        if (id && announcements.some((x) => x.id === id))
          errors.push(`${at}.id ${id} is used twice`);
        if (title.length < 1 || title.length > 80)
          errors.push(`${at}.title must be 1 to 80 characters`);
        if (body.length > 400) errors.push(`${at}.body must be at most 400 characters`);
        const level = a.level === undefined ? "info" : a.level;
        if (level !== "info" && level !== "warning")
          errors.push(`${at}.level must be info or warning`);
        const url = a.url === undefined ? undefined : https(a.url);
        if (a.url !== undefined && !url) errors.push(`${at}.url must be an https link`);
        const starts = a.starts_at === undefined ? undefined : time(a.starts_at);
        const ends = a.ends_at === undefined ? undefined : time(a.ends_at);
        if (a.starts_at !== undefined && !starts)
          errors.push(`${at}.starts_at must be a date and time`);
        if (a.ends_at !== undefined && !ends) errors.push(`${at}.ends_at must be a date and time`);
        let platforms: AppPlatform[] | undefined;
        if (a.platforms !== undefined) {
          if (
            !Array.isArray(a.platforms) ||
            !a.platforms.every((p) => APP_PLATFORMS.includes(p as AppPlatform))
          )
            errors.push(`${at}.platforms must list platforms (${APP_PLATFORMS.join(", ")})`);
          else platforms = a.platforms as AppPlatform[];
        }
        const ver = (k: "min_version" | "max_version") => {
          if (a[k] === undefined) return undefined;
          if (typeof a[k] === "string" && VERSION.test(a[k] as string)) return a[k] as string;
          errors.push(`${at}.${k} must be a version such as 0.8.0`);
          return undefined;
        };
        const min_version = ver("min_version");
        const max_version = ver("max_version");
        if (id && title.length >= 1 && title.length <= 80 && body.length <= 400)
          announcements.push({
            id,
            title,
            body,
            level: level === "warning" ? "warning" : "info",
            ...(url ? { url } : {}),
            ...(starts ? { starts_at: starts } : {}),
            ...(ends ? { ends_at: ends } : {}),
            ...(platforms ? { platforms } : {}),
            ...(min_version ? { min_version } : {}),
            ...(max_version ? { max_version } : {}),
          });
      });
  }

  const flags: Record<string, boolean> = {};
  if (raw.flags !== undefined) {
    if (!isRecord(raw.flags) || Object.keys(raw.flags).length > 100)
      errors.push("flags must map up to 100 names to true or false");
    else
      for (const [k, v] of Object.entries(raw.flags)) {
        if (!FLAG.test(k)) errors.push(`flags.${k}: names are lowercase letters, digits, _ . -`);
        else if (typeof v !== "boolean") errors.push(`flags.${k} must be true or false`);
        else flags[k] = v;
      }
  }

  const links: Record<string, string> = {};
  if (raw.links !== undefined && raw.links !== null) {
    if (!isRecord(raw.links) || Object.keys(raw.links).length > 60)
      errors.push("links must map up to 60 names to https links");
    else
      for (const [k, v] of Object.entries(raw.links)) {
        if (!FLAG.test(k)) errors.push(`links.${k}: names are lowercase letters, digits, _ . -`);
        else if (v === null || v === "") continue;
        else if (!https(v)) errors.push(`links.${k} must be an https link`);
        else links[k] = v as string;
      }
  }

  const prompts: Record<string, string> = {};
  if (raw.prompts !== undefined && raw.prompts !== null) {
    if (!isRecord(raw.prompts) || Object.keys(raw.prompts).length > 40)
      errors.push("prompts must map up to 40 names to text");
    else
      for (const [k, v] of Object.entries(raw.prompts)) {
        const t = typeof v === "string" ? v.trim() : "";
        if (!FLAG.test(k)) errors.push(`prompts.${k}: names are lowercase letters, digits, _ . -`);
        else if (v === null || v === "") continue;
        else if (t.length < 1 || t.length > 1000)
          errors.push(`prompts.${k} must be 1 to 1,000 characters`);
        else prompts[k] = t;
      }
  }

  let quick_reactions: string[] | undefined;
  if (raw.quick_reactions !== undefined && raw.quick_reactions !== null) {
    const list = Array.isArray(raw.quick_reactions) ? raw.quick_reactions : null;
    const norm = (list ?? []).map((e) => (typeof e === "string" ? normalizeReaction(e) : null));
    if (!list || list.length < 1 || list.length > 8 || norm.some((e) => !e))
      errors.push("quick_reactions must list 1 to 8 emoji");
    else if (new Set(norm).size !== norm.length)
      errors.push("quick_reactions lists an emoji twice");
    else quick_reactions = norm as string[];
  }

  const crash_reporter: CrashReporterChoice = {};
  if (raw.crash_reporter !== undefined && raw.crash_reporter !== null) {
    if (!isRecord(raw.crash_reporter))
      errors.push(`crash_reporter must map default or platforms to ${CRASH_REPORTERS.join(", ")}`);
    else
      for (const [k, v] of Object.entries(raw.crash_reporter)) {
        const key = k === "default" ? k : APP_PLATFORMS.find((p) => p === k);
        if (!key)
          errors.push(
            `crash_reporter.${k} isn't default or a platform (${APP_PLATFORMS.join(", ")})`,
          );
        else if (v === null || v === "") continue;
        else if (!CRASH_REPORTERS.includes(v as CrashReporter))
          errors.push(`crash_reporter.${k} must be one of ${CRASH_REPORTERS.join(", ")}`);
        else crash_reporter[key] = v as CrashReporter;
      }
  }

  if (errors.length) return { errors };
  return {
    errors,
    config: {
      min_versions,
      update_urls,
      maintenance,
      announcements,
      flags,
      ...(Object.keys(links).length ? { links } : {}),
      ...(Object.keys(prompts).length ? { prompts } : {}),
      ...(quick_reactions ? { quick_reactions } : {}),
      ...(Object.keys(crash_reporter).length ? { crash_reporter } : {}),
    },
  };
}
