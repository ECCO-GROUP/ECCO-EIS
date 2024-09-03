#!/bin/bash -e
umask 022

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

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/emu_ref
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input for Budget Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_input_setup.sh"
    echo "to download emu_ref needed for the Budget Tool." 
    exit 1
fi

# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_budg.sh"
${emu_dir}/emu/setup_budg.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo " "

# Specify directory with state files
source_dir=${emu_input_dir}/emu_ref/diags
echo "By default, tool will sample EMU reference run from state files in directory "
echo ${source_dir}
echo " " 
echo "Press Enter to continue or enter an alternate directory if sampling another run ... ?"
read ftext

if [[ -z ${ftext} ]]; then
    echo " "
    echo " ... sampling default EMU reference run."
else
    # Check to make sure directory exists.
    if [[ ! -d "${ftext}" ]]; then
	echo "Directory " ${ftext} " does not exist."
	echo "Aborting EMU Budget Tool."
	echo " "
	exit 1
    fi
    echo " ... sampling alternate run in "
    source_dir=$(readlink -f "$ftext")
    echo ${source_dir}
fi

echo "     Running budg.x"
./budg.x ${emu_input_dir} ${source_dir}

# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"
echo "     Running do_budg.x"

returndir=$PWD

read dummy < ./budg.dir_out
rundir=${PWD}/${dummy}/temp

sed -i -e "s|YOURDIR|${rundir}|g" ./pbs_budg.sh
sed -i -e "s|SOURCEDIR|${source_dir}|g" ./pbs_budg.sh
mv ./pbs_budg.sh ${rundir}

cd ${rundir}
BATCH_COMMAND ./pbs_budg.sh

echo "... Batch job pbs_budg.sh has been submitted "
echo "    to compute the budget." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' ./pbs_budg.sh

echo " " 
dum=`sed -n '3p' ./budg.dir_out`
echo '********************************************'
echo "    Results will be in" ${dum}
echo '********************************************'
echo " "

cd ${returndir}
