function [emubudg_name, emubudg, lhs, rhs, adv, mix, frc, nvar, ibud, tt] = rd_budg_sum(ff)
    % RD_BUDG_SUM  Read and sort Budget Tool summary output file emu_budg.sum_*
    %
    % Inputs:
    %   ff - full path to emu_budg.sum_? file
    %
    % Outputs:
    %   emubudg_name - cell array of variable names
    %   emubudg      - [nvar x nmonths] matrix of data
    %   lhs, rhs     - left and right-hand side time series for budget
    %   adv, mix, frc - grouped budget terms
    %   nvar         - number of variables
    %   ibud         - budget ID (1-based)
    %   tt           - time in decimal years

    emubudg_name = {};
    emubudg = [];
    lhs = [];
    rhs = [];
    adv = [];
    mix = [];
    frc = [];
    nvar = 0;
    ibud = 0;
    tt = [];

    if ~isfile(ff)
        fprintf('*********************************************\n');
        fprintf('File %s not found ...\n\n', ff);
        return
    end

    fid = fopen(ff, 'r', 'ieee-be');  % big-endian

    % Budget ID
    ibud = fread(fid, 1, 'int32');
    if ibud < 1 || ibud > 5
        fprintf('INVALID ibud in this Budget Tool output ... %d\n', ibud);
        fclose(fid);
        return
    end

    % Number of months
    nmonths = fread(fid, 1, 'int32');

    % Read fields
    emubudg_name = {};
    emubudg = zeros(0, nmonths);
    while ~feof(fid)
        fvar_bytes = fread(fid, 12, 'uint8=>char')';
        if length(fvar_bytes) < 12
            break
        end
        fvar = strtrim(fvar_bytes);
        emubudg_name{end+1} = fvar;
        fdum = fread(fid, nmonths, 'float32')';
        if isempty(fdum) || length(fdum) < nmonths
            break
        end
        emubudg(end+1, :) = fdum;
    end
    fclose(fid);

    nvar = numel(emubudg_name);

    % Time axis
    tt = (0:(nmonths-1)) / 12 + 1992;

    % RHS is the sum of all terms after index 2
    lhs = emubudg(2, :);
    rhs = sum(emubudg(3:end, :), 1);

    % Group by term types
    adv = zeros(1, nmonths);
    mix = zeros(1, nmonths);
    frc = zeros(1, nmonths);

    for it = 1:nvar
        name = emubudg_name{it};
        if contains(name, 'adv')
            adv = adv + emubudg(it, :);
        elseif contains(name, 'mix')
            mix = mix + emubudg(it, :);
        elseif ~any(strcmp(name, {'dt', 'lhs'})) && ...
               ~contains(name, 'adv') && ~contains(name, 'mix')
            frc = frc + emubudg(it, :);
        end
    end

    if ~any(contains(emubudg_name, 'adv')), disp('**** no adv terms ***'); end
    if ~any(contains(emubudg_name, 'mix')), disp('**** no mix terms ***'); end
    if all(cellfun(@(n) contains(n, 'dt') || contains(n, 'lhs') || ...
                   contains(n, 'adv') || contains(n, 'mix'), emubudg_name))
        disp('**** no frc terms ***');
    end
end
