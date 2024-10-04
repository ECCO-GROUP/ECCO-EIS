import os
import numpy as np
import matplotlib.pyplot as plt
import global_emu_var as emu
import lib_python as emupy
import struct
import glob

# --------------------------------------------
def rd_budg_sum(ff):
    # Read and sort Budget Tool output file emu_budg.sum_*
    
    # ---------------
    # Open emu_budg.sum_? file
    if not os.path.exists(ff):
        print('*********************************************')
        print(f'File {ff} not found ...')
        print('')
        return None, None, None, None, None, None, None, None, None, None

    with open(ff, 'rb') as file:
        # ---------------
        # Read ID of budget quantity (big-endian format)
        ibud = struct.unpack('>l', file.read(4))[0]
        if ibud < 1 or ibud > 5:
            print(f'INVALID ibud in this Budget Tool output ... {ibud}')
            return None, None, None, None, None, None, None, None, None, None
        ibud -= 1
        
        # ---------------
        # Read number of months in the time-series (big-endian format)
        nmonths = struct.unpack('>l', file.read(4))[0]

        # ---------------
        # Read budget variable name and its time-series.
        emubudg_name = []
        emubudg = np.zeros((0, nmonths))

        while True:
            fvar_bytes = file.read(12)
            if len(fvar_bytes) < 12:
                break
            fvar = fvar_bytes.decode('utf-8').strip()
            emubudg_name.append(fvar)
            
            fdum = np.array(struct.unpack(f'>{nmonths}f', file.read(4 * nmonths)))
            emubudg = np.row_stack((emubudg, fdum))
        
        nvar = len(emubudg_name)

        # -----------------------------------
        # For plotting LHS vs RHS of the budget
        tt = np.arange(nmonths) / 12.0 + 1992.0

        fdum = emubudg[2, :].copy()
        for i in range(3, nvar):
            fdum += emubudg[i, :]

        lhs = emubudg[1, :]
        rhs = fdum

        # -----------------------------------
        # Sum the different terms that make up advection (adv), mixing (mix), and forcing (frc)
        
        # adv
        adv = np.zeros(nmonths)
        nterms = 0
        for it in range(nvar):
            if 'adv' in emubudg_name[it]:
                adv += emubudg[it, :]
                nterms += 1
        if nterms == 0:
            print('**** no adv terms ***')

        # mix
        mix = np.zeros(nmonths)
        nterms = 0
        for it in range(nvar):
            if 'mix' in emubudg_name[it]:
                mix += emubudg[it, :]
                nterms += 1
        if nterms == 0:
            print('**** no mix terms ***')

        # frc
        frc = np.zeros(nmonths)
        nterms = 0
        for it in range(nvar):
            if emubudg_name[it] not in ['dt', 'lhs']:
                if all(keyword not in emubudg_name[it] for keyword in ['dt', 'lhs', 'adv', 'mix']):
                    frc += emubudg[it, :]
                    nterms += 1
        if nterms == 0:
            print('**** no frc terms ***')

        return emubudg_name, emubudg, lhs, rhs, adv, mix, frc, nvar, ibud, tt

import numpy as np
import os
import glob
import struct

