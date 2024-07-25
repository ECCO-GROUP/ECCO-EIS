#!/bin/bash -e 

umask 022

#=================================
#
# Script for test running EMU with an example for each tool (reference
# runs). 
# 
# This script runs one of the following examples, based on its argument emu_choice; 
# 
#  1) Sampling (samp) monthly-mean OBP relative to its global mean at the North Pole 
#  2) Forward gradient (fgrd) of 1992 state with respect to eastward wind at 180E 0N during week 5
#  3) Adjoint gradient (adj) of Example 1) for month 6 (June 1992)
#  4) Convolution (conv) of ECCO V4r4 forcing with adjoint gradients of Example 3) 
#  5) Tracer (trc) evolution for 396-days released from top-most 10m-layer at 180E 0N on day 30
#  6) Budget (budg) of temperature integrated over the top-most 10m-layer of Nino3.4
#  7) Modified Simulation (msim) using time-mean wind-stress
#  8) Attribution (atrb) of temporal changes for Example 1)
#
# Usage; 
#    misc_test_indiv.sh emu_choice
# where emu_choice is a number from 1 to 8 corresponding to runs above. 
#
# Progress can be followed in terminal output and the script's log
# file misc_test_suite.log which includes timing information of each
# Example. 
# 
# Progress for Examples 2) Forward Gradient and 7) Modified Simulation 
# can additionally be monitored, respectively, by
#    ls ./emu_fgrd*/temp/diags/*2d*day*data | wc -l
#    ls ./emu_msim*/temp/diags/*2d*day*data | wc -l
# which should reach 396, the total number of days that the model is
# integrated (nominally one year plus one month). 
#
# Progress for Example 3) Adjoint can be monitored by
#    grep ad_time_tsnumber ./emu_adj*/temp/STDOUT.0000 | tail -n 3
# which counts down from 4320 to 240. Variable ad_time_tsnumber is the
# 1-hour time-step number of the adjoint model printed backward every
# 10-days (240).
#
#=================================

