function rd_grid(emu_ref)
    % RD_GRID Read grid files from EMU reference directory into global struct 'emu'

    global emu

    % Define dimensions (these must be set before calling this function)
    % You can alternatively set them here by reading from a config file
    if ~isfield(emu, 'nx') || ~isfield(emu, 'ny') || ~isfield(emu, 'nr')
        error('Fields emu.nx, emu.ny, and emu.nr must be set before calling rd_grid.');
    end
    nx = emu.nx;
    ny = emu.ny;
    nr = emu.nr;

    % Helper function to read binary files
    read2d = @(name) reshape(read_bin(emu_ref, name, [nx, ny]), nx, ny);
    read3d = @(name) reshape(read_bin(emu_ref, name, [nx, ny, nr]), nx, ny, nr);
    read1d = @(name, len) read_bin(emu_ref, name, len);

    % 2D fields
    emu.xc = read2d('XC');
    emu.yc = read2d('YC');
    emu.dxc = read2d('DXC');
    emu.dyc = read2d('DYC');
    emu.xg = read2d('XG');
    emu.yg = read2d('YG');
    emu.dxg = read2d('DXG');
    emu.dyg = read2d('DYG');
    emu.cs = read2d('AngleCS');
    emu.sn = read2d('AngleSN');
    emu.rac = read2d('RAC');
    emu.ras = read2d('RAS');
    emu.raw = read2d('RAW');
    emu.raz = read2d('RAZ');

    % 1D vertical arrays
    emu.rc = read1d('RC', [emu.nr 1]);
    emu.rf = read1d('RF', [emu.nr+1 1]);
    emu.drc = read1d('DRC', [emu.nr 1]);
    emu.drf = read1d('DRF', [emu.nr 1]);

    % 3D masks
    emu.hfacc = read3d('hFacC');
    emu.hfacw = read3d('hFacW');
    emu.hfacs = read3d('hFacS');

    % Compute volume elements
    emu.dvol3d = zeros(nx, ny, nr);
    for k = 1:nr
        emu.dvol3d(:, :, k) = emu.hfacc(:, :, k) .* reshape( emu.rac .* emu.drf(k), [nx, ny, 1]); 
    end
end

function data = read_bin(emu_ref, name, shape)
    % READ_BIN Read binary file with big-endian float32
    fname = fullfile(emu_ref, [name '.data']);
    fid = fopen(fname, 'r', 'ieee-be');  % big-endian
    if fid == -1
        error('Failed to open %s', fname);
    end
    data = fread(fid, prod(shape), 'float32');
    fclose(fid);
    if numel(data) ~= prod(shape)
        error('Incorrect number of elements in %s: expected %d, got %d', ...
              fname, prod(shape), numel(data));
    end
end
