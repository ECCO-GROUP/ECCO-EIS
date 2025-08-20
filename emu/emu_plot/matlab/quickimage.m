function quickimage(dumg, pinfo)
    % Plot 2D variable dumg

    figure('Position', [100, 100, 800, 800]);

    imagesc(dumg', 'AlphaData', ~isnan(dumg'));  % Transparency mask: NaNs invisible
    colormap(jet);
    colorbar;

    axis xy equal tight;
    set(gca, 'Color', [0.5 0.5 0.5]);  % Gray background behind NaNs
    set(gca, 'Layer', 'bottom');       % Axes below image

    title(pinfo, 'Interpreter', 'none');
end
