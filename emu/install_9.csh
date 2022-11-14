# 9) Derive adjoint of MITgcm by TAF and compile (generates executable
#    "mitgcmuv_ad"). This step requires a license for TAF. Skip if
#    Adjoint Tool will not be used.

mkdir build_ad
cd build_ad
 ../../../../tools/genmake2 -mods=../code -optfile=../code/linux_amd64_ifort+mpi_ice_nas -mpi
make depend
make adtaf
make adall
cd ..
