#PBS -S /bin/bash 
#CHOOSE_NODES
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

umask 022

#=================================
# Shell script for V4r4 Forward Gradient Tool (singularity)
#=================================

##=================================
## Set running environment 
#ulimit -s unlimited
#
#export FORT_BUFFERED=1
#export MPI_BUFS_PER_PROC=128
#export MPI_DISPLAY_SETTINGS=""

#=================================
# Set program specific parameters 
nprocs=EMU_NPROC
singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR
native_mpiexec=NATIVE_MPIEXEC

rundir=YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}
 
echo 'Running MITgcm (v4r4_flx.x) ... '

## ID nodes for MPI 
#/bin/rm -f my_machine_file
#cat  $PBS_NODEFILE > my_machine_file
#sed -i '1,24d' my_machine_file

# ---------------------------
echo 'before v4r4_flx.x'
date
# Capture the start time
start_time=$(date +%s)
# ---------------------------

# build Singularity script 
/bin/rm -f my_commands.sh 
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out' >> my_commands.sh
echo "ln -sf \${emu_dir}/emu/exe/nproc/${nprocs}/v4r4_flx.x . "  >> my_commands.sh
echo "ln -sf \${emu_dir}/emu/emu_input/nproc/${nprocs}/data.exch2 . "        >> my_commands.sh    
echo "./v4r4_flx.x  "                                                      >> my_commands.sh    

#${native_mpiexec} -np ${nprocs} --hostfile ./my_machine_file \
#    singularity exec -e --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${rundir}:/inside_out ${singularity_image} /inside_out/my_commands.sh

${native_mpiexec} -np ${nprocs}  --use-hwthread-cpus \
    singularity exec -e --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${rundir}:/inside_out ${singularity_image} /inside_out/my_commands.sh

echo 'Sucessfully ran MITgcm (v4r4_flx.x) ... '

#=================================
# Compute gradient (weighted difference from the reference run).

echo 'Computing forward gradient by fgrd.x ... '

# build Singularity script 
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                       >> my_commands.sh
echo 'ln -sf ${emu_dir}/emu/exe/fgrd.x .'    >> my_commands.sh
echo 'fgrd.x /emu_input_dir'        >> my_commands.sh

singularity exec -e --bind EMU_REF:/emu_input_dir:ro --bind ${rundir}:/inside_out ${singularity_image} /inside_out/my_commands.sh 

echo 'Successfully computed forward gradient  ... '

# ---------------------------
echo 'after fgrd.x'
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

#=================================
# Move result to output dirctory 
mv fgrd_result ../output
mv pbs_fgrd.sh ../output
mv fgrd_spec.info ../output

