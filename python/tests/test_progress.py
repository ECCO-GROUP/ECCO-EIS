"""Tests for emu.inputs.progress: the shared fetch counters (Progress)
and the outputs built from them (Reporter): the live line, the
fetch_progress.log file and the .emu_fetch_progress.json snapshot.
"""

import io
import json
import threading

import pytest

from emu.inputs.manifest import InventoryEntry
from emu.inputs.progress import Progress, Reporter, format_hm
from emu.inputs.transfer import DOWNLOADED, FAILED, SKIPPED, TransferResult

GB = 10**9


def _entries(n, size):
    return [InventoryEntry(f"f{i}.data", size, "x") for i in range(n)]


class Clock:
    """A fake monotonic clock tests can move forward by hand."""

    def __init__(self, t=1000.0):
        self.t = t

    def __call__(self):
        return self.t


# ---- counters ----

def test_totals_from_entries():
    p = Progress(_entries(4, 250), clock=Clock())
    assert p.files_total == 4
    assert p.bytes_total == 1000


def test_finished_files_add_their_size_and_count():
    entries = _entries(4, 250)
    p = Progress(entries, clock=Clock())
    p.finish(TransferResult("f0.data", DOWNLOADED), entries[0])
    p.finish(TransferResult("f1.data", SKIPPED), entries[1])
    p.finish(TransferResult("f2.data", FAILED, error="404"), entries[2])
    assert p.files_done == 2
    assert p.bytes_done == 500
    assert p.failed == 1


def test_in_flight_bytes_count_until_the_file_finishes():
    # A big file's progress shows while it downloads, without counting
    # twice once it completes, and drops out if the .part is restarted.
    entries = _entries(2, 1000)
    p = Progress(entries, clock=Clock())
    p.part_size("f0.data", 400)
    assert p.bytes_done == 400
    p.part_size("f0.data", 0)  # .part restarted from zero
    assert p.bytes_done == 0
    p.part_size("f0.data", 1000)
    p.finish(TransferResult("f0.data", DOWNLOADED), entries[0])
    assert p.bytes_done == 1000


def test_retrying_counts_files_waiting_to_retry():
    p = Progress(_entries(3, 1), clock=Clock())
    p.retry_wait("f0.data", True)
    p.retry_wait("f1.data", True)
    assert p.retrying == 2
    p.retry_wait("f0.data", False)
    assert p.retrying == 1


