function [ifile, trc] = rd_ptracer(ff)
% Read a 3d tracer field from a particular file ff(ifile), 
% plot vertical integral, and return the 3d tracer field. 

% Access global emu variables
global emu 

nx = emu.nx;
ny = emu.ny;
nr = emu.nr;

% Set variables
n_ff = numel(ff);
trc = zeros(nx, ny, nr);
dum2d = zeros(nx, ny);

idum = 1;

% Create land mask
[dumg] = nat2globe(emu.hfacc(:,:,1));
landg = find(dumg == 0);  % index where it is dry

% Loop among files
while idum >= 1 && idum <= n_ff
    ifile = input(sprintf('\nEnter file # to read ... (1-%d or -1 to exit)? ', n_ff));
    if ifile < 1 || ifile > n_ff 
        break;
    end

    fprintf('\nReading file ... %s\n', ff{ifile});

    fid = fopen(ff{ifile}, 'r', 'ieee-be');
    trc = fread(fid, [nx*ny*nr, 1], 'float32');
    fclose(fid);
    trc = reshape(trc, [nx, ny, nr]);

    dum2d(:) = 0;
    for k = 1:nr
        dum2d = dum2d + trc(:,:,k) * emu.drf(k) .* emu.hfacc(:,:,k);
    end

    dum2d_sum = sum(dum2d(:) .* emu.rac(:));

    [~, fname, ext] = fileparts(ff{ifile});
    fname = [fname ext];
    [timestep] = get_timestep(fname, 'ptracer_mon');

    fprintf('\ntime-step              = %d\n', timestep);
    fprintf('global volume integral = %g\n', dum2d_sum);

    % scale
    dum = max(abs(dum2d(:)));
    order_of_magnitude = floor(log10(abs(dum)));
    dscale = 10^(-order_of_magnitude);
    dum2d = dum2d * dscale;

    % plot
    dumg = nat2globe(dum2d);
    dmin = min(dum2d(:));
    dmax = max(dum2d(:));
    dumg(landg) = NaN;

    ftitle = sprintf(' %d %s scaled by x%.0e', ifile, fname, dscale);
    quickimage(dumg, ftitle);
end
end
