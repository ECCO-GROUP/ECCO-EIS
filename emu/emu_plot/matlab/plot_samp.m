function plot_samp(frun)
    % PLOT_SAMP  Read and plot EMU sampling tool output
    %
    %   Input:
    %     frun - path to EMU run directory (e.g., 'emu_samp_m_2_45_585_1')

    global emu
    byte_order = 'ieee-be';  % Big-endian
    ff = fullfile(frun, 'output');

    % ----------------------------------------
    % Read samp.out_? (temporal anomaly + mean)
    % ----------------------------------------
    files = dir(fullfile(ff, 'samp.out_*'));
    if numel(files) ~= 1
        if isempty(files)
            fprintf('*********************************************\n');
            fprintf('File samp.out_* not found ...\n\n');
        else
            fprintf('*********************************************\n');
            fprintf('More than one samp.out_* file found ...\n\n');
        end
        return
    end

    fname = fullfile(ff, files(1).name);
    rec_tag = extractAfter(files(1).name, 'samp.out_');
    nrec = str2double(rec_tag);

    fid = fopen(fname, 'r', byte_order);
    smp = fread(fid, nrec, 'float32');
    smp_mn = fread(fid, 1, 'float32');
    fclose(fid);

    emu.smp = smp;
    emu.smp_mn = smp_mn;

    fprintf('\n*********************************************\n');
    fprintf('Read variables\n');
    fprintf('   smp: temporal anomaly of sampled variable\n');
    fprintf('   smp_mn: reference time-mean of sampled variable\n');
    fprintf('from file %s\n', fname);

    % ----------------------------------------
    % Read samp.step_? (sample times)
    % ----------------------------------------
    fname_step = fullfile(ff, ['samp.step_' rec_tag]);
    if ~isfile(fname_step)
        fprintf('\n*********************************************\n');
        fprintf('File %s not found ...\n\n', ['samp.step_' rec_tag]);
        return
    end

    fid = fopen(fname_step, 'r', byte_order);
    smp_hr = fread(fid, nrec, 'int32');
    fclose(fid);

    emu.smp_hr = smp_hr;

    fprintf('\n*********************************************\n');
    fprintf('Read variable\n');
    fprintf('   smp_hr: sample time (hours from 1/1/1992 12Z)\n');
    fprintf('from file %s\n', fname_step);

    % ----------------------------------------
    % Time conversion and plot
    % ----------------------------------------
    smp_yday = smp_hr / 24 / 365 + 1992;  % Convert hours to decimal year
    samp_t = smp_yday;
    samp_v = smp + smp_mn;

    [~, frun_name] = fileparts(frun);
    tmin = floor(min(samp_t)) - 1;
    tmax = ceil(max(samp_t)) + 1;

    fprintf('\nPlotting sampled time-series ...\n');

    figure;
    plot(samp_t, samp_v, 'DisplayName', 'smp + smp\_mn');
    title(frun_name, 'Interpreter', 'none');
    xlabel('Time (decimal year)');
    ylabel('Sampled value');
    xlim([tmin tmax]);
    grid on;
    legend show;
end
