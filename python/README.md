# emu: Python tools for EMU

`emu` is the Python package for the ECCO Modeling Utilities (EMU). So far
it has one feature, a downloader for EMU's input files:

    emu inputs fetch    download input files, resuming and verifying md5s
    emu inputs status   show how far a download has got (changes nothing)

It is an optional alternative to the input download in `emu_setup.sh` /
`emu_input_install.sh`, which are unchanged. It produces the same
`emu_input_dir` layout, so an input directory from either one works with
EMU 1.2a. It can also take over a directory that the 1.2a installer
started or finished: files already in place are md5-checked and kept,
and only what is missing or wrong is downloaded.

What it adds over the 1.2a installer:

- Downloads only the files the tools you use need (`--tools samp,budg`),
  or everything (`--all`, about 1.1 TB).
- Checks every file against the md5 in EMU's inventory
  (`emu/misc_build_inventory.emu_input_dir.txt`).
- Resumes partial downloads after an interruption, a dropped connection
  or Ctrl-C. Running the same command again carries on.
- Retries failed transfers, and lists the files that still fail.
- Shows progress, rate and estimated time left, also from another
  terminal with `emu inputs status`.

## Requirements and installation

Python 3.9 or later. Nothing else: the package uses only the Python
standard library. To install from the ECCO-EIS directory:

    pip install --user -e ./python

This puts an `emu` command in `~/.local/bin` (add that to your `PATH` if
needed). `-e` (editable) means a `git pull` of ECCO-EIS updates the
command, with no need to reinstall. Install it this way (not from a copy
of the `python` directory): the command reads EMU's inventory from the
ECCO-EIS checkout. Check it with `emu --version`.

An editable install needs pip 21.3 or later (`python3 -m pip install
--user --upgrade pip`). If your Python has no `pip`, or you prefer to keep
the install separate, use a virtual environment:

    python3 -m venv ~/emu_venv
    ~/emu_venv/bin/python -m pip install --upgrade pip
    ~/emu_venv/bin/python -m pip install -e ./python

and run `~/emu_venv/bin/emu` (or activate the environment with
`source ~/emu_venv/bin/activate`, `activate.csh` in csh/tcsh).

## Credentials

Downloads from ECCO Drive (`https://ecco.jpl.nasa.gov/drive/`) need your
Earthdata username and your **ECCO Drive WebDAV password**. The WebDAV
password is not your Earthdata password; log in at
https://ecco.jpl.nasa.gov/drive/ to see it. It is a download-only
password.

`emu inputs fetch` takes them from, in order:

1. `--user` and `--password`,
2. the environment variables `EMU_EARTHDATA_USER` and `EMU_WEBDAV_PASSWORD`,
3. a prompt, if you are at a terminal. The password is shown as you type
   it, so you can check it.

With no terminal (under `nohup`, in a batch job, or with input from a
file) there is nobody to answer the prompt, so give them with options or
environment variables. The credentials are checked with one request
before any download starts. They are not written anywhere.

`--verify-only` and `emu inputs status` need no credentials.

## Downloading: `emu inputs fetch`

### Guided mode

Run `emu inputs fetch` in a terminal with no options and it asks for the
input directory and the tools you will use, showing how much each tool
adds to the download:

    $ emu inputs fetch

    EMU input download (release v4r4-llc90-flux)

    Directory for EMU input files (emu_input_dir)?
      [default: /home/me/emu_input_dir] >

    Which EMU tools will you use? Files each needs (always included: ... GB):
      1) samp  Sampling             +... GB
      2) fgrd  Forward Gradient     +... GB
      ...
      0) all tools                  ... GB
    Enter numbers separated by commas (e.g. 1,6) >

It then asks for credentials, prints the equivalent command, and asks
before it starts. Use that command to run the same download again, or to
run it under `nohup` or `screen` (below).

### Options

    emu inputs fetch --dir DIR (--tools TOOL[,TOOL...] | --all) [options]

| Option | Meaning |
|---|---|
| `--dir DIR` | input directory (`emu_input_dir`); created if missing |
| `--tools samp,trc` | only the files these tools need: `samp fgrd adj conv trc budg msim atrb` |
| `--all` | every input file (about 1.1 TB) |
| `--release NAME` | ECCO release (default and, for now, only: `v4r4-llc90-flux`) |
| `--jobs N` | downloads in progress at once (default 8) |
| `--tries N` | attempts per file before giving it up (default 5) |
| `--log-interval S` | seconds between lines in `fetch_progress.log` (default 60) |
| `--verify-only` | re-check files already on disk; no download (below) |
| `--no-postprocess` | skip the Tracer Tool step after a `trc` fetch (below) |
| `--user`, `--password` | credentials (see above) |

Files that every tool needs are always included. A later run with more
tools only downloads the extra files, so you can start with
`--tools samp` and add tools when you need them.

Example:

    emu inputs fetch --dir /nobackup/me/emu_input_dir --tools samp,budg

### Interrupting and resuming

Press Ctrl-C to stop. Files already finished are kept and recorded as
checked; files in progress keep their partial `.part` file. Run the same
command again to carry on: finished files are skipped without contacting
the server, and `.part` files are resumed from where they stopped.

Only one `emu inputs fetch` can work in a directory at a time; a second
one is refused. A lock left behind by a run that was killed on the same
computer is taken over with a warning. A lock from another computer is
refused, since `emu` cannot tell whether that run is still going. If you
are sure it is not, delete `.emu_fetch.lock` in the input directory.

To move a running download into the background, press Ctrl-Z and then
type `bg`. The progress line stops while the job is in the background
(and starts again after `fg`); `fetch_progress.log` and
`emu inputs status` keep working.

### Tracer Tool post-processing

