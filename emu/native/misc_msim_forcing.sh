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
for i in "${!fctrl[@]}"; do
    printf "%d) %s\n" $((i+1)) "${fctrl[$i]}"
done
echo " "

# Prompt until valid number is entered
while true; do
    echo "Enter control to replace ... (1-${#fctrl[@]})?"
    read choice

    # Check if input is a valid number within range
    if [[ "$choice" =~ ^[1-8]$ ]]; then
        index=$((choice - 1))
        finput="${fctrl[$index]}"
        echo "Replaced control will be: $finput"
        break
    else
        echo "Error: Enter a number between 1 and 8."
        echo " "
    fi
done

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
echo "***********************" >  ${rundir}/misc_msim_forcing.info
echo "Output of misc_msim_forcing.sh"   >> ${rundir}/misc_msim_forcing.info
echo "***********************" >> ${rundir}/misc_msim_forcing.info

ls -al ${rundir} > before.txt

echo " "  >> ${rundir}/misc_msim_forcing.info
echo "Replacing following control with its time-mean: "   >> ${rundir}/misc_msim_forcing.info
echo ${finput}   >> ${rundir}/misc_msim_forcing.info

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
if [[ ! -e ${fsource} ]]; then 
    echo "Averaging failed ... aborting."
    echo " "
else
    for iyr in {1992..2017}; do
	ln -sf ${fsource} ${finput}_6hourlyavg_${iyr}
    done

    #--------------------------
    # End

    ls -al ${rundir} > after.txt
    echo " " 
    echo "Changed files:"
    comm -13 <(sort before.txt) <(sort after.txt) \
	| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
	| grep -vE '^(before.txt|after.txt|\.\.?$)' 

    echo " "   >> ${rundir}/misc_msim_forcing.info
    echo "Modified forcing files with their time-mean using program msim_forcing.f "   >> ${rundir}/misc_msim_forcing.info
    echo " "   >> ${rundir}/misc_msim_forcing.info
    echo "Changed files:"  >> ${rundir}/misc_msim_forcing.info
    comm -13 <(sort before.txt) <(sort after.txt) \
	| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
	| grep -vE '^(before.txt|after.txt|\.\.?$)' >> ${rundir}/misc_msim_forcing.info

    rm before.txt
    rm after.txt

    echo " "  >> ${rundir}/misc_msim_forcing.info
    echo "Files at end: "   >> ${rundir}/misc_msim_forcing.info
    echo "ls -al "$rundir  >> ${rundir}/misc_msim_forcing.info
    ls -al $rundir >> ${rundir}/misc_msim_forcing.info

    cd ${current_dir}

    echo " "
    echo "Successfully modified forcing files in directory " ${rundir}
    echo "Use this directory name as input with the Modified Simulation Tool." 
    echo " "

    echo "misc_msim_forcing.sh execution complete."

fi





