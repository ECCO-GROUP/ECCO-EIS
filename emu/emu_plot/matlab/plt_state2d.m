function plt_state2d(v2d, pinfo)
    % PLT_STATE2D  Plot 2D variable with geographic mapping and masking
    %
    %   v2d  - 2D array (ny x nx)
    %   pinfo - string with label (e.g., 'SSH 12 state_2d_set1_day.000001.data')

    global emu

    % Reference mask: top layer of C-cell wet grid
    ref2d = nat2globe(squeeze(emu.hfacc(:, :, 1)));

    % Scale to O(1)
    dum = max(abs(v2d(:)));
    if dum ~= 0
        dscale = 10^(-floor(log10(dum)));
    else
        dscale = 0.0;
    end
    dum2d = v2d * dscale;

    % Map to global projection
    dumg = nat2globe(dum2d);

    % Apply mask (gray out dry regions)
    dumg(ref2d == 0) = NaN;

%    % Plot
%    figure('Position', [100, 100, 800, 800]);
%    imagesc(dumg');
%    axis xy equal tight;
%    colormap(jet);
%    colorbar;
%    title(sprintf('%s scaled by x%.1e', pinfo, dscale));

    pinfo2 = sprintf('%s scaled by x%.1e', pinfo, dscale);
    quickimage(dumg, pinfo2); 

end
