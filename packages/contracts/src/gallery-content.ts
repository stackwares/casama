import { z } from "@hono/zod-openapi";
import { galleryExtras } from "./gallery.ts";

/**
 * More from the open gallery (D-241): routine ideas, a reviewed plugin directory, and the
 * remote app settings a server's owner changes without an app release.
 */

const Author = z
  .object({ name: z.string(), url: z.string().optional(), handle: z.string().optional() })
  .openapi("ContentAuthor");

/** Gallery v2 (D-315): what an item needs and asks, what it can touch, and how it's used. */
const extras = {
  ...galleryExtras,
  version: z.number().int().optional(),
  tags: z.array(z.string()).optional(),
};

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
    ...extras,
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
    ...extras,
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
  /** Casama for Chrome (D-323). */
  chrome: z.string().optional(),
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
    // D-372: all optional, so older apps and servers ignore them.
    links: z.record(z.string(), z.string()).optional().openapi({
      description:
        "Links the apps open, by name (status, docs, terms, privacy…); an app uses its own address for a name that isn't here",
    }),
    prompts: z.record(z.string(), z.string()).optional().openapi({
      description:
        "Prompts Casama for Chrome sends, by name (selection.explain, write.draft…); its own text otherwise",
    }),
    quick_reactions: z.array(z.string()).optional().openapi({
      description: "The reactions offered first under a message, in order",
    }),
    names: z.record(z.string(), z.record(z.string(), z.string())).optional().openapi({
      description:
        "Display names the server knows (apps: tool-call app names by slug; dns_providers), filled in when served, never stored",
    }),
  })
  .openapi("RemoteAppConfig");

// ---------------------------------------------------------------- content lists (D-372)

export const LibraryStarter = z
  .object({
    id: z.string(),
    label: z.string(),
    prompt: z.string().openapi({ description: "Typed into quick ask; may end in a space" }),
    icon: z.string().openapi({ description: "Lucide icon name; the app falls back to its own" }),
    hue: z.number(),
  })
  .openapi("LibraryStarter");

export const TextStarter = z.object({ id: z.string(), text: z.string() }).openapi("TextStarter");

export const GalleryLists = z
  .object({
    search_words: z
      .record(z.string(), z.array(z.string()))
      .optional()
      .openapi({ description: "Words people use for the same thing, for gallery search" }),
    starters: z
      .object({
        library: z.array(LibraryStarter).optional(),
        tasks: z.array(TextStarter).optional(),
        support: z.array(TextStarter).optional(),
      })
      .optional()
      .openapi({ description: "Things to start from on the empty Library, Tasks and Help" }),
  })
  .openapi("GalleryLists", {
    description:
      "Content lists from the gallery; a missing list means the app keeps its own copy (D-372)",
  });

// ---------------------------------------------------------------- email copy (D-372)

export const EmailCopySettings = z
  .object({
    copy: z.record(z.string(), z.unknown()).openapi({
      description: "The owner's words by email kind; a missing field uses the text in code",
    }),
    defaults: z.record(z.string(), z.unknown()).openapi({
      description: "The text in code for each editable email, to start from",
    }),
  })
  .openapi("EmailCopySettings");

export const SetEmailCopyRequest = z
  .record(z.string(), z.unknown())
  .openapi("SetEmailCopyRequest", {
    description:
      "Words by email kind (welcome, first_bot_nudge, week_one_tips, come_back, gallery_digest): subject, preheader, title, intro, button",
  });

export const SetRemoteAppConfigRequest = z
  .record(z.string(), z.unknown())
  .openapi("SetRemoteAppConfigRequest", {
    description: "The whole settings object; it replaces what's stored after it's checked",
  });
