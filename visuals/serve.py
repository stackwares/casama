#!/usr/bin/env python3
"""Serves the visuals review board at http://localhost:8740/visuals/ (repo root, no caching). Local only."""
import http.server, os, functools
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()
    def log_message(self, *a): pass
http.server.ThreadingHTTPServer(("127.0.0.1", 8740), functools.partial(H, directory=ROOT)).serve_forever()
