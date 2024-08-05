import numpy as np
import global_emu_var as emu

# Define the constants
d2r = np.pi / 180.0

# --------------------------------------------
def nat2globe(llc):
    """
    Reorder a native 1170-by-90 format array (llc) to a geographically contiguous global 360-by-360 array (glb) for visualization.
    
    Parameters:
    llc (np.ndarray): Input array of shape (1170, 90).
    
    Returns:
    np.ndarray: Output array of shape (360, 360).
    """
    # Get the size of the input array
    nx = llc.shape[1]

    # Calculate extended dimensions
    nx2 = nx * 2
    nx3 = nx * 3
    nx4 = nx * 4

    # Initialize the global array
    glb = np.zeros((nx4, nx4), dtype=np.float32)

    # Face 1
    glb[0:nx3, 0:nx] = llc[0:nx3, :]

    # Face 2
    ioff = nx
    glb[0:nx3, nx:nx2] = llc[nx3:nx3*2, :]

    # Face 3
    glb[nx3:, 0:nx] = np.rot90(llc[2*nx3:2*nx3+nx, :], k=3)

    # Face 4
    dum = np.zeros((nx, nx3), dtype=np.float32)
    dum[:, :] = llc[2*nx3+nx:3*nx3+nx, :].reshape(nx, nx3)
    glb[0:nx3, nx2:nx3] = np.rot90(dum, k=1)

    # Face 5
    dum[:, :] = llc[3*nx3+nx:, :].reshape(nx, nx3)
    glb[0:nx3, nx3:] = np.rot90(dum, k=1)

    return glb

# --------------------------------------------
def slct_2d_pt(): 
    """
    Select a horizontal location based on user input.
    """
    print('\nChoose horizontal location ... ')
    print('Enter 1 to select native grid location (i,j),')
    print('or 9 to select by longitude/latitude ... (1 or 9)?')

    try:
        iloc = int(input().strip())
    except ValueError:
        print("Invalid input. Defaulting to selection by index (1).")
        iloc = 1

    if iloc != 9:
        # Select by native grid location
        pert_i = 0
        pert_j = 0

        print('Identify point in native grid ...')
        while pert_i < 1 or pert_i > emu.nx:
            try:
                pert_i = int(input(f'i ... (1-{emu.nx}) ? ').strip())
            except ValueError:
                print("Invalid input. Enter an integer.")

        while pert_j < 1 or pert_j > emu.ny:
            try:
                pert_j = int(input(f'j ... (1-{emu.ny}) ? ').strip())
            except ValueError:
                print("Invalid input. Enter an integer.")

        pert_x = emu.xc[pert_j - 1, pert_i - 1]
        pert_y = emu.yc[pert_j - 1, pert_i - 1]

    else:
        # Select by longitude/latitude
        check_d = False
        pert_x = 1.0
        pert_y = 1.0
        print("Enter location's lon/lat (x,y) ...")

        while not check_d:
            try:
                pert_x = float(input('longitude ... (E)? ').strip())
                pert_y = float(input('latitude ... (N)? ').strip())
            except ValueError:
                print("Invalid input. Enter valid numbers for longitude and latitude.")
                continue

            pert_i, pert_j = ijloc(pert_x, pert_y)

            # Make sure point is wet
            if emu.hfacc[0, pert_j-1, pert_i-1] == 0.0:
                print(f'Closest C-grid ({pert_i},{pert_j}) is dry.')
                print('Select another point ...')
            else:
                check_d = True

    # Confirm location
    print(f'...... Chosen point is (i,j) = {pert_i},{pert_j}')
    print(f'C-grid is (long E, lat N) = {emu.xc[pert_j-1, pert_i-1]}, {emu.yc[pert_j-1, pert_i-1]}')
    pert_x = emu.xc[pert_j-1, pert_i-1] 
    pert_y = emu.yc[pert_j-1, pert_i-1] 

    return pert_x, pert_y, pert_i, pert_j

# --------------------------------------------
def ijloc(pert_x, pert_y):
    """
    Locate the closest model grid point (i, j) to a given longitude/latitude (x, y).
    
    Parameters:
    - pert_x (float): Longitude to locate.
    - pert_y (float): Latitude to locate.
    
    Returns:
    - pert_i (int): Index i of the closest grid point.
    - pert_j (int): Index j of the closest grid point.
    """
    # Reference (x, y) to -180 to 180 East and -90 to 90 North
    pert_x = pert_x % 360.0
    if pert_x > 180.0:
        pert_x -= 360.0

    pert_y = pert_y % 360.0
    if pert_y > 180.0:
        pert_y -= 360.0
    if pert_y > 90.0:
        pert_y = 180.0 - pert_y
    if pert_y < -90.0:
        pert_y = -180.0 - pert_y

    # Find (i, j) pair within 10 degrees of (x, y)
    pert_i = -9
    pert_j = -9
    target = 9e9

    for j in range(emu.ny):
        for i in range(emu.nx):
            if abs(emu.yc[j, i] - pert_y) < 10.0:
                dumdist = np.sin(pert_y * d2r) * np.sin(emu.yc[j, i] * d2r) + \
                          np.cos(pert_y * d2r) * np.cos(emu.yc[j, i] * d2r) * np.cos((emu.xc[j, i] - pert_x) * d2r)
                dumdist = np.arccos(dumdist)
                if dumdist < target:
                    pert_i = i+1
                    pert_j = j+1
                    target = dumdist

    return pert_i, pert_j

