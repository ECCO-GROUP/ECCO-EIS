import numpy as np
import global_emu_var as emu

def rd_grid(emu_ref):
    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    emu.xc = np.fromfile(f"{emu_ref}/XC.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.yc = np.fromfile(f"{emu_ref}/YC.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.rc = np.fromfile(f"{emu_ref}/RC.data", dtype=byte_order+'f4')

    emu.dxc = np.fromfile(f"{emu_ref}/DXC.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.dyc = np.fromfile(f"{emu_ref}/DYC.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.drc = np.fromfile(f"{emu_ref}/DRC.data", dtype=byte_order+'f4')

    emu.xg = np.fromfile(f"{emu_ref}/XG.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.yg = np.fromfile(f"{emu_ref}/YG.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.dxg = np.fromfile(f"{emu_ref}/DXG.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.dyg = np.fromfile(f"{emu_ref}/DYG.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))

    emu.rf = np.fromfile(f"{emu_ref}/RF.data", dtype=byte_order+'f4')
    emu.drf = np.fromfile(f"{emu_ref}/DRF.data", dtype=byte_order+'f4')

    emu.hfacc = np.fromfile(f"{emu_ref}/hFacC.data", dtype=byte_order+'f4').reshape((emu.nr, emu.ny, emu.nx))
    emu.hfacw = np.fromfile(f"{emu_ref}/hFacW.data", dtype=byte_order+'f4').reshape((emu.nr, emu.ny, emu.nx))
    emu.hfacs = np.fromfile(f"{emu_ref}/hFacS.data", dtype=byte_order+'f4').reshape((emu.nr, emu.ny, emu.nx))

    emu.cs = np.fromfile(f"{emu_ref}/AngleCS.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.sn = np.fromfile(f"{emu_ref}/AngleSN.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))

    emu.rac = np.fromfile(f"{emu_ref}/RAC.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.ras = np.fromfile(f"{emu_ref}/RAS.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.raw = np.fromfile(f"{emu_ref}/RAW.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))
    emu.raz = np.fromfile(f"{emu_ref}/RAZ.data", dtype=byte_order+'f4').reshape((emu.ny, emu.nx))

    emu.dvol3d = emu.hfacc.copy()

    for k in range(emu.nr):
        emu.dvol3d[k, :, :] *= emu.rac * emu.drf[k]
