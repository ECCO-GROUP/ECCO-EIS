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
ln -s ${tooldir}/namelist/* . 
ln -s ${inputdir}/other/flux-forced/*/* .

ln -s ${inputdir}/input_init/error_weight/ctrl_weight/* .
ln -s ${inputdir}/input_init/* .
ln -s ${inputdir}/input_init/tools/* .

#=================================
# Over-ride runtime namelist files. 
# (integration duration and output precision) 

if ( -f data_adj  ) then 
mv -f data_adj data 
endif

if ( -f data.ecco_adj ) then 
mv -f data.ecco_adj data.ecco
endif

#=================================
# Run flux-forced V4r4 adjoint 
python mkdir_subdir_diags.py

ln -s ${tooldir}/build_ad/mitgcmuv_ad .
mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./mitgcmuv_ad

#=================================
# Save adjoint gradients 

set adoutdir = ../output
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

