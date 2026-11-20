"""Shared pytest fixtures for the emu package tests.

`drive_server` is a fake ECCO Drive: a local HTTP server, run in a
background thread, that serves files from a temporary directory with
HTTP Basic auth and byte-range (resume) support, plus per-file fault
switches that reproduce network and server failures on demand. Download
tests use it so they never touch the real ecco.jpl.nasa.gov server.
"""

import base64
import http.server
import os
import socketserver
import sys
import threading
import time
from urllib.parse import quote, unquote, urlsplit

import pytest

# `python -m pytest` run from the ECCO-EIS root puts that directory on
# sys.path, where EMU's own emu/ folder (Fortran and scripts) would be
# imported instead of the emu Python package. Drop it before any test
# imports emu. (The venv's pytest script, used by emu_test, doesn't add
# it in the first place.)
_REPO_ROOT = os.path.realpath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path[:] = [p for p in sys.path if os.path.realpath(p or os.getcwd()) != _REPO_ROOT]
for _name in [n for n in sys.modules if n == "emu" or n.startswith("emu.")]:
    if getattr(sys.modules[_name], "__file__", None) is None:
        del sys.modules[_name]  # the wrong emu, imported as a namespace package


class RequestRecord:
    """One request the fake server received, for tests to inspect."""

    def __init__(self, path, range_header, status):
        self.path = path
        self.range_header = range_header
        self.status = status


class Fault:
    """Fault settings for one served file.

    drop_after:   close the connection after sending this many body bytes
    wrong_bytes:  send corrupted bytes of the correct length
    status:       reply with this HTTP error code instead of the file
    ignore_range: ignore Range headers and always send the whole file (200)
    times:        apply the fault to this many requests, then serve
                  normally (None = every request)
    """

    def __init__(self, drop_after=None, wrong_bytes=False, status=None,
                 ignore_range=False, times=None):
        self.drop_after = drop_after
        self.wrong_bytes = wrong_bytes
        self.status = status
        self.ignore_range = ignore_range
        self.remaining = times


class FakeDriveServer:
    """Handle returned by the drive_server fixture."""

    def __init__(self, root, username="testuser", password="testpass"):
        self.root = root
        self.username = username
        self.password = password
        self._expected_password = password
        self._faults = {}
        self._lock = threading.Lock()
        self.requests = []
        self._httpd = None
        self._thread = None
        # Seconds each request takes before replying, so concurrency tests
        # can see overlapping requests; and counters of how many overlap
        self.delay = 0.0
        self.active = 0
        self.max_active = 0
        # Called (with the request's path) as each request starts; tests
        # use it to trigger events at a precise point in a fetch
        self.on_request = None

    def _enter(self):
        with self._lock:
            self.active += 1
            self.max_active = max(self.max_active, self.active)

    def _leave(self):
        with self._lock:
            self.active -= 1

    def add_file(self, rel_path, content):
        """Create a file to serve at rel_path (relative to the base URL)."""
        target = self.root / rel_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
        return target

    def set_fault(self, rel_path, **settings):
        """Apply a Fault (see its fields) to one served file."""
        with self._lock:
            self._faults[rel_path] = Fault(**settings)

    def clear_faults(self):
        with self._lock:
            self._faults.clear()

    @property
    def base_url(self):
        host, port = self._httpd.server_address[:2]
        return f"http://{host}:{port}"

    def url(self, rel_path):
        """Full URL for a served file, with path segments percent-encoded."""
        return self.base_url + "/" + "/".join(quote(s) for s in rel_path.split("/"))

    def start(self):
        # Bind to an OS-chosen free port on loopback, serve in a daemon thread
        handler = _make_handler(self)
        self._httpd = _ThreadingServer(("127.0.0.1", 0), handler)
        # A short poll interval makes shutdown() return quickly (default 0.5 s)
        self._thread = threading.Thread(
            target=self._httpd.serve_forever, kwargs={"poll_interval": 0.02}, daemon=True
        )
        self._thread.start()

    def stop(self):
        self._httpd.shutdown()
        self._httpd.server_close()
        self._thread.join(timeout=5)

    def _take_fault(self, rel_path):
        """Return the active Fault for rel_path, using up one of its
        `times`; None once it has run out or if there is none.
        """
        with self._lock:
            fault = self._faults.get(rel_path)
            if fault is None:
                return None
            if fault.remaining is not None:
                if fault.remaining <= 0:
                    return None
                fault.remaining -= 1
            return fault

    def _record(self, rel_path, range_header, status):
        with self._lock:
            self.requests.append(RequestRecord(rel_path, range_header, status))


