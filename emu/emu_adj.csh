#!/bin/tcsh

#=================================
# Shell script for V4r4 Adjoint Tool
# Script does all three steps of the Tool;
#    1) setup_adj.csh
#    2) adj.x
#    3) do_adj.csh
#=================================

echo " "
echo "************************************"
echo "    EMU Adjoint Tool  "
echo "************************************"
echo " "

set tooldir  = SETUPDIR/emu

# Step 1: Tool Setup
echo "**** Step 1: Tool Setup"
echo "     Running setup_adj.csh "
source ${tooldir}/setup_adj.csh

# Step 2: Specification
echo "**** Step 2: Specification"
echo "     Running adj.x"
adj.x

# Step 3: Calculation 
echo "**** Step 3: Calculation"
echo "     Running do_adj.csh"
echo " "
source do_adj.csh

exit
