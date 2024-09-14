#!/bin/bash -e 

umask 022

#====================================
# Obtain ad_input_code.f for TAF 
#====================================

#echo " "
#echo "Creating ad_taf_output.f for EMU (singularity) ... "
#echo " "

# ----------------------------------------

return_dir=$PWD

# Make directory for executables
exedir=$1
echo "ad_input ad_output in directory: " ${exedir}

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

# End step 0) 
else
    cd WORKDIR/MITgcm/V4r4/flux-forced
fi 

# 11) Derive adjoint of MITgcm by TAF and compile (generates executable
#    "mitgcmuv_ad"). This step requires a license for TAF. Skip if
#    Adjoint Tool will not be used.

echo " " 
echo "COMPILING V4r4 ADJOINT ----------------------------------------------------"
echo " "
if [ $new_compilation -eq 0 ]; then 
    mkdir build_ad
    cd build_ad
    ../../../tools/genmake2 -mods=../code -optfile=../../../tools/build_options/linux_amd64_gfortran -mpi
    sed -i '/^FFLAGS/s/$/ -fallow-argument-mismatch/' Makefile
    make depend
else
    cd build_ad
    make clean
fi 
cp -f ${exedir}/ad_input_code.f .
make adtafonly
cp ad_taf_output.f ${exedir}
cd $return_dir
#
#
