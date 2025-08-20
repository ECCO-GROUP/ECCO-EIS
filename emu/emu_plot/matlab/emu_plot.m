function emu_plot()
    % EMU_PLOT  Read and plot EMU output
    %
    %   This script determines which EMU tool produced the output
    %   and invokes the corresponding plotting function.
    
%    try
        %% Determine EMU base directory
        scriptDir = fileparts(mfilename('fullpath'));
        emuDir = fileparts(scriptDir);
        
        % Look for emu_env.* file (excluding .sh)
        envFiles = dir(fullfile(emuDir, 'emu_env.*'));
        envFiles = envFiles(~endsWith({envFiles.name}, '.sh'));
        
        if numel(envFiles) ~= 1
            error('EMU:env', 'Expected exactly one emu_env file (excluding .sh), found %d.', numel(envFiles));
        end
        
        envPath = fullfile(emuDir, envFiles(1).name);
        fid = fopen(envPath, 'r');
        emuInputDir = '';
        while ~feof(fid)
            line = strtrim(fgetl(fid));
            if startsWith(line, 'input_')
                emuInputDir = extractAfter(line, 'input_');
                fprintf('EMU Input Files directory: %s\n', emuInputDir);
                break;
            end
        end
        fclose(fid);
        
        if isempty(emuInputDir)
            error('EMU:env', 'No input_ line found in emu_env file.');
        end
        
        %% Load grid
	global_emu_var();
        emu_ref = fullfile(emuInputDir, 'emu_ref');
        rd_grid(emu_ref);  

        %% Prompt user for EMU run directory
        frun = input('\nEnter directory of EMU run to examine (e.g., emu_samp_m_2_45_585_1): ', 's');
        if ~isfolder(frun)
            error('EMU:input', 'Directory "%s" does not exist.', frun);
        end

        tool = id_tool(frun);  % Determine tool from run name

        fprintf('Reading %s\n\n', frun);

        %% Dispatch to the appropriate tool plot
        switch tool
            case 'samp'
                fprintf('Reading Sampling Tool output.\n');
                plot_samp(frun);
            case 'fgrd'
                fprintf('Reading Forward Gradient Tool output.\n');
                plot_fgrd(frun);
            case 'adj'
                fprintf('Reading Adjoint Tool output.\n');
                plot_adj(frun);
            case 'conv'
                fprintf('Reading Convolution Tool output.\n');
		plot_conv(frun); 
            case 'trc'
                fprintf('Reading Tracer Tool output.\n');
                plot_trc(frun);
            case 'budg'
                fprintf('Reading Budget Tool output.\n');
                plot_budg(frun);
            case 'msim'
                fprintf('Reading Modified Simulation Tool output.\n');
                plot_msim(frun);
            case 'atrb'
                fprintf('Reading Attribution Tool output.\n');
                plot_atrb(frun);
            otherwise
                warning('Tool "%s" not recognized.', tool);
        end

        %% Print loaded global variables (simulate emu structure)
        global emu;
        if ~isempty(emu)
            vars = fieldnames(emu);
            fprintf('\n***********************\n');
            fprintf('EMU variables are avalable in structure named emu.\n');
	    fprintf('Load by \n');
	    fprintf('  >> global emu \n');
%	    fprintf('Available fields: \n');
%            for i = 1:length(vars)
%                fprintf('%-20s', vars{i});
%                if mod(i, 4) == 0, fprintf('\n'); end
%            end
%            if mod(length(vars), 4) ~= 0, fprintf('\n'); end
            fprintf('***********************\n');
        end
        
%    catch ME
%        fprintf('Caught exception: %s\n', ME.message);
%    end
end

function tool = id_tool(frun)
    % ID_TOOL  Determine EMU tool name from directory string
    [~, name] = fileparts(frun);
    parts = split(name, '_');
    if numel(parts) < 3 || ~strcmp(parts{1}, 'emu')
        error('EMU:id', 'Directory name "%s" does not conform to EMU syntax.', name);
    end
    tool = parts{2};
end
