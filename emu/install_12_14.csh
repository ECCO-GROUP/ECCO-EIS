# 12) Copy files that will be modified, just in case. (optional)
cp -p setup_samp.csh setup_samp.csh_orig
cp -p README_samp README_samp_orig
cp -p pbs_pert_ref.csh pbs_pert_ref.csh_orig
cp -p pbs_pert.csh pbs_pert.csh_orig
cp -p setup_pert.csh setup_pert.csh_orig
cp -p README_pert README_pert_orig
cp -p setup_adj.csh setup_adj.csh_orig
cp -p README_adj README_adj_orig
cp -p pbs_adj.csh pbs_adj.csh_orig
mkdir orig
mv *_orig orig 

# 13) Modify scripts. 
sed -i -e "s|SETUPDIR|${basedir}|g" *.csh

# 14) Run Perturbation Tool without perturbation to obtain reference
#     results.  
qsub pbs_pert_ref.csh

