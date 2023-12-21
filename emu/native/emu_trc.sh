#!/bin/bash 

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

basedir=SETUPDIR

# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_trc.sh"
${basedir}/emu/setup_trc.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running trc.x"
./trc.x

if [ -f "trc.dir_out" ] && [ -f "pbs_trc.sh" ]; then
    read dummy < "trc.dir_out"
    rundir=${PWD}/${dummy}/temp
    sed -i -e "s|YOURDIR|${rundir}|g" pbs_trc.sh
    cp -p pbs_trc.sh ${rundir}
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

cd ${rundir}

${basedir}/emu/native/do_trc_prep.sh

cd ${returndir}

# submit batch job to do 2)
echo "  2) Integrate tracer "

BATCH_COMMAND pbs_trc.sh

echo "... Batch job pbs_trc.sh has been submitted "
echo "    to compute the model's trcoint gradients." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_trc.sh

echo " " 
dum=`sed -n '3p' trc.dir_out`
echo '********************************************'
echo "    Results will be in " ${dum}
echo '********************************************'
echo " "
