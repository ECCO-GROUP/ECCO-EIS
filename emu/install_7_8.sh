# 7) Load module for compilation. 
module purge
module load comp-intel/2020.4.304
module load mpi-hpe/mpt.2.25
module load hdf4/4.2.12
module load hdf5/1.8.18_mpt
module load netcdf/4.4.1.1_mpt
module list

# 8) Compile MITgcm program (generates executable "mitgcmuv").
mkdir build
cd build
../../../../tools/genmake2 -mods=../code -optfile=../../../../tools/build_options/linux_amd64_ifort+mpi_ice_nas -mpi
make depend
make all
cd ..
