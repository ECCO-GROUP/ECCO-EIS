#!/bin/bash -e

umask 022

emu_dir=EMU_DIR
emu_input_dir=EMU_INPUT_DIR

#=================================
#
# This shell scrit runs mask.x to create example mask files equivalent
# to what is used by EMU Sampling and Adoint Tools. 
#
#=================================

echo " "
echo "This routine creates example mask files for EMU. The examples are "
echo "masks for computing area or volume mean quantities over the ocean "
echo "based on interactive specification of a rectilinear domain." 
echo " " 

#--------------------------
# Run mask.x 
${emu_dir}/emu/exe/mask.x ${emu_input_dir}

echo ""
echo "misc_mask.sh execution complete."
