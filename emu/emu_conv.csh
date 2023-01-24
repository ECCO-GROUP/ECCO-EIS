#!/bin/tcsh

#=================================
# Shell script for V4r4 Convolution Tool
# Script does all three steps of the Tool;
#    1) setup_conv.csh
#    2) conv.x
#    3) do_conv.csh
#=================================

echo " "
echo "************************************"
echo "    EMU Convolution Tool  "
echo "************************************"
echo " "

set tooldir  = SETUPDIR/emu

# Step 1: Tool Setup
echo "**** Step 1: Tool Setup"
echo "     Running setup_conv.csh "
source ${tooldir}/setup_conv.csh

# Step 2: Specification
echo "**** Step 2: Specification"
echo "     Running conv.x"
conv.x

# Step 3: Calculation 
echo "**** Step 3: Calculation"
echo "     Running do_conv.csh"
echo " "
source do_conv.csh

exit
