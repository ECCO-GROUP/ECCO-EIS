#!/bin/bash -e 

umask 022

#=================================
# Shell script for setting up V4r4 Budget Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Budget Tool ..."
#echo "    See PUBLICDIR/README_budg "
echo " "

## Set directory names for the tool. 
#echo ${emu_dir} > ./tool_setup_dir
#echo ${emu_input_dir} > ./input_setup_dir

# Set up budget programs (budg.x, do_budg.x)
/bin/ln -sf ${emu_dir}/emu/exe/budg.x .

# Set up data.ecco namelist file 
# The namelist file will be modified by budg.x
/bin/cp -f ${emu_dir}/emu/data.ecco_adj .

# 
#echo " "
#echo '********************************************'
#echo '    Run budg.x to specify budget.'
#echo '********************************************'
#echo " "
