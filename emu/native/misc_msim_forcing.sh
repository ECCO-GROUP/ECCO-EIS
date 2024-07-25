#!/bin/bash -e 
umask 022

emu_dir=EMU_DIR
emu_input_dir=EMU_INPUT_DIR

#=================================
# For EMU Modified Simulation Tool (msim).
# (Native version)
# 
# This is an example of preparing user replacement files for EMU
# Modified Simulation Tool. This example shell script creates, for a
# particular user-defined control (forcing) of V4r4,
#    1) Its 1992-2017 time-mean, 
#    2) Stationary 1992-2017 6-hourly forcing with 1).
#
# The user-created directory from this script (rundir) can then be
# specified when running the Modified Simulation Tool.
#
#=================================

echo " "
echo "This routine creates example replacement files for EMU Modified Simulation Tool."
echo "For a user-chosen control (forcing) of V4r4, this will create "
echo "    1) Its 1992-2017 time-mean, "
echo "    2) Stationary 1992-2017 6-hourly forcing with 1). "
echo "Use the user-created directory below (rundir) to employ " 
echo "these files with the Modified Simulation Tool." 
echo " "

#--------------------------
# Choose control 

fctrl=(
    "oceFWflx"
    "oceQsw"
    "oceSflux"
    "oceSPflx"
    "oceTAUX"
    "oceTAUY"
    "sIceLoadPatmPload_nopabar"
    "TFLUX"
)

echo " "
echo "V4r4's controls are ... "
for element in "${fctrl[@]}"; do
    echo "$element"
done
echo " "

echo "Enter control to replace ... ?"
read finput
echo " "

#--------------------------
# Create directory 
current_dir=${PWD}
echo "Enter directory name for replacement files to be created in ... (rundir)?"
read ftext
echo " "

rundir=$(readlink -f "$ftext")
if [[ -d ${rundir} ]] ; then
    echo "Files will be created in "${rundir}
    echo " "
else
    echo "Creating "${rundir}
    mkdir ${rundir}
    echo " "
fi
cd ${rundir}

#--------------------------
# Compute 1992-2017 time-mean
${emu_dir}/emu/exe/msim_ave6hrly.x <<EOF
${emu_input_dir}/forcing/other/flux-forced/forcing
${finput}
1992
2017
EOF


#--------------------------
# Create time-invariant 1992-2017 6-hourly forcing 

fsource=msim_ave6hrly_1992_2017.${finput}
fsource=${PWD}/${fsource}
if [[ -e ${fsource} ]]; then 
    for iyr in {1992..2017}; do
	ln -sf ${fsource} ${finput}_6hourlyavg_${iyr}
    done
    echo "misc_msim_forcing.sh execution complete."
    echo " "
else
    echo "Averaging failed ... aborting."
    echo " "
fi




