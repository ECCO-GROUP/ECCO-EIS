#!/bin/bash -e

#=================================
# Shell script for interactively creating 
# masks for EMU. 
#=================================

umask 022

# ----------------------
# Set EMU directories
export emu_dir=EMU_DIR
export emu_input_dir=EMU_INPUT_DIR

# ----------------------
echo " "
echo "************************************"
echo "    Creating masks for EMU          "
echo "************************************"

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/emu_ref
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_input_setup.sh"
    echo "to download emu_ref." 
    exit 1
fi

#--------------------------
# Create directory 
current_dir=${PWD}
echo " "
echo "Enter directory name for replacement files to be created in ... (rundir)?"
read ftext
echo " "

rundir=$(readlink -f "$ftext")
if [[ -d ${rundir} ]] ; then
    echo "Files will be created in "${rundir}
else
    echo "Creating "${rundir}
    mkdir ${rundir}
fi

#--------------------------
# Step 1: Run mask.x 
cd ${rundir}
${emu_dir}/emu/exe/mask.x ${emu_input_dir}

#--------------------------
# End

cd ${current_dir}
