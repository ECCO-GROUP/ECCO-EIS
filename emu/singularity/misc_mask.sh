#!/bin/bash -e

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
echo "This routine interactively creates example mask files for EMU "
echo "equivalent to what is created by EMU Sampling and Adjoint Tools."
echo "The examples are masks for computing area or volume mean quantities"
echo "or for computing horizontal volume transport perpendicular to a "
echo "great circle." 

#--------------------------
# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/emu_ref
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_input_setup.sh"
    echo "to download emu_ref." 
    exit 1
fi

#--------------------------
# Create directory 
current_dir=${PWD}
echo " "
echo "Enter directory name for replacement files to be created in ... (rundir)?"
read ftext
echo " "

rundir=$(readlink -f "$ftext")
if [[ -d ${rundir} ]] ; then
    echo "Files will be created in "${rundir}
else
    echo "Creating "${rundir}
    mkdir ${rundir}
fi
cd ${rundir}

#--------------------------
#echo "***********************" >  ${rundir}/misc_mask.info
#echo "Output of misc_mask.sh"   >> ${rundir}/misc_mask.info
#echo "***********************" >> ${rundir}/misc_mask.info

ls -al ${rundir} > before.txt

#--------------------------
# Run mask.x 

/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                             >> my_commands.sh
echo '${emu_dir}/emu/exe/mask.x  /emu_input_dir ' >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

#--------------------------
# End

ls -al ${rundir} > after.txt
echo " " 
echo "Changed files:"
comm -13 <(sort before.txt) <(sort after.txt) \
| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
| grep -vE '^(before.txt|after.txt|\.\.?$)' 

# .....................
 
echo " " >>  ${rundir}/mask.info
echo "***********************" >>  ${rundir}/mask.info
echo "Output of misc_mask.sh"   >> ${rundir}/mask.info
echo "***********************" >> ${rundir}/mask.info

echo " "   >> ${rundir}/mask.info
echo "Changed files:"  >> ${rundir}/mask.info
comm -13 <(sort before.txt) <(sort after.txt) \
| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
| grep -vE '^(before.txt|after.txt|\.\.?$)' >> ${rundir}/mask.info

rm before.txt
rm after.txt

echo " "  >> ${rundir}/mask.info
echo "Files at end: "  >> ${rundir}/mask.info
echo "ls -al "$rundir  >> ${rundir}/mask.info
ls -al $rundir >> ${rundir}/mask.info

cd ${current_dir}

echo ""
echo "misc_mask.sh execution complete."
