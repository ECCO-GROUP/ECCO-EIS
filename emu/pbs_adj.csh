#PBS -S /bin/csh
#PBS -l select=5:ncpus=40:model=sky_ele
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

#=================================
# Shell script for V4r4 Adjoint Tool
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

set basedir = YOURDIR

#=================================
# Create and cd to directory to run (rundir) under basedir 
set rundir_spec = `cat ${basedir}/adj.str`
set rundir = 'emu_adj_'${rundir_spec}

if ( -d ${basedir}/${rundir}) then
echo 'Directory ' ${basedir}/${rundir} ' exists.'
echo 'Please rename/remove it and re-submit the job.'
exit 1
endif
mkdir ${basedir}/${rundir}
# Run under directory temp. Results will be moved to ${rundir} 
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

if ( -f ${basedir}/data  ) then 
/bin/rm -f data
cp -p ${basedir}/data .
endif

if ( -f ${basedir}/data.ecco  ) then 
/bin/rm -f data.ecco
cp -p ${basedir}/data.ecco .
endif

#=================================
# Copy masks 
ln -s ${basedir}/objf_*_mask* .

#=================================
# Run flux-forced V4r4 adjoint 
python mkdir_subdir_diags.py

ln -s ${tooldir}/build_ad/mitgcmuv_ad .
mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./mitgcmuv_ad

#=================================
# Save adjoint gradients 

set adoutdir = adj_result
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
cp -p ${basedir}/adj.info ${adoutdir}

mv ${adoutdir} ..

endif
