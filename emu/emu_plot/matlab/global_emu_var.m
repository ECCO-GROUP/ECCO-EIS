function global_emu_var()
    % global_emu_var Initialize EMU global variables with defaults

    global emu
    emu = struct();

    % Grid dimensions (set manually or externally before rd_grid)
    emu.nx = 90;
    emu.ny = 1170;
    emu.nr = 50;

    % Model grid variables
    emu.xc = [];
    emu.yc = [];
    emu.rc = [];
    emu.dxc = [];
    emu.dyc = [];
    emu.drc = [];
    emu.xg = [];
    emu.yg = [];
    emu.dxg = [];
    emu.dyg = [];
    emu.rf = [];
    emu.drf = [];
    emu.hfacc = [];
    emu.hfacw = [];
    emu.hfacs = [];
    emu.cs = [];
    emu.sn = [];
    emu.rac = [];
    emu.ras = [];
    emu.raw = [];
    emu.raz = [];
    emu.dvol3d = [];

    % 1) Sampling Tool
    emu.smp = [];
    emu.smp_mn = [];
    emu.smp_hr = [];

    % 2) Forward Gradient Tool
    emu.fgrd2d = [];
    emu.fgrd3d = [];

    % 3) Adjoint Tool
    emu.adxx = [];

    % 4) Convolution Tool
    emu.recon1d = [];
    emu.istep = [];
    emu.fctrl = [];
    emu.ev_lag = [];
    emu.ev_ctrl = [];
    emu.ev_space = [];

    % 5) Tracer Tool
    emu.trc3d = [];

    % 6) Budget Tool
    emu.budg_tend = [];
    emu.budg_tend_name = [];
    emu.budg_tint = [];
    emu.budg_tint_name = [];
    emu.budg_msk = [];
    emu.budg_nmsk = [];
    emu.budg_mkup = [];
    emu.budg_nmkup = [];

    % 7) Modified Simulation Tool
    emu.fld2d = [];
    emu.fld3d = [];

    % 8) Attribution Tool
    emu.atrb = [];
    emu.atrb_mn = [];
    emu.atrb_ctrl = [];
    emu.atrb_hr = [];
end
