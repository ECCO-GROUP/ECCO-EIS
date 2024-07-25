#PBS -S /bin/bash 
#CHOOSE_NODES
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

umask 022

#=================================
# Shell script for V4r4 Simulation Difference tool (singularity)
#=================================

#=================================
# Set program specific pafameters 
nprocs=EMU_NPROC
singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR
native_mpiexec=NATIVE_MPIEXEC

rundir=YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}
 
# build Singularity script 
/bin/rm -f my_commands.sh 
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out' >> my_commands.sh
echo './v4r4_flx.x'     >> my_commands.sh

# ---------------------------
echo 'before v4r4_flx.x'
date
# Capture the start time
start_time=$(date +%s)
# ---------------------------

${native_mpiexec} -np ${nprocs}  --use-hwthread-cpus \
    singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${rundir}:/inside_out ${singularity_image} /inside_out/my_commands.sh

# ---------------------------
echo 'after v4r4_flx.x'
date
# Capture the end time
end_time=$(date +%s)
# Calculate the duration
duration=$((end_time - start_time))

# Convert the duration to hours, minutes, and seconds
hours=$((duration / 3600))
minutes=$(( (duration % 3600) / 60 ))
seconds=$((duration % 60))

# Print the duration in hour:minute:second format
printf "Time taken (hh:mm:ss): %d:%02d:%02d\n" $hours $minutes $seconds
# ---------------------------
