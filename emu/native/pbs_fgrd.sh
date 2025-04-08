#PBS -S /bin/bash
#CHOOSE_NODES
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

umask 022

#=================================
# PBS script for V4r4 Forward Gradient Tool (native)
#=================================

#=================================
# Set program specific parameters 
nprocs=EMU_NPROC
emu_dir=EMU_DIR
emu_input_dir=EMU_INPUT_DIR

rundir=YOURDIR

##=================================
# Set running environment 
ulimit -s unlimited

# set_modules.sh must be run by source 
source ${emu_dir}/emu/native/set_modules.sh

#=================================
# cd to directory to run rundir
cd ${rundir}
 
# ================================
# Run flux-forced V4r4 
ln -sf ${emu_dir}/emu/exe/nproc/${nprocs}/v4r4_flx.x .
ln -sf ${emu_dir}/emu/emu_input/nproc/${nprocs}/data.exch2 .

mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./v4r4_flx.x

#=================================
# Compute gradient (weighted difference from the reference run).

ln -sf ${emu_dir}/emu/exe/fgrd.x .

./fgrd.x EMU_REF

#=================================
# Move result to output dirctory 
mv ./fgrd_result ../output
mv ./pbs_fgrd.sh ../output
mv ./fgrd_spec.info ../output

