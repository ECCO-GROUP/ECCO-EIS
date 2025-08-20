function quickmap(dum2d, pinfo)
    % Plot 2D LLC array dum2d into global map format 

    global emu

    % Reference mask: top layer of C-cell wet grid
    ref2d = nat2globe(squeeze(emu.hfacc(:, :, 1)));

    % Scale
    dum = max(abs(dum2d(:)));
    if dum ~= 0
      order_of_magnitude = floor(log10(abs(dum)));
      dscale = 10^(-order_of_magnitude);
    else
      dscale = 0;
    end
    dum2d = dum2d * dscale;

    dumg=nat2globe(dum2d);

    % Apply mask (gray out dry regions)
    dumg(ref2d == 0) = NaN;

    ftitle = sprintf('%s scaled by x%e', pinfo, dscale);
    quickimage(dumg, ftitle); 
end
