#!/bin/bash -e 
#
#=================================
# Compile Open MPI for use with EMU Singularity image 
# (Same Open MPI as what's in the image created outside for compatibility.) 
#
# Same as emu_openmpi_install.sh but for pbs_emu_openmpi_setup.sh.
# (Command 'wget' in emu_openmpi_install.sh is replaced by 'ssh pfe wget'
# in this file.) 
#=================================

umask 022

# Record the start time
start_time=$(date +%s)

#=================================
# Install OpenMPI for EMU (singularity)
#=================================

echo ""
echo "Installing OpenMPI for EMU (singularity) ... "
#echo ""
#echo "Enter directory name for installing OpenMPI ... (OMPI_DIR)?"
#read ompi_dir
ompi_dir=NATIVE_OMPI

if [[ -d ${ompi_dir} ]] ; then
    echo "Files will be created in "${ompi_dir}
else
    echo "Creating "${ompi_dir}
    mkdir ${ompi_dir}
fi

current_dir=$PWD
cd ${ompi_dir}
mkdir ompi_tmp
cd ompi_tmp

# OpenMPI -------------------------------------------------------
    export OMPI_DIR=${ompi_dir}
    export OMPI_VERSION=4.1.5
    export OMPI_URL="https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-$OMPI_VERSION.tar.bz2"
# Download
    ssh pfe wget -O "${ompi_dir}/ompi_tmp/openmpi-${OMPI_VERSION}.tar.bz2" $OMPI_URL
    tar -xjf ./openmpi-$OMPI_VERSION.tar.bz2
# Compile and install
    cd ${OMPI_DIR}/ompi_tmp/openmpi-$OMPI_VERSION && ./configure --prefix=$OMPI_DIR && make install
    rm -rf ${ompi_dir}/ompi_tmp

# ---------------------------------------
# End script
cd ${current_dir}

# Record the end time
end_time=$(date +%s)

# Calculate the difference from start_time
elapsed_time=$((end_time - start_time))

hours=$((elapsed_time / 3600))
minutes=$(((elapsed_time % 3600) / 60))
seconds=$((elapsed_time % 60))

echo " "
echo "Sussessfully created OpenMPI by emu_install_openmpi.sh" 
printf "Elapsed time: %d:%02d:%02d\n" $hours $minutes $seconds
echo "emu_install_openmpi.sh execution complete. $(date)"
echo " "

