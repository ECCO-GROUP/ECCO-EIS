#!/bin/bash -e

umask 022

#=================================
# Shell script for setting up V4r4 Adjoint Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Adjoint Tool ..."
#echo "    See PUBLICDIR/README_adj "
echo " "

## Set directory names for the tool. 
#echo ${emu_dir} > ./tool_setup_dir
#echo ${emu_input_dir} > ./input_setup_dir

# Set up objective function specifying program (adj.x)
ln -sf ${emu_dir}/emu/exe/adj.x .

# Set up data namelist file to be used by MITgcm (data, data.ecco).
# The namelist files will be modified by adj.x
#/bin/cp -fp ${emu_dir}/emu/data_emu .
/bin/cp -fp ${emu_dir}/emu/data_emu_niter0 data_emu 
/bin/cp -fp ${emu_dir}/emu/data.ecco_adj .

## 
#echo " "
#echo '********************************************'
#echo '    Run adj.x to specify computation.'
#echo '********************************************'
#echo " "

