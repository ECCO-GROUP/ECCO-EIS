#!/bin/bash -e

#=================================
# Shell script for V4r4 Forward Gradient Tool
# Script does all three steps of the Tool;
#    1) setup_fgrd.sh
#    2) fgrd_spec.x
#    3) fgrd_pert.x, mitgcmuv, fgrd.x 
#=================================

singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR

echo " "
echo "************************************"
echo "    EMU Forward Gradient Tool (singularity) "
echo "************************************"

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/forcing/other/flux-forced/forcing
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input for Forward Gradient Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_download_input.sh"
    echo "using ${emu_input_dir} as 'directory name to place EMU Input'" 
    echo "to download forcing needed for the Forward Gradient Tool." 
    exit 1
fi

# ------------------------------------------
# Step 1: Tool Setup
echo " "
echo "**** Step 1: Tool Setup"
echo "     Running setup_fgrd.sh "

singularity exec --bind ${PWD}:/inside_out \
     ${singularity_image} bash -c 'cd /inside_out && ${emu_dir}/emu/setup_fgrd.sh '

# Step 2: Specification
echo " "
echo "**** Step 2: Specification"
echo "     Running fgrd_spec.x"

cp -f PUBLICDIR/mitgcm_timing.nml .

/bin/rm -f my_commands.sh 
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                          >> my_commands.sh
echo 'ln -sf ${emu_dir}/emu/exe/fgrd_spec.x .' >> my_commands.sh
echo './fgrd_spec.x '                          >> my_commands.sh
singularity exec --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

if [ -f "./fgrd.dir_out" ] && [ -f "./pbs_fgrd.sh" ]; then
    read dummy < "./fgrd.dir_out"
    rundir=${PWD}/${dummy}/temp
    sed -i -e "s|YOURDIR|${rundir}|g" ./pbs_fgrd.sh
    cp -p ./pbs_fgrd.sh ${rundir}
else
    echo "File fgrd.dir_out and/or pbs_fgrd.sh do(es) not exist ... "
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
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                   >> my_commands.sh
echo '${emu_dir}/emu/singularity/setup_forcing.sh' >> my_commands.sh
echo '${emu_dir}/emu/singularity/do_fgrd_pert.sh' >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

cd ${returndir}

# submit batch job to do 3) and 4) 
echo "  3) Run MITgcm "
echo "  4) Compute difference from reference run" 

#BATCH_COMMAND pbs_fgrd.sh

echo "... Running batch job pbs_fgrd.sh "
echo "    to compute the model's forward gradient." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_fgrd.sh

echo " " 
dum=`tail -n 1 fgrd.dir_out`
echo '********************************************'
echo "    Results will be in " ${dum}
echo '********************************************'
echo " "

dum="${dum%output}temp"
echo "Progress of the computation can be monitored by"
echo "  ls ${dum}/diags/*2d*day*data | wc -l " 
echo "which counts the number of days the model has integrated." 
echo "(As standard output, the model saves daily mean files of"
echo "sea level and ocean bottom pressure.)"  
echo " "

BATCH_COMMAND pbs_fgrd.sh
