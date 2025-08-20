function [budg_msk, nmsk] = rd_budg_msk(fdir)
% RD_BUDG_MSK  Read EMU 3D mask files emu_budg.msk3d_*
%
% Each file contains:
%   [int32]      npts (number of points)
%   [char*80]    name (ASCII, 80 bytes)
%   [float32 x npts] values

files = dir(fullfile(fdir, 'emu_budg.msk3d_*'));
nmsk = length(files);

if nmsk == 0
    warning('No emu_budg.msk3d_* files found in %s', fdir);
    budg_msk = {};
    return;
end

budg_msk = cell(nmsk, 1);

for i = 1:nmsk
    fname = fullfile(fdir, files(i).name);
    fid = fopen(fname, 'rb', 'ieee-be');

    if fid == -1
        error('Cannot open %s', fname);
    end

% Extract mask name from filename
    [~, fname_only, ext] = fileparts(fname);
    fname_combined = [fname_only, ext];  % reconstruct full filename, e.g., 'emu_budg.msk3d_a'
    prefix = 'emu_budg.msk3d_';
    msk_name = fname_combined(length(prefix)+1:end);
    budg_msk{i}.name = msk_name;

% Dimension of mask 
    npts = fread(fid, 1, 'int32');
    budg_msk{i}.npts = npts;

% Mask values 
    msk_val = fread(fid, npts, 'float32');
    budg_msk{i}.f_msk = msk_val;

    msk_val = fread(fid, npts, 'int32');
    budg_msk{i}.i_msk = msk_val;
    msk_val = fread(fid, npts, 'int32');
    budg_msk{i}.j_msk = msk_val;
    msk_val = fread(fid, npts, 'int32');
    budg_msk{i}.k_msk = msk_val;

    fclose(fid);

end
