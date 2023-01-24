#!/bin/tcsh

#=================================
# Shell script for setting up V4r4 Convolution Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Convolution Tool ..."
echo "    See PUBLICDIR/README_conv "

# Set directory names for the tool. 
set tooldir = SETUPDIR

# Set up convolution programs (conv.x, do_conv.x)
/bin/cp -fp ${tooldir}/emu/conv.x .
/bin/cp -fp ${tooldir}/emu/do_conv.csh .
echo ${tooldir} > tool_setup_dir

/bin/cp -fp ${tooldir}/emu/pbs_conv.csh pbs_conv.csh_orig
/bin/cp -fp ${tooldir}/emu/do_conv_int.csh do_conv_int.csh_orig

# 
echo " "
echo '********************************************'
echo '    Run conv.x to specify convolution.'
echo '********************************************'
echo " "
exit
