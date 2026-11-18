/**
 * Gallery v2 (D-315), the community side: the requests board, submissions from the app (each one
 * a pull request on the catalog repository, so review stays where it is), and authors' own stats.
 */
import { createHmac } from "node:crypto";
import type { Database, JwtClaims } from "@casama/db";
import {
  BOT_LICENSES,
  checkBotDocument,
  checkGalleryInputsUsage,
  checkRoutineDocument,
  checkSchemeDocument,
  checkSkillDocument,
  checkThemeDocument,
  checkWallpaperDocument,
  fillGalleryDocument,
  type GalleryInput,
  galleryHasScripts,
  galleryInputDefaults,
  galleryItemKey,
  LOOK_LICENSES,
  parseGalleryMeta,
  ROUTINE_LICENSES,
  SKILL_LICENSES,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { ApiError } from "../api/errors.ts";
import type { Env } from "../env.ts";
import { galleryRecord, galleryRecords } from "./gallery.ts";

// ---------------------------------------------------------------- requests board

export const REQUESTS_PER_DAY = 5;

type RequestRow = {
  id: string;
  kind: string;
  title: string;
  details: string;
  status: string;
  done_item_key: string | null;
  votes: number;
  voted: boolean;
  mine: boolean;
  created_at: Date | string;
};

const requestOut = (r: RequestRow) => ({
  id: r.id,
  kind: r.kind as "skill",
  title: r.title,
  details: r.details,
  status: r.status as "open",
  done_item_key: r.done_item_key,
  votes: Number(r.votes),
  voted: !!r.voted,
  mine: !!r.mine,
  created_at: new Date(r.created_at).toISOString(),
});

const requestSelect = (userId: string) => sql`
  select q.id, q.kind, q.title, q.details, q.status, q.done_item_key, q.created_at,
    (select count(*)::int from public.gallery_request_votes v where v.request_id = q.id) as votes,
    exists(select 1 from public.gallery_request_votes v where v.request_id = q.id and v.user_id = ${userId}::uuid) as voted,
    (q.created_by = ${userId}::uuid) as mine
  from public.gallery_requests q`;

export async function listGalleryRequests(
  db: Database,
  userId: string,
  opts: { sort?: "top" | "new"; status?: string },
) {
  const rows = await db.execute<RequestRow>(sql`${requestSelect(userId)}
    where not q.hidden ${opts.status ? sql`and q.status = ${opts.status}` : sql``}
    order by ${opts.sort === "new" ? sql`q.created_at desc` : sql`votes desc, q.created_at desc`}
    limit 200`);
  return rows.map(requestOut);
}

export async function getGalleryRequest(db: Database, userId: string, id: string) {
  const [r] = await db.execute<RequestRow>(
    sql`${requestSelect(userId)} where q.id = ${id}::uuid and not q.hidden`,
  );
  if (!r) throw new ApiError(404, "request_not_found", "Request not found");
  return requestOut(r);
}

/** Lowercase words without punctuation or filler, for spotting the same ask twice. */
export function requestFingerprint(title: string): string {
  const filler = new Set(["a", "an", "the", "for", "to", "of", "and", "with", "my", "please"]);
  return title
    .toLowerCase()
    .replace(/[^a-z0-9 ]+/g, " ")
    .split(/\s+/)
    .filter((w) => w && !filler.has(w))
    .map((w) => (w.length > 3 && w.endsWith("s") ? w.slice(0, -1) : w))
    .join(" ");
}

export async function createGalleryRequest(
  db: Database,
  userId: string,
  body: { kind: string; title: string; details?: string },
): Promise<{ created: boolean; request: ReturnType<typeof requestOut> }> {
  const title = body.title.trim().replace(/\s+/g, " ");
  const fp = requestFingerprint(title);
  const open = await db.execute<{ id: string; title: string }>(sql`
    select id, title from public.gallery_requests
    where kind = ${body.kind} and status in ('open', 'planned') and not hidden
    order by created_at desc limit 500`);
  const same = open.find((r) => {
    const other = requestFingerprint(r.title);
    return (
      other === fp ||
      (fp.length >= 8 && other.length >= 8 && (other.includes(fp) || fp.includes(other)))
    );
  });
  if (same) {
    // The same ask: a vote for it instead of a second card.
    await db.execute(sql`
      insert into public.gallery_request_votes (request_id, user_id) values (${same.id}::uuid, ${userId}::uuid)
      on conflict do nothing`);
    return { created: false, request: await getGalleryRequest(db, userId, same.id) };
  }
  const [today] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.gallery_requests
    where created_by = ${userId}::uuid and created_at > now() - interval '1 day'`);
  if ((today?.n ?? 0) >= REQUESTS_PER_DAY)
    throw new ApiError(
      429,
      "rate_limited",
      "That's enough requests for today. Try again tomorrow.",
    );
  const [row] = await db.execute<{ id: string }>(sql`
    insert into public.gallery_requests (kind, title, details, created_by)
    values (${body.kind}, ${title}, ${(body.details ?? "").trim()}, ${userId}::uuid) returning id`);
  await db.execute(sql`
    insert into public.gallery_request_votes (request_id, user_id) values (${row?.id}::uuid, ${userId}::uuid)`);
  return { created: true, request: await getGalleryRequest(db, userId, row?.id as string) };
}

export async function voteGalleryRequest(db: Database, userId: string, id: string, on: boolean) {
  await getGalleryRequest(db, userId, id);
  await db.execute(
    on
      ? sql`insert into public.gallery_request_votes (request_id, user_id) values (${id}::uuid, ${userId}::uuid) on conflict do nothing`
      : sql`delete from public.gallery_request_votes where request_id = ${id}::uuid and user_id = ${userId}::uuid`,
  );
  return getGalleryRequest(db, userId, id);
}

export async function setGalleryRequestStatus(
  db: Database,
  userId: string,
  id: string,
  body: { status: string; done_item_key?: string | null },
) {
  const [r] = await db.execute<{ id: string }>(sql`
    update public.gallery_requests set status = ${body.status},
      done_item_key = ${body.status === "done" ? (body.done_item_key ?? null) : null}
    where id = ${id}::uuid returning id`);
  if (!r) throw new ApiError(404, "request_not_found", "Request not found");
  return getGalleryRequest(db, userId, id);
}

// ---------------------------------------------------------------- submissions

export const SUBMISSIONS_PER_DAY = 5;
export const SUBMISSION_MAX_BYTES = 200 * 1024;

const FOLDER: Record<string, string> = {
  theme: "themes",
  scheme: "schemes",
  wallpaper: "wallpapers",
  skill: "skills",
  routine: "routines",
  bot: "bots",
};
const DOC_FILE: Record<string, string> = {
  theme: "theme.json",
  scheme: "scheme.json",
  wallpaper: "wallpaper.json",
  skill: "SKILL.md",
  routine: "routine.json",
  bot: "bot.json",
};
const LICENSES: Record<string, readonly string[]> = {
  theme: LOOK_LICENSES,
  scheme: LOOK_LICENSES,
  wallpaper: LOOK_LICENSES,
  skill: SKILL_LICENSES,
  routine: ROUTINE_LICENSES,
  bot: BOT_LICENSES,
};

export function slugify(name: string): string {
  return (
    name
      .normalize("NFKD")
      .replace(/[̀-ͯ]/g, "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 60)
      .replace(/-+$/, "") || "item"
  );
}

/** The pull request body's author line: a stable keyed hash, never the person's email or id. */
export function casamaUserHash(
  env: Pick<Env, "SUPABASE_JWT_SECRET" | "DATABASE_URL">,
  userId: string,
) {
  return createHmac("sha256", `gallery-submit:${env.SUPABASE_JWT_SECRET ?? env.DATABASE_URL}`)
    .update(userId)
    .digest("hex")
    .slice(0, 16);
}

function parseJson(name: string, text: string, errors: string[]): unknown {
  try {
    return JSON.parse(text);
  } catch {
    errors.push(`${name} isn't valid JSON`);
    return undefined;
  }
}

