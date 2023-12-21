#!/bin/bash 

#=================================
# Shell script for V4r4 Budget Tool
# Script does all three steps of the Tool;
#    1) setup_budg.csh
#    2) budg.x
#    3) do_budg.x
#=================================

echo " "
echo "************************************"
echo "    EMU Budget Tool (native) "
echo "************************************"


basedir=SETUPDIR

# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_budg.sh"
${basedir}/emu/setup_budg.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running budg.x"
./budg.x ${basedir}

# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"
echo "     Running do_budg.x"

returndir=$PWD

read dummy < budg.dir_out
cd ${dummy}/temp
ln -s ${basedir}/emu/do_budg.x .
./do_budg.x ${basedir}

#=================================
# Move result to output dirctory 

mkdir ../output

mv data.ecco  ../output
mv budg.info ../output
mv emu_budg.*  ../output

echo " " 
dum=`tail -n 1 budg.dir_out`
echo '********************************************'
echo "    Results are in" $dum
echo '********************************************'
echo " "

cd ${returndir}