# Check for argument count
if [ $# -ne 1 ]; then
    echo "Usage: $0 <choice>"
    exit 1
fi

# Assign argument 
emu_choice=$1

# Record progress
if [[ ! -e misc_test_suite.log ]]; then
    echo "Log of test running EMU by misc_test_indiv.sh ... $(date)"  > misc_test_suite.log    
    echo " "                                                         >> misc_test_suite.log 
fi

# -----------------------
# 1) Sampling 
if [[ "$emu_choice" -eq 1 ]]; then
    echo "Running 1) Sampling ************** " 
    echo "Running 1) Sampling ************** " >> misc_test_suite.log 
    {
    time PUBLICDIR/emu.sh <<EOF

1

m
2
1
9
0
90
1
1
0
EOF
    } 2>> misc_test_suite.log
    echo "Done 1) Sampling" 
    echo "Done 1) Sampling" >> misc_test_suite.log 
    echo " "
    echo " " >> misc_test_suite.log 

# -----------------------
# 2) Forward Gradient
elif [[ "$emu_choice" -eq 2 ]]; then
    echo "Running 2) Forward Gradient ************** " 
    echo "Running 2) Forward Gradient ************** " >> misc_test_suite.log 
    {
    time PUBLICDIR/emu.sh <<EOF

2
7
9
180
0
5
1
12
EOF
    } 2>> misc_test_suite.log
    echo "Done 2) Forward Gradient"
    echo "Done 2) Forward Gradient" >> misc_test_suite.log 
    echo " "
    echo " " >> misc_test_suite.log 

# -----------------------
# 3) Adjoint Gradient
elif [[ "$emu_choice" -eq 3 ]]; then
    echo "Running 3) Adjoint Gradient ************** " 
    echo "Running 3) Adjoint Gradient ************** " >> misc_test_suite.log 
    {
    time PUBLICDIR/emu.sh <<EOF

3
6
6
2
1
9
0
90
1
1
0
EOF
    } 2>> misc_test_suite.log
    echo "Done 3) Adjoint Gradient"
    echo "Done 3) Adjoint Gradient" >> misc_test_suite.log 
    echo " "
    echo " " >> misc_test_suite.log 

# -----------------------
# 4) Convolution 
elif [[ "$emu_choice" -eq 4 ]]; then
    echo "Running 4) Convolution ************** " 
    echo "Running 4) Convolution ************** " >> misc_test_suite.log 
    echo ""
    # Exit if restuls from Example 3) Adjoint is not available 
    if [ ! -d "emu_adj_6_6_2_45_585_1" ]; then
	echo "**********************"
	echo "WARNING" 
	echo "Directory emu_adj_6_6_2_45_585_1 not found." 
	echo "Example 4) Convolution cannot be run until Example 3) Adjoint has been completed." 
	echo "**********************"
	exit
    fi
    {
    time PUBLICDIR/emu.sh <<EOF

4
emu_adj_6_6_2_45_585_1/output
y
26
EOF
    } 2>> misc_test_suite.log
    echo "Done 4) Convolution"
    echo "Done 4) Convolution" >> misc_test_suite.log 
    echo " "
    echo " " >> misc_test_suite.log 

# -----------------------
# 5) Tracer
elif [[ "$emu_choice" -eq 5 ]]; then
    echo "Running 5) Tracer ************** " 
    echo "Running 5) Tracer ************** " >> misc_test_suite.log 
    {
    time PUBLICDIR/emu.sh <<EOF

5
30
396
1
9
180
0
1
1
EOF
    } 2>> misc_test_suite.log
    echo "Done 5) Tracer"
    echo "Done 5) Tracer" >> misc_test_suite.log 
    echo " "
    echo " " >> misc_test_suite.log 

# -----------------------
# 6) Budget 
elif [[ "$emu_choice" -eq 6 ]]; then
    echo "Running 6) Budget ************** " 
    echo "Running 6) Budget ************** " >> misc_test_suite.log 
    {
    time PUBLICDIR/emu.sh <<EOF

6

2
2
1
-170
-120
-5
5
10
0
EOF
    } 2>> misc_test_suite.log
    echo "Done 6) Budget"
    echo "Done 6) Budget" >> misc_test_suite.log 
    echo " "
    echo " " >> misc_test_suite.log 

# -----------------------
# 7) Modified Simulation
elif [[ "$emu_choice" -eq 7 ]]; then
    echo "Running 7) Modified Simulation ************** " 
    echo "Running 7) Modified Simulation ************** " >> misc_test_suite.log 

# Prepare data file (integrate for 12 months)
    echo "Setting 1-year integration with misc_msim_data.sh"
    echo "Setting 1-year integration with misc_msim_data.sh" >> misc_test_suite.log 
    {
    PUBLICDIR/misc_msim_data.sh <<EOF
for_msim
12
EOF
    } 2>> misc_test_suite.log
    echo "" >> misc_test_suite.log
    echo " "
# Prepare time-mean wind forcing file (prepares all 26-years)
    echo "Computing time-mean oceTAUX with misc_msim_forcing.sh"
    echo "Computing time-mean oceTAUX with misc_msim_forcing.sh" >> misc_test_suite.log 
    {
    PUBLICDIR/misc_msim_forcing.sh <<EOF
oceTAUX
for_msim
EOF
    } 2>> misc_test_suite.log
    echo "" >> misc_test_suite.log
    echo " "

    echo "Computing time-mean oceTAUY with misc_msim_forcing.sh"
    echo "Computing time-mean oceTAUY with misc_msim_forcing.sh" >> misc_test_suite.log 
    {
    PUBLICDIR/misc_msim_forcing.sh <<EOF
oceTAUY
for_msim
EOF
    } 2>> misc_test_suite.log
    echo "" >> misc_test_suite.log
    echo " "

# Run EMU msim 
    echo "Running EMU Modified Simulation Tool with these replacements"
    echo "Running EMU Modified Simulation Tool with these replacements" >> misc_test_suite.log 
    {
    time PUBLICDIR/emu.sh <<EOF

7
for_msim
N
Y
Testing with misc_test_suite.sh
EOF
    } 2>> misc_test_suite.log
    echo "Done 7) Modified Simulation"
    echo "Done 7) Modified Simulation" >> misc_test_suite.log 
    echo " "
    echo " " >> misc_test_suite.log 

# -----------------------
# 8) Attribution
elif [[ "$emu_choice" -eq 8 ]]; then
    echo "Running 8) Attribution ************** " 
    echo "Running 8) Attribution ************** " >> misc_test_suite.log 
    {
    time PUBLICDIR/emu.sh <<EOF

8
m
2
1
9
0
90
1
1
0
EOF
    } 2>> misc_test_suite.log
    echo "Done 8) Attribution"
    echo "Done 8) Attribution" >> misc_test_suite.log 
    echo " "
    echo " " >> misc_test_suite.log 

else 
    echo "Invalid choice of test ... ${emu_choice}"
    exit 1 
fi

# -----------------------
echo ""
echo "misc_test_indiv.sh complete. $(date)"

