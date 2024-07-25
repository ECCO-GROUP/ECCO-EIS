#!/bin/bash -e

umask 022

#=================================
# Shell script for V4r4 Tracer Tool
# Script does all three steps of the Tool;
#    1) setup_trc.csh
#    2) trc.x
#    3) do_trc.csh
#=================================

echo " "
echo "************************************"
echo "    EMU Tracer Tool (native) "
echo "************************************"

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/forcing/other/flux-forced/state_weekly 
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input for Tracer Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_download_input.sh"
    echo "using ${emu_input_dir} as 'directory name to place EMU Input'" 
    echo "to download state_weekly needed for the Tracer Tool." 
    exit 1
fi

# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_trc.sh"
${emu_dir}/emu/setup_trc.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running trc.x"
ln -sf PUBLICDIR/mitgcm_timing.nml .
./trc.x

if [ -f "./trc.dir_out" ] && [ -f "./pbs_trc.sh" ]; then
    read dummy < "./trc.dir_out"
    rundir=${PWD}/${dummy}/temp
    sed -i -e "s|YOURDIR|${rundir}|g" ./pbs_trc.sh
    cp -p ./pbs_trc.sh ${rundir}
else
    echo "File trc.dir_out and/or pbs_trc.sh do(es) not exist ... "
    exit 1
fi

# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"

returndir=$PWD

# step 1) 
echo "  1) Set up files for tracer integration "
echo "     Running do_trc_prep.sh"
echo " "

cd ${rundir}

${emu_dir}/emu/native/do_trc_prep.sh

cd ${returndir}

# submit batch job to do 2)
echo "  2) Integrate tracer "
echo "     submitting pbs_trc.sh"
echo " "

BATCH_COMMAND ./pbs_trc.sh

echo "... Batch job pbs_trc.sh has been submitted "
echo "    to compute passive tracer evolution."

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' ./pbs_trc.sh

echo " " 
dum=`sed -n '3p' ./trc.dir_out`
echo '********************************************'
echo "    Results will be in " ${dum}
echo '********************************************'
echo " "

dum="${dum%output}temp"
echo "Progress of the computation can be monitored by"
echo "  ls -l ${dum}/diags/ptracer_mon_mean*data | wc -l "
echo "which counts the number of monthly mean tracer output files" 
echo "until completion when directory diags will be moved and this"
echo "command will return an error (No such file or directory)"
echo "and list zero as the count." 
echo " "
