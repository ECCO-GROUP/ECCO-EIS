% slct_2d_pt.m
% MATLAB equivalent of IDL's slct_2d_pt.pro
% Prompts user to select a horizontal grid point by (i,j) or by lon/lat

function [xlon, ylat, ix, jy] = slct_2d_pt()

% Access EMU grid variables
global emu

fprintf('\nChoose horizontal location ...\n');e
fprintf('Enter 1 to select native grid location (i,j),\n');
fprintf('or 9 to select by longitude/latitude ... (1 or 9)?\n');
iloc = input('Selection: ');

if iloc ~= 9
    % Select native grid point by index
    ix = 0;
    jy = 0;
    fprintf('Identify point in native grid ...\n');
    while ix < 1 || ix > emu.nx
        ix = input(sprintf('i ... (1-%d)? ', emu.nx));
    end
    while jy < 1 || jy > emu.ny
        jy = input(sprintf('j ... (1-%d)? ', emu.ny));
    end
    xlon = emu.xc(ix, jy);
    ylat = emu.yc(ix, jy);
else
    % Select by lon/lat
    check_d = false;
    fprintf('Enter location\''s lon/lat (E, N) ...\n');
    while ~check_d
        xlon = input('longitude ... (E)? ');
        ylat = input('latitude ... (N)? ');

        [ix, jy] = ijloc(xlon, ylat);  % function must return 1-based indices

        xlon = emu.xc(ix, jy);
        ylat = emu.yc(ix, jy);

        if emu.hfacc(ix, jy, 1) == 0
            fprintf('Closest C-grid (%d, %d) is dry.\n', ix, jy);
            fprintf('Select another point ...\n');
        else
            check_d = true;
        end
    end
end

% Confirm
fprintf('...... Chosen point is (i,j) = (%d, %d)\n', ix, jy);
fprintf('C-grid is (lon E, lat N) = (%.2f, %.2f)\n', xlon, ylat);

end
