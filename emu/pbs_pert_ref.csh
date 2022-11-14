#PBS -S /bin/csh
#PBS -l select=3:ncpus=40:model=sky_ele
#PBS -l walltime=12:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea

#=================================
# Shell script for V4r4 perturbation tool
#=================================

#=================================
# Set running environment 
limit stacksize unlimited

module purge
module load comp-intel/2020.4.304 
module load mpi-hpe/mpt.2.25
module load hdf4/4.2.12 
module load hdf5/1.8.18_mpt
module load netcdf/4.4.1.1_mpt
module list

setenv LD_LIBRARY_PATH ${LD_LIBRARY_PATH}
setenv FORT_BUFFERED 1
setenv MPI_BUFS_PER_PROC 128
setenv MPI_DISPLAY_SETTINGS

#=================================
# Set program specific pafameters 
set nprocs  = 96
set tooldir  = SETUPDIR
set inputdir = ${tooldir}/forcing
set emudir  = ${tooldir}/emu

#=================================
# Create and cd to directory to run (rundir) under tooldir 
set rundir = 'emu_pert_ref'

if ( -d ${tooldir}/${rundir}) then
echo 'Directory ' ${tooldir}/${rundir} ' exists.'
echo 'Please rename/remove it and re-submit the job.'
exit
endif
mkdir ${tooldir}/${rundir}
cd ${tooldir}/${rundir}
 
#=================================
# Link all files needed to run flux-forced V4r4 
ln -s ${tooldir}/namelist/* . 
ln -s ${inputdir}/other/flux-forced/*/* .

ln -s ${inputdir}/input_init/error_weight/ctrl_weight/* .
ln -s ${inputdir}/input_init/* .
ln -s ${inputdir}/input_init/tools/* .

#=================================
# Over-ride runtime namelist files. 
# (integration duration and output precision) 
/bin/rm -f data
/bin/rm -f data.diagnostics 
/bin/rm -f data.pkg
/bin/rm -f data.ecco

ln -s ${emudir}/data .
ln -s ${emudir}/data.diagnostics .
ln -s ${emudir}/data.pkg .
ln -s ${emudir}/data.ecco_pert data.ecco

#=================================
# Run flux-forced V4r4
python mkdir_subdir_diags.py

ln -s ${tooldir}/build/mitgcmuv .
mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./mitgcmuv

