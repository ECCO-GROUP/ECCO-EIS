#PBS -S /bin/bash 
#PBS -l select=3:ncpus=40:model=sky_ele
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

#=================================
# Shell script for V4r4 Tracer Tool (native)
#=================================

##=================================
# Set running environment 
ulimit -s unlimited

module purge
module load comp-intel/2020.4.304 
module load mpi-hpe/mpt
module load hdf4/4.2.12 
module load hdf5/1.8.18_mpt
module load netcdf/4.4.1.1_mpt
module load python3/3.9.12
module list

#=================================
# Set program specific parameters 
nprocs=96
native_setup=NATIVE_SETUP

rundir=YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}
 
# ================================
# Link tracer executable 

BANDAID_PICKUP 
ln -s ${native_setup}/forcing/other/flux-forced/STATE_DIR/* .
ln -s ${native_setup}/FRW_OR_ADJ/mitgcmuv .

# Run tracer executable 
mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./mitgcmuv

#=================================
# Move result to output dirctory 
mv diags ../output
mv pbs_trc.sh ../output
mv trc.info ../output

