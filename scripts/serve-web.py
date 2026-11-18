#!/usr/bin/env python3
"""Serves casama.ai, the docs and the gallery locally, linked to each other, for working on the websites.

    python3 scripts/serve-web.py             # builds the docs and the gallery pages first
    python3 scripts/serve-web.py --no-build  # serves the builds that are already there

    casama.ai  http://localhost:8731   site/
    gallery    http://localhost:8732   gallery/
    docs       http://localhost:8733   docs-site/.vitepress/dist (rebuild the docs to see docs edits)
    casama.link http://localhost:8734  link-site/ (D-317; its links to casama.ai and docs stay local too)
    casama.page http://localhost:8735  sites-site/ with link-site's link.css and assets, {{ZONE}} filled in

- Every https://casama.ai, www, docs and gallery address in a served page, script or stylesheet is
  rewritten to its local server, so links between the three sites stay local. Other addresses
  (the app, the API, GitHub) are left alone. The files on disk are not changed.
- Casama Help (site/assets/support/) talks to the local stack's API (http://localhost:8787) on
  localhost by itself; the pages' Content-Security-Policy is widened to allow it here.
- Nothing is cached: a reload shows the latest edit.
- Paths resolve like on Cloudflare: /privacy serves privacy.html, and a missing page gets 404.html.
- The casama.ai worker's routes (/gallery, /gallery/<type>/<id>, /i/<code>, /open/<route>, /get/<platform>) run site/gallery-link.js
  in Node against the local gallery catalog. The invite preview call to the API is skipped, so an
  invite page shows its generic text.
Needs Python 3 and Node. Production is never touched.
"""
import argparse, http.server, mimetypes, os, re, subprocess, sys, threading, json
from urllib.parse import unquote, urlsplit

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITES = {  # production host prefix -> (port, folder)
    '': (8731, os.path.join(ROOT, 'site')),
    'www.': (8731, os.path.join(ROOT, 'site')),
    'gallery.': (8732, os.path.join(ROOT, 'gallery')),
    'docs.': (8733, os.path.join(ROOT, 'docs-site', '.vitepress', 'dist')),
}
LINK_SITE = (8734, os.path.join(ROOT, 'link-site'))  # casama.link's own page
SITES_SITE = (8735, os.path.join(ROOT, 'sites-site'))  # casama.page's own page (D-329); link.css and assets come from link-site, like deploy-sites-web.sh
PROD = re.compile(rb'https://(www\.|docs\.|gallery\.)?casama\.ai(?![\w-]|\.\w)')
TEXT_TYPES = ('text/', 'application/javascript', 'application/json', 'application/xml', 'image/svg+xml')
WORKER_ROUTES = re.compile(r'^/(gallery(/.*)?|i/.*|open(/.*)?|get(/.*)?)$')  # site/wrangler.jsonc run_worker_first

mimetypes.add_type('font/woff2', '.woff2')
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('application/javascript', '.mjs')
mimetypes.add_type('image/webp', '.webp')

# Runs the casama.ai worker for one request. Gallery fetches read the local gallery folder; others fail.
WORKER = r'''
import { readFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";
const root = process.env.CASAMA_ROOT;
globalThis.fetch = async (input) => {
  const u = new URL(String(input));
  if (u.hostname === "gallery.casama.ai") {
    try { return new Response(await readFile(root + "/gallery" + decodeURIComponent(u.pathname))); }
    catch { return new Response("", { status: 404 }); }
  }
  return new Response("", { status: 503 });
};
const worker = (await import(pathToFileURL(root + "/site/gallery-link.js").href)).default;
const res = await worker.fetch(new Request(process.env.CASAMA_URL, { headers: { "user-agent": process.env.CASAMA_UA ?? "" } }));
process.stdout.write(JSON.stringify({ status: res.status, location: res.headers.get("location"),
  type: res.headers.get("content-type"), body: await res.text() }));
'''


