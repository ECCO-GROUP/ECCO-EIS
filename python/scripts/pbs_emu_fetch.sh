#PBS -S /bin/bash
#PBS -l select=1:ncpus=40:model=sky_ele
#PBS -l walltime=24:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#PBS -N emu_fetch

umask 022

#=================================
# PBS script to download EMU input files at NAS with `emu inputs fetch`.
# The fetch runs on a front end (pfe) through emu_fetch_pfe.sh, since
# NAS compute nodes have no internet access; this job only holds the
# connection. If the job ends before the download is complete, submit
# it again: it carries on where it stopped.
#
# Edit the settings below, then submit with "qsub pbs_emu_fetch.sh".
#=================================

#=================================
# Settings
emu_repo=/nobackup/$USER/ECCO-EIS                # ECCO-EIS checkout
emu_input_dir=/nobackup/$USER/emu_input_dir      # where the inputs go
fetch_args="--all"                               # or e.g. "--tools samp,budg"
limit=23h30m                                     # below the walltime above

#=================================
# Run the fetch on pfe and report how it ended
echo "pbs_emu_fetch.sh: started $(date)"
ssh pfe "$emu_repo/python/scripts/emu_fetch_pfe.sh" "$limit" \
    --dir "$emu_input_dir" $fetch_args
status=$?
echo "pbs_emu_fetch.sh: ended $(date) with exit status $status"
case $status in
    0) echo "All files in place." ;;
    1) echo "Not finished (stopped at the time limit, or some files failed)." \
            "See $emu_input_dir/fetch_failures.txt if present, and submit again." ;;
    *) echo "Could not run the fetch; see the messages above." ;;
esac
exit $status
