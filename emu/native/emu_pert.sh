#!/bin/bash 

#=================================
# Shell script for V4r4 Perturbation Tool
# Script does all three steps of the Tool;
#    1) setup_pert.sh
#    2) pert.x
#    3) pert_xx.x, mitgcmuv, pert_grad.x 
#=================================

echo " "
echo "************************************"
echo "    EMU Perturbation Tool (native) "
echo "************************************"

basedir=SETUPDIR

# ------------------------------------------
# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_pert.csh "
${basedir}/emu/setup_pert.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running pert.x"
./pert.x

if [ -f "pert.dir_out" ] && [ -f "pbs_pert.sh" ]; then
    read dummy < "pert.dir_out"
    rundir=${PWD}/${dummy}/temp
    sed -i -e "s|YOURDIR|${rundir}|g" pbs_pert.sh
    cp -p pbs_pert.sh ${rundir}
else
    echo "File pert.dir_out and/or pbs_pert.sh do(es) not exist ... "
    exit 1
fi

# ------------------------------------------
# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"

returndir=$PWD

cd ${rundir}

echo "  1) Set up files for MITgcm "
${basedir}/emu/native/setup_forcing.sh

echo "  2) Perturb forcing "
${basedir}/emu/native/do_pert_xx.sh

cd ${returndir}

echo "  3) Run MITgcm "
echo "  4) Compute difference from reference run" 
BATCH_COMMAND pbs_pert.sh

echo "... Batch job pbs_pert.sh has been submitted "
echo "    to compute the model's response to perturbation." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_pert.sh

echo " " 
echo '********************************************'
echo "    Results will be in " ${rundir}
echo '********************************************'
echo " "

