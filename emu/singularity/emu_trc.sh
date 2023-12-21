#!/bin/bash 

#=================================
# Shell script for V4r4 Tracer Tool
# Script does all three steps of the Tool;
#    1) setup_trc.csh
#    2) trc.x
#    3) do_trc.csh
#=================================

native_singularity=NATIVE_SINGULARITY
singularity_image=SINGULARITY_IMAGE
native_setup=NATIVE_SETUP

echo " "
echo "************************************"
echo "    EMU Tracer Tool (singularity) "
echo "************************************"

/bin/rm -f my_commands.sh
echo '#!/bin/bash' > my_commands.sh 
chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# Step 1: Tool Setup
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 1: Tool Setup"'    >> my_commands.sh
echo 'echo "     Running setup_trc.sh"'  >> my_commands.sh
echo '${basedir}/emu/setup_trc.sh'       >> my_commands.sh

# Step 2: Specification
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 2: Specification"' >> my_commands.sh
echo 'echo "     Running trc.x"'         >> my_commands.sh
echo './trc.x'                           >> my_commands.sh

${native_singularity} exec --bind ${native_setup}:/emu_outside:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

if [ -f "trc.dir_out" ] && [ -f "pbs_trc.sh" ]; then
    read dummy < "trc.dir_out"
    rundir=${PWD}/${dummy}/temp
    sed -i -e "s|YOURDIR|${rundir}|g" pbs_trc.sh
    cp -p pbs_trc.sh ${rundir}
else
    echo "File trc.dir_out and/or pbs_trc.sh do(es) not exist ... "
    exit 1
fi

# Step 3: Calculation 
echo "**** Step 3: Calculation"

returndir=$PWD

# prepare script for 1) inside Singularity 
echo "  1) Set up files for tracer integration "

cd ${rundir}

/bin/rm -f my_commands.sh 
echo '#!/bin/bash'     > my_commands.sh 
chmod +x my_commands.sh 
echo 'cd /inside_out'                   >> my_commands.sh
echo '${basedir}/emu/singularity/do_trc_prep.sh'   >> my_commands.sh

${native_singularity} exec --bind ${native_setup}:/emu_outside:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

cd ${returndir}

# submit batch job to do 2)
echo "  2) Integrate tracer "

BATCH_COMMAND pbs_trc.sh

echo "... Batch job pbs_trc.sh has been submitted "
echo "    to compute the model's trcoint gradients." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_trc.sh

echo " " 
dum=`sed -n '3p' trc.dir_out`
echo '********************************************'
echo "    Results will be in " ${dum}
echo '********************************************'
echo " "
