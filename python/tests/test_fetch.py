"""Tests for emu.inputs.fetch: running many transfers in parallel,
collecting failures, and stopping cleanly on Ctrl-C.
"""

import hashlib
import json
import os
import threading
import urllib.request

import pytest

from emu.inputs.fetch import EXIT_FAILURES, EXIT_OK, fetch
from emu.inputs.manifest import InventoryEntry
from emu.inputs.state import FetchState

N_FILES = 12


@pytest.fixture
def setup(drive_server, tmp_path):
    """Serve N_FILES small files and return a helper to fetch them."""
    entries = []
    for i in range(N_FILES):
        path = f"dir{i % 3}/file{i:02d}.data"
        content = (f"content of file {i}\n" * (200 + i)).encode()
        drive_server.add_file(path, content)
        entries.append(InventoryEntry(path, len(content), hashlib.md5(content).hexdigest()))
    root = tmp_path / "inputs"
    root.mkdir()

    class Setup:
        server = drive_server

        def run(self, jobs=4, tries=2, stop=None, select=None):
            # Proxy-free opener so test requests always reach the local server
            opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
            return fetch(
                select if select is not None else entries,
                drive_server.url,
                root,
                (drive_server.username, drive_server.password),
                jobs=jobs, tries=tries, sleep=lambda s: None,
                opener=opener, stop=stop,
            )

    s = Setup()
    s.entries, s.root = entries, root
    return s


def test_all_files_arrive_and_verify(setup):
    summary = setup.run()
    assert summary.exit_code == EXIT_OK
    assert summary.downloaded == N_FILES
    assert summary.failed == []
    for entry in setup.entries:
        data = (setup.root / entry.path).read_bytes()
        assert hashlib.md5(data).hexdigest() == entry.md5
    assert set(FetchState(setup.root / ".emu_fetch_state").load_verified()) == {
        e.path for e in setup.entries
    }
    assert not (setup.root / ".emu_fetch.lock").exists()
    assert not (setup.root / "fetch_failures.txt").exists()


@pytest.mark.parametrize("jobs", [1, 4])
def test_never_more_than_jobs_concurrent_requests(setup, jobs):
    # Each request is held for a moment, so overlapping workers overlap
    # on the server and its peak-concurrency counter sees them.
    setup.server.delay = 0.05
    summary = setup.run(jobs=jobs)
    assert summary.exit_code == EXIT_OK
    assert setup.server.max_active == jobs


def test_failures_are_reported_and_others_still_complete(setup):
    bad = [setup.entries[3].path, setup.entries[7].path]
    setup.server.set_fault(bad[0], status=404)
    setup.server.set_fault(bad[1], wrong_bytes=True)

    summary = setup.run()
    assert summary.exit_code == EXIT_FAILURES
    assert sorted(f.path for f in summary.failed) == sorted(bad)
    assert summary.downloaded == N_FILES - 2

    report = (setup.root / "fetch_failures.txt").read_text()
    for path in bad:
        assert path in report
    assert "404" in report and "md5" in report


def test_rerun_fetches_only_missing_or_failed_files(setup):
    bad = setup.entries[5].path
    setup.server.set_fault(bad, status=500)
    first = setup.run()
    assert first.exit_code == EXIT_FAILURES

    # Server fixed; a rerun touches only the one file that failed
    setup.server.clear_faults()
    setup.server.requests.clear()
    second = setup.run()
    assert second.exit_code == EXIT_OK
    assert second.downloaded == 1
    assert second.skipped == N_FILES - 1
    assert [r.path for r in setup.server.requests] == [bad]
    # A clean run removes the earlier failure report
    assert not (setup.root / "fetch_failures.txt").exists()


def test_ctrl_c_stops_cleanly_keeps_part_and_state_and_releases_lock(setup):
    # Setting the stop event the moment the 4th request arrives is what a
    # KeyboardInterrupt handler does; the run must wind down from there.
    stop = threading.Event()
    seen = []

    def on_request(path):
        seen.append(path)
        if len(seen) == 4:
            stop.set()

    setup.server.on_request = on_request
    # A large file so its download is still in progress when stop is set
    big = InventoryEntry("big.data", 3_000_000, None)
    content = os.urandom(big.size)
    setup.server.add_file(big.path, content)
    big.md5 = hashlib.md5(content).hexdigest()
    setup.server.set_fault(big.path, drop_after=1_000_000, times=1)

    summary = setup.run(jobs=1, stop=stop, select=[big] + setup.entries)
    assert summary.interrupted
    assert summary.exit_code == EXIT_FAILURES
    assert not (setup.root / ".emu_fetch.lock").exists()

    # With one worker: request 1 drops, request 2 resumes and finishes
    # big.data, request 3 is file 0, and request 4 (file 1) sets the stop.
    # Only the two files completed before the stop are recorded.
    verified = FetchState(setup.root / ".emu_fetch_state").load_verified()
    assert set(verified) == {big.path, setup.entries[0].path}
    assert len(setup.server.requests) == 4

    # A rerun completes everything, resuming rather than redoing
    setup.server.on_request = None
    again = setup.run(select=[big] + setup.entries)
    assert again.exit_code == EXIT_OK
    assert (setup.root / big.path).read_bytes() == content


