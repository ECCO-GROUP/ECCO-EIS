#!/bin/tcsh

#=================================
# Shell script for V4r4 Sampling Tool
# Script does all three steps of the Tool;
#    1) setup_samp.csh
#    2) samp.x
#    3) do_samp.csh
#=================================

echo " "
echo "************************************"
echo "    EMU Sampling Tool  "
echo "************************************"
echo " "

set tooldir  = SETUPDIR/emu

# Step 1: Tool Setup
echo "**** Step 1: Tool Setup"
echo "     Running setup_samp.csh "
source ${tooldir}/setup_samp.csh

# Step 2: Specification
echo "**** Step 2: Specification"
echo "     Running samp.x"
samp.x

# Step 3: Calculation 
echo "**** Step 3: Calculation"
echo "     Running do_samp.csh"
echo " "
source do_samp.csh

exit
