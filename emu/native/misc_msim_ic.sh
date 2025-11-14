#!/bin/bash -e
umask 022

emu_dir=EMU_DIR
emu_input_dir=EMU_INPUT_DIR

#=================================
# For EMU Modified Simulation Tool (msim).
# (Native version)
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
echo "***********************" >  ${rundir}/misc_msim_ic.info
echo "Output of misc_msim_ic.sh"   >> ${rundir}/misc_msim_ic.info
echo "***********************" >> ${rundir}/misc_msim_ic.info

ls -al ${rundir} > before.txt

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
${emu_dir}/emu/exe/msim_avefiles.x <<EOF > ./msim_avefiles.ssh_obp_script
${emu_input_dir}/emu_ref/diags
state_2d_set1_mon*data
d
2
1
312
EOF

# state_3d_set1_mon*data (UVTS)
echo "Computing means of UVTS (state_3d_set1_mon*data) ... "
echo " "
${emu_dir}/emu/exe/msim_avefiles.x <<EOF > ./msim_avefiles.uvts_script
${emu_input_dir}/emu_ref/diags
state_3d_set1_mon*data
s
3
1
312
EOF

# GGL90TKE_mon_mean (ggl90tke)
echo "Computing mean of ggl90tke (GGL90TKE_mon_mean*data) ... "
echo " "
${emu_dir}/emu/exe/msim_avefiles.x <<EOF > ./msim_avefiles.ggl90tke_script
${emu_input_dir}/emu_ref/diags/GGL90TKE_mon_mean
GGL90TKE_mon_mean*data
s
3
1
312
EOF

#--------------------------
# Modify pickup files with time-mean 

echo " "
echo "Modifying pickup files with computed time-mean states" 
echo "using program msim_ic.f ... "
echo " "

${emu_dir}/emu/exe/msim_ic.x <<EOF > ./msim_ic.script
msim_avefiles.s3d_mean.state_3d_set1_mon
s
3
msim_avefiles.s3d_mean.state_3d_set1_mon
s
4
msim_avefiles.s3d_mean.state_3d_set1_mon
s
1
msim_avefiles.s3d_mean.state_3d_set1_mon
s
2
msim_avefiles.d2d_mean.state_2d_set1_mon
d
1
msim_avefiles.s3d_mean.GGL90TKE_mon_mean
s
1
EOF

#--------------------------
# End

ls -al ${rundir} > after.txt
echo " " 
echo "Changed files:"
comm -13 <(sort before.txt) <(sort after.txt) \
| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
| grep -vE '^(before.txt|after.txt|\.\.?$)' 

echo " "   >> ${rundir}/misc_msim_ic.info
echo "Modified pickup files with time-mean states using program msim_ic.f "   >> ${rundir}/misc_msim_ic.info
echo " "   >> ${rundir}/misc_msim_ic.info
echo "Changed files:"  >> ${rundir}/misc_msim_ic.info
comm -13 <(sort before.txt) <(sort after.txt) \
| awk '{name=""; for (i=9; i<=NF; i++) name = name $i (i<NF ? " " : ""); print name}' \
| grep -vE '^(before.txt|after.txt|\.\.?$)' >> ${rundir}/misc_msim_ic.info

rm before.txt
rm after.txt

echo " "  >> ${rundir}/misc_msim_ic.info
echo "Files at end: "   >> ${rundir}/misc_msim_ic.info
echo "ls -al "$rundir  >> ${rundir}/misc_msim_ic.info
ls -al $rundir >> ${rundir}/misc_msim_ic.info

cd ${current_dir}

echo " "
echo "Successfully modified pickup files in directory " ${rundir}
echo "Use this directory name as input with the Modified Simulation Tool." 
echo " "

echo "misc_msim_ic.sh execution complete."



