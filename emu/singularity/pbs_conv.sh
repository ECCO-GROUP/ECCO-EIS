#PBS -S /bin/bash 
#PBS -l select=1:ncpus=40:model=sky_ele
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#PBS -q devel

#=================================
# Shell script for V4r4 Convolution Tool (singularity)
# (Runs Parallel outside Singularity) 
#=================================

#=================================
# Set program specific pafameters 
native_setup=NATIVE_SETUP

rundir=YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}

native_singularity=NATIVE_SINGULARITY
singularity_image=SINGULARITY_IMAGE

# build Singularity script 
/bin/rm -f my_commands.sh 
echo '#!/bin/bash'     > my_commands.sh & chmod +x my_commands.sh 
echo 'cd /inside_out/SUBDIR'  >> my_commands.sh
echo 'ln -sf ${basedir}/emu/do_conv.x .' >> my_commands.sh 
echo './do_conv.x'     >> my_commands.sh

GPD=$(dirname $(dirname $rundir))
cp -f my_commands.sh ${GPD}

seq 8 | parallel -j 8 -u --joblog conv.log \
    "echo {} | ${native_singularity} exec --bind ${native_setup}:/emu_outside:ro \
        --bind ${GPD}:/inside_out ${singularity_image} /inside_out/my_commands.sh"

#=================================
# Move result to output dirctory 
mkdir ../output

mv conv.info ../output
mv conv.out  ../output
mv istep_*.data ../output
mv recon1d_*.data ../output
mv recon2d_*.data ../output

