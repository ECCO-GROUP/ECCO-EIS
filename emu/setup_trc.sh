#!/bin/bash -e

umask 022

#=================================
# Shell script for setting up V4r4 Passive Tracer Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Passive Tracer Tool ..."
#echo "    See PUBLICDIR/README_trc "
echo " "

## Set directory names for the tool. 
#echo ${emu_dir} > ./tool_setup_dir
#echo ${emu_input_dir} > ./input_setup_dir

# Set up program to specify initial tracer distribution (trc.x)
/bin/ln -sf ${emu_dir}/emu/exe/trc.x .

# Set up data namelist file to be used by MITgcm (data) 
# The namelist files will be modified by trc.x
/bin/cp -f ${emu_dir}/emu/data_trc . 

# Set up Tool's scripts (do_trc.sh, pbs_trc.sh) 
/bin/cp -f ${emu_dir}/emu/pickup_ptracer.meta ./pickup_ptracer.meta_orig

# 
#echo " "
#echo '********************************************'
#echo '    Run trc.x to specify computation.'
#echo '********************************************'
#echo " "

