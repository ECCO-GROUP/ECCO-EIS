function fgrd = rd_state2d_r4(fname, ivar)
    % RD_STATE2D_R4  Read 2D MITgcm output using EMU grid global struct
    %
    %   fgrd = rd_state2d_r4(fname, ivar)
    %
    %   Inputs:
    %     fname - full path to the binary data file
    %     ivar  - 1-based index of variable to extract
    %
    %   Output:
    %     fgrd  - 2D field (ny x nx)

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
        error('Cannot open file: %s', fname);
    end

    % --- Compute byte offset and read data ---
    offset = (ivar - 1) * nx * ny * 4;  % 4 bytes per float32
    fseek(fid, offset, 'bof');

    fgrd = fread(fid, [nx, ny], 'float32');
    fclose(fid);

    % --- Transpose to MATLAB (row-major) convention ---
%    fgrd = fgrd';
end
