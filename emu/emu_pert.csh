#!/bin/tcsh

#=================================
# Shell script for V4r4 Perturbation Tool
# Script does all three steps of the Tool;
#    1) setup_pert.csh
#    2) pert.x
#    3) do_pert.csh
#=================================

echo " "
echo "************************************"
echo "    EMU Perturbation Tool  "
echo "************************************"
echo " "

set tooldir  = SETUPDIR/emu

# Step 1: Tool Setup
echo "**** Step 1: Tool Setup"
echo "     Running setup_pert.csh "
source ${tooldir}/setup_pert.csh

# Step 2: Specification
echo "**** Step 2: Specification"
echo "     Running pert.x"
pert.x

# Step 3: Calculation 
echo "**** Step 3: Calculation"
echo "     Running do_pert.csh"
echo " "
source do_pert.csh

exit
