#PBS -S /bin/bash
#PBS -l select=1:ncpus=40:model=sky_ele
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#PBS -q devel

umask 022

#=================================
# PBS script for V4r4 Convolution Tool (native)
#=================================

#=================================
# Set program specific pafameters 
emu_dir=EMU_DIR

rundir=YOURDIR

#=================================
# cd to directory to run rundir
cd ${rundir}

ln -sf ${emu_dir}/emu/exe/do_conv.x .

seq 8 | parallel -j 8 -u --joblog conv.log "echo {} | ./do_conv.x" 

#=================================
# Move result to output dirctory 
mkdir ../output

mv ./conv.info ../output
mv ./conv.out  ../output
mv ./istep_*.data ../output
mv ./recon1d_*.data ../output
mv ./recon2d_*.data ../output

