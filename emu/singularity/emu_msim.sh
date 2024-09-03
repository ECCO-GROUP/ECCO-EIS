#!/bin/bash -e

#=================================
# Shell script for V4r4 Modified Simulation Tool
#=================================

#=================================
# Set program specific parameters 
nprocs=EMU_NPROC
singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR
native_mpiexec=NATIVE_MPIEXEC

echo " "
echo "************************************"
echo " EMU Modified Simulation Tool (singularity) "
echo "************************************"

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/forcing/other/flux-forced/forcing
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input for Modified Simulation Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_input_setup.sh"
    echo "to download forcing needed for the Modified Simulation Tool." 
    exit 1
fi

# ------------------------------------------
# Step 1: Tool Setup
# Step 2: Specification
echo " "
echo "**** Steps 1 & 2: Setup & Specification"
echo " " 

# ------------------------------------------
# Specify user source directory with replacement files 
echo "NB: V4r4's forcing is in "
echo "    ${emu_input_dir}/forcing/other/flux-forced/forcing"
echo " " 
echo "Enter directory name with user replacement files ... ?"
read source_dir
echo " "

# Check to make sure directory exists.
if [[ ! -d "${source_dir}" ]]; then
    echo "User directory ${source_dir} does not exist."
    read -rp "Press Enter to continue ... "
    default_count=0
    echo " "
else
# Convert source_dir to absolute pathname 
    source_dir=$(readlink -f "$source_dir")
    default_count=1
    
    echo " " 
    echo "Replacement files will be read from "
    echo $source_dir
    echo " "
fi

# ------------------------------------------
# Create directory for EMU Tool 

# Name run 
sdir=$(basename ${source_dir})
dir_out="emu_msim_"${sdir}
if [[ -d ${dir_out} ]] ; then
    echo "Directory " ${PWD}/${dir_out} " exists already."
    current_datetime=$(date +"%Y%m%d_%H%M%S")
#    echo "Current datetime : " $current_datetime
    dir_out=${dir_out}"_"${current_datetime}
fi
echo "Output directory will be "${PWD}/${dir_out}
echo " "
mkdir ./${dir_out}
start_dir=${PWD}

# ------------------------------------------
# Set up run in ${dir_out}/temp

cd ${dir_out}
#mkdir temp
#cd temp
rundir=${PWD}

# Save directory names in file msim.dir_out
echo ${dir_out} > ./msim.dir_out
echo ${PWD}/${dir_out} >> ./msim.dir_out
#echo ${dir_out}/output >> ./msim.dir_out
echo ${dir_out} >> ./msim.dir_out

# -------------------------------------------
# equivalent to Step 2) of emu_fgrd.sh 
# (Set to run 26-yr simulation with 18h wall clock)

# Get timing information 
cp -f PUBLICDIR/mitgcm_timing.nml .
# Use grep to find the line containing "HOUR26YR_FWD" and awk to extract the value
hour26yr=$(grep -i "HOUR26YR_FWD" "mitgcm_timing.nml" | awk -F '=' '{print $2}' | tr -d ' ,')

/bin/rm -f my_commands.sh 
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                   >> my_commands.sh
echo 'cp -f ${emu_dir}/emu/data_emu ./data_msim ' >> my_commands.sh
singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh
sed -i -e "s|NSTEP_EMU|227903|g" ./data_msim

/bin/mv -f ${start_dir}/pbs_msim.sh_orig ./pbs_msim.sh
#sed -i -e "s|WHOURS_EMU|${hour26yr}|g" ./pbs_msim.sh
sed -i -e "s|YOURDIR|${rundir}|g" ./pbs_msim.sh

# -------------------------------------------
# equivalent to Step 3 of emu_fgrd.sh 
echo "  1) Set up files for MITgcm "

/bin/rm -f my_commands.sh 
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                   >> ./my_commands.sh
echo '${emu_dir}/emu/singularity/setup_forcing.sh'   >> ./my_commands.sh

