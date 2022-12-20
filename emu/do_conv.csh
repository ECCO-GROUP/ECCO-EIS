#!/bin/tcsh

#=================================
# Shell script for conducting convolution in V4r4 Convolution Tool
#=================================

# Run do_conv.x in parallel for all 8 controls
seq 8 | parallel -j 8 -u --joblog conv.log "echo {} | do_conv.x" 

# Move convolution specification to output directory
set convdir = `tail -1 conv.out`
/bin/mv conv.info ${convdir}
/bin/mv conv.out ${convdir}
/bin/mv conv.log ${convdir}

exit
