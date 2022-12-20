# EMU 
all: samp_all pert_all adj conv_all

# Convolution Tool 
conv_all: conv do_conv 

conv: conv.f emu_sub.f
	f95 -fconvert=swap -o conv.x conv.f emu_sub.f

do_conv: do_conv.f emu_sub.f 
	f95 -fconvert=swap -o do_conv.x do_conv.f emu_sub.f 

# Sampling Tool 
samp_all: samp do_samp 

samp: samp.f emu_sub.f adj_sub.f 
	f95 -fconvert=swap -o samp.x samp.f emu_sub.f adj_sub.f 

do_samp: do_samp.f emu_sub.f 
	f95 -fconvert=swap -o do_samp.x do_samp.f emu_sub.f

# Adjoint Tool 
adj: adj.f adj_sub.f emu_sub.f
	f95 -fconvert=swap -o adj.x adj.f adj_sub.f emu_sub.f

# Perturbation Tool 
pert_all: pert pert_xx pert_grad 

pert_grad: pert_grad.f
	f95 -fconvert=swap -o pert_grad.x pert_grad.f

pert_xx: pert_xx.f
	f95 -fconvert=swap -o pert_xx.x pert_xx.f

pert: pert.f emu_sub.f
	f95 -fconvert=swap -o pert.x pert.f emu_sub.f



