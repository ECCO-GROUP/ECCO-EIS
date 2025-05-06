#!/bin/bash -e
umask 022

#=================================
# Shell script for V4r4 Sampling Tool
# Script does all three steps of the Tool;
#    1) setup_samp.sh
#    2) samp.x
#    3) do_samp.x 
#=================================

echo " "
echo "************************************"
echo "    EMU Sampling Tool (native) "
echo "************************************"
echo 
echo " The Sampling Tool extract time-series of a user specified variable "
echo " of the ECCO estimate. The variable can be either the model's state "
echo " or its control (forcing). "
echo " See PUBLICDIR/README_samp "

returndir=$PWD

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/emu_ref
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input for Sampling Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_input_setup.sh"
    echo "to download emu_ref." 
    exit 1
fi

# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_samp.sh"
${emu_dir}/emu/setup_samp.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"

# Specify whether to sample State or Control 
echo " "
while true; do
    echo "Sample State (1) or Control (2) .... (1/2)?"
    read isamp
    if [[ "$isamp" == "1" || "$isamp" == "2" ]]; then
        break
    else
        echo "Invalid input. Enter 1 or 2."
    fi
done

if [[ "$isamp" == "1" ]]; then 
    echo "   Sampling State ... "
    # Default directory with state files
    source_dir=${emu_input_dir}/emu_ref/diags
else
    echo "   Sampling Control (forcing) ... "
    # Default directory with state files
    source_dir=${emu_input_dir}/forcing/other/flux-forced/forcing_weekly
fi

echo " "
echo "By default, tool will sample EMU reference run from directory "
echo ${source_dir}
echo " " 
echo "Press ENTER key to continue or enter an alternate directory if sampling another run ... ?"
read ftext

if [[ -z ${ftext} ]]; then
    echo " "
    echo " ... sampling default EMU reference run."
else
    # Check to make sure directory exists.
    if [[ ! -d "${ftext}" ]]; then
	echo "Directory " ${ftext} " does not exist."
	echo "Aborting EMU Sampling Tool."
	echo " "
	exit 1
    fi
    echo " ... sampling alternate run in "
    source_dir=$(readlink -f "$ftext")
    echo ${source_dir}
fi

echo " " 
echo "Running samp.x specifying what will be sampled ... "
./samp.x  ${isamp} ${source_dir}

# Move samp.x output files to rundir (used to be done in samp.x)
if [[ ! -f ./samp.dir_out ]]; then
    echo "ERROR: samp.dir_out not found. Aborting."
    exit 1
fi
read dummy < ./samp.dir_out
rundir=${dummy}/temp
mv ./samp.info ${rundir}
mv ./data.ecco ${rundir}
mv ./samp.dir_out ${rundir}
mv ./tool_setup_dir ${rundir}
mv ./input_setup_dir ${rundir}
PUBLICDIR/misc_move_files.sh ./ ${rundir} '*mask_C'
PUBLICDIR/misc_move_files.sh ./ ${rundir} '*mask_S'
PUBLICDIR/misc_move_files.sh ./ ${rundir} '*mask_W'

# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"
echo "     Running do_samp.x"
cd ${rundir}
ln -sf ${emu_dir}/emu/exe/do_samp.x .
./do_samp.x ${source_dir}

#=================================
# Move result to output dirctory 

mkdir ../output

mv ./data.ecco  ../output
mv ./samp.info ../output
mv ./samp.out_* ../output
mv ./samp.step_* ../output
mv ./samp.txt  ../output

# Save mask
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_C'
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_S'
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_W'

echo " " 
dum=`tail -n 1 ./samp.dir_out`
echo '********************************************'
echo "    Results are in" $dum
echo '********************************************'
echo " "

cd ${returndir}
