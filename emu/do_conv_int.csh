#!/bin/tcsh

#=================================
# Shell script for conducting convolution in V4r4 Convolution Tool INTERACTIVELY
#=================================

#=================================
# Set program specific pafameters 
set tooldir  = SETUPDIR
set emudir  = ${tooldir}/emu

set rundir = YOURDIR

#=================================
# cd to directory to run rundir

set basedir = `pwd`
cd ${rundir}
 
#=================================
# Run do_conv.x in parallel for all 8 controls
ln -s ${emudir}/do_conv.x .
seq 8 | parallel -j 8 -u --joblog conv.log "echo {} | do_conv.x" 

#=================================
# Move result to output dirctory 
mkdir ../output

mv conv.info ../output
mv conv.out  ../output
mv istep_*.data ../output
mv recon1d_*.data ../output
mv recon2d_*.data ../output

echo " " 
set dum = `tail -n 1 conv.dir_out`
echo '********************************************'
echo "    Results are in" $dum
echo '********************************************'
echo " "

cd ${basedir}

exit 
