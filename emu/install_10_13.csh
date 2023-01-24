# 10) Compile off-line passive tracer version of MITgcm (generates
#    executable "mitgcmuv" in directory build_trc)
mkdir build_trc
cd build_trc
/bin/cp -f ../code_offline_ptracer/OFFLINE_OPTIONS.h.fwd ../code_offline_ptracer/OFFLINE_OPTIONS.h 
../../../../tools/genmake2 -mods=../code_offline_ptracer -optfile=../../../../tools/build_options/linux_amd64_ifort+mpi_ice_nas -mpi
make depend
make all
cd ..

#11) Compile off-line adjoint passive tracer version of MITgcm
#    (generates executable "mitgcmuv" in directory build_trc_adj)
mkdir build_trc_adj
cd build_trc_adj
/bin/cp -f ../code_offline_ptracer/OFFLINE_OPTIONS.h.adj ../code_offline_ptracer/OFFLINE_OPTIONS.h 
../../../../tools/genmake2 -mods=../code_offline_ptracer -optfile=../../../../tools/build_options/linux_amd64_ifort+mpi_ice_nas -mpi
make depend
make all
cd ..

#12) Prepare circulation fields for off-line adjoint passive tracer
#    version of MITgcm
cd forcing/other/flux-forced
cp -p ../../../scripts/* .
sh -xv reverseintime_all.sh
cd ../../..

# 13) Download EMU scripts and programs and compile.
#
git clone https://github.com/ECCO-GROUP/ECCO-EIS.git 
mv ECCO-EIS/emu .
rm -rf ECCO-EIS
cd emu
make all
