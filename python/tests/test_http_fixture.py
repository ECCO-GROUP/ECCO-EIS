"""Self-tests for the fake ECCO Drive server fixture (`drive_server` in
conftest.py), so a later download-test failure can be trusted to be a
downloader bug rather than a fixture bug.
"""

import base64
import http.client
import urllib.error
import urllib.request

import pytest

CONTENT = bytes(range(256)) * 40  # 10,240 bytes, every byte value present


def _get(server, path, auth=True, range_start=None):
    """GET `path` from the fixture; return (status, headers, body).

    Uses a proxy-free opener so local requests never go via a proxy,
    and raises nothing for HTTP error statuses.
    """
    request = urllib.request.Request(server.url(path))
    if auth:
        token = base64.b64encode(
            f"{server.username}:{server.password}".encode()
        ).decode()
        request.add_header("Authorization", f"Basic {token}")
    if range_start is not None:
        request.add_header("Range", f"bytes={range_start}-")
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    try:
        with opener.open(request, timeout=10) as response:
            return response.status, response.headers, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.headers, error.read()


@pytest.fixture
def served(drive_server):
    # One known file to fetch in each test
    drive_server.add_file("dir/a file.data", CONTENT)
    return drive_server


# ---- normal behavior ----

def test_serves_file_with_auth(served):
    status, headers, body = _get(served, "dir/a file.data")
    assert status == 200
    assert body == CONTENT
    assert int(headers["Content-Length"]) == len(CONTENT)
    assert headers["Accept-Ranges"] == "bytes"


def test_auth_required(served):
    status, headers, _ = _get(served, "dir/a file.data", auth=False)
    assert status == 401
    assert headers["WWW-Authenticate"].startswith("Basic")


def test_wrong_password_rejected(served):
    served.password = "not-the-password"  # client sends this; server expects the original
    status, _, _ = _get(served, "dir/a file.data")
    served.password = served._expected_password
    assert status == 401


def test_range_returns_206_with_the_rest_of_the_file(served):
    status, headers, body = _get(served, "dir/a file.data", range_start=1000)
    assert status == 206
    assert body == CONTENT[1000:]
    assert headers["Content-Range"] == f"bytes 1000-{len(CONTENT) - 1}/{len(CONTENT)}"
    assert int(headers["Content-Length"]) == len(CONTENT) - 1000


def test_range_past_end_returns_416(served):
    status, _, _ = _get(served, "dir/a file.data", range_start=len(CONTENT))
    assert status == 416


def test_missing_file_returns_404(served):
    status, _, _ = _get(served, "dir/no-such-file.data")
    assert status == 404


def test_requests_are_logged(served):
    _get(served, "dir/a file.data", range_start=5)
    request = served.requests[-1]
    assert request.path == "dir/a file.data"
    assert request.range_header == "bytes=5-"
    assert request.status == 206


def test_url_encodes_special_characters(served):
    assert served.url("dir/a file.data").endswith("/dir/a%20file.data")


# ---- fault switches ----

def test_drop_after_n_bytes(served):
    served.set_fault("dir/a file.data", drop_after=100)
    # Headers promise the full length but the connection closes early, so
    # the client sees an incomplete read rather than a short, valid body.
    with pytest.raises(http.client.IncompleteRead) as exc_info:
        _get(served, "dir/a file.data")
    assert len(exc_info.value.partial) == 100


def test_drop_after_applies_to_range_requests_too(served):
    served.set_fault("dir/a file.data", drop_after=50)
    with pytest.raises(http.client.IncompleteRead) as exc_info:
        _get(served, "dir/a file.data", range_start=1000)
    assert exc_info.value.partial == CONTENT[1000:1050]


def test_drop_only_for_first_k_requests(served):
    served.set_fault("dir/a file.data", drop_after=100, times=1)
    with pytest.raises(http.client.IncompleteRead):
        _get(served, "dir/a file.data")
    status, _, body = _get(served, "dir/a file.data")
    assert status == 200 and body == CONTENT


def test_wrong_bytes(served):
    served.set_fault("dir/a file.data", wrong_bytes=True)
    status, _, body = _get(served, "dir/a file.data")
    assert status == 200
    assert len(body) == len(CONTENT)  # same size, so only an md5 check can catch it
    assert body != CONTENT


@pytest.mark.parametrize("code", [401, 404, 500])
def test_status_fault(served, code):
    served.set_fault("dir/a file.data", status=code)
    status, _, _ = _get(served, "dir/a file.data")
    assert status == code


def test_500_for_first_k_requests_then_ok(served):
    served.set_fault("dir/a file.data", status=500, times=2)
    assert _get(served, "dir/a file.data")[0] == 500
    assert _get(served, "dir/a file.data")[0] == 500
    status, _, body = _get(served, "dir/a file.data")
    assert status == 200 and body == CONTENT


def test_ignore_range_always_sends_whole_file(served):
    served.set_fault("dir/a file.data", ignore_range=True)
    status, headers, body = _get(served, "dir/a file.data", range_start=1000)
    assert status == 200
    assert body == CONTENT
    assert "Content-Range" not in headers


def test_faults_are_per_file(served):
    served.add_file("other.data", b"untouched")
    served.set_fault("dir/a file.data", status=500)
    status, _, body = _get(served, "other.data")
    assert status == 200 and body == b"untouched"