The Tracer Tool (`trc`) also needs `state_weekly_rev_time_227808`, a
directory of links to the weekly state files in reverse time order. As in
1.2a, it is built by running `reverseintime_all.sh` (from `scripts/`) in
`forcing/other/flux-forced/`. `emu inputs fetch --tools trc` (or `--all`)
does this after all the files it needs are in place, unless the directory
already exists. If the script fails, its partial output is moved to
`state_weekly_rev_time_227808.incomplete` and the next run tries again.
`--no-postprocess` skips this step.

### Checking files already on disk: `--verify-only`

    emu inputs fetch --dir DIR --all --verify-only

re-reads every selected file in DIR and compares its size and md5 with
the inventory. It does not use the network or need credentials, and it
changes no input files. It updates the record of checked files, so a
later `emu inputs fetch` downloads whatever was missing or wrong. Files
may be symlinks (for example, links into another input directory); their
targets are checked. Problems are listed and written to
`verify_failures.txt`. Checking all 1.1 TB takes a few hours.

## Watching progress: `emu inputs status`

    emu inputs status --dir DIR [--tools TOOL[,TOOL...]]

From any terminal, while a download runs or after it has stopped, this
shows how many files and bytes are in place and still to fetch, whether a
fetch (or `--verify-only` check) is running and its rate and estimated
time left, when the last fetch or check ran and how it ended, any failed
files, and any leftover `.part` files. It changes nothing. Without
`--tools` it counts all files of the release.

## Running on NASA NAS (Pleiades)

Compute nodes have no internet access, so download from a front end
(`pfe`). A full download takes many hours, so run it so that it survives
logging out, either under `nohup`:

    export EMU_EARTHDATA_USER=myname
    export EMU_WEBDAV_PASSWORD=...
    nohup emu inputs fetch --dir /nobackup/$USER/emu_input_dir --all > fetch.out 2>&1 &

(in csh/tcsh, use `setenv` instead of `export`, and `>&` instead of
`> ... 2>&1`), or in a `screen` session:

    screen -S emu_fetch
    emu inputs fetch --dir /nobackup/$USER/emu_input_dir --all
    # Ctrl-A d to detach; `screen -r emu_fetch` to reattach

Under `nohup` there is no terminal to ask for credentials, so set the two
environment variables (or use `--user`/`--password`) first. Follow
progress with `emu inputs status --dir ...` or
`tail -f /nobackup/$USER/emu_input_dir/fetch_progress.log`. If the front
end reboots or the run is killed, start the same command again.

### As a PBS job

`python/scripts/pbs_emu_fetch.sh` runs the download as a batch job. As
with 1.2a's `pbs_input_setup.sh`, the job itself does no downloading: it
runs `python/scripts/emu_fetch_pfe.sh` on `pfe` over `ssh`, which
fetches until done or until a time limit just below the walltime, then
stops cleanly (as Ctrl-C does). If the download isn't finished, submit
the job again; it carries on where it stopped.

1. Install `emu` on pfe with `pip install --user -e ./python`
   (`emu_fetch_pfe.sh` looks for it in `~/.local/bin`).
2. Put the credentials in `~/.emu_cred`, readable only by you
   (`emu_fetch_pfe.sh` refuses the file otherwise):

       setenv EMU_EARTHDATA_USER <Earthdata username>
       setenv EMU_WEBDAV_PASSWORD <ECCO Drive WebDAV password>

   then `chmod 600 ~/.emu_cred`.
3. Copy `pbs_emu_fetch.sh`, edit its settings (`emu_repo`,
   `emu_input_dir`, `fetch_args`, `limit`) and the `#PBS` lines for your
   group and queue, and submit it with `qsub pbs_emu_fetch.sh`.

The job's output file shows how it ended (exit status 0: all files in
place; 1: not finished, submit again; 2: setup problem). `pfe` stands for
several front ends, so consecutive jobs may run on different ones. If a
job is killed before it stops itself (e.g. by `qdel`), it can leave
`.emu_fetch.lock` behind, and a fetch on a different front end then
refuses to start. Once you are sure no fetch is running, delete
`.emu_fetch.lock` in the input directory.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | every selected file is in place and correct (and post-processing, if any, succeeded) |
| 1 | some files failed, were not attempted, or are wrong (`--verify-only`); or the run was interrupted; or post-processing failed. Run the command again to retry. |
| 2 | usage error, missing or rejected credentials, server not reachable, or another fetch holds the directory |

## Files written in the input directory

Besides the input files themselves, `emu inputs fetch` writes:

| File | Contents |
|---|---|
| `.emu_fetch_state` | record of files checked against their md5 (one JSON line each) |
| `.emu_fetch.lock` | present while a fetch or check is running (its process ID and host) |
| `.emu_fetch_progress.json` | latest progress snapshot, read by `emu inputs status` |
| `fetch_progress.log` | a progress line every `--log-interval` seconds, and a final summary |
| `fetch_failures.txt` | files that failed in the last fetch, and why (removed after a clean run) |
| `verify_failures.txt` | problems found by the last `--verify-only` check (removed after a clean check) |
| `postprocess.log` | output of `reverseintime_all.sh` for the Tracer Tool |
| `<file>.part` | partly downloaded file, resumed by the next run |
| `<file>.bad` | a file that was already there but had the wrong size or md5, moved aside before downloading it again; delete it when no longer needed |

Leave the first three alone while a fetch is running. Deleting
`.emu_fetch_state` is safe when no fetch is running: the next run then
md5-checks every file already on disk again, which takes longer but
downloads nothing that is already correct.

## For developers

The tests use a local fake ECCO Drive server and never contact the real
one:

    pip install --user -e './python[dev]'
    cd python && python3 -m pytest tests
