#!/bin/bash 

#=================================
# Shell script for V4r4 Adjoint Tool
# Script does all three steps of the Tool;
#    1) setup_adj.sh
#    2) adj.x
#    3) do_adj.csh
#=================================

native_singularity=NATIVE_SINGULARITY
singularity_image=SINGULARITY_IMAGE
native_setup=NATIVE_SETUP

echo " "
echo "************************************"
echo "    EMU Adjoint Tool  (singularity) "
echo "************************************"

echo ${PWD} > emu.fcwd 

/bin/rm -f my_commands.sh
echo '#!/bin/bash' > my_commands.sh & chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# ------------------------------------------
# Step 1: Tool Setup
echo 'echo " "'                           >> my_commands.sh
echo 'echo "**** Step 1: Tool Setup"'     >> my_commands.sh
echo 'echo "     Running setup_adj.csh "' >> my_commands.sh
echo '${basedir}/emu/setup_adj.sh'        >> my_commands.sh

# Step 2: Specification
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 2: Specification"' >> my_commands.sh
echo 'echo "     Running adj.x"'         >> my_commands.sh
echo './adj.x'                           >> my_commands.sh

${native_singularity} exec --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

if [ -f "adj.dir_out" ] && [ -f "pbs_adj.sh" ]; then
    read dummy < "adj.dir_out"
    rundir=${PWD}/${dummy}/temp
    sed -i -e "s|YOURDIR|${rundir}|g" pbs_adj.sh
    cp -p pbs_adj.sh ${rundir}
else
    echo "File adj.dir_out and/or pbs_adj.sh do(es) not exist ... "
    exit 1
fi
# ------------------------------------------
# Step 3: Calculation 
echo "**** Step 3: Calculation"

returndir=$PWD

# prepare script for 1) inside Singularity 
echo "  1) Set up files for MITgcm "

cd ${rundir}

/bin/rm -f my_commands.sh 
echo '#!/bin/bash'     > my_commands.sh & chmod +x my_commands.sh 
echo 'cd /inside_out'                   >> my_commands.sh
echo '${basedir}/emu/singularity/setup_forcing.sh' >> my_commands.sh
echo '${basedir}/emu/singularity/do_adj_prep.sh' >> my_commands.sh

${native_singularity} exec --bind ${native_setup}:/emu_outside:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

cd ${returndir}

# submit batch job to do 2)
echo "  2) Run MITgcm adjoint "

BATCH_COMMAND pbs_adj.sh

echo "... Batch job pbs_adj.sh has been submitted "
echo "    to compute the model's adjoint gradients." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_adj.sh

echo " " 
dum=`sed -n '3p' adj.dir_out`
echo '********************************************'
echo "    Results will be in " ${dum}
echo '********************************************'
echo " "

