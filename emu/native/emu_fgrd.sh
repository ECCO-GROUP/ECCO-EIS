#!/bin/bash -e 

umask 022

#=================================
# Shell script for V4r4 Forward Gradient Tool
# Script does all three steps of the Tool;
#    1) setup_fgrd.sh
#    2) fgrd_spec.x
#    3) fgrd_pert.x, mitgcmuv, fgrd.x 
#=================================

echo " "
echo "************************************"
echo "    EMU Forward Gradient Tool (native) "
echo "************************************"

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/forcing/other/flux-forced/forcing
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input for Forward Gradient Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_download_input.sh"
    echo "using ${emu_input_dir} as 'directory name to place EMU Input'" 
    echo "to download forcing needed for the Forward Gradient Tool." 
    exit 1
fi

# ------------------------------------------
# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_fgrd.sh "
${emu_dir}/emu/setup_fgrd.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running fgrd_spec.x"
ln -sf PUBLICDIR/mitgcm_timing.nml .
ln -sf ${emu_dir}/emu/exe/fgrd_spec.x .
./fgrd_spec.x

if [ -f "./fgrd.dir_out" ] && [ -f "./pbs_fgrd.sh" ]; then
    read dummy < "./fgrd.dir_out"
    rundir=${PWD}/${dummy}/temp
    sed -i -e "s|YOURDIR|${rundir}|g" ./pbs_fgrd.sh
    cp -p ./pbs_fgrd.sh ${rundir}
else
    echo "File fgrd.dir_out and/or pbs_fgrd.sh do(es) not exist ... "
    exit 1
fi

# ------------------------------------------
# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"

returndir=$PWD

cd ${rundir}

echo "  1) Set up files for MITgcm "
${emu_dir}/emu/native/setup_forcing.sh

echo "  2) Perturb forcing "
${emu_dir}/emu/native/do_fgrd_pert.sh

cd ${returndir}

echo "  3) Run MITgcm "
echo "  4) Compute difference from reference run" 
BATCH_COMMAND ./pbs_fgrd.sh

echo "... Batch job pbs_fgrd.sh has been submitted "
echo "    to compute the model's forward gradient." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' ./pbs_fgrd.sh

echo " " 
dum=`tail -n 1 ./fgrd.dir_out`
echo '********************************************'
echo "    Results will be in " ${dum}
echo '********************************************'
echo " "

dum="${dum%output}temp"
echo "Progress of the computation can be monitored by"
echo "  ls ${dum}/diags/*2d*day*data | wc -l " 
echo "which counts the number of days the model has integrated." 
echo "(As standard output, the model saves daily mean files of"
echo "sea level and ocean bottom pressure.)"  
echo " "
