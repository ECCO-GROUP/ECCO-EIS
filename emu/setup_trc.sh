#!/bin/bash 

#=================================
# Shell script for setting up V4r4 Passive Tracer Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Passive Tracer Tool ..."
echo "    See PUBLICDIR/README_trc "
echo " "

# Set directory names for the tool. 

setup=SETUPDIR
echo $setup > tool_setup_dir

# Set up program to specify initial tracer distribution (trc.x)
/bin/ln -sf ${setup}/emu/trc.x .

# Set up data namelist file to be used by MITgcm (data) 
# The namelist files will be modified by trc.x
/bin/cp -f ${setup}/emu/data_trc . 

# Set up Tool's scripts (do_trc.sh, pbs_trc.sh) 
/bin/cp -f ${setup}/emu/pickup_ptracer.meta pickup_ptracer.meta_orig

# 
#echo " "
#echo '********************************************'
#echo '    Run trc.x to specify computation.'
#echo '********************************************'
#echo " "

