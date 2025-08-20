function [budg_mkup, nmkup] = rd_budg_mkup(fdir, budg_msk)
% RD_BUDG_MKUP  Read EMU 3D converging fluxes emu_budg.mkup_*
% 
% Usage:
%   [budg_mkup, nmkup] = rd_budg_mkup(fdir, budg_msk)
%
% Each file emu_budg.mkup_x:
%   - 1 byte: mask ID character (e.g., 'a', 'b')
%   - 4 bytes: integer 'isum' (array index of corresponding budget term)
%   - rest: npts Ãƒ— nmonths float32 values

% List mkup files
files = dir(fullfile(fdir, 'emu_budg.mkup_*'));
nmkup = length(files);

if nmkup == 0
    warning('No emu_budg.mkup_* files found in %s', fdir);
    budg_mkup = {};
    return;
end

budg_mkup = cell(nmkup, 1);
prefix = 'emu_budg.mkup_';

for im = 1:nmkup
    fname = fullfile(files(im).folder, files(im).name);
    fid = fopen(fname, 'rb', 'ieee-be');
    if fid == -1
        error('Cannot open file: %s', fname);
    end

    % Extract variable name (after mkup_)
    [~, fshort, fext] = fileparts(fname);
    ip = strfind(fext, 'mkup_');
    var = fext(ip+5:end);

    % Read mask ID (1 byte character)
    fmsk = fread(fid, 1, 'char=>char');

    % Find corresponding mask
    imsk = -1;
    for j = 1:length(budg_msk)
        if strcmp(budg_msk{j}.name, fmsk)
            imsk = j;
            break;
        end
    end
    if imsk == -1
        error('No matching mask found for mask ID "%s" in file %s', fmsk, fname);
    end
    mkup_dim = budg_msk{imsk}.npts;

    % Read array index (isum)
    isum = fread(fid, 1, 'int32');

    % Compute file size and number of months
    fseek(fid, 0, 'eof');
    fsize = ftell(fid);
    fseek(fid, 5, 'bof');  % skip 1 byte + 4 bytes
    nmonths = (fsize - 5) / (4 * mkup_dim);

    % Read mkup time series
    mkup = fread(fid, [mkup_dim, nmonths], 'float32')';
    fclose(fid);

    % Store results
    budg_mkup{im}.var = var;
    budg_mkup{im}.msk = fmsk;
    budg_mkup{im}.isum = isum;
    budg_mkup{im}.mkup_dim = mkup_dim;
    budg_mkup{im}.mkup = mkup;
end