def handler_for(folder, is_site, sites_zone=None):
    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def local(self, match):
            host = (self.headers.get('Host') or 'localhost').rsplit(':', 1)[0]
            return f'http://{host}:{SITES[(match.group(1) or b"").decode()][0]}'.encode()

        def send(self, status, body=b'', ctype='text/plain; charset=utf-8', location=None):
            if ctype.startswith(TEXT_TYPES):
                body = PROD.sub(self.local, body)
                body = body.replace(b"connect-src 'self' https://api.casama.ai;", b"connect-src 'self' https://api.casama.ai http://localhost:8787;")
                if sites_zone:
                    body = body.replace(b'{{ZONE}}', sites_zone.encode()).replace(b'{{API}}', b'https://api.casama.ai')
            self.send_response(status)
            if location:
                self.send_header('Location', PROD.sub(self.local, location.encode()).decode())
            self.send_header('Content-Type', ctype)
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            if self.command != 'HEAD':
                self.wfile.write(body)

        def resolve(self, path):
            if sites_zone and not os.path.exists(os.path.join(folder, path.lstrip('/'))) and (path == '/link.css' or path.startswith('/assets/')):
                full = os.path.normpath(os.path.join(LINK_SITE[1], path.lstrip('/')))
                return (full if full.startswith(LINK_SITE[1] + os.sep) and os.path.isfile(full) else None), None
            full = os.path.normpath(os.path.join(folder, path.lstrip('/')))
            if full != folder and not full.startswith(folder + os.sep):
                return None, None
            if os.path.isdir(full):
                if not path.endswith('/'):
                    return None, path + '/'
                full = os.path.join(full, 'index.html')
            elif not os.path.isfile(full) and os.path.isfile(full + '.html'):
                full += '.html'
            return (full if os.path.isfile(full) else None), None

        def worker(self, path):
            host = self.headers.get('Host') or 'localhost'
            env = dict(os.environ, CASAMA_ROOT=ROOT, CASAMA_URL=f'https://casama.ai{self.path}',
                       CASAMA_UA=self.headers.get('User-Agent') or '')
            run = subprocess.run(['node', '--input-type=module', '-e', WORKER], env=env,
                                 capture_output=True, timeout=20)
            if run.returncode != 0:
                return self.send(500, run.stderr[-2000:])
            out = json.loads(run.stdout)
            self.send(out['status'], out['body'].encode(), out['type'] or 'text/plain; charset=utf-8', out['location'])

        def do_GET(self):
            path = unquote(urlsplit(self.path).path)
            if is_site and WORKER_ROUTES.match(path):
                return self.worker(path)
            full, redirect = self.resolve(path)
            if redirect:
                return self.send(301, location=redirect)
            if not full:
                page = os.path.join(folder, '404.html')
                if os.path.isfile(page):
                    return self.send(404, open(page, 'rb').read(), 'text/html; charset=utf-8')
                return self.send(404, b'Not found')
            ctype = mimetypes.guess_type(full)[0] or 'application/octet-stream'
            if ctype.startswith(TEXT_TYPES) and 'charset' not in ctype:
                ctype += '; charset=utf-8'
            self.send(200, open(full, 'rb').read(), ctype)

        do_HEAD = do_GET

    return Handler


def main():
    parser = argparse.ArgumentParser(description='Serve casama.ai, docs and gallery locally.')
    parser.add_argument('--no-build', action='store_true', help="don't rebuild the docs first")
    parser.add_argument('--only-sites', action='store_true', help='serve only casama.page (when the others already run)')
    args = parser.parse_args()
    docs = SITES['docs.'][1]
    if not args.no_build:
        print('Building the docs...', flush=True)
        subprocess.run(['npm', 'run', 'build'], cwd=os.path.join(ROOT, 'docs-site'), check=True,
                       stdout=subprocess.DEVNULL)
        print('Building the gallery pages...', flush=True)
        subprocess.run(['node', os.path.join(ROOT, 'gallery', 'build-pages.mjs')], check=True)
        subprocess.run(['node', os.path.join(ROOT, 'site', 'build.mjs')], check=True)  # casama.ai's written pages
    elif not os.path.isdir(docs):
        sys.exit('No docs build yet: run without --no-build.')
    servers = []
    port, folder = SITES_SITE
    server = http.server.ThreadingHTTPServer(('127.0.0.1', port), handler_for(folder, False, 'casama.page'))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    servers.append(server)
    print(f'{"casama.page":10} http://localhost:{port}', flush=True)
    if args.only_sites:
        threading.Event().wait()
    for prefix, name in (('', 'casama.ai'), ('gallery.', 'gallery'), ('docs.', 'docs')):
        port, folder = SITES[prefix]
        server = http.server.ThreadingHTTPServer(('127.0.0.1', port), handler_for(folder, prefix == ''))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        servers.append(server)
        print(f'{name:10} http://localhost:{port}', flush=True)
    port, folder = LINK_SITE
    server = http.server.ThreadingHTTPServer(('127.0.0.1', port), handler_for(folder, False))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    servers.append(server)
    print(f'{"casama.link":10} http://localhost:{port}', flush=True)
    try:
        threading.Event().wait()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
