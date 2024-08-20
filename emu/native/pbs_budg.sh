#PBS -S /bin/bash
#PBS -l select=1:ncpus=40:model=sky_ele
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#PBS -q devel

umask 022

#=================================
# PBS script for V4r4 Budget Tool (native)
#=================================

set -e  # Exit immediately if any command fails

#=================================
# Set program specific parameters 
emu_dir=EMU_DIR
emu_input_dir=EMU_INPUT_DIR

rundir=YOURDIR

source_dir=SOURCEDIR

#=================================
# cd to directory to run rundir
cd ${rundir}

# Do parallel do_budg_flx calculation
echo "Running do_budg.x ... "
ln -sf ${emu_dir}/emu/exe/do_budg.x .
b_ncpus=26
seq $b_ncpus | parallel -j $b_ncpus -u --joblog conv.log "echo {} | ./do_budg.x ${emu_input_dir} ${source_dir} ${b_ncpus} {}"
echo "Completed do_budg.x successfully ... " 

# Combine results and do time-integration of tendency 
echo "Running do_budg_flx_combine.x ... "
ln -sf ${emu_dir}/emu/exe/do_budg_flx_combine.x .
./do_budg_flx_combine.x
mkdir parallel
mv *budg*_0* parallel
echo "Completed do_budg_flx_combine.x successfully ... " 

#=================================
# Move result to output dirctory 
mkdir ../output

mv data.ecco  ../output
mv budg.info ../output
mv emu_budg.*  ../output

# Save mask
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_C'
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_S'
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_W'


