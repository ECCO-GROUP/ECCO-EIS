#!/bin/bash -e 

#=================================
# Shell script for testing Open MPI 
# (see EMU's install_openmpi.sh) 
# using hello.x inside EMU singularity image 
#=================================

echo " "
echo "************************************"
echo "Testing Open MPI with hello.x (singularity) "
echo "************************************"
echo " "

#=================================
# Set program specific parameters 
nprocs=12 
singularity_image=SINGULARITY_IMAGE
native_mpiexec=NATIVE_MPIEXEC

#=================================
# Run hello.x that's inside singularity image

${native_mpiexec} -np ${nprocs} \
    singularity exec -e --bind .:/inside_out ${singularity_image} /opt/hello.x 

echo " "
echo "************************************"
echo "When successful, you should see 12 instances above of the following;" 
echo '   Process  ** says "Hello, world!" ' 
echo 'where ** is 0 to 11.'
echo "************************************"
echo " "