# equivalent to do_fgrd_pert.sh
# Over-ride V4 namelist files with EMU's. 
# (integration duration and output precision)
#echo 'ln -s ${emu_dir}/namelist/* .' >> ./my_commands.sh 
echo 'ln -s ${emu_dir}/emu/emu_input/namelist/* .' >> ./my_commands.sh 
echo '/bin/rm -f ./data.diagnostics'   >> ./my_commands.sh 
echo '/bin/rm -f ./data.pkg'           >> ./my_commands.sh 
echo '/bin/rm -f ./data.ecco'          >> ./my_commands.sh 
echo '/bin/rm -f ./data'               >> ./my_commands.sh 

echo 'if [ -f ./data_msim ]; then'     >> ./my_commands.sh 
echo '    mv -f ./data_msim ./data'    >> ./my_commands.sh 
echo 'else'                            >> ./my_commands.sh 
echo '    ln -s ${emu_dir}/emu/data .' >> ./my_commands.sh 
echo 'fi'                              >> ./my_commands.sh 

echo 'ln -s ${emu_dir}/emu/data.pkg_notapes data.pkg' >> ./my_commands.sh 
echo 'ln -s ${emu_dir}/emu/data.ecco_fgrd data.ecco'  >> ./my_commands.sh 

# Specify w/ or w/o budget output
echo "Output budget (fluxes) ... (YES/NO)?"
read choose_budget
echo " "
if [[ "${choose_budget}" == *[yY]* ]]; then
    echo "... outputting budget"
    echo 'ln -s ${emu_dir}/emu/data.diagnostics.budg ./data.diagnostics'  >> ./my_commands.sh 
    echo " "
else
    echo "... NO budget output"
    echo 'ln -s ${emu_dir}/emu/data.diagnostics .'   >> ./my_commands.sh 
    echo " "
fi

# Copy executable and corresponding data.exch2 file 
echo "ln -sf \${emu_dir}/emu/exe/nproc/${nprocs}/v4r4_flx.x . "         >> ./my_commands.sh
echo "ln -sf \${emu_dir}/emu/emu_input/nproc/${nprocs}/data.exch2 . "   >> ./my_commands.sh    

# Create subdirectories according to set up.
#python3 mkdir_subdir_diags.py
echo "python3 /emu_input_dir/forcing/input_init/tools/mkdir_subdir_diags.py "  >> ./my_commands.sh    

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

# ------------------------------------------
# Modify V4r4 input files with user files

target_dir=$PWD
declare -i n_replace
n_replace=1
# Counter starts from 1, otherwise encountered failure with bash -e

# Check to see if there are any files at all in source_dir
if [[ "${default_count}" -eq 0 ]]; then
    src_count=0
else
    src_count=$(find ${source_dir} -maxdepth 1 \( -type f -o -type l \) | wc -l)
fi

# Check which files to replace 
if [[ "${src_count}" -ne 0 ]]; then
    
