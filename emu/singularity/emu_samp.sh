#!/bin/bash -e

#=================================
# Shell script for V4r4 Sampling Tool
# Script does all three steps of the Tool;
#    1) setup_samp.sh
#    2) samp.x
#    3) do_samp.x
#=================================

singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR

echo " "
echo "************************************"
echo "    EMU Sampling Tool (singularity) "
echo "************************************"

returndir=$PWD

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/emu_ref
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input for Sampling Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_download_input.sh"
    echo "using ${emu_input_dir} as 'directory name to place EMU Input'" 
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
echo 'echo "     Running setup_samp.sh"' >> my_commands.sh
echo '${emu_dir}/emu/setup_samp.sh'      >> my_commands.sh

singularity exec --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo " "

# Specify directory with state files
source_dir=${emu_input_dir}/emu_ref/diags
echo "By default, tool will sample EMU reference run from state files in directory "
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

echo "     Running samp.x"

# Reset input_setup_dir for Singularity
echo '/emu_input_dir'  > ./input_setup_dir

# Running samp.x from Singularity image 
/bin/rm -f my_commands.sh
echo '#!/bin/bash' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                >> my_commands.sh
echo './samp.x /inside_alt'          >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     --bind ${source_dir}:/inside_alt:ro ${singularity_image} /inside_out/my_commands.sh

# Move samp.x output files to rundir (used to be done in samp.x)
read dummy < samp.dir_out
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

/bin/rm -f my_commands.sh
echo '#!/bin/bash' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                >> my_commands.sh
echo 'ln -s ${emu_dir}/emu/exe/do_samp.x .'  >> my_commands.sh
echo './do_samp.x /inside_alt'          >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     --bind ${source_dir}:/inside_alt:ro ${singularity_image} /inside_out/my_commands.sh

#=================================
# Move result to output dirctory 

# -------
# Replace /inside_alt in samp.info with actual directory name
sed -i "s| /inside_alt| ${source_dir}|g" samp.info 

mkdir ../output

mv data.ecco  ../output
mv samp.info ../output
mv samp.out_* ../output
mv samp.step_* ../output
mv samp.txt  ../output

# Save mask
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_C'
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_S'
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_W'

echo " " 
dum=`tail -n 1 samp.dir_out`
echo '********************************************'
echo "    Results are in" $dum
echo '********************************************'
echo " "

cd ${returndir}
