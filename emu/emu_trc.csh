#!/bin/tcsh

#=================================
# Shell script for V4r4 Tracer Tool
# Script does all three steps of the Tool;
#    1) setup_trc.csh
#    2) trc.x
#    3) do_trc.csh
#=================================

echo " "
echo "************************************"
echo "    EMU Tracer Tool  "
echo "************************************"
echo " "

set tooldir  = SETUPDIR/emu

# Step 1: Tool Setup
echo "**** Step 1: Tool Setup"
echo "     Running setup_trc.csh "
source ${tooldir}/setup_trc.csh

# Step 2: Specification
echo "**** Step 2: Specification"
echo "     Running trc.x"
trc.x

# Step 3: Calculation 
echo "**** Step 3: Calculation"
echo "     Running do_trc.csh"
echo " "
source do_trc.csh

exit
