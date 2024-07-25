#!/bin/bash -e 

umask 022

#=================================
#
# Script for test running EMU with an example for each tool (reference
# runs).
#
# Progress can be followed in terminal output and this script's log
# file misc_test_suite.log which includes timing information of each
# example. 
# 
# Progress for 2) Forward Gradient can additionally be monitored by 
#    ls ./emu_fgrd*/temp/diags/*2d*day*data | wc -l
# which should reach 396, the total number of days that the model is
# integrated (nominally one year plus one month). 
#
# Progress for 7) Modified Simulation can be monitored by 
#    ls ./emu_msim*/diags/*2d*day*data | wc -l
# which should reach 396, the total number of days that the model is
# integrated (nominally one year plus one month). 
#
# Progress for 3) Adjoint can be monitored by
#    grep ad_time_tsnumber ./emu_adj*/temp/STDOUT.0000 | tail -n 3
# which counts down from 4320 to 240. Variable ad_time_tsnumber is the
# 1-hour time-step number of the adjoint model printed backward every
# 10-days (240).
#
#=================================

echo ""
echo "Test running EMU. "
echo ""
echo "Choose among the following ... " 
echo ""
echo "  1) Sampling (samp) monthly-mean OBP relative to its global mean at the North Pole" 
echo "  2) Forward gradient (fgrd) of 1992 state with respect to eastward wind at 180E 0N during week 5" 
echo "  3) Adjoint gradient (adj) of item 1) for month 6 (June 1992)"
echo "  4) Convolution (conv) of ECCO V4r4 forcing with adjoint gradient of item 3) (also runs item 3 if necessary)"
echo "  5) Tracer (trc) evolution for 396-days released from top-most 10m-layer at 180E 0N on day 30" 
echo "  6) Budget (budg) of temperature integrated over the top-most 10m-layer of Nino3.4"
echo "  7) Modified Simulation (msim) of 1992 using 1992-2016 time-mean wind-stress" 
echo "  8) Attribution (atrb) of temporal changes for item 1)"
echo " "
echo "  0) All of the above (in the order of computational time and dependency)." 
echo " "

echo "Enter choice ... (0-8)?"
read emu_choice

while [[ ${emu_choice} -lt 0 || ${emu_choice} -gt 8 ]] ; do 
    echo "Choice must be 0-8."
    read emu_choice
done

echo "Choice is "$emu_choice
echo "" 

# Print commands 
#set -x 

# Record progress
rm -f misc_test_suite.log
echo "Log of test running EMU by misc_test_suite.sh ..." > misc_test_suite.log
echo " " >> misc_test_suite.log

cat PUBLICDIR/misc_test_indiv.txt

# -----------------------
# 1) Sampling 
if [[ "$emu_choice" -eq 1 ]]; then
    PUBLICDIR/misc_test_indiv.sh 1

# -----------------------
# 8) Attribution
elif [[ "$emu_choice" -eq 8 ]]; then
    PUBLICDIR/misc_test_indiv.sh 8

# -----------------------
# 6) Budget 
elif [[ "$emu_choice" -eq 6 ]]; then
    PUBLICDIR/misc_test_indiv.sh 6

# -----------------------
# 5) Tracer
elif [[ "$emu_choice" -eq 5 ]]; then
    PUBLICDIR/misc_test_indiv.sh 5

# -----------------------
# 2) Forward Gradient
elif [[ "$emu_choice" -eq 2 ]]; then
    PUBLICDIR/misc_test_indiv.sh 2

# -----------------------
# 7) Modified Simulation
elif [[ "$emu_choice" -eq 7 ]]; then
    PUBLICDIR/misc_test_indiv.sh 7

# -----------------------
# 3) Adjoint Gradient
elif [[ "$emu_choice" -eq 3 ]]; then
    PUBLICDIR/misc_test_indiv.sh 3

# -----------------------
# 4) Convolution 
elif [[ "$emu_choice" -eq 4 ]]; then
    PUBLICDIR/misc_test_indiv.sh 4

# -----------------------
# 0) All the examples 
elif [[ "$emu_choice" -eq 0 ]]; then
    PUBLICDIR/misc_test_indiv.sh 1
    PUBLICDIR/misc_test_indiv.sh 8
    PUBLICDIR/misc_test_indiv.sh 6
    PUBLICDIR/misc_test_indiv.sh 5
    PUBLICDIR/misc_test_indiv.sh 2
    PUBLICDIR/misc_test_indiv.sh 7
    PUBLICDIR/misc_test_indiv.sh 3
    PUBLICDIR/misc_test_indiv.sh 4
fi

# -----------------------
echo ""
echo "misc_test_suite.sh complete. $(date)"

