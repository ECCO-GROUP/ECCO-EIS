#PBS -S /bin/bash 
#PBS -l select=3:ncpus=40:model=sky_ele
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

#=================================
# Shell script for V4r4 perturbation tool (singularity)
#=================================

##=================================
## Set running environment 
#ulimit -s unlimited
#
#export FORT_BUFFERED=1
#export MPI_BUFS_PER_PROC=128
#export MPI_DISPLAY_SETTINGS=""

#=================================
# Set program specific parameters 
nprocs=96
native_setup=NATIVE_SETUP

rundir=YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}
 
# ID nodes for MPI 
/bin/rm -f my_machine_file
cat  $PBS_NODEFILE > my_machine_file
sed -i '1,24d' my_machine_file

native_singularity=NATIVE_SINGULARITY
singularity_image=SINGULARITY_IMAGE
native_mpiexec=NATIVE_MPIEXEC

# build Singularity script 
/bin/rm -f my_commands.sh 
echo '#!/bin/bash'     > my_commands.sh & chmod +x my_commands.sh 
echo 'cd /inside_out' >> my_commands.sh
echo './mitgcmuv'     >> my_commands.sh

${native_mpiexec} -np ${nprocs} --hostfile ./my_machine_file \
    ${native_singularity} exec --bind ${native_setup}:/emu_outside:ro --bind ${rundir}:/inside_out ${singularity_image} /inside_out/my_commands.sh

#=================================
# Compute gradient (weighted difference from the reference run).

# build Singularity script 
/bin/rm -f my_commands.sh
echo '#!/bin/bash'     > my_commands.sh & chmod +x my_commands.sh 
echo 'cd /inside_out'                        >> my_commands.sh
echo 'ln -s ${basedir}/emu/pert_grad.x .'    >> my_commands.sh
echo 'pert_grad.x /emu_outside/emu_pert_ref' >> my_commands.sh

${native_singularity} exec --bind ${native_setup}:/emu_outside:ro --bind ${rundir}:/inside_out ${singularity_image} /inside_out/my_commands.sh 

#=================================
# Move result to output dirctory 
mv pert_result ../output
mv pbs_pert.sh ../output
mv pert.info ../output

