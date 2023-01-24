#17) Copy tools (setup_*.csh, README_*) for user access. Replace
#    FORUSERDIR below to a user-accessible directory.
set useraccessdir=FORUSERDIR
if (! -d ${useraccessdir}) mkdir ${useraccessdir}
sed -i -e "s|PUBLICDIR|${useraccessdir}|g" setup_*.csh
sed -i -e "s|PUBLICDIR|${useraccessdir}|g" README*
cp -p emu_*.csh ${useraccessdir}
cp -p README* ${useraccessdir}
cp -p Guide*.pdf ${useraccessdir}
