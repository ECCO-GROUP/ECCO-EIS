#!/bin/bash -e
umask 022

# emu_type.sh
if [ -e "PUBLICDIR/emu_type.sh" ]; then
    bash PUBLICDIR/emu_type.sh
fi

singularity_image=SINGULARITY_IMAGE
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

/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                             >> my_commands.sh
echo '${emu_dir}/emu/exe/mask.x  /emu_input_dir ' >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

echo ""
echo "misc_mask.sh execution complete."
