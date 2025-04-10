#!/bin/bash -e

umask 022

# emu_type.sh
if [ -e "PUBLICDIR/emu_type.sh" ]; then
    bash PUBLICDIR/emu_type.sh
fi

singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR

#=================================
# For EMU Modified Simulation Tool (msim).
# (Singularity version)
# 
# This is an example of preparing user replacement files for EMU's
# Modified Simulation Tool. This example shell script creates a
# modified data file used by MITgcm to integrate a user-defined number
# of months.
#
#=================================

echo " "
echo "This routine creates example replacement files for EMU Modified Simulation Tool."
echo "This particular example modifies the start and duration of model integration "
echo "specified in file data used by MITgcm." 

#--------------------------
# Create directory 
current_dir=${PWD}
echo " "
echo "Enter directory name for replacement file to be created in ... (rundir)?"
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
echo "***********************" >  ${rundir}/misc_msim_data.info
echo "Output of misc_msim_data.sh"   >> ${rundir}/misc_msim_data.info
echo "***********************" >> ${rundir}/misc_msim_data.info

ls -al ${rundir} > before.txt

#--------------------------
# Get data file template 
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'   >> my_commands.sh
echo 'cp -pf ${emu_dir}/emu/data_emu_niter0  ./data'    >> my_commands.sh
echo 'cp -pf ${emu_dir}/emu/data.ctrl.noinitctrl ./data.ctrl'    >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

#--------------------------
# Set integration time
echo " "
echo "V4r4 spans 312-months from 1/1/1992 12Z to 12/31/2017 12Z" 
echo "EMU can re-run V4r4 from the beginning of any of these years"
echo "using V4r4's corresponding estimate as initial condition." 

# Initial condition 
echo " "
echo "Enter year to begin integration ... (1992-2017)"
read iyear

# Get list of available pickup files
pattern=${emu_input_dir}/emu_ref/pickup.*.data
files=($(ls ${pattern} 2>/dev/null))

# Check if files exist
if [ ${#files[@]} -eq 0 ]; then
    echo "No pickup files found : ${pattern}"
    exit 1
fi

# Array to store extracted numbers
numbers=()

# Extract numbers from filenames
for file in "${files[@]}"; do
    filename=$(basename "$file")  # Get filename only
    number=$(echo "$filename" | sed -E 's/pickup\.([0-9]+)\.data/\1/')
    numbers+=("$number")
done

# Output extracted numbers
if [[ "${iyear}" == "1992" ]]; then
    niter0=1
    rm -f ./data.ctrl
else
    niter0=$(( 10#${numbers[$((iyear-1992-1))]} ))
fi 

sed -i -e "s|NITER0_EMU|${niter0}|g" data

echo "Model will be integrated from beginning of year ${iyear}"
echo "which is model timestep ${niter0}"

#--------------------------
echo " "  >> ${rundir}/misc_msim_data.info
echo "Model will be integrated from beginning of year ${iyear}" >> ${rundir}/misc_msim_data.info
echo "which is model timestep ${niter0}" >> ${rundir}/misc_msim_data.info

#--------------------------
echo 
echo "Enter number of days to integrate ... ?"
read ndays

if [[ ndays -lt 1 ]]; then
    ndays=1
fi

# set nTimesteps 
nsteps=$(( 227903 - niter0 ))
nTimesteps=$(( ndays * 24 ))
if [[ ${nTimesteps} -gt ${nsteps} ]]; then
    nTimesteps=$nsteps
fi

sed -i -e "s|NSTEP_EMU|${nTimesteps}|g" data

ndays=$(( nTimesteps / 24 ))
echo "Will integrate model over ${ndays} days"
echo "which is ${nTimesteps} model timesteps."

#--------------------------
echo " "  >> ${rundir}/misc_msim_data.info
echo "Will integrate model over ${ndays} days" >> ${rundir}/misc_msim_data.info
echo "which is ${nTimesteps} model timesteps." >> ${rundir}/misc_msim_data.info

#--------------------------
# End

ls -al ${rundir} > after.txt
echo " " 
echo "Changed files:"
comm -13 <(sort before.txt) <(sort after.txt) \
| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
| grep -vE '^(before.txt|after.txt|\.\.?$)' 

echo " "   >> ${rundir}/misc_msim_data.info
echo "Changed files:"  >> ${rundir}/misc_msim_data.info
comm -13 <(sort before.txt) <(sort after.txt) \
| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
| grep -vE '^(before.txt|after.txt|\.\.?$)' >> ${rundir}/misc_msim_data.info

rm before.txt
rm after.txt

echo " "  >> ${rundir}/misc_msim_data.info
echo "Files at end: "  >> ${rundir}/misc_msim_data.info
echo "ls -al "$rundir  >> ${rundir}/misc_msim_data.info
ls -al $rundir >> ${rundir}/misc_msim_data.info

cd ${current_dir}

echo " "
echo "Successfully modified file data in directory " ${rundir}
echo "Use this directory name as input with the Modified Simulation Tool." 
echo " "

echo "misc_msim_data.sh execution complete."
