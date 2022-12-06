all: samp do_samp pert_all adj 

pert_all: pert pert_xx pert_grad 

samp: samp.f emu_sub.f adj_sub.f 
	f95 -fconvert=swap -o samp.x samp.f emu_sub.f adj_sub.f 

do_samp: do_samp.f emu_sub.f 
	f95 -fconvert=swap -o do_samp.x do_samp.f emu_sub.f

adj: adj.f adj_sub.f emu_sub.f
	f95 -fconvert=swap -o adj.x adj.f adj_sub.f emu_sub.f

pert_grad: pert_grad.f
	f95 -fconvert=swap -o pert_grad.x pert_grad.f

pert_xx: pert_xx.f
	f95 -fconvert=swap -o pert_xx.x pert_xx.f

pert: pert.f emu_sub.f
	f95 -fconvert=swap -o pert.x pert.f emu_sub.f



