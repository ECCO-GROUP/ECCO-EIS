#PBS -S /bin/bash 
#CHOOSE_NODES
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

umask 022

#=================================
# Shell script for V4r4 Tracer Tool (singularity)
#=================================

#=================================
# Set program specific parameters 
nprocs=EMU_NPROC
emu_input_dir=EMU_INPUT_DIR
singularity_image=SINGULARITY_IMAGE
native_mpiexec=NATIVE_MPIEXEC

rundir=YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}
 
# ================================
# Link tracer executable 

# Initialize my_commands.sh
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh
echo 'BANDAID_PICKUP'   >> my_commands.sh
echo 'ln -sf /emu_input_dir/forcing/other/flux-forced/STATE_DIR/* .'   >> my_commands.sh
echo "ln -sf \${emu_dir}/emu/exe/nproc/${nprocs}/FRW_OR_ADJ . "  >> my_commands.sh
echo "ln -sf \${emu_dir}/emu/emu_input/nproc/${nprocs}/data.exch2 . "  >> my_commands.sh

singularity exec -e --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

# Run tracer executable 
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh
echo './FRW_OR_ADJ '     >> my_commands.sh

# ---------------------------
echo 'before FRW_OR_ADJ'
date
# Capture the start time
start_time=$(date +%s)
# ---------------------------

${native_mpiexec} -np ${nprocs}  --use-hwthread-cpus \
    singularity exec -e --bind ${emu_input_dir}:/emu_input_dir:ro \
    --bind ${rundir}:/inside_out ${singularity_image} /inside_out/my_commands.sh

# ---------------------------
echo 'after FRW_OR_ADJ'
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
mv diags ../output
mv pbs_trc.sh ../output
mv trc.info ../output

# Save initial TRC 
PUBLICDIR/misc_move_files.sh ./ ../output 'pickup_ptracers.0*.data'

#=================================
# Reorder (rename time step) ptracer output files if adjoint run
cd ../output

# Initialize my_commands.sh
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh
echo '#REORDER_PTRACER ${emu_dir}/emu/emu_input/scripts/rename_offline_adj_diags_fn.sh YES '  >> my_commands.sh

singularity exec -e --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh
