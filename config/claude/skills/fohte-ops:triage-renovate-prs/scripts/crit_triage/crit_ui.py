"""Local state server and crit process integration."""
import secrets
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

def serve(state_path):
    """Start the state store on a free port and return its (port, token)."""
    # The page is served from crit's origin, so the store has to allow cross-origin
    # requests -- which also lets any other page the user has open reach it by
    # guessing the port. The token in the path is what keeps those pages out.
    token = secrets.token_urlsafe(16)

    class Handler(BaseHTTPRequestHandler):
        def _authorized(self):
            if self.path == f"/{token}":
                return True
            self.send_response(404)
            self.end_headers()
            return False

        def _cors(self):
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Headers", "content-type")

        def do_OPTIONS(self):
            if not self._authorized():
                return
            self.send_response(204)
            self._cors()
            self.end_headers()

        def do_GET(self):
            if not self._authorized():
                return
            body = state_path.read_bytes() if state_path.exists() else b"{}"
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self._cors()
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):
            if not self._authorized():
                return
            n = int(self.headers.get("Content-Length", 0))
            state_path.write_bytes(self.rfile.read(n))
            self.send_response(204)
            self._cors()
            self.end_headers()

        def log_message(self, *args):
            pass

    server = HTTPServer(("127.0.0.1", 0), Handler)
    # Daemon thread: the store dies with crit, so there is nothing to clean up.
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server.server_port, token


def run_crit(argv, html_path):
    """Run crit to completion, mirroring its stderr, and return (rc, approved).

    crit prints the review URL and a final `approved: true|false` on stderr.
    Neither line appears when the daemon dies before the review is finished --
    which exits 0 all the same -- so `approved` is None for that case and must
    not be read as a decision.
    """
    proc = subprocess.Popen(
        ["crit", *argv, "preview", str(html_path)], stderr=subprocess.PIPE, text=True, bufsize=1
    )
    approved = None
    for line in proc.stderr:
        sys.stderr.write(line)
        sys.stderr.flush()
        if line.strip() in {"approved: true", "approved: false"}:
            approved = line.strip().endswith("true")
    return proc.wait(), approved
