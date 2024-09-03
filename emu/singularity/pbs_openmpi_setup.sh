#PBS -S /bin/bash
#PBS -l select=1:ncpus=40:model=sky_ele
#PBS -l walltime=1:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#PBS -k od
#PBS -q devel

umask 022

#=================================
# PBS script to run emu_openmpi_setup.sh in batch mode 
#=================================

set -e  # Exit immediately if any command fails

#=================================
# Set program specific parameters 

emu_userinterface_dir=PUBLICDIR

#=================================
# cd to setup_dir and run emu_openmpi_setup.sh
cd ${emu_userinterface_dir}

./emu_openmpi_install_4batch.sh




