#PBS -S /bin/bash 
#PBS -l select=3:ncpus=40:model=sky_ele
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

#=================================
# Shell script for V4r4 Tracer Tool
#=================================

#=================================
# Set program specific pafameters 
nprocs=96
native_setup=NATIVE_SETUP
native_singularity=NATIVE_SINGULARITY
singularity_image=SINGULARITY_IMAGE
native_mpiexec=NATIVE_MPIEXEC

rundir=YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}
 
#=================================
# ID nodes for MPI 
/bin/rm -f my_machine_file
cat  $PBS_NODEFILE > my_machine_file
sort -u my_machine_file > my_machine_file_uniq

## Test if Singularity is available 
#while IFS= read -r RECORD; do  # make sure node has Singularity 
#    ssh_output=$(ssh "$RECORD" "ls -ld ${native_singularity}" 2>&1)  # Capture both stdout and stderr
#    if [[ $ssh_output == *"No such file or directory"* ]]; then
#        echo "Error: Singularity not available for $RECORD"
#        exit 1  # Abort the PBS job
#    fi
#done < "my_machine_file_uniq" 

## Remove excess cores from top of the list 
#num_core=$(wc -l < my_machine_file)
#num_node=$(wc -l < my_machine_file_uniq)
#num_kill=$((num_core-nprocs))
#if [ ${num_kill} -gt 0 ]; then 
#    sed -i '1,${num_kill}d' my_machine_file
#fi 

# Distribute processes evenly across nodes 
num_core=$(wc -l < my_machine_file)
num_node=$(wc -l < my_machine_file_uniq)
num_even=$((nprocs / num_node))
if [ $((num_even * num_node)) -lt $nprocs ]; then 
    num_even=$((num_even + 1))
fi 

# Initialize new my_machine_file 
> my_machine_file2

# Read each node and repeat it num_even times
while IFS= read -r record; do
    for ((i = 1; i <= $num_even; i++)); do
        echo $record >> my_machine_file2
    done
done < my_machine_file_uniq

# Remove excess processes from the top of the new list
num_core2=$(wc -l < my_machine_file2)
num_kill2=$((num_core2-nprocs))
if [ ${num_kill2} -gt 0 ]; then 
    sed -i "1,${num_kill2}d" my_machine_file2
fi 

# ================================
# Link tracer executable 
/bin/rm -f my_commands.sh 
echo '#!/bin/bash'                             > my_commands.sh 
chmod +x my_commands.sh 
echo 'cd /inside_out'                          >> my_commands.sh
echo 'BANDAID_PICKUP'   >> my_commands.sh
echo 'ln -s /emu_outside/forcing/other/flux-forced/STATE_DIR/* .'   >> my_commands.sh
echo 'ln -s ${basedir}/FRW_OR_ADJ/mitgcmuv .'  >> my_commands.sh

${native_singularity} exec --bind ${native_setup}:/emu_outside:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

# Run tracer executable 
/bin/rm -f my_commands.sh 
echo '#!/bin/bash'     > my_commands.sh 
chmod +x my_commands.sh 
echo 'cd /inside_out' >> my_commands.sh
echo './mitgcmuv'     >> my_commands.sh

${native_mpiexec} -np ${nprocs} --hostfile ./my_machine_file2 \
    ${native_singularity} exec --bind ${native_setup}:/emu_outside:ro \
    --bind ${rundir}:/inside_out ${singularity_image} /inside_out/my_commands.sh

#=================================
# Move result to output dirctory 
mv diags ../output
mv pbs_trc.sh ../output
mv trc.info ../output

