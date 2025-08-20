function plot_atrb(frun)
    % PLOT_ATRB Read and plot Attribution Tool output from EMU
    %
    %   Input:
    %     frun - path to EMU run directory (e.g., 'emu_atrb_m_2_45_585_1')

    global emu
    byte_order = 'ieee-be';  % Big-endian
    ff = fullfile(frun, 'output');

    % ----------------------
    % List of control terms
    % ----------------------
    fctrl = {'ref', 'wind', 'htflx', 'fwflx', 'sflx', 'pload', 'ic', 'mean'};
    nterms = numel(fctrl);

    % ----------------------
    % Read atrb.out_? file
    % ----------------------
    files = dir(fullfile(ff, 'atrb.out_*'));
    if numel(files) ~= 1
        fprintf('\n*********************************************\n');
        if isempty(files)
            fprintf('File atrb.out_* not found ...\n\n');
        else
            fprintf('More than one atrb.out_* found ...\n\n');
        end
        return
    end

    fname = fullfile(ff, files(1).name);
    rec_tag = extractAfter(files(1).name, 'atrb.out_');
    nrec = str2double(rec_tag);

    % Check number of terms in file
    info = dir(fname);
    nbytes = info.bytes;
    nfloat = nbytes / 4;  % number of float32 values
    mterms = fix(nfloat / (nrec + 1));  % number of terms in file

    if mterms == 7
      fprintf('\n');
      fprintf('*********************************************\n');
      fprintf('!!!! BEWARE !!!!\n');
      fprintf('Chosen EMU output is that of an older version of Attribution Tool\n');
      fprintf('with 7 terms and excludes contributions from the mean.\n');
      fprintf('\n');
    end

    % Read binary data
    fid = fopen(fname, 'r', byte_order);
    atrb = fread(fid, [nrec, mterms], 'float32');
    atrb_mn = fread(fid, mterms, 'float32');
    fclose(fid);

    fprintf('*********************************************\n');
    fprintf('Read OBJF and contributions to it from different controls\n');
    fprintf('   atrb: temporal anomaly \n');
    fprintf('   atrb_mn: reference time-mean \n');
    fprintf('   atrb_ctrl: names of atrb/atrb_mn variables \n');
    fprintf('from file %s\n\n', fname);

    emu.atrb = atrb;
    emu.atrb_mn = atrb_mn;
    emu.atrb_ctrl = fctrl;

    % ----------------------
    % Read atrb.step_? file
    % ----------------------
    step_file = fullfile(ff, ['atrb.step_' rec_tag]);
    if ~isfile(step_file)
        fprintf('*********************************************\n');
        fprintf('File %s not found ...\n\n', ['atrb.step_' rec_tag]);
        return
    end

    fid = fopen(step_file, 'r', byte_order);
    atrb_hr = fread(fid, nrec, 'int32');
    fclose(fid);

    fprintf('*********************************************\n');
    fprintf('Read variable \n');
    fprintf('   atrb_hr: sample time (hours from 1/1/1992 12Z)\n');
    fprintf('from file %s\n\n', step_file);

    emu.atrb_hr = atrb_hr;

    % ----------------------
    % Time conversion and plot
    % ----------------------
    atrb_t = double(atrb_hr) / 24 / 365 + 1992;
    [~, frun_name] = fileparts(frun);

    tmin = floor(min(atrb_t)) - 1;
    tmax = ceil(max(atrb_t)) + 1;

    figure;
    hold on
    plot(atrb_t, atrb(:, 1), 'DisplayName', fctrl{1});
    for i = 2:mterms
	      plot(atrb_t, atrb(:, i), 'DisplayName', fctrl{i});
    end
    hold off
    legend show 
    title(frun_name, 'Interpreter', 'none');
    xlabel('Time (decimal year)');
    ylabel('atrb');
    xlim([tmin, tmax]);
    grid on;
end
