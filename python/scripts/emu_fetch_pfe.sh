#!/bin/bash
#=================================
# Run `emu inputs fetch` on a NAS front end (pfe), for pbs_emu_fetch.sh.
# NAS compute nodes have no internet access, so the PBS job runs this
# script on pfe over ssh, as 1.2a's emu_input_install_4batch.sh does
# with "ssh pfe wget".
#
# Usage: emu_fetch_pfe.sh LIMIT FETCH_ARGS...
#   LIMIT       how long to fetch before stopping cleanly: one number
#               and an optional unit s, m, h or d, e.g. 1410m (23.5 h).
#               Keep it below the PBS walltime.
#   FETCH_ARGS  options for `emu inputs fetch`, e.g. --dir DIR --all
#
# Credentials come from ~/.emu_cred (readable only by you), which holds
#   setenv EMU_EARTHDATA_USER <Earthdata username>
#   setenv EMU_WEBDAV_PASSWORD <ECCO Drive WebDAV password>
#=================================

set -u
limit=$1
shift

#=================================
# Check LIMIT is a duration `timeout` accepts (it takes one number and
# one unit; a combination like 23h30m is an error)
if [[ ! $limit =~ ^[0-9]+(\.[0-9]+)?[smhd]?$ ]]; then
    echo "emu_fetch_pfe.sh: invalid time limit '$limit'; give one number and" \
         "unit, e.g. 1410m for 23.5 hours" 1>&2
    exit 2
fi

#=================================
# Put the user's own commands (pip install --user) on PATH; ssh with a
# command doesn't run the login files that usually do
export PATH=$HOME/.local/bin:$PATH
if ! command -v emu > /dev/null; then
    echo "emu_fetch_pfe.sh: no emu command on $(hostname); install it with" \
         "'pip install --user -e ./python' from ECCO-EIS" 1>&2
    exit 2
fi

#=================================
# Read the credentials without echoing them (the file uses tcsh syntax)
cred=$HOME/.emu_cred
if [[ ! -r $cred ]]; then
    echo "emu_fetch_pfe.sh: $cred not found" 1>&2
    exit 2
fi
if [[ -n $(find "$cred" -perm /077) ]]; then
    echo "emu_fetch_pfe.sh: $cred is readable by others; run 'chmod 600 $cred'" 1>&2
    exit 2
fi
eval "$(sed -n 's/^setenv \(EMU_EARTHDATA_USER\|EMU_WEBDAV_PASSWORD\) \(.*\)$/export \1=\2/p' "$cred")"

#=================================
# Fetch until done or until LIMIT, then stop as Ctrl-C does: finished
# files stay recorded, partial ones stay as .part, and the lock is
# released, so the next job carries on where this one stopped
echo "emu_fetch_pfe.sh: fetching on $(hostname) for at most $limit"
timeout -s INT --kill-after=10m "$limit" emu inputs fetch "$@"
status=$?
# timeout reports 124 when it stopped the fetch; emu itself exits 1 then
[[ $status -eq 124 ]] && status=1
exit $status