/**
 * Checks a submission with the same rules as the catalog checker and returns the folder's files.
 * Wallpapers are patterns or meshes only (no image upload); skills bring no scripts.
 */
export function checkSubmission(input: {
  type: string;
  id: string;
  item: Record<string, unknown>;
  files: Record<string, string>;
  author: string;
  remixOf?: { type: string; id: string };
  today: string;
}): { files: Record<string, string>; name: string; errors: string[] } {
  const errors: string[] = [];
  const { type, id } = input;
  const folder = FOLDER[type];
  if (!folder) return { files: {}, name: "", errors: [`${type} can't be submitted`] };
  const item: Record<string, unknown> = {
    ...input.item,
    author: {
      name: input.author.slice(0, 80) || "Casama user",
      ...(typeof (input.item.author as { url?: unknown })?.url === "string"
        ? { url: (input.item.author as { url: string }).url }
        : {}),
    },
    added: input.today,
    featured: false,
    retired: false,
    ...(input.remixOf ? { remix_of: input.remixOf } : {}),
  };
  delete item.pick;
  delete item.updated;
  const { meta, errors: metaErrors } = parseGalleryMeta(item, LICENSES[type] ?? [], {
    kind: type as "theme",
  });
  errors.push(...metaErrors.map((e) => `item.json: ${e}`));
  const docName = DOC_FILE[type] as string;
  const out: Record<string, string> = {};
  for (const name of Object.keys(input.files)) {
    const okName =
      name === docName || (type === "skill" && /^[A-Za-z0-9._-]{1,80}\.md$/.test(name));
    if (!okName || name === "item.json") errors.push(`${name} isn't a file a ${type} can have`);
  }
  if (type === "skill" && galleryHasScripts(Object.keys(input.files)))
    errors.push("skills submitted from the app can't bring scripts");
  const docText = input.files[docName];
  if (docText === undefined) errors.push(`${docName} is missing`);
  else if (type === "skill") errors.push(...checkSkillDocument(id, docText));
  else {
    const doc = parseJson(docName, docText, errors);
    if (doc !== undefined) {
      if (type === "theme") errors.push(...checkThemeDocument(doc));
      else if (type === "scheme") errors.push(...checkSchemeDocument(doc));
      else if (type === "wallpaper") {
        const kind = (doc as { kind?: unknown })?.kind;
        if (kind !== "pattern" && kind !== "mesh")
          errors.push("wallpapers from the app are patterns or meshes");
        else errors.push(...checkWallpaperDocument(doc, []));
      } else {
        const inputs = (meta?.inputs ?? []) as GalleryInput[];
        errors.push(...checkGalleryInputsUsage(type as "routine", inputs, doc));
        const filled = fillGalleryDocument(type as "routine", doc, galleryInputDefaults(inputs));
        errors.push(
          ...(type === "routine" ? checkRoutineDocument(filled) : checkBotDocument(filled)).errors,
        );
      }
    }
  }
  if (errors.length) return { files: {}, name: meta?.name ?? "", errors };
  out[`${folder}/${id}/item.json`] = `${JSON.stringify(item, null, 2)}\n`;
  for (const [name, text] of Object.entries(input.files)) out[`${folder}/${id}/${name}`] = text;
  return { files: out, name: meta?.name ?? id, errors };
}

