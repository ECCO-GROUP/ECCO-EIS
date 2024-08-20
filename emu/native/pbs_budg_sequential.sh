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

#=================================
# Set program specific parameters 
emu_dir=EMU_DIR
emu_input_dir=EMU_INPUT_DIR

rundir=YOURDIR

source_dir=SOURCEDIR

#=================================
# cd to directory to run rundir
cd ${rundir}

ln -sf ${emu_dir}/emu/exe/do_budg.x .
./do_budg.x ${emu_input_dir} ${source_dir}

#=================================
# Move result to output dirctory 

mkdir ../output

mv data.ecco  ../output
mv budg.info ../output
mv emu_budg.*  ../output



