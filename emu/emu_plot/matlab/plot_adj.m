% plot_adj.m
% MATLAB equivalent of IDL's plot_adj.pro for EMU Adjoint Tool

function adxx = plot_adj(frun)

global emu

% --- Set EMU output file directory ---
frun_output = fullfile(frun, 'output');

% --- Define list of controls ---
fctrl = {'empmr', 'pload', 'qnet', 'qsw', 'saltflux', 'spflx', 'tauu', 'tauv'};
nctrl = numel(fctrl);

fprintf('\nChoose control to plot:\n');
for i = 1:nctrl
    fprintf('%d) %s\n', i, fctrl{i});
end
ictrl = input(sprintf('\nEnter control # to plot (1-%d): ', nctrl));
ctrlname = fctrl{ictrl};
fname_pattern = fullfile(frun_output, sprintf('adxx_%s.*.data', ctrlname));

files = dir(fname_pattern);
if isempty(files)
    fprintf('*********************************************\n');
    fprintf('File %s not found\n\n', fname_pattern);
    adxx = [];
    return;
elseif numel(files) > 1
    fprintf('*********************************************\n');
    fprintf('More than one file matching %s found\n\n', fname_pattern);
    adxx = [];
    return;
end

full_fname = fullfile(files(1).folder, files(1).name);
fprintf('Found file: %s\n', full_fname);

% get file name
[~, fname, ext] = fileparts(full_fname);
fname = [fname ext];

% --- Read adxx data ---
nx = emu.nx;
ny = emu.ny;
finfo = dir(full_fname);
nadxx = finfo.bytes / (nx * ny * 4);
fid = fopen(full_fname, 'r', 'ieee-be');
adxx = fread(fid, [nx * ny, nadxx], 'float32');
fclose(fid);
adxx = reshape(adxx, nx, ny, nadxx);

dum2d = zeros(nx, ny, 'single');

fprintf('\n*********************************************\n');
fprintf('Read adjoint gradient for %s\n', ctrlname);
fprintf('adxx: adjoint gradient as a function of space and lag\n');
fprintf('from file %s\n',full_fname)
emu.adxx = adxx;

% --- Identify 0-lag and longest lag ---
lag0 = find(any(any(adxx ~= 0, 1), 2), 1, 'last');
lagmax = find(any(any(adxx ~= 0, 1), 2), 1, 'first');

fprintf('Zero lag at (week/record) = %d\n', lag0);
fprintf('Max  lag at (week/record) = %d\n', lagmax);

% Reference mask: top layer of C-cell wet grid
ref2d = nat2globe(squeeze(emu.hfacc(:, :, 1)));

% --- Plot adxx map at user-specified lag ---
fprintf('\n*********************************************\n');
fprintf('Plotting adjoint gradient map at a selected lag ...\n');
while true
    lag_input = input(sprintf('Enter lag to plot (between %d and %d), or empty to skip: ', 0, lag0-lagmax));
    if isempty(lag_input)
        break;
    elseif lag_input < 0 || lag_input > lag0-lagmax
        fprintf('Invalid lag. Please enter a lag between %d and %d.\n', 0, lag0-lagmax);
        continue;
    end
    irec = lag0-lag_input
    dum2d(:) = adxx(:, :, irec);

    % Scale
    dum = max(abs(dum2d(:)));
    if dum ~= 0
      order_of_magnitude = floor(log10(abs(dum)));
      dscale = 10^(-order_of_magnitude);
    else
      dscale = 0;
    end
    dum2d = dum2d * dscale;

    dumg=nat2globe(dum2d);
    dmax = max(dum2d(:));
    dmin = min(dum2d(:));
    if dmin == dmax
      if dmin == 0
        fprintf('\n*****************************\n');
        fprintf('Field is uniformly zero ...\n');
        dmax =  1e-3;
        dmin = -dmax;
      else
        fprintf('\n*****************************\n');
        fprintf('Field is uniform with value = %12.4e\n', dmin);
        dmax = dmax + 1e-3;
        dmin = dmin - 1e-3;
      end
    else
      dd = max(abs([dmax, dmin]));
      dmax = dd;
      dmin = -dd;
    end

    % Apply mask (gray out dry regions)
    dumg(ref2d == 0) = NaN;

    ftitle = sprintf('lag = %d %s scaled by x%e', lag_input, fname, dscale);
    figure;
    h = imagesc(dumg', [dmin dmax]);
    set(h, 'AlphaData', ~isnan(dumg'));
    colormap(jet);
    colorbar;

    axis xy equal tight;
    set(gca, 'Color', [0.5 0.5 0.5]);  % Gray background behind NaNs
    set(gca, 'Layer', 'bottom');       % Axes below image

    title(ftitle, 'Interpreter', 'none');
end

% --- Plot time-series at selected points ---
nlag = lag0 - lagmax + 1;
ww = 0:(nlag - 1);
iww = lag0 - ww;

fprintf('\n*********************************************\n');
fprintf('Plotting time-series of adxx at select locations ...\n');
while true
    resp = input('\nPress 1 to continue or 2 to exit (1/2)? ');
    if resp ~= 1
        break;
    end
    [xlon, ylat, ix, jy] = slct_2d_pt();
    ts = squeeze(adxx(ix, jy, iww));
    ftitle = sprintf('(i,j,lon,lat)= %d %d %.1f %.1f %s', ix, jy, xlon, ylat, fname);
    figure;
    plot(ww, ts);
    xlabel('lag (weeks)'); ylabel('adxx');
    title(ftitle, 'Interpreter', 'none');
end

end
