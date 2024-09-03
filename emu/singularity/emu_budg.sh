#!/bin/bash -e

#=================================
# Shell script for V4r4 Budget Tool
# Script does all three steps of the Tool;
#    1) setup_budg.csh
#    2) budg.x
#    3) do_budg.x
#=================================

singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR

echo " "
echo "************************************"
echo "    EMU Budget Tool (singularity) "
echo "************************************"

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/emu_ref
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input for Budget Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_input_setup.sh"
    echo "to download emu_ref needed for the Budget Tool." 
    exit 1
fi

# Initialize my_commands.sh for Singularity image
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# Step 1: Tool Setup
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 1: Tool Setup"'    >> my_commands.sh
echo 'echo "     Running setup_budg.sh"' >> my_commands.sh
echo '${emu_dir}/emu/setup_budg.sh'      >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

# Initialize my_commands.sh for Singularity image
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running budg.x"

# Specify directory with state files
source_dir=${emu_input_dir}/emu_ref/diags
echo "By default, tool will sample EMU reference run from state files in directory "
echo ${source_dir}
echo " " 
echo "Press Enter to continue or enter an alternate directory if sampling another run ... ?"
read ftext

if [[ -z ${ftext} ]]; then
    echo " "
    echo " ... sampling default EMU reference run."
else
    # Check to make sure directory exists.
    if [[ ! -d "${ftext}" ]]; then
	echo "Directory " ${ftext} " does not exist."
	echo "Aborting EMU Budget Tool."
	echo " "
	exit 1
    fi
    echo " ... sampling alternate run in "
    source_dir=$(readlink -f "$ftext")
    echo ${source_dir}
fi

echo "     Running budg.x"
echo "./budg.x /emu_input_dir /inside_alt"  >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     --bind ${source_dir}:/inside_alt:ro ${singularity_image} /inside_out/my_commands.sh

# Initialize my_commands.sh for Singularity image
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"
echo "     Running do_budg.x"

returndir=$PWD

read dummy < ./budg.dir_out
rundir=${PWD}/${dummy}/temp

sed -i -e "s|YOURDIR|${rundir}|g" ./pbs_budg.sh
sed -i -e "s|SOURCEDIR|${source_dir}|g" ./pbs_budg.sh
mv ./pbs_budg.sh ${rundir}

cd ${rundir}

echo "... Submitting batch job pbs_budg.sh  "
echo "    to compute the budget." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' ./pbs_budg.sh

BATCH_COMMAND ./pbs_budg.sh

echo " " 
dum=`sed -n '3p' ./budg.dir_out`
echo '********************************************'
echo "    Results will be in" ${dum}
echo '********************************************'
echo " "

cd ${returndir}

