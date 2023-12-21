#!/bin/bash 

#=================================
# Shell script for V4r4 Sampling Tool
# Script does all three steps of the Tool;
#    1) setup_samp.sh
#    2) samp.x
#    3) do_samp.x 
#=================================

echo " "
echo "************************************"
echo "    EMU Sampling Tool (native) "
echo "************************************"

basedir=SETUPDIR

returndir=$PWD

# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_samp.sh"
${basedir}/emu/setup_samp.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running samp.x"
./samp.x

# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"
echo "     Running do_samp.x"
read dummy < samp.dir_out
cd ${dummy}/temp
ln -s ${basedir}/emu/do_samp.x .
./do_samp.x ${basedir}

#=================================
# Move result to output dirctory 

mkdir ../output

mv data.ecco  ../output
mv samp.info ../output
mv samp.out_* ../output
mv samp.step_* ../output
mv samp.txt  ../output

echo " " 
dum=`tail -n 1 samp.dir_out`
echo '********************************************'
echo "    Results are in" $dum
echo '********************************************'
echo " "

cd ${returndir}
