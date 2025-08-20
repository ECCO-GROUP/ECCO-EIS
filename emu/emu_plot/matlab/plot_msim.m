function plot_msim(frun)
% Check Modified Simulation Tool output

% ---------------
% Set EMU output file directory
frun_output = fullfile(frun, 'diags');

% ---------------
% Search files

fprintf('\nChecking EMU standard model state output ... \n\n');

% Call plot_state function
[naa_2d_day, naa_2d_mon, naa_3d_mon] = plot_state(frun_output);

ndum = max([naa_2d_day, naa_2d_mon, naa_3d_mon]);

fprintf('\n*********************************************\n');
if ndum ~= 0
    fprintf('EMU''s standard model state output can be sampled using EMU''s\n');
    fprintf('Sampling Tool, specifying the diag subdirectory of this run\n');
    fprintf('in response to the Tool''s prompt;\n');
    fprintf('%s\n\n', frun_output);
else
    fprintf('No diagnostic state output found in this run''s diag subdirectory.\n');
    fprintf('%s\n\n', frun_output);
end

% ---------------
% Search subdirectories

fprintf('\n*********************************************\n');
fprintf('Checking Budget output ...\n');

% List entries in diag directory
entries = dir(frun_output);
entries = entries([entries.isdir]);  % Keep only directories
entries = entries(~ismember({entries.name}, {'.', '..'}));  % Exclude . and ..

subdir_count = numel(entries);

if subdir_count ~= 0
    % Count total number of .data files in subdirectories
    data_files = dir(fullfile(frun_output, '*', '*.data'));
    total_file_count = numel(data_files);

    if total_file_count ~= 0
        fprintf('\nTotal number of subdirectories: %d\n\n', subdir_count);

        subdir_count2 = 0;
        for i = 1:subdir_count
            subdir_path = fullfile(frun_output, entries(i).name);
            files = dir(fullfile(subdir_path, '*.data'));
            file_count = numel(files);

            subdir_count2 = subdir_count2 + 1;
            fprintf('   %d) %s has %d files\n', ...
                subdir_count2, entries(i).name, file_count);
        end

        fprintf('\n*********************************************\n');
        fprintf('Budget output of this run can be analyzed using\n');
        fprintf('EMU''s Budget Tool, specifying the diag subdirectory of this run\n');
        fprintf('in response to the Tool''s prompt;\n');
        fprintf('%s\n\n', fullfile(frun, 'diags'));
    else
        fprintf('\nNo budget output found in this run''s diag subdirectory.\n');
        fprintf('%s\n\n', fullfile(frun, 'diags'));
    end
else
    fprintf('No budget output found in this run''s diag subdirectory.\n');
    fprintf('%s\n\n', fullfile(frun, 'diags'));
end
end
