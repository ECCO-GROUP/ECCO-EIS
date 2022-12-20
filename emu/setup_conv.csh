#!/bin/tcsh

#=================================
# Shell script for setting up V4r4 Convolution Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Convolution Tool ..."
echo "    See PUBLICDIR/README_conv "
echo " "

# Set directory names for the tool. 
set tooldir = SETUPDIR

# Set up convolution programs (conv.x, do_conv.x)
/bin/cp -fp ${tooldir}/emu/conv.x .
/bin/cp -fp ${tooldir}/emu/do_conv.x .
/bin/cp -fp ${tooldir}/emu/do_conv.csh .
echo ${tooldir} > tool_setup_dir

exit
