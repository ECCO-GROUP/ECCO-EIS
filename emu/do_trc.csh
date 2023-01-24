#!/bin/tcsh

#=================================
# Shell script for conducting tracer integration in V4r4 Tracer Tool
#=================================

qsub pbs_trc.csh

echo " "
echo "... Batch job pbs_trc.csh has been submitted "
echo "    to compute the tracer evolution. " 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_trc.csh
/bin/rm -f pbs_trc.csh

echo " " 
set dum = `tail -n 1 trc.dir_out`
echo '********************************************'
echo "    Results will be in" $dum
echo '********************************************'
echo " "

exit
