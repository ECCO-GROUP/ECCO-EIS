#PBS -S /bin/bash
#CHOOSE_NODES
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

umask 022

#=================================
# PBS script for V4r4 Tracer Tool (native)
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
# Link tracer executable 

BANDAID_PICKUP 
ln -sf ${emu_input_dir}/forcing/other/flux-forced/STATE_DIR/* .
ln -sf ${emu_dir}/emu/exe/nproc/${nprocs}/FRW_OR_ADJ .
ln -sf ${emu_dir}/emu/emu_input/nproc/${nprocs}/data.exch2 .

# Run tracer executable 
mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./FRW_OR_ADJ

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
#REORDER_PTRACER ${emu_dir}/emu/emu_input/scripts/rename_offline_adj_diags_fn.sh YES

