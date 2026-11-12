/**
 * https://casama.ai/gallery/<type>/<id> is a gallery item's link (D-184). With the app installed
 * the phone opens it there; anywhere else this page shows the item, drawn by the gallery's own
 * previews, with a way to open it in the app and a way to get the app.
 * https://casama.ai/gallery goes to the gallery itself.
 *
 * https://casama.ai/i/<code> is a friend's invite link (D-211): who invited you, the code to enter
 * after signing up, and a way to open or get the app. With the app installed the phone opens it there.
 */
const TYPES = "theme|scheme|wallpaper|skill";
const GALLERY = "https://gallery.casama.ai";
const API = "https://api.casama.ai";
const SINGULAR = { theme: "Theme", scheme: "Color scheme", wallpaper: "Wallpaper", skill: "Skill" };

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const invite = /^\/i\/([0-9A-Za-z]{6})\/?$/.exec(url.pathname);
    if (invite) return invitePage(invite[1].toUpperCase());
    if (/^\/gallery\/?$/.test(url.pathname)) return Response.redirect(`${GALLERY}/`, 302);
    const match = new RegExp(`^/gallery/(${TYPES})/([a-z0-9][a-z0-9-]{0,62})/?$`).exec(url.pathname);
    if (!match) return new Response("Not found", { status: 404 });
    const type = match[1];
    const id = match[2];
    let item = null;
    try {
      const index = await fetch(`${GALLERY}/index.json`, { cf: { cacheTtl: 300 } });
      if (index.ok) {
        const data = await index.json();
        item = (data.items ?? []).find((entry) => entry.type === type && entry.id === id && !entry.retired) ?? null;
      }
    } catch {
      // The page still offers the app link when the catalog is briefly unreachable.
    }
    return new Response(page(type, id, item), {
      status: item ? 200 : 404,
      headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=300" },
    });
  },
};

