#!/bin/bash -e

umask 022

#
# Check and optionally change execution timing estimates for MITgcm
# in file mitgcm_timing.nml. 
#

# Read the namelist file
while IFS='= ' read -r var_name var_value; do
    # Check if the line contains a variable assignment
    if [[ $var_name =~ ^[[:alnum:]_]+$ ]]; then
        echo "$var_name is assigned to $var_value"
        # Store the variable name and value in an associative array
        variables["$var_name"]="$var_value"
    fi
done < "mitgcm_timing.nml"

# Ask user if they want to change any value
for var_name in "${!variables[@]}"; do
    if [[ "$var_name" == nproc ]]; then
	echo "Estimate for nproc=" ${variables[$var_name]}
	echo " "
    fi

    if [[ "$var_name" == nproc ]]; then

hereherehere

    read -p "Do you want to change the value of $var_name? (y/n): " answer
    if [[ $answer =~ ^[Yy]$ ]]; then
        read -p "Enter new value for $var_name: " new_value
        variables["$var_name"]="$new_value"
    fi
done

# Write the updated namelist to a new file
output_file="mitgcm_timing.nml"
echo "&mitgcm_timing" > "$output_file"
for var_name in "${!variables[@]}"; do
    echo "  $var_name = ${variables[$var_name]}" >> "$output_file"
done
echo "/" >> "$output_file"



