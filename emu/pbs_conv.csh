#PBS -S /bin/csh
#PBS -l select=3:ncpus=40:model=sky_ele
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#PBS -q devel

#=================================
# Shell script for V4r4 Convolution Tool
#=================================

#=================================
# Set running environment 
limit stacksize unlimited

module purge
module load comp-intel/2020.4.304 
module load mpi-hpe/mpt
module load hdf4/4.2.12 
module load hdf5/1.8.18_mpt
module load netcdf/4.4.1.1_mpt
module load python3/3.9.12
module list

setenv LD_LIBRARY_PATH ${LD_LIBRARY_PATH}
setenv FORT_BUFFERED 1
setenv MPI_BUFS_PER_PROC 128
setenv MPI_DISPLAY_SETTINGS

#=================================
# Set program specific pafameters 
set tooldir  = SETUPDIR
set emudir  = ${tooldir}/emu

set rundir = YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}
 
#=================================
# Run do_conv.x in parallel for all 8 controls
ln -s ${emudir}/do_conv.x .
seq 8 | parallel -j 8 -u --joblog conv.log "echo {} | do_conv.x" 

#=================================
# Move result to output dirctory 
mkdir ../output

mv conv.info ../output
mv conv.out  ../output
mv istep_*.data ../output
mv recon1d_*.data ../output
mv recon2d_*.data ../output

