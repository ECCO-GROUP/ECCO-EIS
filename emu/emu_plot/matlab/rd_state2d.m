function fgrd = rd_state2d(fname, ivar)
    % RD_STATE2D  Read 2D MITgcm output (double precision -> single precision)
    %
    %   fgrd = rd_state2d(fname, ivar)
    %
    %   Inputs:
    %     fname - string: full path to binary file
    %     ivar  - integer: 1-based index of variable (e.g., 1=SSH, 2=OBP)
    %
    %   Output:
    %     fgrd  - 2D array (ny x nx), returned in single precision

    % --- Access EMU grid parameters from global struct ---
    global emu

    if ~isfield(emu, 'nx') || ~isfield(emu, 'ny')
        error('EMU grid not initialized. Run rd_grid or set emu.nx and emu.ny first.');
    end

    nx = emu.nx;
    ny = emu.ny;

    % --- Open binary file in big-endian format ---
    fid = fopen(fname, 'rb', 'ieee-be');
    if fid == -1
        error('Could not open file: %s', fname);
    end

    % Skip to the correct variable (1-based index)
    offset = (ivar - 1) * nx * ny * 8;  % 8 bytes per float64
    fseek(fid, offset, 'bof');

    % Read double-precision data and convert to single
    fgrd_double = fread(fid, [nx, ny], 'float64');
    fclose(fid);

%    fgrd = single(fgrd_double');
    fgrd = single(fgrd_double);

end
