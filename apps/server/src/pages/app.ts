/**
 * The pages origin (D-092, D-119): a separate origin that serves bots' pages with a strict content
 * security policy. Signed-in viewers arrive with a single-use view link from the app, which turns
 * into a short page-scoped cookie; public pages use their revocable token.
 */
import { hashPageToken, newPageToken } from "@kasama/agent";
import { type Database, withUserSession } from "@kasama/db";
import { PAGE_HEADERS, renderPage } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { Hono } from "hono";
import { getCookie, setCookie } from "hono/cookie";
import type { PdfRenderer } from "../services/pdf.ts";

export const PAGE_SESSION_SECONDS = 30 * 60;
const COOKIE = "kasama_page";

type PageRow = { id: string; title: string; html: string; data: unknown; updated_at: string };

export function createPagesApp(deps: { db: Database; pdf?: PdfRenderer | null }) {
  const { db } = deps;
  const app = new Hono();

  const notFound = () =>
    new Response(
      "<!doctype html><meta name=robots content=noindex><title>Not found</title><p style=\"font-family:system-ui;padding:24px\">This page doesn't exist, has expired, or isn't shared with you.</p>",
      { status: 404, headers: { ...PAGE_HEADERS, "content-type": "text/html; charset=utf-8" } },
    );

  const serve = async (page: PageRow, format: "html" | "pdf") => {
    const html = renderPage({
      title: page.title,
      html: page.html,
      data: page.data,
      updatedAt: new Date(page.updated_at),
    });
    if (format === "pdf") {
      if (!deps.pdf)
        return new Response("PDF export isn't set up on this server.", {
          status: 503,
          headers: { "content-type": "text/plain; charset=utf-8" },
        });
      const pdf = await deps.pdf.render(html);
      const name = page.title.replace(/[^\w -]+/g, "").slice(0, 80) || "page";
      return new Response(pdf, {
        headers: {
          ...PAGE_HEADERS,
          "content-type": "application/pdf",
          "content-disposition": `inline; filename="${name}.pdf"`,
        },
      });
    }
    return new Response(html, { headers: { ...PAGE_HEADERS, "content-type": "text/html; charset=utf-8" } });
  };

  // Clean up used and expired view tokens now and then.
  app.use("*", async (_c, next) => {
    if (Math.random() < 0.01)
      void db.execute(sql`delete from public.page_view_tokens where expires_at < now() - interval '1 day'`).catch(() => {});
    await next();
  });

  app.get("/robots.txt", (c) => c.text("User-agent: *\nDisallow: /\n"));

  // A view link from the app: single use, 60 s, bound to the page and the viewer.
  app.get("/v/:token", async (c) => {
    const [link] = await db.execute<{ page_id: string; user_id: string; format: "html" | "pdf" }>(sql`
      update public.page_view_tokens set used_at = now()
      where token_hash = ${hashPageToken(c.req.param("token"))} and kind = 'link' and used_at is null and expires_at > now()
      returning page_id, user_id, format`);
    if (!link) return notFound();
    const session = newPageToken();
    await db.execute(sql`
      insert into public.page_view_tokens (token_hash, page_id, user_id, kind, expires_at)
      values (${hashPageToken(session)}, ${link.page_id}::uuid, ${link.user_id}::uuid, 'session', now() + make_interval(secs => ${PAGE_SESSION_SECONDS}))`);
    setCookie(c, COOKIE, session, {
      path: `/p/${link.page_id}`,
      httpOnly: true,
      secure: new URL(c.req.url).protocol === "https:",
      sameSite: "Lax",
      maxAge: PAGE_SESSION_SECONDS,
    });
    c.header("referrer-policy", "no-referrer");
    return c.redirect(`/p/${link.page_id}${link.format === "pdf" ? "/pdf" : ""}`, 302);
  });

  const signedIn = async (id: string, cookie: string | undefined) => {
    if (!cookie || !/^[0-9a-f-]{36}$/.test(id)) return null;
    const [s] = await db.execute<{ user_id: string }>(sql`
      select user_id from public.page_view_tokens
      where token_hash = ${hashPageToken(cookie)} and kind = 'session' and page_id = ${id}::uuid and expires_at > now()`);
    if (!s) return null;
    // Still allowed? (Access is checked again as the viewer, so removing them works at once.)
    const [page] = await withUserSession(db, { sub: s.user_id, role: "authenticated" }, (tx) =>
      tx.execute<PageRow>(sql`select id, title, html, data, updated_at from public.pages where id = ${id}::uuid`),
    );
    return page ?? null;
  };

  for (const format of ["html", "pdf"] as const) {
    app.get(format === "html" ? "/p/:id" : "/p/:id/pdf", async (c) => {
      const page = await signedIn(c.req.param("id"), getCookie(c, COOKIE));
      return page ? serve(page, format) : notFound();
    });
    app.get(format === "html" ? "/s/:token" : "/s/:token/pdf", async (c) => {
      const [page] = await db.execute<PageRow>(sql`
        select id, title, html, data, updated_at from public.pages
        where public_token_hash = ${hashPageToken(c.req.param("token"))} and visibility = 'public'
          and (expires_at is null or expires_at > now())`);
      return page ? serve(page, format) : notFound();
    });
  }

  return app;
}
