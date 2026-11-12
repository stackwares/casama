import { z } from "@hono/zod-openapi";

/**
 * More from the open gallery (D-241): routine ideas, a reviewed plugin directory, and the
 * remote app settings a server's owner changes without an app release.
 */

const Author = z.object({ name: z.string(), url: z.string().optional() }).openapi("ContentAuthor");

const TemplateCategory = z.enum(["work", "research", "build", "create", "life"]);

export const RoutineIdea = z
  .object({
    id: z.string(),
    name: z.string(),
    description: z.string(),
    category: TemplateCategory,
    icon: z.string().openapi({ description: "Lucide icon name, kebab-case" }),
    instructions_md: z.string(),
    schedule_cron: z.string(),
    featured: z.boolean(),
    author: Author,
  })
  .openapi("RoutineIdea");

export const RoutineIdeaList = z.object({ items: z.array(RoutineIdea) }).openapi("RoutineIdeaList");

export const DirectoryPlugin = z
  .object({
    id: z.string(),
    name: z.string(),
    description: z.string(),
    url: z.string().openapi({ description: "The plugin's GitHub folder" }),
    commit: z.string().openapi({ description: "The reviewed commit; installing pins it" }),
    icon: z.string().optional(),
    adds: z.array(z.string()),
    author: Author,
  })
  .openapi("DirectoryPlugin");

export const PluginDirectory = z
  .object({ items: z.array(DirectoryPlugin) })
  .openapi("PluginDirectory");

const Platform = z.enum(["ios", "android", "macos", "windows", "linux", "web"]);
const PerPlatform = z.object({
  ios: z.string().optional(),
  android: z.string().optional(),
  macos: z.string().optional(),
  windows: z.string().optional(),
  linux: z.string().optional(),
  web: z.string().optional(),
});

export const Announcement = z
  .object({
    id: z.string(),
    title: z.string(),
    body: z.string(),
    url: z.string().optional(),
    level: z.enum(["info", "warning"]),
    starts_at: z.string().optional(),
    ends_at: z.string().optional(),
    platforms: z.array(Platform).optional(),
    min_version: z.string().optional(),
    max_version: z.string().optional(),
  })
  .openapi("Announcement");

export const RemoteAppConfig = z
  .object({
    min_versions: PerPlatform.openapi({
      description: "Apps older than this on a platform must update first",
    }),
    update_urls: PerPlatform.openapi({ description: "Where Update goes on each platform" }),
    maintenance: z.object({ message: z.string() }).nullable(),
    announcements: z.array(Announcement),
    flags: z.record(z.string(), z.boolean()).openapi({
      description: "Feature switches; a missing name means the app's own default",
    }),
  })
  .openapi("RemoteAppConfig");

export const SetRemoteAppConfigRequest = z
  .record(z.string(), z.unknown())
  .openapi("SetRemoteAppConfigRequest", {
    description: "The whole settings object; it replaces what's stored after it's checked",
  });
