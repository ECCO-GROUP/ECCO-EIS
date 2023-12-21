#!/bin/bash
#
# Install shell scripts to run EMU
#

basedir=SETUPDIR

echo ""
echo "Installing EMU scripts for running EMU Tools ... "

# ----------------------------------------
# Choose and create destination directory 
echo ""
echo "Enter destination directory name ... ?"
read useraccessdir

echo "EMU Scripts destination will be "${useraccessdir}
if [ ! -d ${useraccessdir} ]; then
    mkdir ${useraccessdir}
fi

# ----------------------------------------
# Choose between native or singularity version of the scripts 
echo ""
echo "Enter native or singularity ... (1/2)?"
read native_singularity
if [ ${native_singularity} -eq 2 ]; then
    export emu_version='singularity'
    echo "Installing Singularity version ... "
else
    export emu_version='native'
    echo "Installing Native version ... "
fi

# ----------------------------------------
# Installing scripts
cp -p ${basedir}/emu/emu*.*sh ${useraccessdir}
ln -s ${useraccessdir}/emu.sh ${useraccessdir}/emu
cp -p ${basedir}/emu/pbs*.*sh ${useraccessdir}
cp -p ${basedir}/emu/README* ${useraccessdir}
cp -p ${basedir}/emu/Guide*.pdf ${useraccessdir}

cp -p -f ${basedir}/emu/${emu_version}/emu* ${useraccessdir}
cp -p -f ${basedir}/emu/${emu_version}/pbs* ${useraccessdir}

## ----------------------------------------
## Setup emu environment variables
#returndir=$PWD
#
#cd ${useraccessdir}
#
#./emu_env.sh
#
#cd ${returndir}
#
## ----------------------------------------
# Finish 
echo ""
echo "Done ... install_access.sh"
echo "Go to " ${useraccessdir} " and set up EMU environment variables by emu_env.sh ..."
echo ""


