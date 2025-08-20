function plot_fgrd(frun)
    % PLOT_FGRD  Read and plot EMU forward gradient tool output
    %
    %   Input:
    %     frun - path to EMU run directory (e.g., 'emu_fgrd_7_15_743_124_-1.00E-0')
    global emu

    % Set EMU output directory
    ff = fullfile(frun, 'output');

    % Search available output files
    aa_2d_day = dir(fullfile(ff, 'state_2d_set1_day.*.data'));
    aa_2d_mon = dir(fullfile(ff, 'state_2d_set1_mon.*.data'));
    aa_3d_mon = dir(fullfile(ff, 'state_3d_set1_mon.*.data'));

    naa_2d_day = numel(aa_2d_day);
    naa_2d_mon = numel(aa_2d_mon);
    naa_3d_mon = numel(aa_3d_mon);

    fprintf('%6d files of state_2d_set1_day\n', naa_2d_day);
    fprintf('%6d files of state_2d_set1_mon\n', naa_2d_mon);
    fprintf('%6d files of state_3d_set1_mon\n', naa_3d_mon);

    % Define variable list
    f_var = {'SSH', 'OBP', 'THETA', 'SALT', 'U', 'V'};
    nvar = numel(f_var);

    fprintf('\nVariables to plot ...\n');
    for i = 1:nvar
        fprintf('%d) %s\n', i, f_var{i});
    end

    fmd = lower(input('\nSelect monthly or daily mean (m/d)? ', 's'));

    if strcmp(fmd, 'd')
        fprintf('==> Reading and plotting daily means ...\n');
        pvar = 0;
        while pvar < 1 || pvar > 2
            pvar = input('Enter variable # to plot ... (1-2)? ');
        end
        ivar = pvar;

        while true
            pfile = input(sprintf('Enter file # to read ... (1-%d or -1 to exit)? ', naa_2d_day));
            if pfile < 1 || pfile > naa_2d_day
                break;
            end
            fname = fullfile(ff, aa_2d_day(pfile).name);
            fgrd2d = rd_state2d_r4(fname, ivar);
            title_str = sprintf('%s %d %s', f_var{ivar}, pfile, aa_2d_day(pfile).name);
            plt_state2d(fgrd2d, title_str);
        end
	fprintf('\n*********************************************')
        fprintf('\nReturning variable: fgrd2d (last plotted gradient 2D)\n');
	emu.fgrd2d = fgrd2d;

    else
        fprintf('==> Reading and plotting monthly means ...\n');
        pvar = 0;
        while pvar < 1 || pvar > nvar
            pvar = input(sprintf('Enter variable # to plot ... (1-%d)? ', nvar));
        end
        ivar = pvar;

        if ivar <= 2  % 2D case
            while true
                pfile = input(sprintf('Enter file # to read ... (1-%d or -1 to exit)? ', naa_2d_mon));
                if pfile < 1 || pfile > naa_2d_mon
                    break;
                end
                fname = fullfile(ff, aa_2d_mon(pfile).name);
                fgrd2d = rd_state2d_r4(fname, ivar);
                title_str = sprintf('%s %d %s', f_var{ivar}, pfile, aa_2d_mon(pfile).name);
                plt_state2d(fgrd2d, title_str);
            end
	    fprintf('\n*********************************************')
            fprintf('\nReturning variable: fgrd2d (last plotted gradient 2D)\n');
	    emu.fgrd2d = fgrd2d;

        else  % 3D case
            while true
                pfile = input(sprintf('Enter file # to read ... (1-%d or -1 to exit)? ', naa_3d_mon));
                if pfile < 1 || pfile > naa_3d_mon
                    break;
                end
                fname = fullfile(ff, aa_3d_mon(pfile).name);
                fgrd3d = rd_state3d(fname, ivar - 2);  % no 3D SSH/OBP
                title_str = sprintf('%s %d %s', f_var{ivar}, pfile, aa_3d_mon(pfile).name);
                plt_state3d(fgrd3d, title_str, ivar - 2);
            end
	    fprintf('\n*********************************************')
            fprintf('\nReturning variable: fgrd3d (last plotted gradient 3D)\n');
	    emu.fgrd3d = fgrd3d;
        end
    end
end