function page(type, id, item) {
  const name = item?.name ?? id;
  const author = item?.author?.name ?? "";
  const kind = SINGULAR[type];
  const about = item
    ? item.description ?? `${kind} for Casama${author ? ` by ${author}` : ""}. Free and open source (${item.license}).`
    : "This item isn't in the gallery anymore, or the gallery can't be reached right now.";
  const open = `casama://app/gallery/${type}/${id}`;
  const inGallery = `${GALLERY}/#${type}/${id}`;
  // The item rides along as JSON for the preview; "<" is escaped so it can't close the script.
  const data = JSON.stringify(item).replace(/</g, "\\u003c");
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(name)} · Casama Gallery</title>
<meta name="description" content="${esc(about)}">
<meta property="og:title" content="${esc(name)} · Casama Gallery">
<meta property="og:description" content="${esc(about)}">
<meta property="og:url" content="https://casama.ai/gallery/${type}/${id}">
<link rel="canonical" href="https://casama.ai/gallery/${type}/${id}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="${GALLERY}/gallery.css">
<style>
  :root { --bg:#f6f4ef; --ink:#1d1f1c; --muted:#5c625b; --line:#dcd8cf; --accent:#0f6b5c; --accent-ink:#fff; --card:#fffdf8; }
  @media (prefers-color-scheme: dark) { :root { --bg:#121412; --ink:#ecebe6; --muted:#a3a8a0; --line:#2a2e2a; --accent:#5cc4ae; --accent-ink:#0b1210; --card:#181b18; } }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--ink); font: 17px/1.55 ui-sans-serif, -apple-system, "Segoe UI", Inter, system-ui, sans-serif; }
  a { color: inherit; }
  .wrap { max-width: 1080px; margin: 0 auto; padding: 0 20px; }
  header { display: flex; align-items: center; gap: 10px; padding: 22px 0; }
  .logo { font-weight: 700; letter-spacing: -0.02em; font-size: 20px; text-decoration: none; }
  .crumb { color: var(--muted); text-decoration: none; }
  .item { display: grid; grid-template-columns: minmax(0, 1.15fr) minmax(0, 0.85fr); gap: 48px; align-items: center; padding: 40px 0 72px; }
  .pic { display: grid; gap: 12px; }
  .pic .cg-frame { --cg-radius: 12px; border: 1px solid var(--line); }
  .pic.two { grid-template-columns: 0.42fr 1fr; align-items: center; }
  .instructions { margin: 0; max-height: 420px; overflow: auto; white-space: pre-wrap; background: var(--card); border: 1px solid var(--line); border-radius: 12px; padding: 18px 20px; font: 13.5px/1.55 ui-monospace, SFMono-Regular, Menlo, monospace; }
  .kind { color: var(--muted); margin: 0 0 6px; }
  h1 { font-size: clamp(34px, 5vw, 52px); line-height: 1.05; letter-spacing: -0.03em; margin: 0 0 14px; font-weight: 700; }
  .about { font-size: 19px; color: var(--muted); margin: 0 0 26px; max-width: 34ch; }
  .ctas { display: flex; gap: 12px; flex-wrap: wrap; }
  .btn { display: inline-block; padding: 12px 18px; border-radius: 10px; text-decoration: none; font-weight: 600; font-size: 15px; border: 1px solid var(--line); }
  .btn.primary { background: var(--accent); color: var(--accent-ink); border-color: transparent; }
  .more { margin: 22px 0 0; font-size: 15px; color: var(--muted); }
  footer { padding: 32px 0 56px; color: var(--muted); font-size: 14px; border-top: 1px solid var(--line); }
  @media (max-width: 820px) { .item { grid-template-columns: 1fr; gap: 28px; padding-top: 16px; } }
</style>
</head>
<body>
<div class="wrap">
  <header><a class="logo" href="https://casama.ai">casama</a><span class="crumb" aria-hidden="true">/</span><a class="crumb" href="${GALLERY}/">Gallery</a></header>
  <main class="item">
    <div class="pic" id="pic"></div>
    <div>
      <p class="kind">${esc(kind)}${author ? ` · By ${esc(author)}` : ""}${item ? ` · ${esc(item.license)}` : ""}</p>
      <h1 id="name">${esc(name)}</h1>
      <p class="about">${esc(about)}</p>
      <div class="ctas">
        <a class="btn primary" href="${open}">Open in Casama</a>
        <a class="btn" href="https://casama.ai">Get Casama</a>
      </div>
      <p class="more"><a href="${inGallery}">See it in the gallery</a>, with everything else people have made for Casama.</p>
    </div>
  </main>
  <footer>Casama Gallery: themes, color schemes, wallpapers and skills, free and open source. <a href="${GALLERY}/#contribute">Add your own</a>.</footer>
</div>
<script src="${GALLERY}/gallery.js"></script>
<script>
  (function () {
    var item = ${data};
    var G = window.CasamaGallery;
    var pic = document.getElementById("pic");
    if (!item || !G) return;
    var dark = matchMedia("(prefers-color-scheme: dark)").matches;
    if (item.type === "theme" && item.document && item.document.headingFont) {
      G.ensureFonts([item.document.headingFont]);
      document.getElementById("name").style.fontFamily = "'" + item.document.headingFont + "', ui-sans-serif, system-ui, sans-serif";
    }
    if (item.type === "skill") {
      var pre = document.createElement("pre");
      pre.className = "instructions";
      pre.textContent = item.description || "";
      pic.appendChild(pre);
      var path = (item.files || []).filter(function (f) { return /\\/SKILL\\.md$/.test(f); })[0];
      if (path) fetch(G.HOST + "/" + path).then(function (r) { return r.text(); }).then(function (md) {
        pre.textContent = md.replace(/^---\\n[\\s\\S]*?\\n---\\n?/, "").trim();
      });
      return;
    }
    var look = G.lookOf(item, { alone: false });
    if (item.type === "wallpaper") {
      pic.className = "pic two";
      pic.appendChild(G.wallpaper(item, { dark: dark }));
    }
    pic.appendChild(G.chat(look, { dark: dark, aspect: "16 / 10", label: item.name + " in a Casama chat" }));
  })();
</script>
</body>
</html>`;
}

async function invitePage(code) {
  let preview = null;
  try {
    const res = await fetch(`${API}/v1/referral/preview?code=${code}`, { cf: { cacheTtl: 300 } });
    if (res.ok) preview = await res.json();
  } catch {
    // The page still shows the code and the app links when the API is briefly unreachable.
  }
  const name = preview?.inviter_name ?? "";
  const who = name ? `${name} invited you to Casama` : "You're invited to Casama";
  const bonus = Number(preview?.welcome_usd ?? 0);
  const dollars = Number.isInteger(bonus) ? `$${bonus}` : `$${bonus.toFixed(2)}`;
  const about =
    bonus > 0
      ? `AI teammates that get things done for you, each on its own computer. Sign up with this code and get ${dollars} of free usage after your first chat.`
      : "AI teammates that get things done for you, each on its own computer. Sign up, then enter the code so your friend gets the credit.";
  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${esc(who)}</title>
<meta name="description" content="${esc(about)}">
<meta property="og:title" content="${esc(who)}">
<meta property="og:description" content="${esc(about)}">
<meta property="og:image" content="https://casama.ai/og-image.png">
<style>
  :root { --bg:#f6f4ef; --ink:#1d1f1c; --muted:#5c625b; --line:#dcd8cf; --accent:#0f6b5c; --accent-ink:#fff; --card:#fffdf8; }
  @media (prefers-color-scheme: dark) { :root { --bg:#121412; --ink:#ecebe6; --muted:#a3a8a0; --line:#2a2e2a; --accent:#5cc4ae; --accent-ink:#0b1210; --card:#181b18; } }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100vh; display: grid; place-items: center; padding: 16px; background: var(--bg); color: var(--ink); font: 17px/1.55 ui-sans-serif, -apple-system, "Segoe UI", Inter, system-ui, sans-serif; }
  main { width: 100%; max-width: 440px; background: var(--card); border: 1px solid var(--line); border-radius: 20px; padding: 32px 24px; text-align: center; }
  .logo { font-weight: 700; letter-spacing: -0.02em; font-size: 20px; text-decoration: none; color: inherit; }
  h1 { font-size: 28px; line-height: 1.15; letter-spacing: -0.02em; margin: 20px 0 10px; }
  p { margin: 0 0 18px; color: var(--muted); }
  .code { display: inline-block; margin: 4px 0 22px; padding: 10px 18px; border-radius: 12px; border: 1px dashed var(--accent); font: 700 26px/1 ui-monospace, SFMono-Regular, Menlo, monospace; letter-spacing: 6px; user-select: all; }
  .btn { display: block; padding: 13px 18px; border-radius: 10px; text-decoration: none; font-weight: 600; font-size: 15px; border: 1px solid var(--line); color: inherit; margin-top: 10px; }
  .btn.primary { background: var(--accent); color: var(--accent-ink); border-color: transparent; }
  .small { font-size: 14px; margin: 18px 0 0; }
</style>
</head>
<body>
<main>
  <a class="logo" href="https://casama.ai">casama</a>
  <h1>${esc(who)}</h1>
  <p>${esc(about)}</p>
  <div class="code" aria-label="Invite code">${esc(code)}</div>
  <a class="btn primary" href="casama://app/i/${esc(code)}">Open in Casama</a>
  <a class="btn" href="https://casama.ai">Get Casama</a>
  <p class="small">Already have the app? It opens this invite by itself. Otherwise, after signing up go to Settings → Invite friends and enter the code within a week.</p>
</main>
</body>
</html>`;
  return new Response(html, {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=300" },
  });
}

function esc(value) {
  return String(value).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
}
