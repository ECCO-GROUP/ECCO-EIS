function fgrd = rd_state3d(fname, ivar)
    % RD_STATE3D  Read 3D MITgcm output using EMU grid global struct
    %
    %   fgrd = rd_state3d(fname, ivar)
    %
    %   Inputs:
    %     fname - full path to binary file
    %     ivar  - 1-based index of variable to extract (e.g., 1=THETA, 2=SALT, etc.)
    %
    %   Output:
    %     fgrd  - 3D field (ny x nx x nr) in single precision

    % --- Access EMU grid parameters from global struct ---
    global emu

    if ~isfield(emu, 'nx') || ~isfield(emu, 'ny') || ~isfield(emu, 'nr')
        error('EMU grid not initialized. Run rd_grid or define emu.nx, emu.ny, emu.nr.');
    end

    nx = emu.nx;
    ny = emu.ny;
    nr = emu.nr;

    % --- Open binary file in big-endian format ---
    fid = fopen(fname, 'rb', 'ieee-be');
    if fid == -1
        error('Cannot open file: %s', fname);
    end

    % Compute offset in bytes (ivar is 1-based)
    offset = (ivar - 1) * nx * ny * nr * 4;  % 4 bytes per float32
    fseek(fid, offset, 'bof');

    fgrd = fread(fid, [nx*ny, nr], 'float32');
    fclose(fid);

    % Reshape and convert
    fgrd = reshape(fgrd, [nx, ny, nr]);
%    fgrd = permute(fgrd, [3, 2, 1]);  % final shape: [nr, ny, nx]

end
