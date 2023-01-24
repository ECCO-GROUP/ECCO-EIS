#!/bin/tcsh

#=================================
# Shell script for computing model response in V4r4 Perturbation Tool
#=================================

qsub pbs_pert.csh

echo " "
echo "... Batch job pbs_pert.csh has been submitted "
echo "    to compute the model's response to perturbation." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_pert.csh
/bin/rm -f pbs_pert.csh

echo " " 
set dum = `tail -n 1 pert.dir_out`
echo '********************************************'
echo "    Results will be in" $dum
echo '********************************************'
echo " "

exit
