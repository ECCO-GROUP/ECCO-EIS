#!/bin/bash -e

umask 022

emu_dir=EMU_DIR
emu_input_dir=EMU_INPUT_DIR

#=================================
# For EMU Modified Simulation Tool (msim).
# (Native version)
# 
# This is an example of preparing user replacement files for EMU's
# Modified Simulation Tool. This example shell script creates a
# modified data file used by MITgcm to integrate a user-defined number
# of months.
#
#=================================

echo " "
echo "This routine creates example replacement files for EMU Modified Simulation Tool."
echo "This particular example modifies the data file used by MITgcm to integrate a user-defined number of months."
echo " "

#--------------------------
# Create directory 
current_dir=${PWD}
echo "Enter directory name for replacement file to be created in ... (rundir)?"
read ftext
echo " "

rundir=$(readlink -f "$ftext")
if [[ -d ${rundir} ]] ; then
    echo "Files will be created in "${rundir}
    echo " "
else
    echo "Creating "${rundir}
    mkdir ${rundir}
    echo " "
fi
cd ${rundir}

#--------------------------
# Get data file template 
cp -pf ${emu_dir}/emu/data_emu  ./data

#--------------------------
# Set integration time
echo " "
echo "V4r4 integrates 312-months from 1/1/1992 12Z to 12/31/2017 12Z" 
echo "Enter number of months to integrate ... (1-312)?"
read iend

if [[ iend -gt 312 ]]; then
    iend=312
elif [[ iend -lt 1 ]]; then
    iend=1
fi

echo "Will integrate model over ${iend} months"

# set nTimesteps in data to 1-month beyond iend to make sure computation is complete,.
nsteps=227903 
nTimesteps=$(( (iend / 12) * 365 * 24 + (iend % 12) * 30 * 24 + 30 * 24 * 1 ))
if [[ ${nTimesteps} -gt ${nsteps} ]]; then
    nTimesteps=$nsteps
fi

sed -i -e "s|NSTEP_EMU|${nTimesteps}|g" data

#--------------------------
# End

cd ${current_dir}

echo " "
echo "Successfully modified data file in directory " ${rundir}
echo "Use this directory name as input with the Modified Simulation Tool." 
echo " "

echo "misc_data.sh execution complete."
