#!/bin/tcsh

#=================================
# Shell script for conducting sampling in V4r4 Sampling Tool INTERACTIVELY 
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
# Run do_samp.x 
ln -s ${emudir}/do_samp.x .
do_samp.x

#=================================
# Move result to output dirctory 
mkdir ../output

mv data.ecco  ../output
mv samp.info ../output
mv samp.out_* ../output
mv samp.step_* ../output
mv samp.txt  ../output

echo " " 
set dum = `tail -n 1 samp.dir_out`
echo '********************************************'
echo "    Results are in" $dum
echo '********************************************'
echo " "

cd ${basedir}

exit
