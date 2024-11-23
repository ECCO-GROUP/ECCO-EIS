#!/bin/bash -e 

umask 022

#====================================
# Compile models employed by EMU for select nproc 
#====================================

echo " "
echo "Compiling MITgcm for EMU (native) ... "
echo " "

# ----------------------------------------
# ID path to EMU tools

# Get the full path name of this script (located in emu/native) 
script_path=$(readlink -f "$0")

# Get the directory containing the script (full path to emu/native)
nativedir=$(dirname "$script_path")

# Get the parent directory of emudir (full path to parent directory of emu)
emu_dir=$(dirname "$(dirname "$nativedir")")

cd $emu_dir

# ----------------------------------------
# Specify nproc
echo "Choose number of CPU cores (nproc) to use for MITgcm employed by EMU." 
echo "Choose among the following nproc ... "
echo " "
echo "   13"
echo "   36"
echo "   48"
echo "   68"
echo "   72"
echo "   96"
echo "  192"
echo "  360"
echo " "
echo "Enter choice for nproc ... ?"

read emu_nproc

if [ "$emu_nproc" -ne  13 ] && \
   [ "$emu_nproc" -ne  36 ] && \
   [ "$emu_nproc" -ne  48 ] && \
   [ "$emu_nproc" -ne  68 ] && \
   [ "$emu_nproc" -ne  72 ] && \
   [ "$emu_nproc" -ne  96 ] && \
   [ "$emu_nproc" -ne 192 ] && \
   [ "$emu_nproc" -ne 360 ]; then 
    echo "Invalid choice for nproc ... " $emu_nproc
    exit 1 
else
    echo "nproc will be ... " $emu_nproc
    echo " "
fi

# Make directory for executables
exedir=${emu_dir}/emu/exe/nproc/${emu_nproc}
if [ ! -d "$exedir" ]; then
    mkdir -p $exedir
fi
exedir=$(readlink -f "$exedir")

# 0) Test if WORKDIR already exists. If so, skip downloading.
new_compilation=1
if [ ! -d WORKDIR ]; then
    new_compilation=0

# 1) Make temporary directory for code download and compilation
    mkdir WORKDIR
    cd WORKDIR

# 2) Download MITgcm "checkpoint  66g".
    echo " " 
    echo "Downloading MITgcm -------------------------------------------------------"
    echo " "
    git clone https://github.com/MITgcm/MITgcm.git -b checkpoint66g

# 3) Create and cd to subdirectory V4r4
    cd MITgcm
    mkdir -p V4r4
    cd V4r4

# 4) Download V4 configurations.
    git clone https://github.com/ECCO-GROUP/ECCO-v4-Configurations

# 5) Extract flux-forced configuration of the model.
    mv ECCO-v4-Configurations/ECCOv4\ Release\ 4/flux-forced .
    rm -rf ECCO-v4-Configurations
    cd flux-forced

# 6) Copy to emu_dir flux-forced directories with files needed for emu
    cp -rf namelist ${emu_dir}
    cp -rf namelist_offline_ptracer ${emu_dir}
    cp -rf scripts ${emu_dir}

# End step 0) 
else
    cd WORKDIR/MITgcm/V4r4/flux-forced
fi 

# 7) Load module for compilation. 
source /usr/local/lib/global.profile
source ${nativedir}/set_modules.sh

# 8) Compile off-line passive tracer version of MITgcm (generates
#    executable "mitgcmuv" in directory build_trc)
echo " " 
echo "COMPILING offline tracer model -------------------------------------------"
echo " "
if [ $new_compilation -eq 0 ]; then 
    mkdir build_trc
    cd build_trc
#    ../../../tools/genmake2 -mods=../code_offline_ptracer -optfile=../../../tools/build_options/linux_amd64_ifort+mpi_ice_nas -mpi
    ../../../tools/genmake2 -mods=../code_offline_ptracer -optfile=../code/linux_amd64_ifort+mpi_ice_nas -mpi
    make depend
else
    cd build_trc
    make clean
fi 
/bin/cp -f ../code_offline_ptracer/OFFLINE_OPTIONS.h.fwd ../code_offline_ptracer/OFFLINE_OPTIONS.h 
/bin/rm SIZE.h
ln -sf ${emu_dir}/emu/emu_input/nproc/${emu_nproc}/SIZE.h .
make all
cp mitgcmuv ${exedir}/trc.x
cd ..

# 9) Compile off-line adjoint passive tracer version of MITgcm
#    (generates executable "mitgcmuv" in directory build_trc_adj)
echo " " 
echo "COMPILING offline tracer model ADJOINT -----------------------------------"
echo " "
if [ $new_compilation -eq 0 ]; then 
    mkdir build_trc_ad
    cd build_trc_ad
#    ../../../tools/genmake2 -mods=../code_offline_ptracer -optfile=../../../tools/build_options/linux_amd64_ifort+mpi_ice_nas -mpi
    ../../../tools/genmake2 -mods=../code_offline_ptracer -optfile=../code/linux_amd64_ifort+mpi_ice_nas -mpi
    make depend
else
    cd build_trc_ad
    make clean
fi
/bin/cp -f ../code_offline_ptracer/OFFLINE_OPTIONS.h.adj ../code_offline_ptracer/OFFLINE_OPTIONS.h 
/bin/rm SIZE.h
ln -sf ${emu_dir}/emu/emu_input/nproc/${emu_nproc}/SIZE.h .
make all
cp mitgcmuv ${exedir}/trc_ad.x
cd ..

# 10) Compile MITgcm program (generates executable "mitgcmuv").
echo " " 
echo "COMPILING V4r4 ------------------------------------------------------------"
echo " "
if [ $new_compilation -eq 0 ]; then 
    mkdir build
    cd build
#    ../../../tools/genmake2 -mods=../code -optfile=../../../tools/build_options/linux_amd64_ifort+mpi_ice_nas -mpi
    ../../../tools/genmake2 -mods=../code -optfile=../code/linux_amd64_ifort+mpi_ice_nas -mpi
    make depend
else
    cd build
    make clean
fi 
/bin/rm SIZE.h
ln -sf ${emu_dir}/emu/emu_input/nproc/${emu_nproc}/SIZE.h .
make all
cp mitgcmuv ${exedir}/v4r4_flx.x
cd ..

# 11) Derive adjoint of MITgcm by TAF and compile (generates executable
#    "mitgcmuv_ad"). This step requires a license for TAF. Skip if
#    Adjoint Tool will not be used.

echo " " 
echo "COMPILING V4r4 ADJOINT ----------------------------------------------------"
echo " "

# Check staf 
if command -v staf &> /dev/null; then

    if [ $new_compilation -eq 0 ]; then 
	mkdir build_ad
	cd build_ad
	../../../tools/genmake2 -mods=../code -optfile=../code/linux_amd64_ifort+mpi_ice_nas -mpi
	make depend
    else
	cd build_ad
	make clean
    fi 
    /bin/rm SIZE.h
    ln -sf ${emu_dir}/emu/emu_input/nproc/${emu_nproc}/SIZE.h .
    make adtaf
    make adall
    cp mitgcmuv_ad ${exedir}/v4r4_flx_ad.x
    cd ..

else
    echo "staf command does not exist."
    echo "Skipping adjoint compilation."
    exit 1
fi
#
#

# ----------------------------------------
# Finish 
echo 
echo "emu_compile_mdl.sh (native) execution complete. $(date)"

