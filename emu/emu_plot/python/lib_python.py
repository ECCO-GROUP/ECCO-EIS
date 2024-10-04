import os
import numpy as np
import glob
import matplotlib.pyplot as plt
import global_emu_var as emu

# Define the constants
d2r = np.pi / 180.0

# Create a custom colormap that maps masked values to gray
cmap = plt.cm.jet
cmap.set_bad(color='gray')  # Set the color for masked elements to gray

# --------------------------------------------
def nat2globe(llc):
    """
    Reorder a native 1170-by-90 format array (llc) to a geographically
    contiguous global 360-by-360 array (glb) for visualization.
    
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

# --------------------------------------------
def list_var(module):
    """
    list variables in module
    """

    # List all attributes in the module
    attributes = dir(module)

    # Filter to include only non-callable, non-special, and non-None variables
    variables = [
        attr for attr in attributes
        if not callable(getattr(module, attr))
        and not attr.startswith("__")
        and getattr(module, attr) is not None
    ]

    # Print the variable names, their values, or shape if it's an array
    for var in variables:
        value = getattr(module, var)
        if isinstance(value, np.ndarray):
            print(f"{var} shape = {value.shape}")
        else:
            print(f"{var} = {value}")

# --------------------------------------------
def index_n2g(ynat, xnat):

    # Ensure xnat and ynat are numpy arrays for easier handling
    ynat = np.atleast_1d(ynat)
    xnat = np.atleast_1d(xnat)

    # Initialize the native array
    native = np.arange(emu.nx * emu.ny).reshape((emu.ny, emu.nx)) + 1

    # Perform native to globe mapping
    globe = nat2globe(native)

    # Get the values at each (xnat, ynat) pair
    inat = native[ynat, xnat]

    # Find the indices in the globe array where values match each `inat`
    xglb, yglb = [], []
    for value in inat:
        iglobe = np.where(globe == value)
        if iglobe[0].size > 0:
            yglb.append(iglobe[0][0])  # Take the first matching index
            xglb.append(iglobe[1][0])
        else:
            yglb.append(-1)  # Indicate no match found
            xglb.append(-1)

    return yglb, xglb

# --------------------------------------------
def index_g2n(yglb, xglb):

    # Ensure xglb and yglb are numpy arrays for easier handling
    yglb = np.atleast_1d(yglb)
    xglb = np.atleast_1d(xglb)

    # Initialize the native array
    native = np.arange(emu.nx * emu.ny).reshape((emu.ny, emu.nx)) + 1

    # Perform native to globe mapping
    globe = nat2globe(native)

    # Get the values at each (xnat, ynat) pair
    iglb = globe[yglb, xglb]

    # Find the indices in the native array where values match each `iglb`
    xnat, ynat = [], []
    for value in iglb:
        inat = np.where(native == value)
        if inat[0].size > 0:
            ynat.append(inat[0][0])  # Take the first matching index
            xnat.append(inat[1][0])
        else:
            ynat.append(-1)  # Indicate no match found
            xnat.append(-1)

    return ynat, xnat

# --------------------------------------------
def rd_state2d_r4(ff, ivar): 
    """
    Read a particular record (ivar) of a 2d file (ff) and return in fld2d 
    """

    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    # Define variables 
    fld2d = np.zeros((emu.ny, emu.nx), dtype=np.float32)

    record_size = emu.nx * emu.ny * 4  # Size of one record in bytes (float32 = 4 bytes)

    # Open the file and read data
    with open(ff, 'rb') as file:
        # Seek to the start of the desired record (ivar)
        file.seek(ivar * record_size)

        # Read the nx*ny record from the file
        fld2d = np.frombuffer(file.read(record_size), dtype=byte_order+'f4').reshape((emu.ny, emu.nx))

    return fld2d

# --------------------------------------------
def rd_state2d(ff, ivar): 
    """
    Read a particular record (ivar) of a real*8 2d file (ff) and return in fld2d 
    """

    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    # Define variables 
    fld2d = np.zeros((emu.ny, emu.nx), dtype=np.float32)

    record_size = emu.nx * emu.ny * 8  # Size of one record in bytes (float64 = 8 bytes)

    # Open the file and read data
    with open(ff, 'rb') as file:
        # Seek to the start of the desired record (ivar)
        file.seek(ivar * record_size)

        # Read the nx*ny record from the file
        fld2d_float64 = np.frombuffer(file.read(record_size), dtype=byte_order+'f8').reshape((emu.ny, emu.nx))

        # Convert the data to float32
        fld2d = fld2d_float64.astype(np.float32)

    return fld2d

# --------------------------------------------
def rd_state3d(ff, ivar): 
    """
    Read a particular record (ivar) of a 3d file (ff) and return in fld3d 
    """

    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    # Define variables
    fld3d = np.zeros((emu.nr, emu.ny, emu.nx), dtype=np.float32)

    record_size = emu.nx * emu.ny * emu.nr * 4  # Size of one record in bytes (float32 = 4 bytes)

    # Open the file and read data
    with open(ff, 'rb') as file:
        # Seek to the start of the desired record (ivar)
        file.seek(ivar * record_size)

        # Read the nx*ny*nr record from the file
        fld3d = np.frombuffer(file.read(record_size), dtype=byte_order+'f4').reshape((emu.nr, emu.ny, emu.nx))

    return fld3d

# --------------------------------------------
def plt_state2d(v2d, pinfo): 
    """
    Plot 2d variable (v2d) scaled to O(1) 
    with variable information (pinfo) printed as caption. 
    """

    # Define variables 
    dum2d = np.zeros((emu.ny, emu.nx), dtype=np.float32)

    ref2d = nat2globe(emu.hfacc[0,:,:])

    # Scale
    dum2d[:] = v2d[:]
    dum = np.max(np.abs(dum2d))
    if dum != 0:
        order_of_magnitude = np.floor(np.log10(np.abs(dum)))
        dscale = 10.0 ** (-order_of_magnitude)
    else:
        dscale = 0.0
        
    dum2d *= dscale

    dumg = nat2globe(dum2d)

    # Mask dry grid points 
    masked_dumg = np.ma.masked_where(ref2d == 0, dumg)

    # Plot 
    plt.figure(figsize=(10,10))
    ftitle = f"{pinfo} scaled by x{dscale:.9e}"
    plt.title(ftitle)        
    plt.imshow(masked_dumg, origin='lower',cmap=cmap, aspect='auto')
    plt.colorbar()

    plt.ion()  # Enable interactive mode
    plt.show(block=False)  # Show the plot without blocking

# --------------------------------------------
def plt_state3d(v3d, pinfo, ivar): 
    """
    Plot a particular depth of a 3d variable (v3d) scaled to O(1) 
    with mask corresponding to the variable (ivar)
       ivar = 0 (THETA), 1 (SALT), 2 (U), 3 (V)
    with variable information (pinfo) printed as caption. 
    """

    # Define variables 
    dum2d = np.zeros((emu.ny, emu.nx), dtype=np.float32)

    kdum = 1
    while kdum >= 1 and kdum <= emu.nr: 
        kdum = int(input(f"Enter depth # to plot ... (1-{emu.nr})? "))
        if kdum < 1 or kdum > emu.nr:
            break
        kk = kdum - 1
        
        # Scale
        dum2d[:] = v3d[kk,:,:]
        dum = np.max(np.abs(dum2d))
        if dum != 0:
            order_of_magnitude = np.floor(np.log10(np.abs(dum)))
            dscale = 10.0 ** (-order_of_magnitude)
        else:
            dscale = 0.0
        
        dum2d *= dscale
        
        dumg = nat2globe(dum2d)

        # ID Mask region 
        if ivar == 2:
            ref2d = nat2globe(emu.hfacw[kk,:,:])
        elif ivar == 3:
            ref2d = nat2globe(emu.hfacs[kk,:,:])
        else:
            ref2d = nat2globe(emu.hfacc[kk,:,:])
            
        # Mask dry grid points 
        masked_dumg = np.ma.masked_where(ref2d == 0, dumg)

        # Plot 
        plt.figure(figsize=(10,10))
        ftitle = f"{pinfo} scaled by x{dscale:.9e}"
        plt.title(ftitle)        
        plt.imshow(masked_dumg, origin='lower',cmap=cmap, aspect='auto')
        plt.colorbar()

        plt.ion()  # Enable interactive mode
        plt.show(block=False)  # Show the plot without blocking


# --------------------------------------------
def lib_chk_emu_name(fdir):
    """
    Truncate fdir to directory name of emu output, in case fdir points to a
    subdirectory of emu output. 
    """

    # Check if the input is provided
    if not fdir:
        print('Error: No input provided.')
        return ' '

    # Check if the input is a string
    if not isinstance(fdir, str):
        print('Error: Input is not a string.')
        return ' '

    # Remove trailing slash if present
    if fdir.endswith('/'):
        fdir = fdir[:-1]

    # Extract the directory name
    directory_name = os.path.basename(fdir)

    # Check if the directory name starts with 'emu_'
    if directory_name.startswith('emu_'):
        # The directory name starts with "emu_", no changes needed
        pass
    else:
        # Extract the parent directory path
        parent_directory = os.path.dirname(fdir)

        # Check if the parent directory name start with 'emu_'
        parent_directory_name = os.path.basename(fdir)
        if parent_directory_name.startswith('emu_'): 
            # Substitute parent directory path as fdir
            fdir = parent_directory
        else:
            print('Error: Directory name does not conform to EMU syntax')
            return ' '

    return fdir

# --------------------------------------------
def lib_var(ss, flag=False):
    """
    Compute variance with respect to the mean.
    
    Parameters:
    ss : numpy array
        Input array.
    flag : bool, optional
        If True, only consider values not equal to 32767. Default is False.
        
    Returns:
    float
        Computed variance.
    """
    dummy = 32767.0

    if flag:
        # Find elements that are not equal to 32767
        ok = ss != 32767.0
        nok = np.sum(ok)  # Count of valid elements
        
        if nok != 0:
            mean = np.sum(ss[ok]) / nok
            dummy = np.sum((ss[ok] - mean) ** 2) / nok
    else:
        mean = np.mean(ss)
        dummy = np.mean((ss - mean) ** 2)

    return dummy

# --------------------------------------------
def lib_pinv(a, mrange=1e-4):
    """
    Compute the pseudo-inverse of matrix `a` using SVD.
    
    Parameters:
    a (numpy array): Input matrix.
    mrange (float): Threshold to filter out small singular values.
    
    Returns:
    numpy array: The pseudo-inverse of the input matrix `a`.
    """
    # Perform Singular Value Decomposition (SVD)
    u, s, v_t = np.linalg.svd(a, full_matrices=False)
    
    # Find indices of singular values that are below the threshold
    zero_indices = np.where(s < np.max(s) * mrange)[0]
    
    if zero_indices.size > 0:
        print(f"Non-zero singular values found: {len(s) - len(zero_indices)}")
        print(f"Zero singular values found: {len(zero_indices)}")
        
        # Set small singular values to zero for stability
        s[zero_indices] = 1.0  # Avoid division by zero
        si = np.diag(1.0 / s)
        si[zero_indices, zero_indices] = 0.0  # Set small singular values to zero
    else:
        # No singular values are below the threshold
        si = np.diag(1.0 / s)
    
    # Compute the pseudo-inverse
    pseudo_inverse = np.dot(v_t.T, np.dot(si, u.T))
    
    return pseudo_inverse

# --------------------------------------------
def lib_mean_trend(time):
    """
    Compute inverse operator for estimating mean and trend.
    
    Parameters:
    time (numpy array): Time coordinate
    
    Returns:
    tcent (float): Mean time (time offset)
    inva (numpy array): 2D array to compute mean and trend (inverse of design matrix)
    a (numpy array): Design matrix (ntime x 2)
    """
    ntime = len(time)
    
    # Compute the central time (mean of min and max time)
    tcent = 0.5 * (np.max(time) + np.min(time))
    
    # Create the design matrix `a`
    a = np.zeros((ntime, 2), dtype=float)
    a[:, 0] = 1.0  # First column is all ones (to capture the mean)
    a[:, 1] = time - tcent  # Second column is time offset from `tcent` (to capture the trend)
    
    # Compute the pseudo-inverse of `a` to solve the least squares problem
    inva = lib_pinv(a, mrange=1e-4)
    
    return tcent, inva, a

# --------------------------------------------
def get_timestep(fname, fprefix):
    """
    Extract timestep from MITgcm output file name.
    
    Parameters:
    fname (str): The full file name.
    fprefix (str): The prefix string to search for in the file name.
    
    Returns:
    int: The extracted timestep, or a default value if not found.
    """
    # Default value for timestep
    timestep = -999999999

    # Search for the prefix string in the file name
    pos = fname.find(fprefix)
    
    # If the prefix is found, proceed to extract the number
    if pos != -1:
        # Find the position of the first '.' after the prefix
        dot_pos = fname.find('.', pos)
        
        # Extract the number part starting from the dot position
        if dot_pos != -1:
            # Extract the number as a substring after the dot
            number_string = fname[dot_pos + 1:-5]
            
            try:
                # Convert the number string to an integer (removes preceding zeros)
                timestep = int(number_string)
            except ValueError:
                print('Error converting the extracted string to an integer.')
        else:
            print('No dot found after prefix string.')
    else:
        print('Prefix string not found.')

    return timestep

# --------------------------------------------
def plot_state(fdir):
    """
    Read and plot standard state output.
    
    Parameters:
    fdir (str): The directory containing the output files.
    """
    
    # Search available output
    print('')
    print('Detected ')
    
    # Search for daily 2D files
    fdum = 'state_2d_set1_day.*.data'
    aa_2d_day = glob.glob(os.path.join(fdir, fdum))
    naa_2d_day = len(aa_2d_day)
    print(f'{naa_2d_day:6} files of {fdum}')
    
    # Search for monthly 2D files
    fdum = 'state_2d_set1_mon.*.data'
    aa_2d_mon = glob.glob(os.path.join(fdir, fdum))
    naa_2d_mon = len(aa_2d_mon)
    print(f'{naa_2d_mon:6} files of {fdum}')
    
    # Search for monthly 3D files
    fdum = 'state_3d_set1_mon.*.data'
    aa_3d_mon = glob.glob(os.path.join(fdir, fdum))
    naa_3d_mon = len(aa_3d_mon)
    print(f'{naa_3d_mon:6} files of {fdum}')
    
    # Test whether any output was detected
    ndum = max(naa_2d_day, naa_2d_mon, naa_3d_mon)
    
    if ndum != 0:
        # Plot available output
        f_var = ['SSH', 'OBP', 'THETA', 'SALT', 'U', 'V']
        nvar = len(f_var)
        
        print('')
        print('Choose variable to plot ... ')
        for i in range(nvar):
            pdum = f'{i+1}) {f_var[i]}'
            print(pdum)
        
        # Option to plot another field
        plot_another = 'Y'
        while plot_another.lower() == 'y':
            print('')
            fmd = input('Select monthly or daily mean ... (m/d)?\n(NOTE: daily mean available for SSH and OBP only.): ').lower()
            
            if fmd == 'd':
                if naa_2d_day != 0:
                    print('')
                    print('==> Reading and plotting daily means ... ')
                    while True:
                        pvar = int(input('Enter variable # to plot ... (1-2)? '))
                        if 1 <= pvar <= 2:
                            ivar = pvar - 1
                            break
                    print('')
                    print(f'Plotting ... {f_var[ivar]}')
                    
                    # Loop among daily mean 2D files
                    while True:
                        pfile = int(input(f'Enter file # to read ... (1-{naa_2d_day})? '))
                        if 1 <= pfile <= naa_2d_day:
                            ifile = pfile - 1
                            fld2d = rd_state2d(aa_2d_day[ifile], ivar)
                            
                            fname = os.path.basename(aa_2d_day[ifile])
                            pinfo = f'{f_var[ivar]} {pfile} {fname}'
                            plt_state2d(fld2d, pinfo)
                        else:
                            break
                    
                    emu.fld2d = fld2d 

                    print('*********************************************')
                    print('Returning variable ')
                    print('   fld2d: last plotted 2d field')
                    print('')
                else:
                    print('')
                    print('No daily mean output available ... ')
            
            elif fmd == 'm':
                print('')
                print('==> Reading and plotting monthly means ... ')
                while True:
                    pvar = int(input(f'Enter variable # to plot ... (1-{nvar})? '))
                    if 1 <= pvar <= nvar:
                        ivar = pvar - 1
                        break
                print('')
                print('-------------------')
                print(f'Plotting ... {f_var[ivar]}')
                
                if ivar <= 1:
                    if naa_2d_mon != 0:
                        print('')
                        print('==> Reading and plotting 2d monthly means ... ')
                        print(f'Plotting ... {f_var[ivar]}')
                        
                        # Loop among monthly mean 2D files
                        while True:
                            pfile = int(input(f'Enter file # to read ... (1-{naa_2d_mon})? '))
                            if 1 <= pfile <= naa_2d_mon:
                                ifile = pfile - 1
                                fld2d = rd_state2d(aa_2d_mon[ifile], ivar)
                                
                                fname = os.path.basename(aa_2d_mon[ifile])
                                pinfo = f'{f_var[ivar]} {pfile} {fname}'
                                plt_state2d(fld2d, pinfo)
                            else:
                                break

                        emu.fld2d = fld2d 
                        
                        print('*********************************************')
                        print('Returning variable ')
                        print('   fld2d: last plotted 2d field')
                        print('')
                    else:
                        print('')
                        print('No monthly mean 2d output available ... ')
                else:
                    if naa_3d_mon != 0:
                        print('')
                        print('==> Reading and plotting 3d monthly means ... ')
                        print(f'Plotting ... {f_var[ivar]}')
                        
                        # Loop among monthly mean 3D files
                        while True:
                            pfile = int(input(f'Enter file # to read ... (1-{naa_3d_mon})? '))
                            if 1 <= pfile <= naa_3d_mon:
                                ifile = pfile - 1
                                fld3d = rd_state3d(aa_3d_mon[ifile], ivar - 2)  # ivar-2 because no 3D SSH/OBP
                                
                                fname = os.path.basename(aa_3d_mon[ifile])
                                pinfo = f'{f_var[ivar]} {pfile} {fname}'
                                plt_state3d(fld3d, pinfo, ivar - 2)  # ivar-2 because no 3D SSH/OBP
                            else:
                                break

                        emu.fld3d = fld3d

                        print('*********************************************')
                        print('Returning variable ')
                        print('   fld3d: last plotted 3d field')
                        print('')
                    else:
                        print('')
                        print('No monthly mean 3d output available ... ')
            
            print('')
            plot_another = input('Plot another file ... (Y/N)? ').lower()
    
    else:
        # No available output
        print('')
        print('*********************************************')
        print('No standard state output found in directory ')
        print(fdir)

    return naa_2d_day, naa_2d_mon, naa_3d_mon
