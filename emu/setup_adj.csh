#!/bin/tcsh

#=================================
# Shell script for setting up V4r4 Adjoint Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Adjoint Tool ..."
echo "    See PUBLICDIR/README_adj "

# Set directory names for the tool. 
set userdir=`pwd`
set tooldir = SETUPDIR

# Set up objective function specifying program (adj.x)
/bin/cp -fp ${tooldir}/emu/adj.x .
echo $tooldir > tool_setup_dir

# Set up data namelist file to be used by MITgcm (data, data.ecco).
# The namelist files will be modified by adj.x
/bin/cp -fp ${tooldir}/emu/data_emu .
/bin/cp -fp ${tooldir}/emu/data.ecco_adj .

# Set up Tool's PBS script (pbs_adj.csh) 
# The script will be modified by adj.x
/bin/cp -fp ${tooldir}/emu/do_adj.csh . 
/bin/cp -fp ${tooldir}/emu/pbs_adj.csh pbs_adj.csh_orig

# 
echo " "
echo '********************************************'
echo '    Run adj.x to specify computation.'
echo '********************************************'
echo " "
exit
