#PBS -S /bin/bash 
#PBS -l select=1:ncpus=40:model=sky_ele
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#PBS -q devel

umask 022

#=================================
# Shell script for V4r4 Convolution Tool (singularity)
# (Runs Parallel outside Singularity) 
#=================================

#=================================
# Set program specific parameters 
singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR

rundir=YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}

#=================================
# Modify conv.out for singularity version of EMU
cp -f conv.out conv.out_orig

# Read the first two lines from the file
read -r f_ctrl < conv.out
read -r f_adxx < <(sed -n '2p' conv.out)

# Replace the first two lines in the file with the specified strings
sed -i '1s|.*|/emu_input_dir|' conv.out
sed -i '2s|.*|/inside_alt|' conv.out

echo " ************ "
echo " ctrl read from = ${f_ctrl}  "
echo "    (aliased below to /emu_input_dir for singularity) "
echo " adxx read from = ${f_adxx}  "
echo "    (aliased below to /inside_alt for singularity) "
echo " ************ "

#=================================
# build Singularity script 
/bin/rm -f my_commands.sh 
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out '  >> my_commands.sh
echo 'ln -sf ${emu_dir}/emu/exe/do_conv.x .' >> my_commands.sh 
echo 'b_ncpus=8 '                             >> my_commands.sh
echo 'seq $b_ncpus | parallel -j $b_ncpus -u --joblog conv.log "echo {} | ./do_conv.x {}" '  >> my_commands.sh

echo 'before do_conv.x'
date
# Capture the start time
start_time=$(date +%s)

singularity exec --bind ${f_ctrl}:/emu_input_dir:ro --bind ${f_adxx}:/inside_alt:ro \
     --bind ${PWD}:/inside_out ${singularity_image} /inside_out/my_commands.sh

# Capture the end time
end_time=$(date +%s)
echo 'after do_conv.x'
date
# Calculate the duration
duration=$((end_time - start_time))
# Print the duration in seconds
echo "Time taken: $duration seconds"


#=================================
# Move result to output dirctory 
mkdir ../output

mv conv.info ../output
mv conv.out_orig  ../output/conv.out
mv istep_*.data ../output
mv recon1d_*.data ../output
mv recon2d_*.data ../output