def test_counters_are_thread_safe():
    entries = _entries(1, 10**9)
    p = Progress(entries, clock=Clock())

    def add():
        for _ in range(10_000):
            p.transferred(1)

    threads = [threading.Thread(target=add) for _ in range(8)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    assert p.bytes_transferred == 80_000


# ---- rate and ETA ----

def test_rate_is_a_moving_average_over_the_last_30_seconds():
    clock = Clock()
    p = Progress(_entries(1, 10 * GB), clock=clock)
    p.sample()
    for _ in range(10):  # 10 MB/s for 10 s
        clock.t += 1
        p.transferred(10_000_000)
        p.sample()
    assert p.rate() == pytest.approx(10_000_000)

    for _ in range(40):  # then 2 MB/s for 40 s; the old fast period ages out
        clock.t += 1
        p.transferred(2_000_000)
        p.sample()
    assert p.rate() == pytest.approx(2_000_000)


def test_eta_is_bytes_remaining_over_rate():
    clock = Clock()
    entries = _entries(1, 1000 * 10**6)
    p = Progress(entries, clock=clock)
    p.sample()
    clock.t += 10
    p.transferred(100 * 10**6)
    p.part_size("f0.data", 100 * 10**6)
    p.sample()
    # 900 MB left at 10 MB/s
    assert p.eta_seconds() == pytest.approx(90)


def test_eta_never_shows_done_while_a_file_is_still_in_progress():
    # A .part can reach full size before its md5 check finishes; until the
    # file is finished the ETA must not read 0:00.
    clock = Clock()
    entries = _entries(2, 1000)
    p = Progress(entries, clock=clock)
    p.finish(TransferResult("f0.data", DOWNLOADED), entries[0])
    p.sample()
    clock.t += 1
    p.transferred(1000)
    p.part_size("f1.data", 1000)  # full size, not finished yet
    p.sample()
    assert p.eta_seconds() > 0
    assert " · ETA 0:01" in p.line()


def test_eta_is_none_when_rate_is_zero():
    p = Progress(_entries(1, 100), clock=Clock())
    p.sample()
    assert p.rate() == 0
    assert p.eta_seconds() is None


# ---- live line ----

def test_live_line_matches_the_spec():
    # The plan's example: "12,480/37,084 files (34%) · 61.2/181.5 GB ·
    # 48 MB/s · elapsed 0:21 · ETA 0:42 · 3 retrying"
    clock = Clock()
    entries = _entries(37_084, 181_500_000_000 // 37_084)
    p = Progress(entries, clock=clock)
    p.sample()
    for e in entries[:12_480]:
        p.finish(TransferResult(e.path, DOWNLOADED), e)
    clock.t += 21 * 60
    p.transferred(48_000_000 * 21 * 60)
    p.sample()
    for path in ["a", "b", "c"]:
        p.retry_wait(path, True)

    line = p.line()
    assert line.startswith("12,480/37,084 files (34%) · ")
    assert " · 48 MB/s · " in line
    assert " · elapsed 0:21 · " in line
    assert line.endswith(" · 3 retrying")
    gb_done = 12_480 * entries[0].size / GB
    assert f" · {gb_done:.1f}/181.5 GB · " in line


def test_percent_never_shows_100_until_every_file_is_done():
    entries = _entries(1000, 1)
    p = Progress(entries, clock=Clock())
    for e in entries[:999]:
        p.finish(TransferResult(e.path, DOWNLOADED), e)
    assert "files (99%)" in p.line()
    p.finish(TransferResult(entries[999].path, DOWNLOADED), entries[999])
    assert "files (100%)" in p.line()


def test_live_line_shows_eta_dashes_and_failures():
    p = Progress(_entries(2, 100), clock=Clock())
    p.finish(TransferResult("f0.data", FAILED, error="x"), _entries(1, 100)[0])
    line = p.line()
    assert " · ETA -- · " in line
    assert " · 1 failed" in line


def test_format_hm():
    assert format_hm(0) == "0:00"
    assert format_hm(21 * 60 + 59) == "0:21"
    assert format_hm(3 * 3600 + 5 * 60) == "3:05"
    assert format_hm(30, round_up=True) == "0:01"  # never show an ETA of 0:00 early


# ---- Reporter outputs ----

def test_live_line_only_on_a_tty(tmp_path):
    p = Progress(_entries(1, 100), clock=Clock())
    out = io.StringIO()
    Reporter(p, tmp_path, stream=out, live=False).tick()
    assert out.getvalue() == ""

    out = io.StringIO()
    Reporter(p, tmp_path, stream=out, live=True).tick()
    assert out.getvalue().startswith("\r0/1 files (0%)")


def test_log_lines_every_log_interval_and_a_final_summary(tmp_path):
    clock = Clock()
    entries = _entries(3, 100)
    p = Progress(entries, clock=clock)
    r = Reporter(p, tmp_path, stream=io.StringIO(), live=False, log_interval=60)
    r.tick()  # first tick logs at once
    for _ in range(150):  # 150 s of ticks, one per second
        clock.t += 1
        r.tick()
    p.finish(TransferResult("f0.data", DOWNLOADED), entries[0])
    r.close("finished", "1 downloaded, 0 skipped, 0 failed")

    lines = (tmp_path / "fetch_progress.log").read_text().splitlines()
    progress_lines = [l for l in lines if "files (" in l]
    assert len(progress_lines) == 4  # at 0, 60, 120 s, plus the final line
    assert lines[-1].endswith("finished: 1 downloaded, 0 skipped, 0 failed")


def test_log_is_appended_across_runs(tmp_path):
    (tmp_path / "fetch_progress.log").write_text("earlier run\n")
    p = Progress(_entries(1, 1), clock=Clock())
    r = Reporter(p, tmp_path, stream=io.StringIO(), live=False)
    r.tick()
    r.close("finished", "ok")
    assert (tmp_path / "fetch_progress.log").read_text().startswith("earlier run\n")


def test_snapshot_contents(tmp_path):
    clock = Clock()
    entries = _entries(2, 100)
    p = Progress(entries, clock=clock)
    r = Reporter(p, tmp_path, stream=io.StringIO(), live=False)
    p.finish(TransferResult("f0.data", DOWNLOADED), entries[0])
    r.tick()
    snap = json.loads((tmp_path / ".emu_fetch_progress.json").read_text())
    assert snap["state"] == "running"
    assert snap["files_done"] == 1 and snap["files_total"] == 2
    assert snap["bytes_done"] == 100 and snap["bytes_total"] == 200
    assert snap["failed"] == 0 and snap["retrying"] == 0
    assert snap["eta_seconds"] is None
    assert "pid" in snap and "host" in snap and "updated" in snap

    r.close("finished", "done")
    snap = json.loads((tmp_path / ".emu_fetch_progress.json").read_text())
    assert snap["state"] == "finished"


def test_snapshot_is_written_every_few_seconds_not_every_tick(tmp_path, monkeypatch):
    clock = Clock()
    p = Progress(_entries(1, 1), clock=clock)
    r = Reporter(p, tmp_path, stream=io.StringIO(), live=False, snapshot_interval=5)
    writes = []
    real = r._write_snapshot
    monkeypatch.setattr(r, "_write_snapshot", lambda state: (writes.append(clock.t), real(state)))
    r.tick()
    for _ in range(12):
        clock.t += 1
        r.tick()
    assert writes == [1000.0, 1005.0, 1010.0]


def test_snapshot_reader_never_sees_a_half_written_file(tmp_path):
    p = Progress(_entries(1000, 10**6), clock=Clock())
    r = Reporter(p, tmp_path, stream=io.StringIO(), live=False)
    r._write_snapshot("running")
    path = tmp_path / ".emu_fetch_progress.json"
    errors = []
    done = threading.Event()

    def reader():
        while not done.is_set():
            try:
                json.loads(path.read_text())
            except (ValueError, FileNotFoundError) as e:
                errors.append(e)

    t = threading.Thread(target=reader)
    t.start()
    for _ in range(300):
        r._write_snapshot("running")
    done.set()
    t.join()
    assert errors == []
    assert not list(tmp_path.glob("*.tmp*"))  # no temp files left behind
