# 10) Download EMU scripts and programs and compile.

git clone https://github.com/ECCO-GROUP/ECCO-EIS.git 
mv ECCO-EIS/emu .
rm -rf ECCO-EIS
cd emu
make all
