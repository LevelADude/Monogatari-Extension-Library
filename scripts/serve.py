#!/usr/bin/env python3
"""Local test server for the Monogatari Extension Library.

Regenerates index.json, then serves the repository over HTTP so the
Monogatari app can use it as a repository while developing extensions.

Usage:
    py scripts/serve.py [port]      # default port: 8000

Then add  http://<your-pc-ip>:<port>  as repository URL in the app
(Settings -> Repositories). Phone and PC must be on the same network.
"""

import socket
import subprocess
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def main() -> int:
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000

    result = subprocess.run(
        [sys.executable, str(REPO_ROOT / "scripts" / "generate_index.py")],
        cwd=REPO_ROOT,
    )
    if result.returncode != 0:
        return result.returncode

    handler = partial(NoCacheHandler, directory=str(REPO_ROOT))
    server = ThreadingHTTPServer(("0.0.0.0", port), handler)
    print(f"Serving extension repository at: http://{local_ip()}:{port}")
    print("Add this URL as a repository in the Monogatari app. Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
