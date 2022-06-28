#PBS -S /bin/csh
#PBS -l select=3:ncpus=40:model=sky_ele
#PBS -l walltime=2:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#PBS -q devel

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
set basedir  = /nobackupp17/ifukumor/WORK3/MITgcm/ECCOV4/release4/flux-forced
set inputdir = ${basedir}/forcing
set pertdir  = ${basedir}/tool_pert
set refdir   = ${basedir}/run_pert_ref

#=================================
# Create and cd to directory to run (rundir) under basedir 
#set rundir = run_`date +"%Y.%m.%d-%H:%M:%S"`
set rundir_spec = `cat ${pertdir}/pert_xx.str`
set rundir = 'run_pert_'${rundir_spec}

if ( -d ${basedir}/${rundir}) then
echo 'Directory ' ${basedir}/${rundir} ' exists.'
echo 'Please rename/remove it and re-submit the job.'
exit 1
endif
mkdir ${basedir}/${rundir}
cd ${basedir}/${rundir}

#=================================
# Link all files needed to run flux-forced V4r4 
ln -s ${basedir}/namelist/* . 
ln -s ${inputdir}/other/flux-forced/*/* .

ln -s ${inputdir}/input_init/error_weight/ctrl_weight/* .
ln -s ${inputdir}/input_init/* .
ln -s ${inputdir}/input_init/tools/* .

#=================================
# Over-ride runtime parameter 
# (integration duration and output precision) 
/bin/rm -f data
/bin/rm -f data.diagnostics 
/bin/rm -f data.pkg
ln -s ${pertdir}/data .
ln -s ${pertdir}/data.diagnostics .
ln -s ${pertdir}/data.pkg .

#=================================
# Perturb (change) control file by pert_xx.f
# Perturbation specified in pert_xx.nml, created by 
# mk_pert_nml.f or equivalent.

#ln -s ${pertdir}/pert_xx.f .
#ln -s ${pertdir}/pert_xx.nml .
#
#f95 -fconvert=swap -o pert_xx.x pert_xx.f

ln -s ${pertdir}/pert_xx.x .
cp ${pertdir}/pert_xx.nml .

pert_xx.x ${inputdir}

#=================================
# Run flux-forced V4r4
python mkdir_subdir_diags.py

cp -p ../build/mitgcmuv .
mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./mitgcmuv

#=================================
# If this is not a reference run, 
# compute difference from the reference run

if ( ${rundir_spec} != 'ref') then

#ln -s ${pertdir}/pert_result.f .
#f95 -fconvert=swap -o pert_result.x pert_result.f
ln -s ${pertdir}/pert_result.x .

pert_result.x ${refdir}

endif