# --------------------------------------------
def rd_budg_msk(fdir):
    # Create template for mask
    msk_template = {
        'msk': '',
        'msk_dim': 0,
        'f_msk': None,
        'i_msk': None,
        'j_msk': None,
        'k_msk': None
    }

    # ID mask files
    ff = os.path.join(fdir, 'emu_budg.msk3d_*')
    fmsk = glob.glob(ff)
    fmsk.sort()
    nmsk = len(fmsk)
    
    if nmsk == 0:
        print('*********************************************')
        print(f'nmsk = {nmsk}')
        print('No emu_budg.msk3d_? file found ...')
        print('')
        return None

    # Initialize budg_msk as a list of dictionaries based on the template
    budg_msk = [msk_template.copy() for _ in range(nmsk)]

    mag = 0.0
    inum = 0
    fvar = '.msk3d_'

    # Loop among all masks
    for im in range(nmsk):
        with open(fmsk[im], 'rb') as file:
            # ID mask type
            ip1 = fmsk[im].find(fvar) + len(fvar)
            ip2 = len(fmsk[im])
            budg_msk[im]['msk'] = fmsk[im][ip1:ip2]

            # Read inum (dimension of the mask)
            inum = struct.unpack('>l', file.read(4))[0]  # Assuming big-endian
            budg_msk[im]['msk_dim'] = inum

            # Initialize arrays
            budg_msk[im]['f_msk'] = np.zeros(inum, dtype=np.float32)
            budg_msk[im]['i_msk'] = np.zeros(inum, dtype=np.int32)
            budg_msk[im]['j_msk'] = np.zeros(inum, dtype=np.int32)
            budg_msk[im]['k_msk'] = np.zeros(inum, dtype=np.int32)

            # Read mask data
            budg_msk[im]['f_msk'] = np.array(struct.unpack(f'>{inum}f', file.read(4 * inum)), dtype=np.float32)
            budg_msk[im]['i_msk'] = np.array(struct.unpack(f'>{inum}l', file.read(4 * inum)), dtype=np.int32)
            budg_msk[im]['j_msk'] = np.array(struct.unpack(f'>{inum}l', file.read(4 * inum)), dtype=np.int32)
            budg_msk[im]['k_msk'] = np.array(struct.unpack(f'>{inum}l', file.read(4 * inum)), dtype=np.int32)

    return budg_msk

# --------------------------------------------
class MkupTemplate:
    def __init__(self, var='*', msk='*', isum=1, mkup_dim=0, mkup=None):
        self.var = var      # Variable name (postfix in filename)
        self.msk = msk      # Mask name
        self.isum = isum    # Corresponding array number in emu_budg.sum file
        self.mkup_dim = mkup_dim  # Dimension of the budget makeup field
        self.mkup = mkup    # Time-series of the budget component

def rd_budg_mkup(fdir, budg_msk):
    # Define the template for mkup
    mkup_template = MkupTemplate()

    # Find budget makeup files
    ff = os.path.join(fdir, 'emu_budg.mkup_*')
    fmkup = glob.glob(ff)
    fmkup.sort()
    nmkup = len(fmkup)

    if nmkup == 0:
        print('*********************************************')
        print(f'nmkup = {nmkup}')
        print('No emu_budg.mkup_? file found ...')
        print('')
        return [], nmkup

    # Initialize budg_mkup structure (list of MkupTemplate objects)
    budg_mkup = [MkupTemplate() for _ in range(nmkup)]

    fvar = '.mkup_'
    iterm = 1

    for im in range(nmkup):
        # Open file
        with open(fmkup[im], 'rb') as file:
            # Identify makeup name
            ip1 = fmkup[im].find(fvar) + len(fvar)
            ip2 = len(fmkup[im])
            budg_mkup[im].var = fmkup[im][ip1:ip2]

            file.seek(0)
            # Read the 1-byte character (fmsk)
            fmsk = file.read(1).decode('utf-8')  # Only read 1 byte for the character

            budg_mkup[im].msk = fmsk

            imsk = next((i for i, msk in enumerate(budg_msk) if msk["msk"] == fmsk), -1)

            if imsk == -1:
                print(f'rd_budg_mkup: No corresponding mask ... {fvar}')
                return [], nmkup

            # Read corresponding array number in emu_budg.sum (big-endian integer)
            iterm = np.fromfile(file, dtype='>i4', count=1)[0]  # big-endian 4-byte integer

            budg_mkup[im].isum = iterm

            # Read time-series of makeup term
            mkup_dim = budg_msk[imsk]["msk_dim"]
            budg_mkup[im].mkup_dim = mkup_dim

            # Determine the number of months of data
            file_size = os.path.getsize(fmkup[im])
            nmonths = (file_size - 2) // (4 * mkup_dim)

            budg_mkup[im].mkup = np.zeros((nmonths, mkup_dim), dtype=np.float32)

            # Read the actual data (big-endian floating-point numbers)
            fdum = np.fromfile(file, dtype='>f4', count=mkup_dim * nmonths)  # big-endian float32
            budg_mkup[im].mkup = fdum.reshape((nmonths, mkup_dim))

    return budg_mkup, nmkup
