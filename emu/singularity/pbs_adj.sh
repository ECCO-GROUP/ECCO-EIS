#PBS -S /bin/bash 
#CHOOSE_NODES
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

#=================================
# Shell script for V4r4 Adjoint Tool (singularity)
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
 
echo 'Running MITgcm_ad (v4r4_flx_ad.x) ... '

# ================================
# build Singularity script 
/bin/rm -f my_commands.sh 
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out' >> my_commands.sh
echo "ln -sf \${emu_dir}/emu/exe/nproc/${nprocs}/v4r4_flx_ad.x . "  >> my_commands.sh
echo "ln -sf \${emu_dir}/emu/emu_input/nproc/${nprocs}/data.exch2 . "        >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out' >> my_commands.sh
echo './v4r4_flx_ad.x'     >> my_commands.sh

# ---------------------------
echo 'before v4r4_flx_ad.x'
date
# Capture the start time
start_time=$(date +%s)
# ---------------------------

${native_mpiexec} -np ${nprocs}  --use-hwthread-cpus \
    singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro \
    --bind ${rundir}:/inside_out ${singularity_image} /inside_out/my_commands.sh

echo 'Sucessfully ran MITgcm_ad (v4r4_flx_ad.x) ... '

# ---------------------------
echo 'after v4r4_flx_ad.x'
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
# Save adjoint gradients 

adoutdir=../output
mkdir ${adoutdir}

mv adxx_empmr.0*.* ${adoutdir}
mv adxx_pload.0*.* ${adoutdir}
mv adxx_qnet.0*.* ${adoutdir}
mv adxx_qsw.0*.* ${adoutdir}
mv adxx_saltflux.0*.* ${adoutdir}
mv adxx_spflx.0*.* ${adoutdir}
mv adxx_tauu.0*.* ${adoutdir}
mv adxx_tauv.0*.* ${adoutdir}

mv data.ecco ${adoutdir}
mv data ${adoutdir}
mv adj.info ${adoutdir}

# Save mask
PUBLICDIR/misc_move_files.sh ./ ${adoutdir} '*mask_C'
PUBLICDIR/misc_move_files.sh ./ ${adoutdir} '*mask_S'
PUBLICDIR/misc_move_files.sh ./ ${adoutdir} '*mask_W'
PUBLICDIR/misc_move_files.sh ./ ${adoutdir} '*mask_T'

#=================================
# Delete tape files

/bin/rm -f tapes/tapes*