type GitHub = { api: string; repo: string; token: string; fetch: typeof fetch };

async function gh(g: GitHub, method: string, path: string, body?: unknown) {
  const res = await g.fetch(`${g.api.replace(/\/$/, "")}/repos/${g.repo}${path}`, {
    method,
    headers: {
      authorization: `Bearer ${g.token}`,
      accept: "application/vnd.github+json",
      "x-github-api-version": "2022-11-28",
      "user-agent": "casama-gallery",
      ...(body ? { "content-type": "application/json" } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    signal: AbortSignal.timeout(20_000),
  });
  const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
  if (!res.ok)
    throw new ApiError(
      502,
      "submission_failed",
      `GitHub said ${res.status}${typeof json.message === "string" ? `: ${json.message}`.slice(0, 200) : ""}`,
    );
  return json;
}

/** Opens a pull request with the files on a new branch: ref, one commit per file, then the PR. */
export async function openGalleryPullRequest(
  g: GitHub,
  pr: { branch: string; title: string; body: string; files: Record<string, string> },
): Promise<{ url: string; number: number }> {
  const repo = await gh(g, "GET", "");
  const base = typeof repo.default_branch === "string" ? repo.default_branch : "main";
  const ref = await gh(g, "GET", `/git/ref/heads/${encodeURIComponent(base)}`);
  const sha = (ref.object as { sha?: string } | undefined)?.sha;
  if (!sha) throw new ApiError(502, "submission_failed", "GitHub didn't return the main branch");
  await gh(g, "POST", "/git/refs", { ref: `refs/heads/${pr.branch}`, sha });
  for (const [path, text] of Object.entries(pr.files))
    await gh(g, "PUT", `/contents/${path.split("/").map(encodeURIComponent).join("/")}`, {
      message: `Add ${path}`,
      content: Buffer.from(text, "utf8").toString("base64"),
      branch: pr.branch,
    });
  const made = await gh(g, "POST", "/pulls", {
    title: pr.title,
    head: pr.branch,
    base,
    body: pr.body,
    maintainer_can_modify: true,
  });
  return { url: String(made.html_url ?? ""), number: Number(made.number) };
}

export type SubmitEnv = Pick<
  Env,
  | "GALLERY_SUBMIT_TOKEN"
  | "GALLERY_SUBMIT_REPO"
  | "GITHUB_API_URL"
  | "SUPABASE_JWT_SECRET"
  | "DATABASE_URL"
> &
  Env;

function github(env: SubmitEnv, fetchImpl: typeof fetch): GitHub | null {
  if (!env.GALLERY_SUBMIT_TOKEN) return null;
  return {
    api: env.GITHUB_API_URL ?? "https://api.github.com",
    repo: env.GALLERY_SUBMIT_REPO,
    token: env.GALLERY_SUBMIT_TOKEN,
    fetch: fetchImpl,
  };
}

type SubmissionRow = {
  id: string;
  item_key: string;
  name: string;
  pr_url: string | null;
  pr_number: number | null;
  status: "open" | "merged" | "closed" | "failed";
  status_checked_at: Date | string | null;
  created_at: Date | string;
};

const submissionOut = (r: SubmissionRow) => {
  const i = r.item_key.indexOf("/");
  return {
    id: r.id,
    type: r.item_key.slice(0, i) as "theme",
    item_id: r.item_key.slice(i + 1),
    name: r.name,
    pr_url: r.pr_url,
    status: r.status,
    created_at: new Date(r.created_at).toISOString(),
  };
};

export async function createGallerySubmission(
  db: Database,
  env: SubmitEnv,
  claims: JwtClaims,
  body: {
    type: string;
    id?: string;
    item: Record<string, unknown>;
    files: Record<string, string>;
    remix_of?: { type: string; id: string };
  },
  fetchImpl: typeof fetch = fetch,
) {
  const g = github(env, fetchImpl);
  if (!g)
    throw new ApiError(503, "submissions_off", "Submissions aren't turned on for this server.");
  const bytes =
    Buffer.byteLength(JSON.stringify(body.item)) +
    Object.values(body.files).reduce((n, t) => n + Buffer.byteLength(t), 0);
  if (bytes > SUBMISSION_MAX_BYTES)
    throw new ApiError(400, "submission_too_big", "A submission can be at most 200 KB.");
  const [today] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.gallery_submissions
    where user_id = ${claims.sub}::uuid and created_at > now() - interval '1 day'`);
  if ((today?.n ?? 0) >= SUBMISSIONS_PER_DAY)
    throw new ApiError(
      429,
      "rate_limited",
      "That's enough submissions for today. Try again tomorrow.",
    );
  const [person] = await db.execute<{ name: string | null }>(sql`
    select nullif(btrim(coalesce(p.preferred_name, p.display_name)), '') as name
    from public.profiles p where p.user_id = ${claims.sub}::uuid`);
  const author = person?.name ?? "Casama user";
  const id =
    body.id ?? slugify(typeof body.item.name === "string" ? body.item.name : `my-${body.type}`);
  if (body.remix_of && !(await galleryRecord(env, body.remix_of.type, body.remix_of.id)))
    throw new ApiError(400, "validation_failed", "The item this remixes isn't in the gallery.", {
      errors: [{ path: "remix_of", message: "Not in the gallery" }],
    });
  if (await galleryRecord(env, body.type, id).catch(() => undefined))
    throw new ApiError(409, "gallery_id_taken", "The gallery already has an item with that id.", {
      errors: [{ path: "id", message: "Taken; pick another" }],
    });
  const today2 = new Date().toISOString().slice(0, 10);
  const checked = checkSubmission({
    type: body.type,
    id,
    item: body.item,
    files: body.files,
    author,
    remixOf: body.remix_of,
    today: today2,
  });
  if (checked.errors.length)
    throw new ApiError(400, "validation_failed", checked.errors.slice(0, 5).join("; "), {
      errors: checked.errors.slice(0, 30).map((message) => ({ path: "item", message })),
    });
  const [row] = await db.execute<{ id: string }>(sql`
    insert into public.gallery_submissions (user_id, item_key, name, bytes, status)
    values (${claims.sub}::uuid, ${galleryItemKey(body.type, id)}, ${checked.name.slice(0, 120)}, ${bytes}, 'open')
    returning id`);
  const subId = row?.id as string;
  try {
    const pr = await openGalleryPullRequest(g, {
      branch: `submission/${body.type}-${id}-${subId.slice(0, 8)}`,
      title: `Add ${body.type} ${checked.name}`,
      body: [
        `A ${body.type} submitted from the Casama app.`,
        "",
        `- Author: ${author}`,
        `- casama_user: ${casamaUserHash(env, claims.sub)}`,
        ...(body.remix_of ? [`- Remix of: ${body.remix_of.type}/${body.remix_of.id}`] : []),
        "",
        "Run `node gallery/check.mjs` and review it like any other gallery pull request.",
      ].join("\n"),
      files: checked.files,
    });
    await db.execute(sql`
      update public.gallery_submissions set pr_url = ${pr.url}, pr_number = ${pr.number}, status_checked_at = now()
      where id = ${subId}::uuid`);
  } catch (err) {
    await db.execute(
      sql`update public.gallery_submissions set status = 'failed' where id = ${subId}::uuid`,
    );
    throw err;
  }
  const [out] = await db.execute<SubmissionRow>(
    sql`select * from public.gallery_submissions where id = ${subId}::uuid`,
  );
  return submissionOut(out as SubmissionRow);
}

/** Asks GitHub how open pull requests went: merged, closed or still open. */
export async function refreshSubmissionStatuses(
  db: Database,
  env: SubmitEnv,
  where: { userId?: string; olderThanMinutes?: number } = {},
  fetchImpl: typeof fetch = fetch,
): Promise<number> {
  const g = github(env, fetchImpl);
  if (!g) return 0;
  const rows = await db.execute<SubmissionRow>(sql`
    select * from public.gallery_submissions
    where status = 'open' and pr_number is not null
      ${where.userId ? sql`and user_id = ${where.userId}::uuid` : sql``}
      and (status_checked_at is null or status_checked_at < now() - make_interval(mins => ${where.olderThanMinutes ?? 10}))
    order by status_checked_at nulls first limit 20`);
  let changed = 0;
  for (const r of rows) {
    try {
      const pr = await gh(g, "GET", `/pulls/${r.pr_number}`);
      const status =
        pr.merged === true || pr.merged_at ? "merged" : pr.state === "closed" ? "closed" : "open";
      await db.execute(sql`
        update public.gallery_submissions set status = ${status}, status_checked_at = now() where id = ${r.id}::uuid`);
      if (status !== "open") changed++;
    } catch {
      await db.execute(
        sql`update public.gallery_submissions set status_checked_at = now() where id = ${r.id}::uuid`,
      );
    }
  }
  return changed;
}

export async function listGallerySubmissions(
  db: Database,
  env: SubmitEnv,
  userId: string,
  fetchImpl: typeof fetch = fetch,
) {
  await refreshSubmissionStatuses(db, env, { userId }, fetchImpl).catch(() => 0);
  const rows = await db.execute<SubmissionRow>(sql`
    select * from public.gallery_submissions where user_id = ${userId}::uuid order by created_at desc limit 100`);
  return rows.map(submissionOut);
}

/** Items from my merged submissions, with their full (unthresholded) numbers. */
export async function myGalleryItems(db: Database, env: Env, userId: string) {
  const subs = await db.execute<{ item_key: string; name: string }>(sql`
    select distinct on (item_key) item_key, name from public.gallery_submissions
    where user_id = ${userId}::uuid and status = 'merged' order by item_key, created_at desc`);
  if (!subs.length) return [];
  const keys = subs.map((s) => s.item_key);
  const stats = await db.execute<{
    item_key: string;
    installers: number;
    installers_7d: number;
    active_14d: number;
    runs_ok: number;
    runs_total: number;
  }>(
    sql`select * from public.gallery_item_stats where item_key in (${sql.join(
      keys.map((k) => sql`${k}`),
      sql`, `,
    )})`,
  );
  const reports = await db.execute<{ target_id: string; n: number }>(sql`
    select target_id, count(*)::int as n from public.content_reports
    where target_kind = 'gallery_item' and status = 'open' and target_id in (${sql.join(
      keys.flatMap((k) => [sql`${k}`, sql`${k.slice(k.indexOf("/") + 1)}`]),
      sql`, `,
    )}) group by target_id`);
  const types = [...new Set(keys.map((k) => k.slice(0, k.indexOf("/"))))];
  const records = await galleryRecords(env, types).catch(() => []);
  return subs.map((s) => {
    const i = s.item_key.indexOf("/");
    const type = s.item_key.slice(0, i);
    const id = s.item_key.slice(i + 1);
    const st = stats.find((x) => x.item_key === s.item_key);
    const rec = records.find((r) => r.type === type && r.id === id);
    return {
      type: type as "theme",
      id,
      name: rec?.name ?? s.name,
      version: typeof rec?.version === "number" ? rec.version : null,
      stats: {
        installers: Number(st?.installers ?? 0),
        installers_7d: Number(st?.installers_7d ?? 0),
        active: Number(st?.active_14d ?? 0),
        runs_ok: Number(st?.runs_ok ?? 0),
        runs_total: Number(st?.runs_total ?? 0),
      },
      reports_open: reports
        .filter((r) => r.target_id === s.item_key || r.target_id === id)
        .reduce((n, r) => n + Number(r.n), 0),
    };
  });
}
