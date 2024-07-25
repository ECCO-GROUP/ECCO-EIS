# EMU Makefile

FC = f95

FFLAGS = -fconvert=swap

SRCDIR=.

OBJDIR=${SRCDIR}/exe

# Create the exe directory if it doesn't exist
$(shell mkdir -p $(OBJDIR))

#
all: samp_all fgrd_all adj conv_all trc budg_all msim_all atrb_all misc_all mask 

${OBJDIR}/%.o: ${SRCDIR}/%.f
	$(FC) $(FFLAGS) -c $< -o $@

# Miscellaneous 
mask: mask.f ${OBJDIR}/emu_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/mask.x ${SRCDIR}/mask.f ${OBJDIR}/emu_sub.o

misc_all: check_timing

check_timing: ${SRCDIR}/check_timing.f
	$(FC) $(FFLAGS) -o ${OBJDIR}/check_timing.x ${SRCDIR}/check_timing.f

# Attribution Tool (atrb)
atrb_all: set_samp do_atrb

set_samp: ${SRCDIR}/set_samp.f ${OBJDIR}/emu_sub.o ${OBJDIR}/adj_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/set_samp.x ${SRCDIR}/set_samp.f ${OBJDIR}/emu_sub.o ${OBJDIR}/adj_sub.o 

do_atrb: ${SRCDIR}/do_atrb.f ${OBJDIR}/emu_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/do_atrb.x ${SRCDIR}/do_atrb.f ${OBJDIR}/emu_sub.o

# Modified Simulation Tool (msim)
msim_all: msim_ave6hrly msim_avefiles msim_ic 

msim_ave6hrly: ${SRCDIR}/msim_ave6hrly.f
	$(FC) $(FFLAGS) -o ${OBJDIR}/msim_ave6hrly.x ${SRCDIR}/msim_ave6hrly.f

msim_avefiles: ${SRCDIR}/msim_avefiles.f ${OBJDIR}/emu_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/msim_avefiles.x ${SRCDIR}/msim_avefiles.f ${OBJDIR}/emu_sub.o 

msim_ic: ${SRCDIR}/msim_ic.f ${OBJDIR}/emu_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/msim_ic.x ${SRCDIR}/msim_ic.f ${OBJDIR}/emu_sub.o 

# Budget Tool (budg)
budg_all: budg do_budg do_budg_flx_combine

budg: ${SRCDIR}/budg.f ${OBJDIR}/emu_sub.o ${OBJDIR}/adj_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/budg.x budg.f ${OBJDIR}/emu_sub.o ${OBJDIR}/adj_sub.o 

do_budg: ${SRCDIR}/do_budg.f ${OBJDIR}/emu_sub.o ${OBJDIR}/mysparse.o
	$(FC) $(FFLAGS) -o ${OBJDIR}/do_budg.x ${SRCDIR}/do_budg.f ${OBJDIR}/emu_sub.o ${OBJDIR}/mysparse.o

do_budg_flx_combine: ${SRCDIR}/do_budg_flx_combine.f ${OBJDIR}/emu_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/do_budg_flx_combine.x ${SRCDIR}/do_budg_flx_combine.f ${OBJDIR}/emu_sub.o 

# Tracer Tool (trc)
trc: ${SRCDIR}/trc.f ${OBJDIR}/emu_sub.o ${OBJDIR}/adj_sub.o
	$(FC) $(FFLAGS) -o ${OBJDIR}/trc.x ${SRCDIR}/trc.f ${OBJDIR}/emu_sub.o ${OBJDIR}/adj_sub.o

# Convolution Tool (conv)
conv_all: conv do_conv 

conv: ${SRCDIR}/conv.f ${OBJDIR}/emu_sub.o
	$(FC) $(FFLAGS) -o ${OBJDIR}/conv.x ${SRCDIR}/conv.f ${OBJDIR}/emu_sub.o

do_conv: ${SRCDIR}/do_conv.f ${OBJDIR}/emu_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/do_conv.x ${SRCDIR}/do_conv.f ${OBJDIR}/emu_sub.o 

# Adjoint Tool (adj)
adj: ${SRCDIR}/adj.f ${OBJDIR}/adj_sub.o ${OBJDIR}/emu_sub.o
	$(FC) $(FFLAGS) -o ${OBJDIR}/adj.x ${SRCDIR}/adj.f ${OBJDIR}/adj_sub.o ${OBJDIR}/emu_sub.o

# Forward Gradient Tool (fgrd)
fgrd_all: fgrd_spec fgrd_pert fgrd

fgrd: ${SRCDIR}/fgrd.f ${OBJDIR}/emu_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/fgrd.x ${SRCDIR}/fgrd.f ${OBJDIR}/emu_sub.o

fgrd_pert: ${SRCDIR}/fgrd_pert.f
	$(FC) $(FFLAGS) -o ${OBJDIR}/fgrd_pert.x ${SRCDIR}/fgrd_pert.f

fgrd_spec: ${SRCDIR}/fgrd_spec.f ${OBJDIR}/emu_sub.o
	$(FC) $(FFLAGS) -o ${OBJDIR}/fgrd_spec.x ${SRCDIR}/fgrd_spec.f ${OBJDIR}/emu_sub.o

# Sampling Tool (samp)
samp_all: samp do_samp 

samp: ${SRCDIR}/samp.f ${OBJDIR}/emu_sub.o ${OBJDIR}/adj_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/samp.x ${SRCDIR}/samp.f ${OBJDIR}/emu_sub.o ${OBJDIR}/adj_sub.o 

do_samp: ${SRCDIR}/do_samp.f ${OBJDIR}/emu_sub.o 
	$(FC) $(FFLAGS) -o ${OBJDIR}/do_samp.x ${SRCDIR}/do_samp.f ${OBJDIR}/emu_sub.o



