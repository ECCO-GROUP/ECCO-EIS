# 6) Download forcing from ECCO Drive. 
#    Substitute username "fukumori" with your own. 

wget -P forcing -r --no-parent --user fukumori --ask-password -nH --cut-dirs=4 https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/input_init
wget -P forcing -r --no-parent --user fukumori --ask-password -nH --cut-dirs=4 https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/other/flux-forced

