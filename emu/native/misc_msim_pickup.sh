#!/bin/bash -e

umask 022

emu_dir=EMU_DIR
emu_input_dir=EMU_INPUT_DIR

#=================================
# For EMU Modified Simulation Tool (msim).
# (Native version)
# 
# This is an example of preparing a model initial condition file
# (pickup file) from the end state of another simulation and a
# corresponding file data to use it to integrated the ECCO model for a
# user-defined number of months.
#
#=================================

echo " "
echo "This routine creates example replacement files for EMU Modified Simulation Tool."
echo "This particular example prepares a model initial condition file (pickup file)"
echo "from the end state of another similation (pickup.ckptA.data/meta) and creates"
echo "a corresponding file data to integrate the ECCO model for a user-defined duration." 

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

#--------------------------
echo "***********************" >  ${rundir}/misc_msim_pickup.info
echo "Output of misc_msim_pickup.sh"   >> ${rundir}/misc_msim_pickup.info
echo "***********************" >> ${rundir}/misc_msim_pickup.info

ls -al ${rundir} > ${rundir}/before.txt

#--------------------------
# Get data file template 
cp -pf ${emu_dir}/emu/data_emu_niter0  ${rundir}/data

#--------------------------
# Get pickup file
echo " "
echo "Enter directory name with pickup.ckptA.data and meta files ... ?"
read ftext

pickup_dir=$(readlink -f "$ftext")
echo " "
echo "File pickup.ckptA.data being read from ${pickup_dir} "

echo " "  >> ${rundir}/misc_msim_pickup.info
echo "File pickup.ckptA.data being read from ${pickup_dir} " >> ${rundir}/misc_msim_pickup.info

# Get list of available pickup files
pattern_data="${pickup_dir}/pickup.ckptA.data"
pattern_meta="${pickup_dir}/pickup.ckptA.meta"
pattern_ecco="${pickup_dir}/pickup_ecco.ckptA.data"
pattern_ggl90="${pickup_dir}/pickup_ggl90.ckptA.data"

files_data=($(ls ${pattern_data} 2>/dev/null))
files_meta=($(ls ${pattern_meta} 2>/dev/null))
files_ecco=($(ls ${pattern_ecco} 2>/dev/null))
files_ggl90=($(ls ${pattern_ggl90} 2>/dev/null))

# Check if all pickup files exist
if [ ${#files_data[@]} -eq 0 ] || [ ${#files_meta[@]} -eq 0 ] || [ ${#files_ecco[@]} -eq 0 ] || [ ${#files_ggl90[@]} -eq 0 ]; then
    echo "Missing pickup files:"
    [ ${#files_data[@]} -eq 0 ] && echo "  - ${pattern_data} not found"
    [ ${#files_meta[@]} -eq 0 ] && echo "  - ${pattern_meta} not found"
    [ ${#files_ecco[@]} -eq 0 ] && echo "  - ${pattern_ecco} not found"
    [ ${#files_ggl90[@]} -eq 0 ] && echo "  - ${pattern_ggl90} not found"
    exit 1
fi

# Extract the integer value of timeStepNumber from meta file 
time_step=$(grep -oP 'timeStepNumber\s*=\s*\[\s*\K\d+' "$pattern_meta")

# Check if extraction was successful
if [ -z "$time_step" ]; then
    echo "Could not extract timeStepNumber from $pattern_meta"
    exit 1
fi

# Format timeStepNumber as a 10-digit integer (zero-padded)
time_step_padded=$(printf "%010d" "$time_step")

# Define new file names
new_data_file="${rundir}/pickup.${time_step_padded}.data"
new_ecco_file="${rundir}/pickup_ecco.${time_step_padded}.data"
new_ggl90_file="${rundir}/pickup_ggl90.${time_step_padded}.data"

# Copy the data file with the new name
cp "$pattern_data" "$new_data_file"
cp "$pattern_ecco" "$new_ecco_file"
cp "$pattern_ggl90" "$new_ggl90_file"

echo 
echo "Copied $pattern_data to $new_data_file"
echo "Copied $pattern_ecco to $new_ecco_file"
echo "Copied $pattern_ggl90 to $new_ggl90_file"

# Define reference date (12Z January 1, 1992)
ref_date="1992-01-01 12:00:00"

# Convert time_step_padded to an integer
niter0=$((10#$time_step_padded))  # Ensure leading zeros don't cause issues

sed -i -e "s|NITER0_EMU|${niter0}|g" ${rundir}/data

# Convert hours to a date using 'date' command
converted_date=$(date -u -d "${ref_date} UTC +${niter0} hours" +"%Y-%m-%d %H:%M:%SZ")

# Output the result
echo 
echo "Model will integrate from time step: $time_step_padded"
echo "Converted date and hour: $converted_date"

echo " "  >> ${rundir}/misc_msim_pickup.info
echo "Model will integrate from time step: $time_step_padded"  >> ${rundir}/misc_msim_pickup.info
echo "Converted date and hour: $converted_date" >> ${rundir}/misc_msim_pickup.info

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

sed -i -e "s|NSTEP_EMU|${nTimesteps}|g" ${rundir}/data

ndays=$(( nTimesteps / 24 ))
echo 
echo "Will integrate model over ${ndays} days"
echo "which is ${nTimesteps} model timesteps."

echo " "  >> ${rundir}/misc_msim_pickup.info
echo "Will integrate model over ${ndays} days"  >> ${rundir}/misc_msim_pickup.info
echo "which is ${nTimesteps} model timesteps."  >> ${rundir}/misc_msim_pickup.info

#--------------------------
# End

ls -al ${rundir} > ${rundir}/after.txt
echo " " 
echo "Changed files:"
comm -13 <(sort ${rundir}/before.txt) <(sort ${rundir}/after.txt) \
| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
| grep -vE '^(before.txt|after.txt|\.\.?$)' 

echo " "   >> ${rundir}/misc_msim_pickup.info
echo "Changed files:"  >> ${rundir}/misc_msim_pickup.info
comm -13 <(sort ${rundir}/before.txt) <(sort ${rundir}/after.txt) \
| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
| grep -vE '^(before.txt|after.txt|\.\.?$)' >> ${rundir}/misc_msim_pickup.info

rm ${rundir}/before.txt
rm ${rundir}/after.txt

echo " "   >> ${rundir}/misc_msim_pickup.info
echo "Files at end: "   >> ${rundir}/misc_msim_pickup.info
echo "ls -al "$rundir  >> ${rundir}/misc_msim_pickup.info
ls -al $rundir >> ${rundir}/misc_msim_pickup.info

echo " "
echo "Successfully created pickup file and modified file data in directory " ${rundir}
echo "Use this directory name as input with the Modified Simulation Tool." 
echo " "

echo "misc_msim_pickup.sh execution complete."
