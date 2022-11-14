#PBS -S /bin/csh
#PBS -l select=3:ncpus=40:model=sky_ele
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

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
set refdir   = ${tooldir}/emu_pert_ref

set basedir = YOURDIR

#=================================
# Create and cd to directory to run (rundir) under basedir 
set rundir_spec = `cat ${basedir}/pert_xx.str`
set rundir = 'emu_pert_'${rundir_spec}

if ( -d ${basedir}/${rundir}) then
echo 'Directory ' ${basedir}/${rundir} ' exists.'
echo 'Please rename/remove it and re-submit the job.'
exit 1
endif
mkdir ${basedir}/${rundir}
# Ran under temp. Results will be moved to ${rundir} 
mkdir ${basedir}/${rundir}/temp
cd ${basedir}/${rundir}/temp
 
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
/bin/rm -f data.diagnostics 
/bin/rm -f data.pkg
/bin/rm -f data.ecco

if ( -f ${basedir}/data  ) then 
/bin/rm -f data
cp -p ${basedir}/data .
else
ln -s ${emudir}/data .
endif
ln -s ${emudir}/data.diagnostics .
ln -s ${emudir}/data.pkg .
ln -s ${emudir}/data.ecco_pert data.ecco

#=================================
# Perturb (change) control file by pert_xx.f
# Perturbation specified in pert_xx.nml, created by 
# mk_pert_nml.f or equivalent.

ln -s ${emudir}/pert_xx.x .
cp ${basedir}/pert_xx.nml .

pert_xx.x ${inputdir}

#=================================
# Run flux-forced V4r4
python mkdir_subdir_diags.py

ln -s ${tooldir}/build/mitgcmuv .
mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./mitgcmuv

#=================================
# If this is not a reference run, 
# compute gradient (weighted difference from the reference run).

if ( ${rundir_spec} != 'ref') then

ln -s ${emudir}/pert_grad.x .

pert_grad.x ${refdir}

# Move result to parent directory
mv pert_result ..

endif
