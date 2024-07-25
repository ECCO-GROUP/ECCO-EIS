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
# modified initial condition file (pickup files) with 1992-2017 
# time-mean states of V4r4.
#
# The user-created directory from this script (rundir) can then be
# specified when running the Modified Simulation Tool with these
# Initial Conditions.
#
#=================================

echo " "
echo "This routine creates example replacement files for EMU Modified Simulation Tool."
echo "This particular example creates an initial condition file (pickup files) with "
echo "1992-2017 time-mean states of V4r4 (emu_ref). Employ the user-created directory "
echo "below (rundir) to use these files with the Modified Simulation Tool." 
echo " "
echo "emu_ref read from"
echo "${emu_input_dir}/emu_ref"
echo " "

#--------------------------
# Create directory 
current_dir=${PWD}
echo "Enter directory name for replacement files to be created in ... (rundir)?"
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
cd ${rundir}

#--------------------------
# Copy and rename data.ctrl.noinitctrl
echo " "
echo "Setting data.ctrl replacement ... "
echo " "

/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'   >> my_commands.sh
echo 'cp -pf ${emu_dir}/emu/data.ctrl.noinitctrl ./data.ctrl'  >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

#--------------------------
# Create copy of V4r4's pickup files which are to be modified 
echo " "
echo "Copying V4r4's pickup files ... "
echo " "
cp ${emu_input_dir}/forcing/input_init/pickup.0000000001.data .
cp ${emu_input_dir}/forcing/input_init/pickup_ggl90.0000000001.data .

#--------------------------
# Compute time-mean state using msim_avefiles.f
echo " "
echo "Computing 1992-2017 time-mean state of V4r4 (emu_ref)"
echo "by averaging its monthly mean results using program "
echo "msim_avefiles.f ... "
echo " "

# state_2d_set1_mon*data (ssh, obp)
echo "Computing means of ssh & obp (state_2d_set1_mon*data) ... "
echo " "

/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh
echo '${emu_dir}/emu/exe/msim_avefiles.x <<EOF > ./msim_avefiles.ssh_obp_script '  >> my_commands.sh
echo '/emu_input_dir/emu_ref/diags ' >> my_commands.sh
echo 'state_2d_set1_mon*data ' >> my_commands.sh
echo 'd '  >> my_commands.sh
echo '2 '  >> my_commands.sh
echo '1 '  >> my_commands.sh
echo '312 '  >> my_commands.sh
echo 'EOF'  >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

# state_3d_set1_mon*data (UVTS)
echo "Computing means of UVTS (state_3d_set1_mon*data) ... "
echo " "

/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh
echo '${emu_dir}/emu/exe/msim_avefiles.x <<EOF > ./msim_avefiles.uvts_script '  >> my_commands.sh
echo '/emu_input_dir/emu_ref/diags ' >> my_commands.sh
echo 'state_3d_set1_mon*data ' >> my_commands.sh
echo 's ' >> my_commands.sh
echo '3 ' >> my_commands.sh
echo '1 ' >> my_commands.sh
echo '312 ' >> my_commands.sh
echo 'EOF' >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

# GGL90TKE_mon_mean (ggl90tke)
echo "Computing mean of ggl90tke (GGL90TKE_mon_mean*data) ... "
echo " "

/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh
echo '${emu_dir}/emu/exe/msim_avefiles.x <<EOF > ./msim_avefiles.ggl90tke_script '  >> my_commands.sh
echo '/emu_input_dir/emu_ref/diags/GGL90TKE_mon_mean '  >> my_commands.sh
echo 'GGL90TKE_mon_mean*data '  >> my_commands.sh
echo 's '  >> my_commands.sh
echo '3 '  >> my_commands.sh
echo '1 '  >> my_commands.sh
echo '312 '  >> my_commands.sh
echo 'EOF'  >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

#--------------------------
# Modify pickup files with time-mean 

echo " "
echo "Modifying pickup files with computed time-mean states" 
echo "using program msim_ic.f ... "
echo " "

/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh
echo '${emu_dir}/emu/exe/msim_ic.x <<EOF > ./msim_ic.script '  >> my_commands.sh
echo 'msim_avefiles.s3d_mean.state_3d_set1_mon '  >> my_commands.sh
echo 's '  >> my_commands.sh
echo '3 '  >> my_commands.sh
echo 'msim_avefiles.s3d_mean.state_3d_set1_mon '  >> my_commands.sh
echo 's '  >> my_commands.sh
echo '4 '  >> my_commands.sh
echo 'msim_avefiles.s3d_mean.state_3d_set1_mon '  >> my_commands.sh
echo 's '  >> my_commands.sh
echo '1 '  >> my_commands.sh
echo 'msim_avefiles.s3d_mean.state_3d_set1_mon '  >> my_commands.sh
echo 's '  >> my_commands.sh
echo '2 '  >> my_commands.sh
echo 'msim_avefiles.d2d_mean.state_2d_set1_mon '  >> my_commands.sh
echo 'd '  >> my_commands.sh
echo '1 '  >> my_commands.sh
echo 'msim_avefiles.s3d_mean.GGL90TKE_mon_mean '  >> my_commands.sh
echo 's '  >> my_commands.sh
echo '1 '  >> my_commands.sh
echo 'EOF'  >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

#--------------------------
# End

cd ${current_dir}

echo " "
echo "Successfully modified pickup files in directory " ${rundir}
echo "Use this directory name as input with the Modified Simulation Tool." 
echo " "



