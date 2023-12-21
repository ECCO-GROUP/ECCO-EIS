# 15) Modify scripts. 
sed -i -e "s|SETUPDIR|${basedir}|g" *.csh

# 16) Run Perturbation Tool without perturbation to obtain reference
#    results.  
qsub pbs_pert_ref.csh



