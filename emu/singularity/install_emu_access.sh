#!/bin/bash -e 
#
# Install shell scripts to run EMU
#

umask 022

echo ""
echo "Installing EMU scripts for running EMU Tools (singularity) ... "

# ----------------------------------------
# Choose and create destination directory 
echo 
echo "Enter destination directory name ... ?"
read useraccessdir

echo 
echo "EMU Scripts destination will be "${useraccessdir}
if [ ! -d ${useraccessdir} ]; then
    mkdir ${useraccessdir}
fi

# Make sure path is absolute
useraccessdir=$(realpath "$useraccessdir")

# ----------------------------------------
# ID path to EMU Singularity image (sif file).

# ..................
# Look for sif in default location

echo 
echo "Enter full path to EMU singularity image ... ?"
read singularity_image

# check file
if [ ! -e "${singularity_image}" ] || [ ! -x "${singularity_image}" ]; then
    echo 
    echo "Singularity Image File does not exist or is not executable."
    exit 1 
fi    

# Make sure path is absolute
singularity_image=$(realpath "$singularity_image")
emu_dir=$(dirname "$singularity_image")

echo 'image_'${singularity_image}  >> ${useraccessdir}/install_emu_access.singularity

echo 
echo "EMU singularity image: ${singularity_image}"

# ----------------------------------------
# Installing scripts from EMU source files 

currentdir=$PWD
cd ${useraccessdir}

cp -p ${emu_dir}/emu/emu*.sh .
cp -p ${emu_dir}/emu/README*  .
cp -p ${emu_dir}/emu/Guide*.pdf .
cp -p ${emu_dir}/emu/misc*.sh .
cp -p ${emu_dir}/emu/misc*.txt .
emu_version="singularity" 
cp -p -f ${emu_dir}/emu/${emu_version}/emu_* .
cp -p -f ${emu_dir}/emu/${emu_version}/pbs_* .
cp -p -f ${emu_dir}/emu/${emu_version}/misc_* .

ln -sf ${useraccessdir}/emu.sh ${useraccessdir}/emu

# copy emu_plot
cp -p -f -r ${emu_dir}/emu/emu_plot/* .

# ----------------------------------------
# Setup emu environment variables

./emu_env.sh

cd ${currentdir}

# ----------------------------------------
# Finish 

echo 
echo 
echo "install_emu_access.sh (singularity) execution complete. $(date)"
echo 
echo 
