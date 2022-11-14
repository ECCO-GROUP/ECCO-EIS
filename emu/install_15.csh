# 15) Copy tools (setup_*.csh, README_*) for user access. Replace
#     FORUSERDIR below to a user-accessible directory.

set useraccessdir=/nobackup/ifukumor/ECCO_tools/emu
if (! -d ${useraccessdir}) mkdir ${useraccessdir}
sed -i -e "s|PUBLICDIR|${useraccessdir}|g" setup_*.csh
sed -i -e "s|PUBLICDIR|${useraccessdir}|g" README_*
cp -p ${basedir}/emu/setup_*.csh ${useraccessdir}
cp -p ${basedir}/emu/README_* ${useraccessdir}
