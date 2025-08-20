function [naa_2d_day, naa_2d_mon, naa_3d_mon] = plot_state(fdir)
% Read and plot standard state output 

global emu

% -------------------
% Search for available files

fprintf('\nDetected ');

aa_2d_day_struct = dir(fullfile(fdir, 'state_2d_set1_day.*.data'));
aa_2d_day = fullfile(fdir, {aa_2d_day_struct.name});
naa_2d_day = numel(aa_2d_day);
fprintf('\n%6d files of state_2d_set1_day\n', naa_2d_day);

aa_2d_mon_struct = dir(fullfile(fdir, 'state_2d_set1_mon.*.data'));
aa_2d_mon = fullfile(fdir, {aa_2d_mon_struct.name});
naa_2d_mon = numel(aa_2d_mon);
fprintf('%6d files of state_2d_set1_mon\n', naa_2d_mon);

aa_3d_mon_struct = dir(fullfile(fdir, 'state_3d_set1_mon.*.data'));
aa_3d_mon = fullfile(fdir, {aa_3d_mon_struct.name});
naa_3d_mon = numel(aa_3d_mon);
fprintf('%6d files of state_3d_set1_mon\n', naa_3d_mon);

% ---------------
% Test whether any output was detected 

ndum = max([naa_2d_day, naa_2d_mon, naa_3d_mon]);
if ndum == 0
    fprintf('\n*********************************************\n');
    fprintf('No standard state output found in directory\n%s\n', fdir);
    return;
end

% -------------------
% Available variables
f_var = {'SSH', 'OBP', 'THETA', 'SALT', 'U', 'V'};
nvar = numel(f_var);

% -------------------
% Plot loop
plot_another = 'Y';
while strcmpi(plot_another, 'Y')
    fprintf('\nVariables to plot:\n');
    for i = 1:nvar
        fprintf('%d) %s\n', i, f_var{i});
    end

    fprintf('\nSelect monthly or daily mean ... (m/d)?\n');
    fprintf('(NOTE: daily mean available for SSH and OBP only.)\n');
    fmd = 'n';
    tmp = input(' ', 's');
    if ~isempty(tmp)
      fmd = tmp;
    end

    % ---------------
    % Reading state_2d_set1_day
    if strcmpi(fmd, 'd')
        if naa_2d_day == 0
            fprintf('\nNo daily mean output available.\n');
        else
            fprintf('\n==> Reading and plotting daily means ...\n');
            ivar = input('Enter variable # to plot ... (1-2)? ');
            if ivar < 1 || ivar > 2, continue; end

	    fprintf('\nPlotting ... %s',f_var{ivar});

	    % ---------------------------      
	    % loop among daily mean 2d files 
            pfile = 1;
            while pfile >= 1 && pfile <= naa_2d_day
                pfile = input(sprintf('\nEnter file # to read ... (1-%d)? ', naa_2d_day));
                if pfile < 1 || pfile > naa_2d_day, break; end

                fld2d = rd_state2d(aa_2d_day{pfile}, ivar);
                [~, fname, ext] = fileparts(aa_2d_day{pfile});
                pinfo = sprintf('%s %d %s%s', f_var{ivar}, pfile, fname, ext);
                plt_state2d(fld2d, pinfo);
            end
            fprintf('*********************************************\n');
            fprintf('Returning variable \n');
            fprintf('   fld2d: last plotted 2d field\n\n');
	    emu.fld2d = fld2d; 
        end

    else
        fprintf('\n==> Reading and plotting 2d monthly means ...\n');

        ivar = input(sprintf('\nEnter variable # to plot ... (1-%d)? ', nvar));
        if ivar < 1 || ivar > nvar, continue; end

	fprintf('\nPlotting ... %s',f_var{ivar});

        if ivar <= 2
            if naa_2d_mon == 0
                fprintf('\nNo monthly mean 2d output available.\n');
            else
                pfile = 1;
                while pfile >= 1 && pfile <= naa_2d_mon
                    pfile = input(sprintf('\nEnter file # to read ... (1-%d)? ', naa_2d_mon));
                    if pfile < 1 || pfile > naa_2d_mon, break; end

                    fld2d = rd_state2d(aa_2d_mon{pfile}, ivar);
                    [~, fname, ext] = fileparts(aa_2d_mon{pfile});
                    pinfo = sprintf('%s %d %s%s', f_var{ivar+1}, pfile, fname, ext);
                    plt_state2d(fld2d, pinfo);
                end
		fprintf('*********************************************\n');
		fprintf('Returning variable \n');
		fprintf('   fld2d: last plotted 2d field\n\n');
		emu.fld2d = fld2d; 
            end
        else
            if naa_3d_mon == 0
                fprintf('\nNo monthly mean 3d output available.\n');
            else
                fprintf('\n==> Reading and plotting 3d monthly means ...\n');
		fprintf('\nPlotting ... %s',f_var{ivar});

		% ---------------------------      
		% loop among monthly mean 3d files 
                pfile = 1;
                while pfile >= 1 && pfile <= naa_3d_mon
                    pfile = input(sprintf('\nEnter file # to read ... (1-%d)? ', naa_3d_mon));
                    if pfile < 1 || pfile > naa_3d_mon, break; end

                    fld3d = rd_state3d(aa_3d_mon{pfile}, ivar - 2);
                    [~, fname, ext] = fileparts(aa_3d_mon{pfile});
                    pinfo = sprintf('%s %d %s%s', f_var{ivar}, pfile, fname, ext);
                    plt_state3d(fld3d, pinfo, ivar-2);
                end
		fprintf('*********************************************\n');
		fprintf('Returning variable \n');
		fprintf('   fld3d: last plotted 3d field\n\n');
		emu.fld3d = fld3d; 
            end
        end
    end

    plot_another = input('\nPlot another file ... (Y/N)? ', 's');
end
