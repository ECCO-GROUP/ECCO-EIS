#!/bin/tcsh

#=================================
# Shell script for setting up V4r4 Passive Tracer Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Passive Tracer Tool ..."
echo "    See PUBLICDIR/README_trc "

# Set directory names for the tool. 
set userdir=`pwd`
set tooldir = SETUPDIR

# Set up program to specify initial tracer distribution (trc.x)
/bin/cp -fp ${tooldir}/emu/trc.x .
echo $tooldir > tool_setup_dir

# Set up data namelist file to be used by MITgcm (data) 
# The namelist files will be modified by trc.x
/bin/cp -fp ${tooldir}/emu/data_trc . 

# Set up Tool's scripts (do_trc.csh, >pbs_trc.csh) 
/bin/cp -fp ${tooldir}/emu/do_trc.csh . 
/bin/cp -fp ${tooldir}/emu/pbs_trc.csh pbs_trc.csh_orig
#sed -i -e "s|YOURDIR|${userdir}|g" pbs_trc.csh_orig
/bin/cp -fp ${tooldir}/emu/pickup_ptracer.meta pickup_ptracer.meta_orig

# 
echo " "
echo '********************************************'
echo '    Run trc.x to specify computation.'
echo '********************************************'
echo " "
exit