def test_ctrl_c_mid_download_keeps_the_part_file(setup, monkeypatch):
    # Stop right after the first 1 MiB chunk of a large file is written:
    # the transfer must end there, keeping that chunk in the .part, and
    # a rerun must resume from it with a Range request.
    import emu.inputs.transfer as transfer

    stop = threading.Event()
    big = InventoryEntry("big.data", 5 * transfer.CHUNK, None)
    content = os.urandom(big.size)
    setup.server.add_file(big.path, content)
    big.md5 = hashlib.md5(content).hexdigest()

    real_open = open

    def open_that_stops_after_first_write(path, mode="r", *args, **kwargs):
        f = real_open(path, mode, *args, **kwargs)
        if str(path).endswith(".part") and "b" in mode and "w" in mode:
            real_write = f.write

            def write(data):
                n = real_write(data)
                stop.set()
                return n

            f.write = write
        return f

    monkeypatch.setattr(transfer, "open", open_that_stops_after_first_write, raising=False)
    summary = setup.run(jobs=1, stop=stop, select=[big])
    monkeypatch.undo()

    part = setup.root / "big.data.part"
    assert summary.interrupted
    assert part.stat().st_size == transfer.CHUNK
    assert not (setup.root / big.path).exists()

    setup.server.requests.clear()
    again = setup.run(select=[big])
    assert again.exit_code == EXIT_OK
    assert (setup.root / big.path).read_bytes() == content
    assert setup.server.requests[0].range_header == f"bytes={transfer.CHUNK}-"


def test_real_keyboard_interrupt_in_main_thread(setup):
    # A real Ctrl-C raises KeyboardInterrupt in the main thread, which is
    # waiting on the workers. fetch() must catch it, stop the workers,
    # release the lock and return a summary instead of crashing.
    import _thread

    setup.server.delay = 0.2  # keep requests in flight long enough
    setup.server.on_request = lambda path: threading.Timer(0.05, _thread.interrupt_main).start()
    setup.server.on_request = _once(setup.server.on_request)

    summary = setup.run(jobs=2)
    assert summary.interrupted
    assert summary.exit_code == EXIT_FAILURES
    assert not (setup.root / ".emu_fetch.lock").exists()
    assert summary.downloaded < N_FILES

    setup.server.on_request = None
    setup.server.delay = 0.0
    assert setup.run().exit_code == EXIT_OK


def _once(func):
    """Wrap func so only its first call does anything."""
    called = threading.Event()

    def wrapper(*args):
        if not called.is_set():
            called.set()
            func(*args)

    return wrapper


def test_fetch_writes_progress_log_and_final_summary(setup):
    import io

    # Hold each request a moment so the run lasts several reporter ticks
    setup.server.delay = 0.05
    setup.server.set_fault(setup.entries[2].path, status=404)
    out = io.StringIO()
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    summary = fetch(
        setup.entries, setup.server.url, setup.root,
        (setup.server.username, setup.server.password),
        jobs=2, tries=1, sleep=lambda s: None, opener=opener,
        progress_stream=out, live=True, tick_seconds=0.05, log_interval=0,
    )
    assert summary.exit_code == EXIT_FAILURES

    log = (setup.root / "fetch_progress.log").read_text().splitlines()
    progress_lines = [l for l in log if " files (" in l]
    assert len(progress_lines) >= 3  # several ticks during the run, plus the final one
    assert progress_lines[-1].split(" ", 2)[2].startswith(f"{N_FILES - 1:,}/{N_FILES:,} files")
    assert log[-1].endswith(f"finished: {N_FILES - 1} downloaded, 0 skipped, 1 failed")

    snap = json.loads((setup.root / ".emu_fetch_progress.json").read_text())
    assert snap["state"] == "finished"
    assert snap["files_done"] == N_FILES - 1 and snap["failed"] == 1
    assert snap["bytes_done"] == sum(e.size for e in setup.entries) - setup.entries[2].size

    # Live output redraws one line with \r and ends with a newline
    text = out.getvalue()
    assert text.count("\r") >= 3 and text.endswith("\n")


def test_interrupted_fetch_records_interrupted_state(setup):
    stop = threading.Event()
    stop.set()
    summary = setup.run(stop=stop)
    assert summary.interrupted
    snap = json.loads((setup.root / ".emu_fetch_progress.json").read_text())
    assert snap["state"] == "interrupted"
    assert (setup.root / "fetch_progress.log").read_text().splitlines()[-1].split(" ", 2)[2].startswith(
        "interrupted:"
    )


def test_lock_prevents_a_second_concurrent_fetch(setup):
    (setup.root / ".emu_fetch.lock").write_text(
        json.dumps({"pid": os.getpid(), "host": __import__("socket").gethostname()})
    )
    from emu.inputs.state import LockHeldError

    with pytest.raises(LockHeldError):
        setup.run()
    assert setup.server.requests == []
