function plot_conv(frun)
% Read Convolution Tool output
% MATLAB equivalent of IDL plot_conv.pro, with outputs

global emu

% Set output directory
frun_output = fullfile(frun, 'output');

% Determine number of lags from frun string
tokens = regexp(frun, '_', 'split');
if length(tokens) >= 3 && length(tokens{end}) == 7
    nlag = str2double(tokens{end-2}) + 1;
else
    parts = regexp(frun, '_', 'split');
    nlag = str2double(parts{end}) + 1;
end

% Control variables
fctrl = {'empmr', 'pload', 'qnet', 'qsw', 'saltflux', 'spflx', 'tauu', 'tauv'};
nctrl = numel(fctrl);

emu.fctrl = fctrl; 

% ---------------
% Read recon1d (Reconstruction time-series summed in space. Function
% of lag and control.)

nweeks = 1357; % maximum number of weeks that should be in EMU Convolution Tool output

recon1d = zeros(nweeks, nlag, nctrl);
recon1d_sum = zeros(nweeks, nlag);

for i = 1:nctrl
    fname = fullfile(frun_output, ['recon1d_' fctrl{i} '.data']);
    if ~isfile(fname)
        fprintf('*** Missing file: %s\n', fname);
        continue;
    end
    fid = fopen(fname, 'rb', 'ieee-be');
    dum = fread(fid, [nweeks, nlag], 'float32');
    fclose(fid);
    recon1d(:,:,i) = dum;
    recon1d_sum = recon1d_sum + dum;
end

emu.recon1d = recon1d; 

fprintf('*********************************************\n');
fprintf('Read variable recon1d, the global spatial sum time-series \n');
fprintf('of the convolution as a function of lag and control.\n');
fprintf('   recon1d: adjoint gradient reconstruction\n');
fprintf('from file recon1d_*.data\n\n');

% ---------------
% Read istep (time-step; All istep files are identical)

istep = zeros(nweeks, 1, 'int32');

i = 1;  % MATLAB is 1-based indexing
ff = fullfile(frun_output, ['istep_' fctrl{i} '.data']);

if ~isfile(ff)
    fprintf('*********************************************\n');
    fprintf('No istep_%s.data file found ...\n\n', fctrl{i});
    return;
end

% Open and read file big-endian
fid = fopen(ff, 'r', 'ieee-be');  

istep = fread(fid, nweeks, 'int32');
fclose(fid);

% Convert hours since 1/1/1992 12Z to decimal year
ww = double(istep) / 24 / 365 + 1992;
wwmin = floor(min(ww)) - 1;
wwmax = floor(max(ww)) + 1;

fprintf('*********************************************\n');
fprintf('Read variable\n');
fprintf('   istep: time (hours since 1/1/1992 12Z) of recon1d\n');
fprintf('from file istep_%s.data\n\n', fctrl{i});

% -------------------------
% Compute Explained Variance vs lag (w/ all control)

ev_lag = zeros(1, nlag);
ev_ctrl = zeros(1, nctrl);

vref = var(recon1d_sum(:,nlag),1);
for ilag = 1:nlag
    ev_lag(ilag) = 1. - var(recon1d_sum(:,ilag)-recon1d_sum(:,nlag),1)/vref;
end

emu.ev_lag = ev_lag; 

fprintf('*********************************************\n');
fprintf('Computed Explained Variance (EV) vs lag with all controls. \n');
fprintf('   ev_lag: EV as function of lag\n\n');

% Explained Variance vs control (at max lag) 
vref = var(recon1d_sum(:,nlag),1); 
for ictrl = 1:nctrl
    ev_ctrl(ictrl) = 1. - var(recon1d(:,nlag,ictrl)-recon1d_sum(:,nlag),1)/vref;
end

emu.ev_ctrl = ev_ctrl; 

fprintf('*********************************************\n');
fprintf('Computed Explained Variance (EV) vs control at maximum lag. \n');
fprintf('   ev_ctrl: EV as function of control\n\n');

% ========== Plotting ==========
figure('Position', [100, 100, 1000, 800]);

ip = nlag-1; 

while ip >= 0 && ip <= nlag - 1
  clf; 
   
  % --- Top: Recon Time-series at user-specified lag ---
  subplot(2,2,[1 2]);
  hold on;
  plot(ww, recon1d_sum(:, ip+1), 'k'); % recon1d_sum in black
  xlim([wwmin, wwmax]);  
  colors = lines(nctrl);
  for i = 1:nctrl
    plot(ww, recon1d(:, ip+1, i), '-', 'Color', colors(i,:), 'DisplayName', fctrl{i});
  end
  xlabel('Time (Year)');
  ylabel('Reconstruction Value');
  title(sprintf('recon1d: reconstruction at Lag %d Weeks', ip));
  legend('Total', fctrl{:}, 'Location', 'bestoutside');
  grid on;
  hold off;

% Plot EV vs lag
  subplot(2,2,3);
  plot(0:nlag-1, ev_lag, 'LineWidth', 2);
  xlabel('Lag (weeks)');
  ylabel('Explained Variance');
  title('Exp Var vs Lag (ev_lag)', 'Interpreter', 'none');
  hold on;
  plot(ip, ev_lag(ip+1), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);  

% Plot EV vs control at max lag 
  subplot(2,2,4);
  bar(categorical(fctrl), ev_ctrl);
  ylabel('Explained Variance');
  title(sprintf('Exp Var vs Control (ev_ctrl) at lag %d', nlag-1), 'Interpreter', 'none');

  prompt = sprintf('Enter lag to plot ... (0-%d or -1 to exit)? ', nlag - 1);
  ip = input(prompt);
end

% ---------------
% Optionally read recon2d and compute explained variance as a function
% of space

reply = input('\nCompute/plot explained variance vs space ... (y/n)?', 's');

if contains(reply, 'y', 'IgnoreCase', true)
  plot_conv_recon2d(frun, fctrl, recon1d_sum);
end

end
