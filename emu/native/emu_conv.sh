#!/bin/bash 

#=================================
# Shell script for V4r4 Convolution Tool
# Script does all three steps of the Tool;
#    1) setup_conv.csh
#    2) conv.x
#    3) do_conv.csh
#=================================

echo " "
echo "************************************"
echo "    EMU Convolution Tool (native) "
echo "************************************"

basedir=SETUPDIR

returndir=$PWD

# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_conv.sh"
${basedir}/emu/setup_conv.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running conv.x"
./conv.x ${basedir}


if [ -f "conv.dir_out" ] && [ -f "pbs_conv.sh" ]; then
    read dummy < "conv.dir_out"
    subdir=${dummy}/temp
    sed -i -e "s|SUBDIR|${subdir}|g" pbs_conv.sh
    rundir=${PWD}/${subdir}
    sed -i -e "s|YOURDIR|${rundir}|g" pbs_conv.sh
    cp -p pbs_conv.sh ${rundir}
else
    echo "File conv.dir_out and/or pbs_conv.sh do(es) not exist ... "
    exit 1
fi
# Step 3: Calculation 

echo " "                       
echo "**** Step 3: Calculation"
echo "     Running do_conv.x in PBS"
echo " "

BATCH_COMMAND pbs_conv.sh

echo "... Batch job pbs_conv.sh has been submitted "
echo "    to compute the convolution." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_conv.sh

echo " " 
dum=`sed -n '3p' conv.dir_out`
echo '********************************************'
echo "    Results will be in " ${dum}
echo '********************************************'
echo " "


