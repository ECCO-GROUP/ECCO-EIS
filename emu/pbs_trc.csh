#PBS -S /bin/csh
#PBS -l select=3:ncpus=40:model=sky_ele
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

#=================================
# Shell script for V4r4 Tracer Tool
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
set nprocs  = 96
set tooldir  = SETUPDIR
set inputdir = ${tooldir}/forcing
set emudir  = ${tooldir}/emu

set rundir = YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}
 
#=================================
# Link all files needed to run flux-forced V4r4 
ln -s ${tooldir}/namelist_offline_ptracer/* . 

set state = STATE_DIR
ln -s ${inputdir}/other/flux-forced/${state}/* .
#ln -s ${inputdir}/other/flux-forced/forcing_weekly/* .
#ln -s ${inputdir}/other/flux-forced/*/* .

ln -s ${inputdir}/input_init/error_weight/ctrl_weight/* .
ln -s ${inputdir}/input_init/* .
ln -s ${inputdir}/input_init/tools/* .

# BANDAID_PICKUP

#=================================
# Over-ride runtime namelist files. 
# (data_trc integration time set by trc.f)
mv -f data_trc data

#=================================
# Run flux-forced V4r4
python mkdir_subdir_diags.py

set trc_drct = FRW_OR_ADJ

ln -s ${tooldir}/${trc_drct}/mitgcmuv .
mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./mitgcmuv

#=================================
# Move result to output dirctory 
mv diags ../output
mv pbs_trc.csh ../output
mv trc.info ../output

