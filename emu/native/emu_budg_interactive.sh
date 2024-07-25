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
./budg.x ${emu_input_dir}

# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"
echo "     Running do_budg.x"

returndir=$PWD

read dummy < ./budg.dir_out
cd ${dummy}/temp
ln -sf ${emu_dir}/emu/exe/do_budg.x .
./do_budg.x ${emu_input_dir} ${source_dir}

#=================================
# Move result to output dirctory 

mkdir ../output

mv ./data.ecco  ../output
mv ./budg.info ../output
mv ./emu_budg.*  ../output

echo " " 
dum=`tail -n 1 ./budg.dir_out`
echo '********************************************'
echo "    Results are in" $dum
echo '********************************************'
echo " "

cd ${returndir}
