# 2) Download MITgcm "checkpoint  66g".
git clone https://github.com/MITgcm/MITgcm.git -b checkpoint66g

#3) Create and cd to subdirectory.
cd MITgcm
mkdir -p ECCOV4/release4
cd ECCOV4/release4

#4) Download V4 configurations.
git clone https://github.com/ECCO-GROUP/ECCO-v4-Configurations

#5) Extract flux-forced configuration of the model.
mv ECCO-v4-Configurations/ECCOv4\ Release\ 4/flux-forced .
rm -rf ECCO-v4-Configurations
cd flux-forced
set basedir=`pwd`
mkdir forcing