class _ThreadingServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def _make_handler(server):
    """Build a request handler class bound to one FakeDriveServer."""

    class Handler(http.server.BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def log_message(self, format, *args):
            pass  # keep test output quiet

        def do_GET(self):
            # Count this request as in progress while it is handled
            server._enter()
            try:
                if server.on_request is not None:
                    server.on_request(unquote(urlsplit(self.path).path).lstrip("/"))
                if server.delay:
                    time.sleep(server.delay)
                self._handle_get()
            finally:
                server._leave()

        def _handle_get(self):
            rel_path = unquote(urlsplit(self.path).path).lstrip("/")
            range_header = self.headers.get("Range")

            # Credentials are checked against the password the server
            # was created with; tests change `server.password` to make
            # the client send a wrong one.
            if not self._authorized():
                self._send_error(rel_path, range_header, 401,
                                 {"WWW-Authenticate": 'Basic realm="ECCO Drive"'})
                return

            fault = server._take_fault(rel_path)
            if fault is not None and fault.status is not None:
                self._send_error(rel_path, range_header, fault.status)
                return

            target = server.root / rel_path
            if target.is_dir():
                # A directory answers 200 with a small listing page, as
                # ECCO Drive does; the credential check requests one
                body = b"<html>directory listing</html>\n"
                server._record(rel_path, range_header, 200)
                self.send_response(200)
                self.send_header("Content-Type", "text/html")
                self.send_header("Content-Length", str(len(body)))
                self.send_header("Connection", "close")
                self.end_headers()
                self.wfile.write(body)
                return
            if not target.is_file():
                self._send_error(rel_path, range_header, 404)
                return
            content = target.read_bytes()
            if fault is not None and fault.wrong_bytes:
                content = _corrupt(content)

            # Byte-range resume: honor "bytes=N-" unless told to ignore it
            start = 0
            honor_range = range_header is not None and not (fault and fault.ignore_range)
            if honor_range:
                start = _parse_range_start(range_header)
                if start is None or start >= len(content):
                    self._send_error(rel_path, range_header, 416,
                                     {"Content-Range": f"bytes */{len(content)}"})
                    return

            body = content[start:]
            status = 206 if honor_range else 200
            # Log before replying, so a client that reads the reply and
            # returns at once never sees a log missing this request
            server._record(rel_path, range_header, status)
            self.send_response(status)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Accept-Ranges", "bytes")
            if honor_range:
                self.send_header("Content-Range",
                                 f"bytes {start}-{len(content) - 1}/{len(content)}")
            self.send_header("Connection", "close")
            self.end_headers()

            # Drop the connection partway through if asked to
            if fault is not None and fault.drop_after is not None:
                self.wfile.write(body[:fault.drop_after])
                self.wfile.flush()
                self.close_connection = True
                self.connection.shutdown(2)
                return
            self.wfile.write(body)

        def _authorized(self):
            expected = base64.b64encode(
                f"{server.username}:{server._expected_password}".encode()
            ).decode()
            return self.headers.get("Authorization") == f"Basic {expected}"

        def _send_error(self, rel_path, range_header, code, extra_headers=None):
            body = f"{code}\n".encode()
            server._record(rel_path, range_header, code)  # before replying
            self.send_response(code)
            for name, value in (extra_headers or {}).items():
                self.send_header(name, value)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(body)

    return Handler


def _parse_range_start(header):
    """Return N from a "bytes=N-" Range header, or None if unsupported."""
    if not header.startswith("bytes=") or not header.endswith("-"):
        return None
    try:
        return int(header[len("bytes="):-1])
    except ValueError:
        return None


def _corrupt(content):
    """Return bytes of the same length as `content`, every byte changed."""
    # Flipping all bits of each byte guarantees every byte differs
    return bytes(b ^ 0xFF for b in content)


@pytest.fixture
def drive_server(tmp_path):
    """A running fake ECCO Drive serving files from a temporary directory."""
    root = tmp_path / "drive"
    root.mkdir()
    server = FakeDriveServer(root)
    server.start()
    yield server
    server.stop()
