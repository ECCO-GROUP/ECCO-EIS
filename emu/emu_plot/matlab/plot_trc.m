function plot_trc(frun)
% Read and plot Tracer Tool output

global emu

% ---------------
% Set EMU output file directory
frun_output = fullfile(frun, 'output');

% ---------------
% Search available output

fprintf('\nDetected\n');

fdum = 'ptracer_mon_mean.*.data';
aa_mon = dir(fullfile(frun_output, fdum));
naa_mon = numel(aa_mon);
fprintf('%6d files of %s\n', naa_mon, fdum);

fdum = 'ptracer_mon_snap.*.data';
aa_snap = dir(fullfile(frun_output, fdum));
naa_snap = numel(aa_snap);
fprintf('%6d files of %s\n', naa_snap, fdum);

% Choose variable
fmd = input(sprintf('\nSelect monthly mean or snapshot ... (m/s)? '), 's');

if strcmpi(fmd, 'm')
    fprintf('\n==> Reading and plotting monthly means ...\n');
    ff = fullfile(frun_output, {aa_mon.name});
    [ifile, trc3d] = rd_ptracer(ff);
else
    fprintf('\n==> Reading and plotting snapshots ...\n');
    ff = fullfile(frun_output, {aa_snap.name});
    [ifile, trc3d] = rd_ptracer(ff);
end

fprintf('\n*********************************************\n');
fprintf('Returning variable\n');
fprintf('   trc3d: last plotted tracer\n\n');

emu.trc3d = trc3d; 

end
