#!/bin/bash 

#=================================
# Shell script for V4r4 Perturbation Tool
# Script does all three steps of the Tool;
#    1) setup_pert.sh
#    2) pert.x
#    3) pert_xx.x, mitgcmuv, pert_grad.x 
#=================================

native_singularity=NATIVE_SINGULARITY
singularity_image=SINGULARITY_IMAGE
native_setup=NATIVE_SETUP

echo " "
echo "************************************"
echo "    EMU Perturbation Tool (singularity) "
echo "************************************"

# ------------------------------------------
# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_pert.sh "

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running pert.x"

${native_singularity} exec --bind ${PWD}:/inside_out \
     ${singularity_image} bash -c 'cd /inside_out && ${basedir}/emu/setup_pert.sh && ./pert.x'

if [ -f "pert.dir_out" ] && [ -f "pbs_pert.sh" ]; then
    read dummy < "pert.dir_out"
    rundir=${PWD}/${dummy}/temp
    sed -i -e "s|YOURDIR|${rundir}|g" pbs_pert.sh
    cp -p pbs_pert.sh ${rundir}
else
    echo "File pert.dir_out and/or pbs_pert.sh do(es) not exist ... "
    exit 1
fi

# ------------------------------------------
# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"

returndir=$PWD

# prepare script for 1) & 2) inside Singularity 
echo "  1) Set up files for MITgcm "
echo "  2) Perturb forcing "

cd ${rundir}

/bin/rm -f my_commands.sh 
echo '#!/bin/bash'     > my_commands.sh & chmod +x my_commands.sh 
echo 'cd /inside_out'                   >> my_commands.sh
echo '${basedir}/emu/singularity/setup_forcing.sh' >> my_commands.sh
echo '${basedir}/emu/singularity/do_pert_xx.sh' >> my_commands.sh

${native_singularity} exec --bind ${native_setup}:/emu_outside:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

cd ${returndir}

# submit batch job to do 3) and 4) 
echo "  3) Run MITgcm "
echo "  4) Compute difference from reference run" 

BATCH_COMMAND pbs_pert.sh

echo "... Batch job pbs_pert.sh has been submitted "
echo "    to compute the model's response to perturbation." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_pert.sh

echo " " 
echo '********************************************'
echo "    Results will be in " ${rundir}
echo '********************************************'
echo " "


