#!/bin/tcsh

#=================================
# Shell script for setting up V4r4 perturbation tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Perturbation Tool ..."
echo "    See PUBLICDIR/README_pert "

# Set directory names for the tool. 
set userdir=`pwd`
set tooldir = SETUPDIR

# Set up perturbation specifying program (pert.x)
/bin/cp -fp ${tooldir}/emu/pert.x .
echo $tooldir > tool_setup_dir

# Set up data namelist file to be used by MITgcm (data) 
# The namelist files will be modified by pert.x
/bin/cp -fp ${tooldir}/emu/data_emu . 

# Set up Tool's PBS script (pbs_pert.csh) 
# The script will be modified by pert.x
/bin/cp -fp ${tooldir}/emu/do_pert.csh . 
/bin/cp -fp ${tooldir}/emu/pbs_pert.csh pbs_pert.csh_orig

# 
echo " "
echo '********************************************'
echo '    Run pert.x to specify computation.'
echo '********************************************'
echo " "
exit
