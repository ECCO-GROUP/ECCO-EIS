function plt_state3d(v3d, pinfo, ivar)
    % PLT_STATE3D  Plot a horizontal slice of a 3D variable at chosen depth
    %
    %   v3d   - 3D array (nr x ny x nx)
    %   pinfo - string label for plot
    %   ivar  - variable index to determine mask type
    %           1=THETA, 2=SALT, 3=U, 4=V

    global emu

    while true
        kdum = input(sprintf('Enter depth # to plot ... (1-%d)? ', emu.nr));
        if kdum < 1 || kdum > emu.nr
            break;
        end

        % Extract 2D slice and scale
        dum2d = squeeze(v3d(:, :, kdum));
        dum = max(abs(dum2d(:)));
        if dum ~= 0
            dscale = 10^(-floor(log10(dum)));
        else
            dscale = 0.0;
        end
        dum2d = dum2d * dscale;

        % Choose mask type
        if ivar == 3
    	    ref2d = nat2globe(squeeze(emu.hfacw(:, :, kdum)));
        elseif ivar == 4
     	    ref2d = nat2globe(squeeze(emu.hfacs(:, :, kdum)));
        else
   	    ref2d = nat2globe(squeeze(emu.hfacc(:, :, kdum)));
        end

        % Project and mask
        dumg = nat2globe(dum2d);
        dumg(ref2d == 0) = NaN;

%        % Plot
%        figure('Position', [100, 100, 800, 800]);
%        imagesc(dumg');
%        axis xy equal tight;
%        colormap(jet);
%        colorbar;
%        title(sprintf('%s depth %d scaled by x%.1e', pinfo, kdum, dscale));

        pinfo2 = sprintf('%s depth %d scaled by x%.1e', pinfo, kdum, dscale);
        quickimage(dumg, pinfo2); 

    end
end
