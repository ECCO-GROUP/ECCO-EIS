#!/bin/tcsh

#=================================
# Shell script for setting up V4r4 Sampling Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Sampling Tool ..."
echo "    See PUBLICDIR/README_samp "

# Set directory names for the tool. 
set tooldir = SETUPDIR

# Set up sampling programs (samp.x, do_samp.x)
/bin/cp -fp ${tooldir}/emu/do_samp.csh do_samp.csh_orig
/bin/cp -fp ${tooldir}/emu/samp.x .
#/bin/cp -fp ${tooldir}/emu/do_samp.x .
echo ${tooldir} > tool_setup_dir

# Set up data.ecco namelist file 
# The namelist file will be modified by samp.x
/bin/cp -fp ${tooldir}/emu/data.ecco_adj .

# 
echo " "
echo '********************************************'
echo '    Run samp.x to specify sampling.'
echo '********************************************'
echo " "
exit
