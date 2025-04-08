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
# modified data.diagnostic file that specifies diagnostic output 
# for MITgcm.
#
#=================================

echo " "
echo "This routine creates example replacement files for EMU Modified Simulation Tool."
echo "This particular example creates file data.diagnostics which specifies what "
echo "state variables are output and at what time interval they are saved."
echo " "

#--------------------------
# Create directory 
current_dir=${PWD}
echo "Enter directory name for replacement file to be created in ... (rundir)?"
read ftext
echo " "

rundir=$(readlink -f "$ftext")
if [[ -d ${rundir} ]] ; then
    echo "Files will be created in "${rundir}
    echo " "
else
    echo "Creating "${rundir}
    mkdir ${rundir}
    echo " "
fi

#--------------------------
echo "***********************" >  ${rundir}/misc_msim_diagnostics.info
echo "Output of misc_msim_diagnostics.sh"   >> ${rundir}/misc_msim_diagnostics.info
echo "***********************" >> ${rundir}/misc_msim_diagnostics.info

ls -al ${rundir} > ${rundir}/before.txt

#--------------------------
# Get data file template 

FILE="${rundir}/data.diagnostics"

/bin/rm -f ${rundir}/my_commands.sh
echo '#!/bin/bash -e' > ${rundir}/my_commands.sh && chmod +x ${rundir}/my_commands.sh
echo 'cd /inside_out'   >> ${rundir}/my_commands.sh
echo 'cp -pf ${emu_dir}/emu/data.diagnostics_emu  ./data.diagnostics'    >> ${rundir}/my_commands.sh

singularity exec -e --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

#--------------------------
# Initialize counter for output group
count_group=0

#--------------------------
# Ask if any 3d variables are to be saved

echo "Output 3d state (e.g., T, S, U, V) ... (y/n)?"
read f3d

#echo "f3d is "$f3d

if [[ ${f3d,,} == "y" ]] ; then
    ((count_group++)) || true

    while true; do 
	echo "Enter which variables to output ... (e.g., TSUV for all four)?"
	read f3d_TSUV

# Convert input to lowercase for case-insensitive matching
	f3d_TSUV_lower=$(echo "$f3d_TSUV" | tr '[:upper:]' '[:lower:]')

# Initialize counter and fields array
	count=0
	fields=()

# Check for each variable and add to the list
	if [[ $f3d_TSUV_lower == *t* ]]; then
	    echo "T is selected."
	    fields+=("'THETA'")
	    ((count++)) || true
	fi

	if [[ $f3d_TSUV_lower == *s* ]]; then
	    echo "S is selected."
	    fields+=("'SALT'")
	    ((count++)) || true
	fi

	if [[ $f3d_TSUV_lower == *u* ]]; then
	    echo "U is selected."
	    fields+=("'UVEL'")
	    ((count++)) || true
	fi

	if [[ $f3d_TSUV_lower == *v* ]]; then
	    echo "V is selected."
	    fields+=("'VVEL'")
	    ((count++)) || true
	fi

# Trap for when none are selected
	if [[ $count -eq 0 ]]; then
	    echo "Error: No valid variables were selected. Enter at least one of T, S, U, or V."
            continue  # Restart the loop
	fi

# Output results
	echo "Total number of selected 3d output variables: $count"
	echo "Output variables: ${fields[*]}"

# Construct the final string with comma-separated values
	joined_fields=$(IFS=,; echo "${fields[*]}")
	fields_string="fields(1:$count,$count_group) = ${joined_fields}"

	break  # Exit loop if valid input was given
    done

