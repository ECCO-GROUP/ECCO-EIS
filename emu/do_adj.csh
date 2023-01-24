#!/bin/tcsh

#=================================
# Shell script for computing adjoint gradient in V4r4 Adjoint Tool
#=================================

qsub pbs_adj.csh

echo " "
echo "... Batch job pbs_adj.csh has been submitted "
echo "    to compute the adjoint gradients."

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_adj.csh
/bin/rm -f pbs_adj.csh

echo " " 
set dum = `tail -n 1 adj.dir_out`
echo '********************************************'
echo "    Results will be in" $dum
echo '********************************************'
echo " "

exit
