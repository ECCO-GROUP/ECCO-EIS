#!/bin/bash -e

umask 022

#=================================
# Shell script for setting up V4r4 Forward Gradient tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Forward Gradient Tool ..."
#echo "    See PUBLICDIR/README_fgrd "
echo " "

## Set directory names for the tool. 
#echo ${emu_dir} > ./tool_setup_dir
#echo ${emu_input_dir} > ./input_setup_dir

# Set up perturbation specifying program (fgrd_spec.x)
#/bin/ln -sf ${emu_dir}/emu/exe/fgrd_spec.x .

# Set up data namelist file to be used by MITgcm (data) 
# The namelist files will be modified by fgrd_spec.x
/bin/cp -f ${emu_dir}/emu/data_emu . 

# 
#echo " "
#echo '********************************************'
#echo '    Run fgrd_spec.x to specify computation.'
#echo '********************************************'
#echo " "