# Specify time-interval 
    while true; do
	echo 
	echo "Enter interval to output in seconds (integer) ... (e.g., 86400 for daily)?"
	echo "(Enter multiple of the model time-step which is 3600 seconds.)"
	echo "(Enter positive number for time-average, negative number for snap-shot.)"
	read freq

    # Check if the input is a valid integer
	if ! [[ "$freq" =~ ^-?[0-9]+$ ]]; then
            echo "Error: Enter a valid integer."
            continue  # Restart the loop if input is invalid
	fi

    # Check if it is a multiple of 3600
	abs_freq=${freq#-}  # remove minus sign if present
	if (( abs_freq % 3600 != 0 )); then
            echo "Error: Value must be a multiple of 3600."
            continue  # Restart the loop if input is invalid
	fi

    # Convert to floating-point (real number format)
	freq_real=$(printf "%.1f" "$freq")

    # Construct the frequency string
	freq_string="frequency($count_group) = ${freq_real},"

    # Output results
	echo "Output frequency (seconds): $freq"

	break  # Exit loop if valid input was given
    done

# Specify depth 
    while true; do
	echo 
	echo "Enter top-most level to output ... (1-50)?"
	read kmin

	# Check if the input is a valid integer
	if ! [[ "$kmin" =~ ^[0-9]+$ ]] || (( kmin < 1 || kmin > 50 )); then 
            echo "Error: Enter a valid integer."
            continue  # Restart the loop if input is invalid
	fi
	break  # Exit loop if valid input was given
    done
    
    while true; do
	echo 
	echo "Enter bottom-most level to output ... (${kmin}-50)?"
	read kmax

	# Check if the input is a valid integer
	if ! [[ "$kmax" =~ ^[0-9]+$ ]] || (( kmax < kmin || kmax > 50 )); then
            echo "Error: Enter a valid integer."
            continue  # Restart the loop if input is invalid
	fi
	break  # Exit loop if valid input was given
    done

# output to data.diagnostics
    fname="diags/state_3d"
    file_name="filename($count_group) = '${fname}',"
    awk -v freq_string="$freq_string" -v fields_string="$fields_string" -v file_name="$file_name" -v kmin="$kmin" -v kmax="$kmax" -v count_group="$count_group" '
/misc_msim_diagnostics.sh/ {
    count++;
    if (count == 2) {
        print freq_string;
        print fields_string;
    
        # Compute the number of levels
        num_levels = kmax - kmin + 1;
        printf "levels(1:%d,%d) = ", num_levels, count_group;

        # Print levels with correct formatting
        for (i = kmin; i <= kmax; i++) {
            printf "%d.", i;
            if ((i - kmin + 1) % 10 == 0 && i < kmax) {
                printf ",\n                     ";
            } else if (i < kmax) {
                printf ",";
            } else {
                print ",";
            }
        }
	print file_name;
        print "#---";
    }
}
{ print }
' "$FILE" > tmpfile && mv tmpfile "$FILE"

#    awk -v freq_string="$freq_string" -v fields_string="$fields_string" -v file_name="$file_name" '
#/misc_msim_diagnostics.sh/ {
#    count++;
#    if (count == 2) {
#        print freq_string;
#        print fields_string; 
#        print file_name;
#	print "#---";
#    }
#}
#{ print }
#' "$FILE" > tmpfile && mv tmpfile "$FILE"

#--------------------------
echo " "  >> ${rundir}/misc_msim_diagnostics.info
echo "Output 3d state ${fields_string} " >> ${rundir}/misc_msim_diagnostics.info
echo "   Frequency (seconds) $freq"  >> ${rundir}/misc_msim_diagnostics.info
echo "   Min/Max levels : ${kmin}, ${kmax} "  >> ${rundir}/misc_msim_diagnostics.info
echo "   Output file: ${fname} "  >> ${rundir}/misc_msim_diagnostics.info

#--------------------------
fi

#--------------------------
# Ask if any 2d variables are to be saved

echo ""
echo "Output 2d state (e.g., SSH, OBP) ... (y/n)?"
read f2d
if [[ ${f2d,,} == "y" ]] ; then
    ((count_group++)) || true

    while true; do 
	echo "Enter which variables to output ... ?"
	echo "(Enter Y for SSH, P for OBP, YP for both.)"
	read f2d_YP

# Convert input to lowercase for case-insensitive matching
	f2d_YP_lower=$(echo "$f2d_YP" | tr '[:upper:]' '[:lower:]')

# Initialize counter and fields array
	count=0
	fields=()

# Check for each variable and add to the list
	if [[ $f2d_YP_lower == *y* ]]; then
	    echo "Y is selected."
	    fields+=("'SSH'")
	    ((count++)) || true
	fi

	if [[ $f2d_YP_lower == *p* ]]; then
	    echo "P is selected."
	    fields+=("'OBP'")
	    ((count++)) || true
	fi

# Trap for when none are selected
	if [[ $count -eq 0 ]]; then
	    echo "Error: No valid variables were selected. Enter at least one of Y or P."
            continue  # Restart the loop
	fi

# Output results
	echo "Total number of selected 2d output variables: $count"
	echo "Output variables: ${fields[*]}"

# Construct the final string with comma-separated values
	joined_fields=$(IFS=,; echo "${fields[*]}")
	fields_string="fields(1:$count,$count_group) = ${joined_fields}"

	break  # Exit loop if valid input was given
    done

# Specify time-interval 
    while true; do
	echo 
	echo "Enter frequency to output in seconds (integer) ... (e.g., 86400 for daily)?"
	echo "(Enter positive number for time-average, negative number for snap-shot.)"
	read freq

	# Check if the input is a valid integer
	if ! [[ "$freq" =~ ^-?[0-9]+$ ]]; then
            echo "Error: Enter a valid integer."
            continue  # Restart the loop if input is invalid
	fi

    # Convert to floating-point (real number format)
	freq_real=$(printf "%.1f" "$freq")

    # Construct the frequency string
	freq_string="frequency($count_group) = ${freq_real},"

    # Output results
	echo "Output frequency (seconds): $freq"

	break  # Exit loop if valid input was given
    done

# output to data.diagnostics
    fname="diags/state_2d"
    file_name="filename($count_group) = '${fname}',"
    file_flags="fileFlags($count_group) = 'D ',"
    awk -v freq_string="$freq_string" -v fields_string="$fields_string" -v file_name="$file_name" -v file_flags="$file_flags" '
/misc_msim_diagnostics.sh/ {
    count++;
    if (count == 2) {
        print freq_string;
        print fields_string; 
        print file_name;
        print file_flags;
	print "#---";
    }
}
{ print }
' "$FILE" > tmpfile && mv tmpfile "$FILE"

#--------------------------
echo " "  >> ${rundir}/misc_msim_diagnostics.info
echo "Output 2d state ${fields_string} " >> ${rundir}/misc_msim_diagnostics.info
echo "   Frequency (seconds) $freq"  >> ${rundir}/misc_msim_diagnostics.info
echo "   Output file: ${fname} "  >> ${rundir}/misc_msim_diagnostics.info
echo "   Precision: Double "  >> ${rundir}/misc_msim_diagnostics.info

fi

#--------------------------
# End

ls -al ${rundir} > ${rundir}/after.txt
echo " " 
echo "Changed files:"
comm -13 <(sort ${rundir}/before.txt) <(sort ${rundir}/after.txt) \
| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
| grep -vE '^(before.txt|after.txt|\.\.?$)' 

echo " "   >> ${rundir}/misc_msim_diagnostics.info
echo "Changed files:"  >> ${rundir}/misc_msim_diagnostics.info
comm -13 <(sort ${rundir}/before.txt) <(sort ${rundir}/after.txt) \
| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
| grep -vE '^(before.txt|after.txt|\.\.?$)' >> ${rundir}/misc_msim_diagnostics.info

rm ${rundir}/before.txt
rm ${rundir}/after.txt

echo " "   >> ${rundir}/misc_msim_diagnostics.info
echo "Files at end: "   >> ${rundir}/misc_msim_diagnostics.info
echo "ls -al "$rundir  >> ${rundir}/misc_msim_diagnostics.info
ls -al $rundir >> ${rundir}/misc_msim_diagnostics.info

echo " "
echo "Successfully modified file data.diagnostics in directory " ${rundir}
echo "Use this directory name as input with the Modified Simulation Tool." 
echo " "

echo "misc_msim_diagnostics.sh execution complete."
