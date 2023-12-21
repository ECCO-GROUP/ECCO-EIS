#PBS -S /bin/bash 
#PBS -l select=3:ncpus=40:model=sky_ele
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

#=================================
# Shell script for V4r4 perturbation tool (native)
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
# Set program specific pafameters 
nprocs=96
native_setup=NATIVE_SETUP

rundir=YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}
 
# ================================
# Run flux-forced V4r4 
mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./mitgcmuv

#=================================
# Compute gradient (weighted difference from the reference run).

ln -s ${native_setup}/emu/pert_grad.x .

./pert_grad.x ${native_setup}/emu_pert_ref 

#=================================
# Move result to output dirctory 
mv pert_result ../output
mv pbs_pert.sh ../output
mv pert.info ../output