# First check source_dir to see what is to be replaced
# (does not yet replace them)
for sourceFile in ${source_dir}/* ; do
  # Extract the file name from the path
    fileName=$(basename ${sourceFile})
#    echo "source file ... " ${fileName}

  # Check if the file exists in the target directory
  if ([ -e ${target_dir}/${fileName} ] || [ -L "${target_dir}/${fileName}" ]) && [ "${fileName}" != "my_commands.sh" ]; then
  # Count replacement file
    ((n_replace++))  
    echo 'Replacement file ... '${fileName}
  fi
done

fi # end block for src_count check 

(( n_replace -=1 ))
echo "Total # of files to be replaced ... " ${n_replace}
echo " "

# ------------------------------------------
# Check to proceed or not

if [[ "${src_count}" -eq 0 ]]; then
    echo "0 files will be replaced. Simulation will be the same as Reference Run."
    echo " "
    echo "Proceed to run the model ... (Y/N)?"
else
    echo "Proceed to replace and run the model ... (Y/N)?"
fi
read proceed_yn
echo " "

# 
if [[ ${proceed_yn} == "N" || ${proceed_yn} == "n" ]] ; then
    echo " "
    echo "Aborting EMU Simulation Difference Tool."
    echo " "
    exit 0
fi

echo "***********************" >  ./msim.info
echo "Output of emu_msim.sh"   >> ./msim.info
echo "***********************" >> ./msim.info
echo " "  >> ./msim.info
echo "EMU Simulation Tool replacement read from: " >> ./msim.info
echo $source_dir >> ./msim.info 
echo " "  >> ./msim.info
if [[ "${default_count}" -ne 0 ]]; then
    echo "ls -al "$source_dir >> ./msim.info
    ls -al $source_dir >> ./msim.info
else
    echo "User directory " ${source_dir} " does not exist." >> ./msim.info
    echo "No files are replaced." >> ./msim.info
fi 
echo " "  >> ./msim.info

echo " "
echo "Optionally, enter short description about the replacement files ... ?"
echo "   (Will be copied in output file msim.info for reference.)"
echo "   (Skip if not needed.)"
read ftext
echo " "

if [[ -z ${ftext} ]]; then
    echo " ... skipping description"
    echo " "
else
    echo "User-provided description of replacement files: " >> ./msim.info 
    echo ${ftext} >> ./msim.info
fi
echo " "  >> ./msim.info

# Loop through files in source_dir
n_replace=1
# If there are no files to replace skip replacement 
if [[ "${src_count}" -ne 0 ]]; then
    
    for sourceFile in ${source_dir}/* ; do
	# Extract the file name from the path
	fileName=$(basename ${sourceFile})
	#    echo "source file ... " ${fileName}
	# Check if the file exists in the target directory
	if ([ -e ${target_dir}/${fileName} ] || [ -L "${target_dir}/${fileName}" ]) && [ "${fileName}" != "my_commands.sh" ]; then
	    # Count replacement file
	    ((n_replace++))  
	    echo 'Replacing ... '${fileName}
	    echo 'Replacing ... '${fileName} >> ./msim.info
	    # Remove the file from the target directory
	    rm -f ${target_dir}/${fileName}
	    # link the file from the source directory to the target directory
#	    ln -s ${sourceFile} ${target_dir}
	    cp -L ${sourceFile} ${target_dir}
	fi
    done
fi
(( n_replace -=1 ))
    echo "Total # of files replaced ... " ${n_replace}
    echo "Total # of files replaced ... " ${n_replace} >> ./msim.info

# Create subdirectories according to set up.
#python3 mkdir_subdir_diags.py  # Moved ahead of file modification 

# ------------------------------------------
# Step 3: Calculation 

# Adjust Wall Clock estimate 
#   Read the data file, ignore lines starting with '#', and find the value of nTimeSteps
nTimeSteps=$(grep -v '^#' "./data" | grep 'nTimeSteps' | awk -F'=' '{print $2}' | tr -d ' ,')
#   Estimate wall clock hours needed and ensure the result is an integer
hour_estimate=$(echo "$hour26yr / 227903 * ${nTimeSteps} + 1" | bc -l | awk '{print int($1)}')
sed -i -e "s|WHOURS_EMU|${hour_estimate}|g" ./pbs_msim.sh

# 
echo "  3) Run MITgcm "
#BATCH_COMMAND ./pbs_msim.sh

echo "... Running batch job pbs_msim.sh "
echo "    to compute the model's response to modified input." 

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' ./pbs_msim.sh

echo " " 
dum=`sed -n '3p' ./msim.dir_out`
echo '********************************************'
echo "    Results will be in " ${dum}
echo '********************************************'
echo " "

echo "Progress of the computation can be monitored by"
echo "  ls -l ${dum}/diags/*2d*day*data | wc -l " 
echo "which counts the number of days the model has integrated." 
echo "(As standard output, the model saves daily mean files of"
echo "sea level and ocean bottom pressure, unless changed in "  
echo "file data.diagnostics.)"
echo " "

BATCH_COMMAND ./pbs_msim.sh

cd ${start_dir}
