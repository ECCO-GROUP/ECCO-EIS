#!/bin/bash -e

#=================================
# Shell script for V4r4 Adjoint Tool
# Script does all three steps of the Tool;
#    1) setup_adj.sh
#    2) adj.x
#    3) do_adj.csh
#=================================

singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR

echo " "
echo "************************************"
echo "    EMU Adjoint Tool  (singularity) "
echo "************************************"

echo ${PWD} > emu.fcwd 

# ------------------------------------------
# Check setup 

# Check required EMU Input 
fdum=${emu_input_dir}/forcing/other/flux-forced/forcing
if [[ ! -d $fdum ]]; then 
    echo 
    echo "**********************"
    echo "ABORT: EMU Input for Adjoint Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_input_setup.sh"
    echo "to download forcing needed for the Adjoint Tool." 
    exit 1
fi

# ------------------------------------------
# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_adj.csh "

# Initialize my_commands.sh
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh
echo '${emu_dir}/emu/setup_adj.sh'        >> my_commands.sh

singularity exec --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running adj.x"

# Initialize my_commands.sh
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh
cp -f PUBLICDIR/mitgcm_timing.nml .
echo /emu_input_dir > ./input_setup_dir
echo './adj.x'                           >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
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

cd ${rundir}

# prepare script for 1) inside Singularity 
echo "  1) Set up files for MITgcm "

/bin/rm -f my_commands.sh 
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                   >> my_commands.sh
echo '${emu_dir}/emu/singularity/setup_forcing.sh' >> my_commands.sh
echo '${emu_dir}/emu/singularity/do_adj_prep.sh' >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

cd ${returndir}

# submit batch job to do 2)
echo "  2) Run MITgcm adjoint "

#BATCH_COMMAND pbs_adj.sh

echo "... Running batch job pbs_adj.sh "
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

dum="${dum%output}temp"
echo "Progress of the computation can be monitored by"
echo "  grep ad_time_tsnumber ${dum}/STDOUT.0000 "
echo "which lists the model's time-step (one-hour) at 10-day"
echo "intervals backward from the target instant to the model's"
echo "initial time (hour 0), 01 January 1992 12Z." 
echo " "

BATCH_COMMAND pbs_adj.sh
