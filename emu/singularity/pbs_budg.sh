#PBS -S /bin/bash
#PBS -l select=1:ncpus=40:model=sky_ele
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#PBS -q devel

umask 022

#=================================
# PBS script for V4r4 Budget Tool (singularity)
#=================================

set -e  # Exit immediately if any command fails

#=================================
# Set program specific parameters 
nprocs=EMU_NPROC
emu_input_dir=EMU_INPUT_DIR
singularity_image=SINGULARITY_IMAGE
native_mpiexec=NATIVE_MPIEXEC

rundir=YOURDIR

source_dir=SOURCEDIR

#=================================
# cd to directory to run rundir
cd ${rundir}

# Initialize my_commands.sh for Singularity image
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# Do parallel do_budg_flx calculation
echo 'echo "Running do_budg.x ... " '          >> my_commands.sh
echo 'ln -sf ${emu_dir}/emu/exe/do_budg.x . '   >> my_commands.sh
echo 'b_ncpus=26 '                             >> my_commands.sh
echo 'seq $b_ncpus | parallel -j $b_ncpus -u --joblog conv.log "echo {} | ./do_budg.x /emu_input_dir /inside_alt ${b_ncpus} {}" '  >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     --bind ${source_dir}:/inside_alt:ro ${singularity_image} /inside_out/my_commands.sh

echo "Completed do_budg.x successfully ... " 

# Initialize my_commands.sh for Singularity image
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# Combine results and do time-integration of tendency 
echo 'echo "Running do_budg_flx_combine.x ... " '        >> my_commands.sh
echo 'ln -sf ${emu_dir}/emu/exe/do_budg_flx_combine.x . ' >> my_commands.sh
echo './do_budg_flx_combine.x '                          >> my_commands.sh
echo 'mkdir parallel '                                   >> my_commands.sh
echo 'mv *budg*_0* parallel '                            >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     --bind ${source_dir}:/inside_alt:ro ${singularity_image} /inside_out/my_commands.sh

echo "Completed do_budg_flx_combine.x successfully ... " 

#=================================
# Move result to output dirctory 

# -------
# Replace /inside_alt in budg.info with actual directory name
sed -i "s| /inside_alt| ${source_dir}|g" budg.info 

mkdir ../output

mv data.ecco  ../output
mv budg.info ../output
mv emu_budg.*  ../output

# Save mask
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_C'
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_S'
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_W'


