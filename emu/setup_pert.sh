#!/bin/bash 

#=================================
# Shell script for setting up V4r4 perturbation tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Perturbation Tool ..."
echo "    See PUBLICDIR/README_pert "
echo " "

# Set directory names for the tool. 

setup=SETUPDIR
echo $setup > tool_setup_dir

# Set up perturbation specifying program (pert.x)
/bin/ln -f ${setup}/emu/pert.x .

# Set up data namelist file to be used by MITgcm (data) 
# The namelist files will be modified by pert.x
/bin/cp -f ${setup}/emu/data_emu . 

# 
#echo " "
#echo '********************************************'
#echo '    Run pert.x to specify computation.'
#echo '********************************************'
#echo " "
