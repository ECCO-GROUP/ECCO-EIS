function plot_conv_recon2d(frun, fctrl, recon1d_sum)
% MATLAB version of IDL plot_conv_recon2d.pro
% Computes spatial explained variance using residual variance (1 - var(resid)/var_all)

global emu

% ---------------
fprintf('Reading recon2d_*.data and computing explained variance vs space (ev_space) ...\n\n');
fprintf('Variable recon2d is the adjoint gradient reconstruction (time-series)\n');
fprintf('as a function of space by a particular control using the maximum lag\n'); 
fprintf('chosen in the convolution. Here, recon2d is read to compute the explained\n'); 
fprintf('variance vs space (ev_space), but recon2d is not retained by this plotting\n');
fprintf('routine to minimize memory usage.\n\n');
% ---------------

frun_output = fullfile(frun, 'output');
nctrl = numel(fctrl);

[nweeks, nlag] = size(recon1d_sum);
recon_all = recon1d_sum(:, nlag);
var_all = var(recon_all, 1);  % normalize by N

ev_space = zeros(emu.nx, emu.ny, nctrl);
ff_ev_space = fullfile(frun_output, 'plot_conv_recon2d.ev_space.mat');

if isfile(ff_ev_space)
    load(ff_ev_space, 'ev_space');
    fprintf('*********************************************\n');
    fprintf('Detected ev_space file. Reading explained variance (EV)\n');
    fprintf('as a function of space and control with respect to \n');
    fprintf('the variance of full reconstruction up to maximum lag. \n');
    fprintf('   ev_space: EV per unit area \n');
    fprintf('from file %s\n\n',ff_ev_space);
else
%    area_mask = emu.rac ~= 0;  % logical mask of valid area grid cells
    area_flat = reshape(emu.rac, emu.nx*emu.ny, 1);
    mask_flat = area_flat ~= 0;

    for i = 1:nctrl
        fname = fullfile(frun_output, ['recon2d_' fctrl{i} '.data']);
        if ~isfile(fname)
            fprintf('*** Missing file: %s\n', fname);
            continue;
        end
        fid = fopen(fname, 'rb', 'ieee-be');
        recon2d = fread(fid, [emu.nx * emu.ny, nweeks], 'float32');
        fclose(fid);
	fprintf('*** Read recon2d from file %s\n\n', fname);

	ts_valid = recon2d(mask_flat, :); 
	resid = ts_valid - recon_all(:)';  % broadcast subtraction
	
	% Compute variance across time (dim 2)
	v_resid = var(resid, 1, 2);              % normalize by N 

	% Compute explained variance per area
	ev_valid = (1 - v_resid / var_all) ./ area_flat(mask_flat);

	% Fill ev_space(:, :, i)
	ev_flat = zeros(emu.nx*emu.ny, 1);
	ev_flat(mask_flat) = ev_valid;
	ev_space(:, :, i) = reshape(ev_flat, emu.nx, emu.ny);

%        recon2d = reshape(recon2d, [emu.nx, emu.ny, nweeks]);
%
%        for ix = 1:emu.nx
%            for iy = 1:emu.ny
%                if ~area_mask(ix, iy)
%                    continue;
%                end
%                ts = squeeze(recon2d(ix, iy, :));
%                resid = recon_all - ts;
%                v_resid = var(resid, 1);
%                ev_space(ix, iy, i) = (1 - v_resid / var_all) / emu.rac(ix,iy);
%            end
%        end
    end

    fprintf('*********************************************\n');
    fprintf('Finished computing explained variance (EV) as a function of \n');
    fprintf('space and control with respect to the variance of full \n');
    fprintf('reconstruction up to maximum lag. \n');
    fprintf('   ev_space: EV per unit area \n\n');
    fprintf('Saving ev_space to file %s\n\n', ff_ev_space);

    save(ff_ev_space, 'ev_space');
end

emu.ev_space = ev_space;

% -------------------------
% Plot explained variance map for user-specified control

fprintf('\nPlot explained variance vs space (ev_space) ...  ');

fprintf('\nChoose control to plot ... \n');

for i = 1:nctrl
  pdum = sprintf('%d) %s', i, fctrl{i});
  disp(pdum);	   
end

dum2d = zeros(emu.nx, emu.ny, 'single');

ic = 1;
while ic >= 1 && ic <= nctrl
    fprintf('\n');

    prompt = sprintf('Enter control to plot explained variance (EV) vs space ...  (1-%d)? ', nctrl);
    ic = input(prompt);
    if ic < 1 || ic > nctrl
        break;
    end
    fprintf('Control chosen: %s\n', fctrl{ic});

    dum2d(:) = ev_space(:,:,ic);

    pinfo = sprintf('%s EV per area (ev_space)', fctrl{ic});
    quickmap(dum2d, pinfo); 

end

end
