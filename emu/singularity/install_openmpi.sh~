#!/bin/bash -e 
#
# Compile Open MPI for use with EMU Singularity image 
# (Same Open MPI as what's in the image created outside for compatibility.) 
#

umask 022

echo ""
echo "Installing Open MPI for EMU (singularity) ... "
echo ""
echo "Enter directory name for installing Open MPI ... (OMPI_DIR)?"
read ompi_dir
if [[ -d ${ompi_dir} ]] ; then
    echo "Files will be created in "${ompi_dir}
else
    echo "Creating "${ompi_dir}
    mkdir ${ompi_dir}
fi

current_dir=$PWD
cd ${ompi_dir}
mkdir ichiro_tmp
cd ichiro_tmp

# OpenMPI -------------------------------------------------------
    export OMPI_DIR=${ompi_dir}
    export OMPI_VERSION=4.1.5
    export OMPI_URL="https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-$OMPI_VERSION.tar.bz2"
# Download
    wget -O openmpi-$OMPI_VERSION.tar.bz2 $OMPI_URL
    tar -xjf ./openmpi-$OMPI_VERSION.tar.bz2
# Compile and install
    cd ${OMPI_DIR}/ichiro_tmp/openmpi-$OMPI_VERSION && ./configure --prefix=$OMPI_DIR && make install
    rm -rf ${ompi_dir}/ichiro_tmp

# End script
cd ${current_dir}
echo " "
echo "Sussessfully created Open MPI" 
echo "install_openmpi.sh execution complete. $(date)"


