#!/bin/bash 

#=================================
# Shell script for V4r4 Adjoint Tool
# Script does all three steps of the Tool;
#    1) setup_adj.sh
#    2) adj.x
#    3) do_adj.csh
#=================================

echo " "
echo "************************************"
echo "    EMU Adjoint Tool  (native) "
echo "************************************"

basedir=SETUPDIR

echo ${PWD} > emu.fcwd 

# ------------------------------------------
# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_adj.csh "
${basedir}/emu/setup_adj.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running adj.x"
./adj.x

if [ -f "adj.dir_out" ] && [ -f "pbs_adj.sh" ]; then
    read dummy < "adj.dir_out"
    rundir=${PWD}/${dummy}/temp
    sed -i -e "s|YOURDIR|${rundir}|g" pbs_adj.sh
    cp -p pbs_adj.sh ${rundir}
else
    echo "File adj.dir_out and/or pbs_adj.sh do(es) not exist ... "
    exit 1
fi

# ------------------------------------------
# Step 3: Calculation 
echo "**** Step 3: Calculation"

returndir=$PWD

cd ${rundir}

echo "  1) Set up files for MITgcm "
${basedir}/emu/native/setup_forcing.sh
${basedir}/emu/native/do_adj_prep.sh

cd ${returndir}

echo "  2) Run MITgcm adjoint "
BATCH_COMMAND pbs_adj.sh

echo "... Batch job pbs_adj.sh has been submitted "
echo "    to compute the model's adjoint gradients." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_adj.sh

echo " " 
dum=`sed -n '3p' adj.dir_out`
echo '********************************************'
echo "    Results will be in " ${dum}
echo '********************************************'
echo " "

