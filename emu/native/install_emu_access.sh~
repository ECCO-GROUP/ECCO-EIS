#!/bin/bash -e 
#
# Install shell scripts to run EMU
#

umask 022

echo ""
echo "Installing EMU scripts for running EMU Tools (native) ... "

# ----------------------------------------
# Choose and create destination directory 
echo ""
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
# ID path to EMU tools

# Get the full path of this script
script_path=$(readlink -f "$0")

# Get the directory containing the script (native)
scriptdir=$(dirname "$script_path")

# Get the parent directory of scriptdir (emu) 
basedir=$(dirname "$scriptdir")

# Get the parent directory of basedir (emu) 
emu_dir=$(dirname "$basedir")

# Make sure path is absolute
emu_dir=$(realpath "$emu_dir")

# ----------------------------------------
# Installing scripts
emu_version='native'

cp -p ${emu_dir}/emu/emu*.sh ${useraccessdir}
ln -sf ${useraccessdir}/emu.sh ${useraccessdir}/emu
cp -p ${emu_dir}/emu/README* ${useraccessdir}
cp -p ${emu_dir}/emu/Guide*.pdf ${useraccessdir}
cp -p ${emu_dir}/emu/misc*.sh ${useraccessdir}
cp -p ${emu_dir}/emu/misc*.txt ${useraccessdir}

cp -p -f ${emu_dir}/emu/${emu_version}/emu_* ${useraccessdir}
cp -p -f ${emu_dir}/emu/${emu_version}/pbs_* ${useraccessdir}
cp -p -f ${emu_dir}/emu/${emu_version}/misc_* ${useraccessdir}

# ----------------------------------------
# Setup emu environment variables
currentdir=$PWD
cd ${useraccessdir}

sed -i -e "s|BASE_DIR|${emu_dir}|g" ./emu_env.sh

./emu_env.sh

cd ${currentdir}

# ----------------------------------------
# Finish 
echo ""
echo "Done ... install_emu_access.sh (native)"
echo ""


