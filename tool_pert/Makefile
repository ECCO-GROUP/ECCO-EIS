all: pert_result pert_nml pert_xx

pert_result: pert_result.f
	f95 -fconvert=swap -o pert_result.x pert_result.f

pert_nml: pert_nml.f tool_sub.f
	f95 -fconvert=swap -o pert_nml.x pert_nml.f tool_sub.f

pert_xx: pert_xx.f
	f95 -fconvert=swap -o pert_xx.x pert_xx.f

