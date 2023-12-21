#PBS -S /bin/bash 
#PBS -l select=3:ncpus=40:model=sky_ele
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

#=================================
# Shell script for V4r4 Adjoint Tool (native)
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
# Run flux-forced V4r4 adjoint 
mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./mitgcmuv_ad

#=================================
# Save adjoint gradients 

adoutdir=../output
mkdir ${adoutdir}

cp -p adxx_empmr.0*.* ${adoutdir}
cp -p adxx_pload.0*.* ${adoutdir}
cp -p adxx_qnet.0*.* ${adoutdir}
cp -p adxx_qsw.0*.* ${adoutdir}
cp -p adxx_saltflux.0*.* ${adoutdir}
cp -p adxx_spflx.0*.* ${adoutdir}
cp -p adxx_tauu.0*.* ${adoutdir}
cp -p adxx_tauv.0*.* ${adoutdir}

cp -p `realpath objf_*_mask*` ${adoutdir}
cp -p data.ecco ${adoutdir}
cp -p data ${adoutdir}
cp -p adj.info ${adoutdir}
